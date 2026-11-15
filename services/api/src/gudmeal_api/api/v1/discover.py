"""Discover tab: dish-first feed (most loved dishes, new kitchens, top-rated kitchens). Public, no sign-in."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Query

from ...domain.geo import GeoPoint
from ...errors import ValidationFailed
from ...services.discover import DiscoverFeed, DiscoverService
from ..deps import Ctr

router = APIRouter(prefix="/v1/discover", tags=["public"])


@router.get("/dishes", response_model=DiscoverFeed)
async def discover_dishes(
    c: Ctr,
    city: Annotated[str | None, Query(max_length=30)] = None,
    lat: Annotated[float | None, Query(ge=-90, le=90)] = None,
    lng: Annotated[float | None, Query(ge=-180, le=180)] = None,
    limit: Annotated[int, Query(ge=1, le=12)] = 6,
) -> DiscoverFeed:
    """Hero dishes for the Discover carousel. With lat/lng, each dish carries delivery fee and ETA."""
    if (lat is None) != (lng is None):
        raise ValidationFailed("Provide both lat and lng")
    location = GeoPoint(lat=lat, lng=lng) if lat is not None and lng is not None else None
    return await DiscoverService(c.repos, c.catalog).dishes(city=city, location=location, limit=limit)
