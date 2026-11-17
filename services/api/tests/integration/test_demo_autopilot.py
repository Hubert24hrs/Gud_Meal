"""Demo shop autopilot (local testing only): a demo shop accepts and packs an order nobody at its dashboard has
answered, so one person with the customer and rider apps can finish a food or beauty order.

Found on a phone test: the tester has no one at the restaurant, so a paid food order would never reach a rider."""

from __future__ import annotations

from datetime import timedelta

from conftest import auth
from gudmeal_api.config import Settings
from gudmeal_api.seed.autopilot import run_demo_shops
from gudmeal_api.services import dispatch as dispatch_mod


async def test_autopilot_accepts_then_packs_an_unanswered_delivery_order(flow, client, container):
    order = await flow.paid_order()
    assert order["status"] == "submitted_to_restaurant"

    # Too soon: a person at the dashboard still has time to answer.
    assert await run_demo_shops(container) == 0
    assert (await flow.get(order["id"]))["status"] == "submitted_to_restaurant"

    later = dispatch_mod.utcnow() + timedelta(seconds=20)
    assert await run_demo_shops(container, now=later) == 1
    assert (await flow.get(order["id"]))["status"] == "restaurant_accepted"
    # Accepting is what starts the search for a rider.
    offers = await container.repos.assignments.find(where=[("order_id", "==", order["id"])])
    assert len(offers) == 1 and offers[0].status == "offered"

    # The shop's own view shows who accepted, and the order is packed a little later.
    assert await run_demo_shops(container, now=later + timedelta(seconds=45)) == 1
    stored = await container.repos.orders.get(order["id"])
    assert stored.ready_at is not None
    assert await run_demo_shops(container, now=later + timedelta(seconds=90)) == 0  # nothing left to do


async def test_autopilot_leaves_answered_orders_pickups_and_packages_alone(flow, client, container):
    # The kitchen answered first: the autopilot does not accept again.
    answered = await flow.paid_order()
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{answered['id']}/accept",
        json={"prep_minutes": 15},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200, r.text
    # A pickup order is accepted, but handing it over at the counter (with the customer's code) stays with a person.
    pickup = await flow.paid_order(fulfillment="pickup")

    later = dispatch_mod.utcnow() + timedelta(seconds=20)
    assert await run_demo_shops(container, now=later, ready_after=3600) == 1  # only the pickup order's accept
    assert (
        await container.repos.orders.get(answered["id"])
    ).prep_minutes == 15  # the kitchen's answer stands
    assert (
        await run_demo_shops(container, now=later + timedelta(hours=2), ready_after=3600) == 1
    )  # answered one
    assert (await container.repos.orders.get(pickup["id"])).ready_at is None
    assert (await flow.get(pickup["id"]))["status"] == "restaurant_accepted"


def test_demo_switches_are_refused_outside_local_testing():
    base = dict(
        environment="production",
        database_url="postgresql+asyncpg://u:p@db/gudmeal",
        internal_auth_mode="oidc",
        internal_oidc_audience="https://api.example",
        internal_oidc_service_accounts=["tasks@example.iam.gserviceaccount.com"],
        seed_demo_data=False,
    )
    for switch in ("demo_shops_always_open", "demo_shop_autopilot"):
        try:
            Settings(**base, **{switch: True}).validate_for_environment()
        except Exception as exc:  # the settings refuse to start
            assert "local testing only" in str(exc)
        else:
            raise AssertionError(f"{switch} was accepted in production")
