"""Keyless fallback: GudMeals' own neighbourhood table and straight-line estimates.

Used when no Google Maps key is configured, when Google is unreachable, or when the daily request cap
is reached. Results are labelled ``source="local"`` / ``"estimate"`` with ``precision="area"`` so the
apps can say "about" and never imply a measured route or a rooftop pin.
"""

from __future__ import annotations

import math
from decimal import Decimal

from ..domain import places
from ..domain.cities import city_name
from ..domain.geo import GeoPoint, haversine_km
from .models import PlaceResult, PlaceSuggestion, RouteEstimate

AREA_PREFIX = "area:"
#: Reverse geocoding only names a neighbourhood when its centre is this close.
REVERSE_RADIUS_KM = 4.0


def area_id(area: places.Area) -> str:
    return f"{AREA_PREFIX}{area.city}:{area.name}"


def _area_result(area: places.Area) -> PlaceResult:
    return PlaceResult(
        place_id=area_id(area),
        formatted_address=f"{area.name}, {city_name(area.city)}",
        location=area.location,
        area=area.name,
        city=area.city,
        precision="area",
        source="local",
    )


class LocalMapsProvider:
    def autocomplete(
        self, text: str, *, near: GeoPoint | None = None, city: str | None = None, limit: int = 6
    ) -> list[PlaceSuggestion]:
        q = text.strip().lower()
        if len(q) < 2:
            return []
        hits = []
        for a in places.areas(city):
            names = [a.name.lower(), *a.aliases]
            if any(q in n or n in q for n in names) or any(w.startswith(q) for n in names for w in n.split()):
                hits.append(a)
        if not hits:
            found = places.find_area(text, city)
            hits = [found] if found else []
        if near is not None:
            hits.sort(key=lambda a: haversine_km(near, a.location))
        return [
            PlaceSuggestion(
                place_id=area_id(a),
                title=a.name,
                subtitle=city_name(a.city),
                distance_m=round(haversine_km(near, a.location) * 1000) if near is not None else None,
                source="local",
            )
            for a in hits[:limit]
        ]

    def place(self, place_id: str) -> PlaceResult | None:
        if not place_id.startswith(AREA_PREFIX):
            return None
        city, _, name = place_id[len(AREA_PREFIX) :].partition(":")
        for a in places.areas(city):
            if a.name == name:
                return _area_result(a)
        return None

    def geocode(self, address: str, city: str | None = None) -> PlaceResult | None:
        area = places.find_area(address, city)
        return _area_result(area) if area else None

    def reverse_geocode(self, point: GeoPoint) -> PlaceResult | None:
        nearest = min(places.areas(), key=lambda a: haversine_km(point, a.location), default=None)
        if nearest is None or haversine_km(point, nearest.location) > REVERSE_RADIUS_KM:
            return None
        return PlaceResult(
            place_id=None,  # a GPS fix is not a neighbourhood centre: keep the customer's own coordinates
            formatted_address=f"Near {nearest.name}, {city_name(nearest.city)}",
            location=point,
            area=nearest.name,
            city=nearest.city,
            precision="approximate",
            source="local",
        )

    def route(
        self, origin: GeoPoint, destination: GeoPoint, *, road_factor: Decimal, avg_speed_kmh: Decimal
    ) -> RouteEstimate:
        """Straight line x a road factor at an average city speed: the pre-Maps pricing model."""
        km = haversine_km(origin, destination) * float(road_factor)
        minutes = max(1, math.ceil(km / float(avg_speed_kmh) * 60))
        return RouteEstimate(distance_km=round(km, 3), duration_minutes=minutes, source="estimate")
