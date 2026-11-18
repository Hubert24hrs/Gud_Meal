"""Cities GudMeals operates in. Delivery zones (pricing config) belong to a city via `ZoneConfig.city`."""

from __future__ import annotations

from dataclasses import dataclass

from .geo import GeoPoint


@dataclass(frozen=True, slots=True)
class City:
    id: str
    name: str
    state: str
    center: GeoPoint


CITIES: dict[str, City] = {
    "lagos": City("lagos", "Lagos", "Lagos", GeoPoint(lat=6.4550, lng=3.4200)),
    "enugu": City("enugu", "Enugu", "Enugu", GeoPoint(lat=6.4500, lng=7.5100)),
}


def city_name(city_id: str) -> str:
    city = CITIES.get(city_id)
    return city.name if city else city_id.title()
