"""Interstate waybill: lane pricing, schedules, postings, state rules and guards (pure domain, no I/O)."""

import random
from datetime import UTC, date, datetime

import pytest

from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.logistics import (
    default_network,
    delivery_window,
    next_departure,
    stage_label,
    stage_step,
)
from gudmeal_api.domain.models import (
    Fulfillment,
    Order,
    ParcelSize,
    PaymentSummary,
    PriceBreakdown,
    SettlementTerms,
    Vertical,
    WaybillDetails,
    WaybillParty,
    WaybillStage,
)
from gudmeal_api.domain.money import apply_bps
from gudmeal_api.domain.order_state import ActorType, OrderStatus, can_transition
from gudmeal_api.domain.pricing import PricingConfig, compute_waybill_price, parcel_fee, waybill_linehaul_fee
from gudmeal_api.errors import InvalidTransition, ValidationFailed
from gudmeal_api.ledger.ledger import _owner, leg_rider_pay, validate_postings, waybill_completed
from gudmeal_api.services.orders import OrderService

S = OrderStatus
A = ActorType
NET = default_network()
LANE = NET.lane("lagos", "enugu")
WAT = datetime(2026, 11, 16, 9, 0, tzinfo=UTC)  # Monday 10:00 in Lagos


def _price(**kw):
    args = {
        "lane": LANE,
        "size": ParcelSize.SMALL,
        "weight_kg": 1.0,
        "max_weight_kg": 5.0,
        "service_fee_kobo": NET.service_fee_kobo,
        "pickup_km": None,
        "delivery_km": None,
        "cod_amount_kobo": None,
        "cfg": PricingConfig(),
    }
    return compute_waybill_price(**{**args, **kw})


# ------------------------------------------------------------------------------------- pricing
def test_linehaul_fee_charges_whole_extra_kilos_above_the_included_weight():
    assert waybill_linehaul_fee(LANE, ParcelSize.SMALL, 2.0) == 450_000  # 2 kg included
    assert waybill_linehaul_fee(LANE, ParcelSize.SMALL, 2.01) == 480_000  # any part of a kg counts
    assert waybill_linehaul_fee(LANE, ParcelSize.SMALL, 4.5) == 450_000 + 3 * 30_000
    assert waybill_linehaul_fee(LANE, ParcelSize.LARGE, 10.0) == 950_000


def test_waybill_price_adds_rider_legs_cod_fee_and_vat_on_everything():
    cfg = PricingConfig()
    plain = _price().breakdown
    assert (plain.linehaul_fee_kobo, plain.pickup_fee_kobo, plain.delivery_fee_kobo) == (450_000, 0, 0)
    assert plain.total_kobo == 450_000 + 20_000 + apply_bps(470_000, cfg.vat_bps)

    full = _price(weight_kg=3.2, pickup_km=6.0, delivery_km=4.0, cod_amount_kobo=2_500_000)
    b, s = full.breakdown, full.settlement
    assert b.pickup_fee_kobo == parcel_fee(6.0, ParcelSize.SMALL, cfg)
    assert b.delivery_fee_kobo == parcel_fee(4.0, ParcelSize.SMALL, cfg)
    assert b.cod_fee_kobo == 38_000
    taxable = (
        b.linehaul_fee_kobo + b.pickup_fee_kobo + b.delivery_fee_kobo + b.service_fee_kobo + b.cod_fee_kobo
    )
    assert b.vat_kobo == apply_bps(taxable, cfg.vat_bps) and b.total_kobo == taxable + b.vat_kobo
    assert s.carrier_cost_kobo == apply_bps(b.linehaul_fee_kobo, LANE.carrier_share_bps)
    assert s.commission_kobo == 0 and s.restaurant_earning_kobo == 0 and s.rider_pay_kobo > 0


def test_waybill_price_limits():
    with pytest.raises(ValidationFailed, match="up to 5 kg"):
        _price(weight_kg=5.5)
    with pytest.raises(ValidationFailed, match="too far from the hub"):
        _price(pickup_km=PricingConfig().parcel.max_distance_km + 1)


# ------------------------------------------------------------------------------------- schedule
def test_departures_respect_cutoff_and_operating_days():
    assert next_departure(LANE, WAT) == date(2026, 11, 16)  # Monday before 15:00 → today
    late = datetime(2026, 11, 16, 15, 30, tzinfo=UTC)  # 16:30 in Lagos → tomorrow
    assert next_departure(LANE, late) == date(2026, 11, 17)
    saturday_evening = datetime(2026, 11, 21, 17, 0, tzinfo=UTC)  # no Sunday departures → Monday
    assert next_departure(LANE, saturday_evening) == date(2026, 11, 23)


def test_delivery_window_adds_pickup_time_and_a_day_for_door_delivery():
    assert delivery_window(LANE, WAT, first_mile="dropoff", last_mile="collect") == (
        date(2026, 11, 17),
        date(2026, 11, 18),
    )
    assert delivery_window(LANE, WAT, first_mile="dropoff", last_mile="door") == (
        date(2026, 11, 17),
        date(2026, 11, 19),
    )
    lunchtime = datetime(2026, 11, 16, 12, 30, tzinfo=UTC)  # 13:30 + 3 h pickup → after the cut-off
    assert delivery_window(LANE, lunchtime, first_mile="pickup", last_mile="collect")[0] == date(2026, 11, 18)


def test_network_helpers():
    assert [ln.destination_city for ln in NET.destinations("lagos")] == ["enugu", "abuja", "port-harcourt"]
    assert NET.lane("abuja", "lagos") is None  # Abuja and Port Harcourt are destinations only for now
    lekki = GeoPoint(lat=6.4410, lng=3.4600)
    assert NET.nearest_hub("lagos", lekki, dropoff=True).id == "lagos-lekki"
    assert [h.id for h in NET.hubs_in("abuja", collection=True)] == ["abuja-utako"]
    assert NET.hubs_in("abuja", dropoff=True) == []
    assert all(h.is_sample for h in NET.hubs) and all(c.is_sample for c in NET.carriers)


# ------------------------------------------------------------------------------------- orders
def _details(stage: WaybillStage | None = None) -> WaybillDetails:
    party = WaybillParty(name="Ada", phone="+2348011111111")
    return WaybillDetails(
        tracking_code="GMW23456789",
        lane_id="lagos-enugu",
        carrier_id="sample-east",
        carrier_name="Sample Carrier East",
        origin_city="lagos",
        destination_city="enugu",
        origin_city_name="Lagos",
        destination_city_name="Enugu",
        origin_hub_id="lagos-lekki",
        destination_hub_id="enugu-independence",
        origin_hub_name="GudMeals Hub, Lekki (sample)",
        destination_hub_name="GudMeals Hub, Independence Layout (sample)",
        first_mile="dropoff",
        last_mile="collect",
        sender=party,
        recipient=party,
        size=ParcelSize.SMALL,
        weight_kg=1.0,
        eta_from=date(2026, 11, 17),
        eta_to=date(2026, 11, 18),
        stage=stage,
    )


def _order(
    *, status=S.PAID, vertical=Vertical.WAYBILL, leg_of=None, provider="local_sandbox", pay="paid"
) -> Order:
    priced = _price(cod_amount_kobo=None)
    now = datetime(2026, 11, 16, tzinfo=UTC)
    return Order(
        id="w1",
        short_code="ABC123",
        vertical=vertical,
        customer_id="c1",
        restaurant_id="gm-waybill",
        restaurant_name="Waybill to Enugu",
        restaurant_location=GeoPoint(lat=6.44, lng=3.47),
        status=status,
        fulfillment=Fulfillment.PICKUP,
        lines=[],
        breakdown=priced.breakdown
        if vertical == Vertical.WAYBILL
        else PriceBreakdown(subtotal_kobo=0, total_kobo=0),
        settlement=priced.settlement
        if vertical == Vertical.WAYBILL
        else SettlementTerms(
            commission_bps=0, commission_kobo=0, rider_pay_kobo=90_000, restaurant_earning_kobo=0
        ),
        quote_id="q1",
        payment=PaymentSummary(provider=provider, status=pay),  # type: ignore[arg-type]
        waybill=_details(WaybillStage.AT_ORIGIN_HUB) if vertical == Vertical.WAYBILL else None,
        leg_of=leg_of,
        leg_kind="first_mile" if leg_of else None,
        created_at=now,
        updated_at=now,
    )


@pytest.mark.parametrize("seed", range(15))
def test_waybill_settlement_postings_balance(seed):
    rng = random.Random(seed)
    priced = _price(
        weight_kg=rng.uniform(0.1, 5.0),
        pickup_km=rng.choice([None, rng.uniform(0.5, 30)]),
        delivery_km=rng.choice([None, rng.uniform(0.5, 30)]),
        cod_amount_kobo=rng.choice([None, rng.randint(100, 10_000_000)]),
    )
    order = _order().model_copy(update={"breakdown": priced.breakdown, "settlement": priced.settlement})
    postings = waybill_completed(order)
    validate_postings(postings)
    by = {(p.account, p.direction): p.amount_kobo for p in postings}
    assert by[("liability:carrier:sample-east", "credit")] == priced.settlement.carrier_cost_kobo
    assert by[("revenue:waybill", "credit")] == (
        priced.breakdown.total_kobo - priced.breakdown.vat_kobo - priced.breakdown.cod_fee_kobo
    )
    validate_postings(leg_rider_pay("demo-rider-1", rng.randint(1, 500_000)))
    assert _owner("liability:carrier:sample-east") == ("carrier", "sample-east")


def test_waybill_state_rules_and_flow_guard():
    assert can_transition(S.PAID, S.IN_TRANSIT, A.STAFF) and can_transition(S.PAID, S.IN_TRANSIT, A.SYSTEM)
    assert not can_transition(S.PAID, S.IN_TRANSIT, A.CUSTOMER)
    assert can_transition(S.DRAFT, S.READY_FOR_PICKUP, A.SYSTEM)
    assert can_transition(S.IN_TRANSIT, S.DELIVERED, A.SYSTEM)

    def move(order, to, actor=A.SYSTEM, **patch):
        OrderService.build_transition(
            order, to, actor_type=actor, actor_id="x", reason="r", patch=patch, now=order.created_at
        )

    move(_order(), S.IN_TRANSIT, A.STAFF)  # a paid waybill reaching the hub
    food = _order(vertical=Vertical.FOOD)
    with pytest.raises(InvalidTransition, match="Only waybills go in transit"):
        move(food, S.IN_TRANSIT, A.STAFF)
    with pytest.raises(InvalidTransition, match="Only waybill rider jobs"):
        move(_order(status=S.DRAFT, vertical=Vertical.PARCEL), S.READY_FOR_PICKUP)
    move(
        _order(status=S.DRAFT, vertical=Vertical.PARCEL, leg_of="w1", provider="internal", pay="unpaid"),
        S.READY_FOR_PICKUP,
    )
    with pytest.raises(InvalidTransition, match="marked delivered by the system"):
        move(food.model_copy(update={"status": S.IN_TRANSIT}), S.DELIVERED)
    # Pay on delivery's "send to the merchant unpaid" step never applies to packages.
    for vertical in (Vertical.WAYBILL, Vertical.PARCEL):
        unpaid = _order(status=S.PENDING_PAYMENT, vertical=vertical, provider="cash", pay="pending")
        with pytest.raises(InvalidTransition, match="not sent to a merchant"):
            move(unpaid, S.SUBMITTED_TO_RESTAURANT)

    # Rider jobs hold no money: they can be called off, never "refunded".
    leg = _order(
        status=S.RIDER_ASSIGNED, vertical=Vertical.PARCEL, leg_of="w1", provider="internal", pay="unpaid"
    )
    move(leg, S.CANCELLED)
    with pytest.raises(InvalidTransition, match="cancel it instead"):
        move(leg, S.REFUND_PENDING, A.STAFF)


def test_stage_labels_and_steps():
    d = _details()
    assert stage_label(d) == "Awaiting payment" and stage_step(d) == 0
    assert stage_label(_details(WaybillStage.DEPARTED)) == "On the way to Enugu"
    assert stage_step(_details(WaybillStage.DEPARTED)) == 2
    assert stage_label(_details(WaybillStage.READY_FOR_COLLECTION)).startswith(
        "Ready for collection at GudMeals Hub"
    )
    assert stage_step(_details(WaybillStage.DELIVERED)) == 4
