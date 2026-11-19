"""Interstate waybill network: cities, hubs, carriers and lanes.

A waybill moves a package between cities in three legs:

- **first mile**: a Yummy Chops rider collects it from the sender (cities where Yummy Chops riders work) or the sender
  drops it at a hub;
- **line haul**: a partner carrier takes it from the origin hub to the destination hub on a scheduled departure;
- **last mile**: a Yummy Chops rider delivers it to the door (Lagos, Enugu) or the recipient collects it at the hub.

The default network below is **sample data** (placeholder hubs and carriers, flagged `is_sample`) until real logistics
partners are signed. Lane prices are configuration; the arithmetic lives in `domain/pricing.py`.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Literal
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field

from .geo import GeoPoint, haversine_km
from .models import ParcelSize, WaybillDetails, WaybillStage

LAGOS_TZ = ZoneInfo("Africa/Lagos")
PICKUP_TO_HUB = timedelta(hours=3)  # typical time for a first-mile rider to bring a package to the hub


class WaybillCity(BaseModel):
    id: str = Field(pattern=r"^[a-z][a-z-]{1,30}$")
    name: str
    state: str
    center: GeoPoint
    door_service: bool = False  # Yummy Chops riders work here: home pickup and door delivery


class Hub(BaseModel):
    id: str = Field(pattern=r"^[a-z0-9-]{2,40}$")
    name: str
    city: str
    kind: Literal["gm_hub", "partner_terminal"] = "gm_hub"
    address: str
    location: GeoPoint
    phone: str
    hours: str = "Mon–Sat, 8am–7pm"
    accepts_dropoff: bool = True
    offers_collection: bool = True
    is_sample: bool = True


class Carrier(BaseModel):
    id: str
    name: str
    is_sample: bool = True


class WaybillLane(BaseModel):
    id: str
    origin_city: str
    destination_city: str
    carrier_id: str
    transit_days_min: int = Field(ge=0, le=14)
    transit_days_max: int = Field(ge=0, le=14)
    departure_weekdays: list[int] = Field(default_factory=lambda: [0, 1, 2, 3, 4, 5])  # Monday = 0
    cutoff_hour: int = Field(
        default=15, ge=0, le=23
    )  # at the origin hub by this Lagos hour → leaves that day
    base_by_size_kobo: dict[ParcelSize, int]
    included_kg_by_size: dict[ParcelSize, float]
    per_extra_kg_kobo: int = Field(default=30_000, ge=0)  # ₦300 per kg above the included weight
    carrier_share_bps: int = Field(
        default=6_000, ge=0, le=10_000
    )  # share of the line-haul fee owed to the carrier
    is_active: bool = True


class WaybillNetwork(BaseModel):
    version: int = 1
    cities: list[WaybillCity]
    hubs: list[Hub]
    carriers: list[Carrier]
    lanes: list[WaybillLane]
    service_fee_kobo: int = Field(default=20_000, ge=0)  # ₦200 booking fee
    max_kg_by_size: dict[ParcelSize, float] = Field(
        default_factory=lambda: {ParcelSize.SMALL: 5.0, ParcelSize.MEDIUM: 10.0, ParcelSize.LARGE: 20.0}
    )

    def city(self, city_id: str) -> WaybillCity | None:
        return next((c for c in self.cities if c.id == city_id), None)

    def city_name(self, city_id: str) -> str:
        city = self.city(city_id)
        return city.name if city else city_id.replace("-", " ").title()

    def hub(self, hub_id: str) -> Hub | None:
        return next((h for h in self.hubs if h.id == hub_id), None)

    def carrier(self, carrier_id: str) -> Carrier | None:
        return next((c for c in self.carriers if c.id == carrier_id), None)

    def lane(self, origin_city: str, destination_city: str) -> WaybillLane | None:
        return next(
            (
                ln
                for ln in self.lanes
                if ln.is_active and ln.origin_city == origin_city and ln.destination_city == destination_city
            ),
            None,
        )

    def destinations(self, origin_city: str) -> list[WaybillLane]:
        return [ln for ln in self.lanes if ln.is_active and ln.origin_city == origin_city]

    def origins(self) -> list[str]:
        return sorted({ln.origin_city for ln in self.lanes if ln.is_active})

    def hubs_in(self, city_id: str, *, dropoff: bool = False, collection: bool = False) -> list[Hub]:
        return [
            h
            for h in self.hubs
            if h.city == city_id
            and (not dropoff or h.accepts_dropoff)
            and (not collection or h.offers_collection)
        ]

    def nearest_hub(
        self, city_id: str, point: GeoPoint | None, *, dropoff: bool = False, collection: bool = False
    ) -> Hub | None:
        hubs = self.hubs_in(city_id, dropoff=dropoff, collection=collection)
        if not hubs:
            return None
        if point is None:
            return hubs[0]
        return min(hubs, key=lambda h: haversine_km(point, h.location))


def lagos_date(moment: datetime) -> date:
    return moment.astimezone(LAGOS_TZ).date()


def next_departure(lane: WaybillLane, at_hub: datetime) -> date:
    """First departure day once the package is at the origin hub (after the cut-off it waits for the next one)."""
    local = at_hub.astimezone(LAGOS_TZ)
    day = local.date() + timedelta(days=1 if local.hour >= lane.cutoff_hour else 0)
    for _ in range(15):
        if day.weekday() in lane.departure_weekdays:
            return day
        day += timedelta(days=1)
    raise ValueError(f"Lane {lane.id} has no departure days")


def delivery_window(
    lane: WaybillLane, booked_at: datetime, *, first_mile: str, last_mile: str
) -> tuple[date, date]:
    """Estimated arrival dates (Lagos dates). Drop-offs are assumed to reach the hub the day they are booked."""
    at_hub = booked_at + (PICKUP_TO_HUB if first_mile == "pickup" else timedelta(0))
    departs = next_departure(lane, at_hub)
    earliest = departs + timedelta(days=lane.transit_days_min)
    latest = departs + timedelta(days=lane.transit_days_max + (1 if last_mile == "door" else 0))
    return earliest, latest


# ------------------------------------------------------------------------------------------------
# Customer-facing progress
# ------------------------------------------------------------------------------------------------

WAYBILL_STEPS = ("Booked", "At the hub", "On the way", "Arrived", "Delivered")
_STAGE_STEP = {
    WaybillStage.AWAITING_DROPOFF: 0,
    WaybillStage.PICKUP_SCHEDULED: 0,
    WaybillStage.PICKED_UP: 0,
    WaybillStage.AT_ORIGIN_HUB: 1,
    WaybillStage.DEPARTED: 2,
    WaybillStage.AT_DESTINATION_HUB: 3,
    WaybillStage.OUT_FOR_DELIVERY: 3,
    WaybillStage.READY_FOR_COLLECTION: 3,
    WaybillStage.DELIVERED: 4,
    WaybillStage.CANCELLED: -1,
}


def stage_label(details: WaybillDetails, stage: WaybillStage | None = None) -> str:
    stage = stage or details.stage
    origin = details.origin_city_name or details.origin_city
    destination = details.destination_city_name or details.destination_city
    return {
        None: "Awaiting payment",
        WaybillStage.AWAITING_DROPOFF: f"Drop off at {details.origin_hub_name or 'the hub'}",
        WaybillStage.PICKUP_SCHEDULED: "Rider pickup booked",
        WaybillStage.PICKED_UP: "Collected by the rider",
        WaybillStage.AT_ORIGIN_HUB: f"At the {origin} hub",
        WaybillStage.DEPARTED: f"On the way to {destination}",
        WaybillStage.AT_DESTINATION_HUB: f"Arrived in {destination}",
        WaybillStage.OUT_FOR_DELIVERY: "Out for delivery",
        WaybillStage.READY_FOR_COLLECTION: f"Ready for collection at {details.destination_hub_name or 'the hub'}",
        WaybillStage.DELIVERED: "Delivered",
        WaybillStage.CANCELLED: "Cancelled",
    }[stage]


def stage_step(details: WaybillDetails) -> int:
    return _STAGE_STEP.get(details.stage, 0) if details.stage else 0


# ------------------------------------------------------------------------------------------------
# Sample network (placeholder hubs, addresses, phones and carriers until real partners sign)
# ------------------------------------------------------------------------------------------------

_S, _M, _L = ParcelSize.SMALL, ParcelSize.MEDIUM, ParcelSize.LARGE
_INCLUDED = {_S: 2.0, _M: 5.0, _L: 10.0}


def _lane(
    lane_id: str,
    origin: str,
    destination: str,
    carrier: str,
    days: tuple[int, int],
    base: tuple[int, int, int],
) -> WaybillLane:
    return WaybillLane(
        id=lane_id,
        origin_city=origin,
        destination_city=destination,
        carrier_id=carrier,
        transit_days_min=days[0],
        transit_days_max=days[1],
        base_by_size_kobo={_S: base[0], _M: base[1], _L: base[2]},
        included_kg_by_size=dict(_INCLUDED),
    )


def default_network() -> WaybillNetwork:
    return WaybillNetwork(
        cities=[
            WaybillCity(
                id="lagos",
                name="Lagos",
                state="Lagos",
                center=GeoPoint(lat=6.4550, lng=3.4200),
                door_service=True,
            ),
            WaybillCity(
                id="enugu",
                name="Enugu",
                state="Enugu",
                center=GeoPoint(lat=6.4500, lng=7.5100),
                door_service=True,
            ),
            WaybillCity(id="abuja", name="Abuja", state="FCT", center=GeoPoint(lat=9.0765, lng=7.3986)),
            WaybillCity(
                id="port-harcourt",
                name="Port Harcourt",
                state="Rivers",
                center=GeoPoint(lat=4.8156, lng=7.0498),
            ),
        ],
        hubs=[
            Hub(
                id="lagos-ikeja",
                name="Yummy Chops Hub, Ikeja (sample)",
                city="lagos",
                address="Sample address: Allen Avenue, Ikeja, Lagos",
                location=GeoPoint(lat=6.6018, lng=3.3515),
                phone="+234 000 000 0011",
            ),
            Hub(
                id="lagos-lekki",
                name="Yummy Chops Hub, Lekki (sample)",
                city="lagos",
                address="Sample address: Admiralty Way, Lekki Phase 1, Lagos",
                location=GeoPoint(lat=6.4478, lng=3.4723),
                phone="+234 000 000 0012",
            ),
            Hub(
                id="enugu-independence",
                name="Yummy Chops Hub, Independence Layout (sample)",
                city="enugu",
                address="Sample address: Nike Lake Road, Independence Layout, Enugu",
                location=GeoPoint(lat=6.4440, lng=7.5180),
                phone="+234 000 000 0021",
            ),
            Hub(
                id="abuja-utako",
                name="Partner terminal, Utako (sample)",
                city="abuja",
                kind="partner_terminal",
                address="Sample address: Utako District, Abuja",
                location=GeoPoint(lat=9.0700, lng=7.4360),
                phone="+234 000 000 0031",
                accepts_dropoff=False,
            ),
            Hub(
                id="ph-gra",
                name="Partner terminal, GRA Phase 2 (sample)",
                city="port-harcourt",
                kind="partner_terminal",
                address="Sample address: GRA Phase 2, Port Harcourt",
                location=GeoPoint(lat=4.8150, lng=7.0150),
                phone="+234 000 000 0041",
                accepts_dropoff=False,
            ),
        ],
        carriers=[
            Carrier(id="sample-east", name="Sample Carrier East"),
            Carrier(id="sample-north", name="Sample Carrier North"),
            Carrier(id="sample-south", name="Sample Carrier South"),
        ],
        lanes=[
            _lane("lagos-enugu", "lagos", "enugu", "sample-east", (1, 2), (450_000, 650_000, 950_000)),
            _lane("enugu-lagos", "enugu", "lagos", "sample-east", (1, 2), (450_000, 650_000, 950_000)),
            _lane("lagos-abuja", "lagos", "abuja", "sample-north", (1, 2), (500_000, 700_000, 1_000_000)),
            _lane(
                "lagos-port-harcourt",
                "lagos",
                "port-harcourt",
                "sample-south",
                (2, 3),
                (500_000, 750_000, 1_050_000),
            ),
            _lane("enugu-abuja", "enugu", "abuja", "sample-north", (1, 2), (450_000, 650_000, 950_000)),
            _lane(
                "enugu-port-harcourt",
                "enugu",
                "port-harcourt",
                "sample-south",
                (1, 1),
                (350_000, 500_000, 750_000),
            ),
        ],
    )
