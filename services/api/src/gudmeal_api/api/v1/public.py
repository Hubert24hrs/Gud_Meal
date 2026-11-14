"""Unauthenticated discovery endpoints (SEO pages and browsing before sign-in)."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Query
from sqlalchemy import text

from ...domain.geo import GeoPoint
from ...errors import ServiceUnavailable, ValidationFailed
from ...services.catalog import RestaurantCard, RestaurantDetail
from ..deps import Ctr

router = APIRouter(prefix="/v1", tags=["public"])


def _location(lat: float | None, lng: float | None) -> GeoPoint | None:
    if (lat is None) != (lng is None):
        raise ValidationFailed("Provide both lat and lng")
    return GeoPoint(lat=lat, lng=lng) if lat is not None and lng is not None else None


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/ready")
async def ready(c: Ctr) -> dict[str, str]:
    try:
        async with c.db.session() as s:
            await s.execute(text("SELECT 1"))
    except Exception as exc:
        raise ServiceUnavailable("Database unavailable") from exc
    return {"status": "ready"}


@router.get("/restaurants", response_model=list[RestaurantCard])
async def list_restaurants(
    c: Ctr,
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
    cuisine: Annotated[str | None, Query(max_length=40)] = None,
    q: Annotated[str | None, Query(max_length=60)] = None,
    open_now: bool = False,
    sort: Literal["recommended", "distance", "rating", "delivery_fee"] = "recommended",
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
) -> list[RestaurantCard]:
    return await c.catalog.list_restaurants(
        location=_location(lat, lng), cuisine=cuisine, query=q, open_now=open_now, sort=sort, limit=limit
    )


@router.get("/restaurants/{restaurant_id}", response_model=RestaurantDetail)
async def restaurant_detail(
    restaurant_id: str,
    c: Ctr,
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
) -> RestaurantDetail:
    return await c.catalog.get_restaurant_detail(restaurant_id, location=_location(lat, lng))


@router.get("/restaurants/{restaurant_id}/reviews")
async def restaurant_reviews(
    restaurant_id: str, c: Ctr, limit: Annotated[int, Query(ge=1, le=50)] = 20
) -> list[Any]:
    return await c.reviews.for_restaurant(restaurant_id, limit)


@router.get("/search")
async def search(
    c: Ctr,
    q: Annotated[str, Query(min_length=2, max_length=60)],
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
) -> dict[str, Any]:
    return await c.catalog.search(q, location=_location(lat, lng))


@router.get("/cuisines")
async def cuisines(c: Ctr) -> list[dict[str, Any]]:
    return await c.catalog.cuisines()


@router.get("/config/public")
async def public_config(c: Ctr) -> dict[str, Any]:
    cfg = await c.repos.get_pricing_config()
    flags = await c.repos.list_feature_flags()
    return {
        "currency": "NGN",
        "service_fee_bps": cfg.service_fee_bps,
        "service_fee_min_kobo": cfg.service_fee_min_kobo,
        "service_fee_max_kobo": cfg.service_fee_max_kobo,
        "small_order_threshold_kobo": cfg.small_order_threshold_kobo,
        "small_order_fee_kobo": cfg.small_order_fee_kobo,
        "vat_bps": cfg.vat_bps,
        "zones": [
            {"id": z.id, "name": z.name, "center": z.center, "radius_km": z.radius_km}
            for z in cfg.zones
            if z.is_active
        ],
        "features": {k: bool(v.get("enabled")) for k, v in flags.items()},
        "payment_providers": sorted(c.providers),
    }
