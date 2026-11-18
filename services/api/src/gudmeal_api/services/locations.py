"""Restaurant locations: where a kitchen is, whether the pin matches its address, and its delivery coverage.

Rules (they protect customers' prices and riders' routes, which both depend on the pin):

* the pin must be inside a delivery zone of the restaurant's own city;
* when Google can place the street address, the pin must be within ``PIN_TOLERANCE_KM`` of it unless the
  partner confirms the pin (e.g. a back entrance) - the mismatch is returned with Google's suggested point;
* partners can correct their pin by up to ``SELF_SERVICE_MOVE_KM``; larger moves and delivery-radius changes
  need GudMeals staff (``restaurants:manage``);
* every change is written to the audit log.
"""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field

from ..domain.geo import GeoPoint, geohash_encode, haversine_km
from ..errors import NotFound, PermissionDenied, ValidationFailed
from ..ledger.audit import AuditLog
from ..maps import MapsService
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, require_restaurant

SELF_SERVICE_MOVE_KM = 2.0
PIN_TOLERANCE_KM = 1.0


class LocationInput(BaseModel):
    address: str = Field(min_length=5, max_length=200)
    location: GeoPoint
    area: str | None = Field(default=None, max_length=80)
    place_id: str | None = Field(default=None, max_length=300)
    confirm_pin: bool = False
    delivery_radius_km: float | None = Field(default=None, gt=0, le=40)


class RestaurantLocationService:
    def __init__(self, repos: Repositories, maps: MapsService, audit: AuditLog) -> None:
        self.repos = repos
        self.maps = maps
        self.audit = audit

    async def get(self, principal: Principal, restaurant_id: str) -> dict[str, Any]:
        require_restaurant(principal, restaurant_id, "settings")
        r = await self.repos.restaurants.get(restaurant_id)
        if r is None:
            raise NotFound("Restaurant not found")
        zone = (await self.repos.get_pricing_config()).zone_for(r.location)
        return {
            "restaurant_id": r.id,
            "address": r.address,
            "area": r.area,
            "city": r.city,
            "location": r.location.model_dump(),
            "delivery_radius_km": r.delivery_radius_km,
            "zone": zone.name if zone else None,
            "in_service_area": zone is not None and zone.city == r.city,
            "maps_provider": self.maps.provider,
        }

    async def update(self, principal: Principal, restaurant_id: str, data: LocationInput) -> dict[str, Any]:
        require_restaurant(principal, restaurant_id, "settings")
        r = await self.repos.restaurants.get(restaurant_id)
        if r is None:
            raise NotFound("Restaurant not found")
        staff = principal.can(Permission.RESTAURANTS_MANAGE)
        point = data.location

        zone = (await self.repos.get_pricing_config()).zone_for(point)
        if zone is None or zone.city != r.city:
            raise ValidationFailed("That pin is outside the areas we deliver in your city")

        checked = await self.maps.geocode(data.address, city=r.city)
        if checked is not None and checked.source == "google" and checked.precision in ("rooftop", "street"):
            gap = haversine_km(checked.location, point)
            if gap > PIN_TOLERANCE_KM and not data.confirm_pin:
                raise ValidationFailed(
                    f"The pin is {gap:.1f} km from that address. Move the pin to your entrance, or confirm it.",
                    details={
                        "suggested_location": checked.location.model_dump(),
                        "distance_km": round(gap, 2),
                    },
                )

        moved = haversine_km(r.location, point)
        if moved > SELF_SERVICE_MOVE_KM and not staff:
            raise PermissionDenied(
                "Moving more than 2 km needs GudMeals to verify the new address. Please contact partner support.",
                details={"moved_km": round(moved, 2)},
            )
        changes: dict[str, Any] = {
            "location": point,
            "geohash": geohash_encode(point.lat, point.lng, 9),
            "address": data.address.strip(),
            "area": data.area or (checked.area if checked and checked.area else r.area),
        }
        if data.delivery_radius_km is not None and data.delivery_radius_km != r.delivery_radius_km:
            if not staff:
                raise PermissionDenied("Delivery coverage is set by GudMeals operations")
            changes["delivery_radius_km"] = data.delivery_radius_km
        await self.repos.restaurants.save(r.model_copy(update=changes))
        await self.audit.record(
            actor_id=principal.uid,
            actor_roles=principal.audit_roles(),
            action="restaurant.location_updated",
            resource_type="restaurant",
            resource_id=r.id,
            details={
                "from": r.location.model_dump(),
                "to": point.model_dump(),
                "moved_km": round(moved, 3),
                "address": changes["address"],
                "pin_confirmed": data.confirm_pin,
                "delivery_radius_km": changes.get("delivery_radius_km"),
            },
        )
        return await self.get(principal, restaurant_id)
