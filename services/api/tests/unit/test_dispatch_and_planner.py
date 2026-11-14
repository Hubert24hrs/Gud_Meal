from datetime import UTC, datetime, timedelta

from gudmeal_api.domain.dispatch import DispatchConfig, ineligibility_reason, rank_riders
from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.meal_planner import PlannerRequest, plan_meals
from gudmeal_api.domain.models import RiderProfile, RiderStatus, VehicleType
from gudmeal_api.domain.money import naira
from gudmeal_api.seed.lagos import PRICING, RESTAURANTS, _menus

NOW = datetime(2026, 11, 16, 17, 0, tzinfo=UTC)  # 18:00 Lagos, Monday
RESTAURANT = GeoPoint(lat=6.4478, lng=3.4723)


def rider(uid, lat, lng, **kw):
    base = dict(
        uid=uid,
        name=uid,
        status=RiderStatus.ACTIVE,
        is_online=True,
        vehicle=VehicleType.MOTORCYCLE,
        last_location=GeoPoint(lat=lat, lng=lng),
        last_location_at=NOW - timedelta(seconds=30),
    )
    base.update(kw)
    return RiderProfile(**base)


class TestDispatch:
    def test_ineligible_riders_are_filtered(self):
        cfg = DispatchConfig()
        cases = {
            "offline": rider("a", 6.448, 3.472, is_online=False),
            "not_active": rider("b", 6.448, 3.472, status=RiderStatus.SUSPENDED),
            "stale_location": rider("c", 6.448, 3.472, last_location_at=NOW - timedelta(minutes=10)),
            "at_capacity": rider("d", 6.448, 3.472, active_order_ids=["o1", "o2"]),
            "too_far": rider("e", 6.60, 3.35),
            "vehicle_unsuitable": rider("f", 6.448, 3.472, vehicle=VehicleType.BICYCLE),
        }
        for expected, r in cases.items():
            assert (
                ineligibility_reason(
                    r, restaurant_location=RESTAURANT, delivery_distance_km=8, now=NOW, cfg=cfg
                )
                == expected
            )

    def test_ranking_prefers_close_idle_reliable_riders(self):
        riders = [
            rider("far", 6.47, 3.49),
            rider("near_busy", 6.4480, 3.4725, active_order_ids=["x"]),
            rider("near_idle", 6.4485, 3.4730),
            rider("near_unreliable", 6.4482, 3.4726, acceptance_rate=0.2),
        ]
        ranked = rank_riders(riders, restaurant_location=RESTAURANT, delivery_distance_km=4, now=NOW)
        assert ranked[0].rider_id == "near_idle"
        assert [r.rider_id for r in ranked][-1] == "far"

    def test_exclusion(self):
        ranked = rank_riders(
            [rider("a", 6.448, 3.472)],
            restaurant_location=RESTAURANT,
            delivery_distance_km=3,
            now=NOW,
            exclude={"a"},
        )
        assert ranked == []


class TestMealPlanner:
    catalog = [(r, _menus()[r.id][1], {g.id: g for g in _menus()[r.id][2]}) for r in RESTAURANTS]

    def test_vision_request_ten_thousand_for_two_before_8pm(self):
        req = PlannerRequest(
            budget_kobo=naira(10_000),
            party_size=2,
            location=GeoPoint(lat=6.4410, lng=3.4600),
            now=NOW,
            deliver_by=NOW.replace(hour=19),
        )  # 20:00 Lagos
        result = plan_meals(req, self.catalog, PRICING)
        assert result.plans, result.notes
        for plan in result.plans:
            assert plan.breakdown.total_kobo <= naira(10_000)
            assert plan.meets_deadline and plan.estimated_delivery_at <= NOW.replace(hour=19)
            people_served = sum(
                ln.quantity * next(i for i in _menus()[plan.restaurant_id][1] if i.id == ln.item_id).serves
                for ln in plan.items
                if ln.kind in ("main", "combo")
            )
            assert people_served >= 2
        totals = [p.score for p in result.plans]
        assert totals == sorted(totals, reverse=True)

    def test_allergens_are_excluded(self):
        req = PlannerRequest(
            budget_kobo=naira(20_000),
            party_size=1,
            location=GeoPoint(lat=6.4300, lng=3.4220),
            now=NOW,
            exclude_allergens={"peanuts"},
            cuisines={"grills"},
        )
        result = plan_meals(req, self.catalog, PRICING)
        menus = _menus()
        for plan in result.plans:
            for ln in plan.items:
                item = next(i for i in menus[plan.restaurant_id][1] if i.id == ln.item_id)
                assert "peanuts" not in item.allergens

    def test_budget_too_small_returns_explanation(self):
        req = PlannerRequest(
            budget_kobo=naira(1_000), party_size=4, location=GeoPoint(lat=6.4410, lng=3.4600), now=NOW
        )
        result = plan_meals(req, self.catalog, PRICING)
        assert result.plans == []
        assert result.cheapest_total_kobo and result.cheapest_total_kobo > naira(1_000)
        assert result.notes

    def test_closed_restaurants_are_skipped(self):
        early = datetime(2026, 11, 16, 5, 0, tzinfo=UTC)  # 06:00 Lagos — almost everything closed
        req = PlannerRequest(
            budget_kobo=naira(50_000), party_size=2, location=GeoPoint(lat=6.4410, lng=3.4600), now=early
        )
        assert plan_meals(req, self.catalog, PRICING).plans == []
