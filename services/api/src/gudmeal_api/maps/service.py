"""MapsService: the single entry point for places, geocoding and routes.

Google Maps Platform when ``GOOGLE_MAPS_API_KEY`` is set (server key, Secret Manager in the cloud), the
keyless neighbourhood/estimate fallback otherwise or whenever Google fails. Cost and policy controls:

* Places session tokens + Essentials field masks; autocomplete results are never cached.
* Coordinates for a place id / address are cached for 24 h; road routes for 5 min (traffic changes).
* A per-instance daily request cap (``MAPS_DAILY_REQUEST_CAP``) stops runaway spend; GCP API quotas and
  budget alerts are the account-level backstop (see docs/GOOGLE_MAPS.md).
"""

from __future__ import annotations

import logging
import time
from collections import OrderedDict
from collections.abc import Callable
from datetime import UTC, datetime
from typing import Any
from zoneinfo import ZoneInfo

import httpx

from ..domain.geo import GeoPoint
from ..domain.pricing import PricingConfig
from .google import MAX_MATRIX_ORIGINS, GoogleMapsClient
from .local import AREA_PREFIX, LocalMapsProvider
from .models import MapsError, PlaceResult, PlaceSuggestion, RouteEstimate

log = logging.getLogger("gudmeal_api.maps")
LAGOS = ZoneInfo("Africa/Lagos")

PLACE_TTL_SECONDS = 24 * 3600
ROUTE_TTL_SECONDS = 300


class _TTLCache:
    """Small in-memory LRU with expiry (per Cloud Run instance)."""

    def __init__(self, ttl: float, max_items: int, clock: Callable[[], float]) -> None:
        self.ttl = ttl
        self.max_items = max_items
        self._clock = clock
        self._data: OrderedDict[str, tuple[float, Any]] = OrderedDict()

    def get(self, key: str) -> Any | None:
        hit = self._data.get(key)
        if hit is None:
            return None
        expires, value = hit
        if expires < self._clock():
            self._data.pop(key, None)
            return None
        self._data.move_to_end(key)
        return value

    def put(self, key: str, value: Any) -> None:
        self._data[key] = (self._clock() + self.ttl, value)
        self._data.move_to_end(key)
        while len(self._data) > self.max_items:
            self._data.popitem(last=False)


def _point_key(p: GeoPoint) -> str:
    return f"{p.lat:.4f},{p.lng:.4f}"  # ~11 m: nearby pings share a cached route


class MapsService:
    def __init__(
        self,
        google: GoogleMapsClient | None,
        *,
        daily_cap: int = 20_000,
        routes_enabled: bool = True,
        live_refresh_seconds: int = 180,
        clock: Callable[[], float] = time.monotonic,
        today: Callable[[], str] | None = None,
    ) -> None:
        self.google = google
        self.local = LocalMapsProvider()
        self.daily_cap = daily_cap
        self.routes_enabled = routes_enabled
        self.live_refresh_seconds = max(30, live_refresh_seconds)
        self._today = today or (lambda: datetime.now(UTC).astimezone(LAGOS).date().isoformat())
        self._day = self._today()
        self._used = 0
        self._capped_logged = False
        self._places = _TTLCache(PLACE_TTL_SECONDS, 5_000, clock)
        self._routes = _TTLCache(ROUTE_TTL_SECONDS, 5_000, clock)

    @classmethod
    def from_settings(cls, settings: Any, http: httpx.AsyncClient) -> MapsService:
        key = settings.google_maps_api_key.get_secret_value() if settings.google_maps_api_key else ""
        google = (
            GoogleMapsClient(
                key,
                http,
                travel_mode=settings.maps_travel_mode,
                traffic_aware=settings.maps_traffic_aware,
                timeout=settings.maps_timeout_seconds,
            )
            if key
            else None
        )
        return cls(
            google,
            daily_cap=settings.maps_daily_request_cap,
            routes_enabled=settings.maps_routes_enabled,
            live_refresh_seconds=settings.maps_live_eta_refresh_seconds,
        )

    # ------------------------------------------------------------------------------ budget
    @property
    def provider(self) -> str:
        return "google" if self.google is not None else "local"

    def _allow(self, calls: int = 1) -> bool:
        """Count Google calls against today's cap; False means "use the fallback"."""
        if self.google is None:
            return False
        today = self._today()
        if today != self._day:
            self._day, self._used, self._capped_logged = today, 0, False
        if self._used + calls > self.daily_cap:
            if not self._capped_logged:
                log.warning("maps daily request cap reached; using estimates", extra={"cap": self.daily_cap})
                self._capped_logged = True
            return False
        self._used += calls
        return True

    def status(self) -> dict[str, Any]:
        return {
            "provider": self.provider,
            "routes": "google" if self.google is not None and self.routes_enabled else "estimate",
            "traffic_aware": bool(self.google and self.google.traffic_aware),
            "live_eta_refresh_seconds": self.live_refresh_seconds,
            "requests_today": self._used,
            "daily_cap": self.daily_cap,
        }

    # ------------------------------------------------------------------------------ places
    async def autocomplete(
        self,
        text: str,
        *,
        session_token: str | None = None,
        near: GeoPoint | None = None,
        city: str | None = None,
    ) -> list[PlaceSuggestion]:
        text = text.strip()
        if len(text) < 2:
            return []
        if self._allow():
            try:
                found = await self.google.autocomplete(text, session_token=session_token, near=near)  # type: ignore[union-attr]
                if found:
                    return found
            except MapsError as exc:
                log.warning("places autocomplete failed; using neighbourhoods", extra={"error": str(exc)})
        return self.local.autocomplete(text, near=near, city=city)

    async def place(self, place_id: str, *, session_token: str | None = None) -> PlaceResult | None:
        if place_id.startswith(AREA_PREFIX):
            return self.local.place(place_id)
        cached = self._places.get(f"place:{place_id}")
        if cached is not None:
            return cached
        if not self._allow():
            return None
        try:
            result = await self.google.place(place_id, session_token=session_token)  # type: ignore[union-attr]
        except MapsError as exc:
            log.warning("place details failed", extra={"error": str(exc)})
            return None
        self._places.put(f"place:{place_id}", result)
        return result

    async def geocode(self, address: str, *, city: str | None = None) -> PlaceResult | None:
        key = f"geo:{city}:{' '.join(address.lower().split())}"
        cached = self._places.get(key)
        if cached is not None:
            return cached
        if self._allow():
            try:
                found = await self.google.geocode(address)  # type: ignore[union-attr]
                if found is not None and (city is None or found.city == city):
                    self._places.put(key, found)
                    return found
            except MapsError as exc:
                log.warning("geocoding failed; using neighbourhoods", extra={"error": str(exc)})
        return self.local.geocode(address, city)

    async def reverse(self, point: GeoPoint) -> PlaceResult | None:
        key = f"rev:{_point_key(point)}"
        cached = self._places.get(key)
        if cached is not None:
            return cached
        if self._allow():
            try:
                found = await self.google.reverse_geocode(point)  # type: ignore[union-attr]
                if found is not None:
                    # keep the device's own fix: the address is a label, the pin is what riders navigate to
                    found = found.model_copy(update={"location": point})
                    self._places.put(key, found)
                    return found
            except MapsError as exc:
                log.warning("reverse geocoding failed; using neighbourhoods", extra={"error": str(exc)})
        return self.local.reverse_geocode(point)

    # ------------------------------------------------------------------------------ routes
    def estimate(self, origin: GeoPoint, destination: GeoPoint, cfg: PricingConfig) -> RouteEstimate:
        return self.local.route(
            origin, destination, road_factor=cfg.delivery.road_factor, avg_speed_kmh=cfg.avg_speed_kmh
        )

    async def route(self, origin: GeoPoint, destination: GeoPoint, cfg: PricingConfig) -> RouteEstimate:
        """Road distance and travel time: measured by Google when available, otherwise an estimate."""
        key = f"{_point_key(origin)}>{_point_key(destination)}"
        cached = self._routes.get(key)
        if cached is not None:
            return cached
        if self.routes_enabled and self._allow():
            try:
                found = await self.google.route(origin, destination)  # type: ignore[union-attr]
                self._routes.put(key, found)
                return found
            except MapsError as exc:
                log.warning("routes failed; using estimate", extra={"error": str(exc)})
        return self.estimate(origin, destination, cfg)

    async def routes_to(
        self, origins: list[GeoPoint], destination: GeoPoint, cfg: PricingConfig
    ) -> list[RouteEstimate]:
        """Routes from several kitchens to one customer (one matrix call for the uncached ones)."""
        out: list[RouteEstimate | None] = []
        missing: list[int] = []
        for i, o in enumerate(origins):
            hit = self._routes.get(f"{_point_key(o)}>{_point_key(destination)}")
            out.append(hit)
            if hit is None:
                missing.append(i)
        batch = missing[:MAX_MATRIX_ORIGINS]
        if batch and self.routes_enabled and self._allow(len(batch)):
            try:
                found = await self.google.route_matrix([origins[i] for i in batch], destination)  # type: ignore[union-attr]
                for i, est in zip(batch, found, strict=True):
                    if est is not None:
                        self._routes.put(f"{_point_key(origins[i])}>{_point_key(destination)}", est)
                        out[i] = est
            except MapsError as exc:
                log.warning("route matrix failed; using estimates", extra={"error": str(exc)})
        return [
            est if est is not None else self.estimate(o, destination, cfg)
            for o, est in zip(origins, out, strict=True)
        ]
