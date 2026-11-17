"""Dispatch keeps looking for a rider: riders who come online or show up again get waiting jobs right away, a
rider whose offer ran out is asked again later (one who declined is not), and retries go on after ops are alerted.

Found on a phone test: with a small fleet every rider had missed an offer once, the job was never offered again
and dispatch stopped after eight rounds, so a parcel stayed at "Finding a rider" while a rider waited online."""

from __future__ import annotations

from datetime import timedelta

from conftest import auth, idem
from gudmeal_api.services import dispatch as dispatch_mod

PICKUP = {
    "name": "Ada Obi",
    "phone": "+2348022222222",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": {"lat": 6.4410, "lng": 3.4600},
}
DROPOFF = {
    "name": "Tunde Bello",
    "phone": "+2348033333333",
    "line1": "7 Ajose Adeogun Street",
    "area": "Victoria Island",
    "location": {"lat": 6.4281, "lng": 3.4219},
}
DEMO_RIDERS = ["demo-rider-1", "demo-rider-2", "demo-rider-3", "demo-rider-4"]


async def only_online(container, *uids: str) -> None:
    for uid in DEMO_RIDERS:
        await container.repos.riders.update(uid, {"is_online": uid in uids})


async def paid_parcel(client, pickup: dict = PICKUP, dropoff: dict = DROPOFF) -> str:
    r = await client.post(
        "/v1/parcels/quotes",
        json={"pickup": pickup, "dropoff": dropoff, "size": "small", "category": "documents"},
        headers=auth("customer"),
    )
    assert r.status_code == 201, r.text
    r = await client.post(
        "/v1/parcels", json={"quote_id": r.json()["id"]}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 201, r.text
    order_id = r.json()["id"]
    r = await client.post(f"/v1/orders/{order_id}/checkout", json={}, headers={**auth("customer"), **idem()})
    r = await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    assert r.status_code == 303
    return order_id


async def offered_to(client, who: str) -> list[str]:
    r = await client.get("/v1/rider/offers", headers=auth(who))
    assert r.status_code == 200, r.text
    return [o["order_id"] for o in r.json()]


async def test_a_rider_who_comes_online_gets_the_waiting_job(client, container):
    await only_online(container)
    order_id = await paid_parcel(client)
    order = await container.repos.orders.get(order_id)
    assert order.rider_id is None and order.dispatch_attempts == 1  # nobody to ask yet

    r = await client.put("/v1/rider/availability", json={"online": True}, headers=auth("rider1"))
    assert r.status_code == 200, r.text
    assert await offered_to(client, "rider1") == [order_id]


async def test_a_waiting_rider_who_went_quiet_gets_the_job_after_the_next_ping(client, container):
    await only_online(container, "demo-rider-1")
    quiet = dispatch_mod.utcnow() - timedelta(minutes=10)  # no position for 10 minutes: not offered anything
    await container.repos.riders.update("demo-rider-1", {"last_location_at": quiet})
    order_id = await paid_parcel(client)
    assert await offered_to(client, "rider1") == []

    r = await client.post("/v1/rider/location", json={"lat": 6.442, "lng": 3.461}, headers=auth("rider1"))
    assert r.status_code == 204, r.text
    assert await offered_to(client, "rider1") == [order_id]


async def test_a_rider_whose_offer_ran_out_is_asked_again_later(client, container):
    await only_online(container, "demo-rider-1")
    order_id = await paid_parcel(client)
    [offer] = await container.repos.assignments.find(where=[("order_id", "==", order_id)])
    assert offer.rider_id == "demo-rider-1"

    await container.dispatch.handle_offer_timeout({"assignment_id": offer.id})
    assert await offered_to(client, "rider1") == []  # skipped for a while: they may be away from the phone

    long_ago = dispatch_mod.utcnow() - dispatch_mod.REOFFER_AFTER - timedelta(seconds=1)
    await container.repos.assignments.update(offer.id, {"expires_at": long_ago})
    await container.dispatch.retry({"order_id": order_id})
    assert await offered_to(client, "rider1") == [order_id]


async def test_a_rider_who_declined_is_not_asked_again(client, container):
    await only_online(container, "demo-rider-1")
    order_id = await paid_parcel(client)
    [offer] = await container.repos.assignments.find(where=[("order_id", "==", order_id)])
    r = await client.post(
        f"/v1/rider/offers/{offer.id}/decline", json={"reason": "Too far"}, headers=auth("rider1")
    )
    assert r.status_code in (200, 204), r.text

    long_ago = dispatch_mod.utcnow() - dispatch_mod.REOFFER_AFTER - timedelta(minutes=1)
    await container.repos.assignments.update(offer.id, {"expires_at": long_ago})
    await container.dispatch.retry({"order_id": order_id})
    assert await offered_to(client, "rider1") == []


async def test_dispatch_keeps_trying_after_alerting_ops(client, container):
    await only_online(container)
    order_id = await paid_parcel(client)
    await container.repos.orders.update(order_id, {"dispatch_attempts": dispatch_mod.MAX_ATTEMPTS + 2})
    container.tasks.tasks.clear()

    await container.dispatch.retry({"order_id": order_id})
    retries = [t for t in container.tasks.tasks if t[0] == dispatch_mod.TASK_DISPATCH_RETRY]
    assert retries and retries[-1][2] == dispatch_mod.SLOW_RETRY_SECONDS


async def test_dispatch_looks_further_when_nobody_is_close(client, container):
    """Found on a phone test: a package picked up in Ajah never reached the only rider, 11.5 km away in Ikate,
    because dispatch only ever looked 6 km around the pickup. Each empty round now looks 3 km further."""
    ajah = {
        "name": "Ada",
        "phone": "+2348022222222",
        "line1": "1 Addo Road",
        "area": "Ajah",
        "location": {"lat": 6.4682, "lng": 3.5852},
    }
    vgc = {
        "name": "Oge",
        "phone": "+2348033333333",
        "line1": "2 Bank Road",
        "area": "VGC",
        "location": {"lat": 6.4720, "lng": 3.5600},
    }
    await only_online(container, "demo-rider-1")
    ikate = {"lat": 6.42975, "lng": 3.48816}
    await container.repos.riders.update(
        "demo-rider-1", {"last_location": ikate, "last_location_at": dispatch_mod.utcnow()}
    )
    order_id = await paid_parcel(client, pickup=ajah, dropoff=vgc)
    assert await offered_to(client, "rider1") == []  # round 1: 6 km

    await container.dispatch.retry({"order_id": order_id})
    assert await offered_to(client, "rider1") == []  # round 2: 9 km
    await container.repos.riders.update("demo-rider-1", {"last_location_at": dispatch_mod.utcnow()})
    await container.dispatch.retry({"order_id": order_id})
    assert await offered_to(client, "rider1") == [order_id]  # round 3: 12 km reaches the rider


async def test_demo_shops_can_stay_open_around_the_clock_for_local_testing(container):
    from datetime import UTC, datetime

    from gudmeal_api.domain.hours import is_open
    from gudmeal_api.seed.lagos import open_demo_shops_all_day

    assert await open_demo_shops_all_day(container.repos) > 10
    jollof = await container.repos.restaurants.get("r-jollof-junction")
    three_am_lagos = datetime(2026, 11, 17, 2, 0, tzinfo=UTC)
    assert is_open(jollof.opening_hours, three_am_lagos)


async def test_a_fruitless_extra_look_adds_no_tries_and_counts_no_round(client, container):
    """Riders coming online or finishing deliveries trigger extra looks at waiting jobs. Those must not pile up
    scheduled tries (one more per look, for ever) or make the search radius grow faster."""
    await only_online(container)
    order_id = await paid_parcel(client)

    def tries() -> int:
        return len([t for t in container.tasks.tasks if t[0] == dispatch_mod.TASK_DISPATCH_RETRY])

    scheduled, rounds = tries(), (await container.repos.orders.get(order_id)).dispatch_attempts
    assert scheduled == 1 and rounds == 1
    for _ in range(3):
        assert await container.dispatch.sweep() == 0
    assert tries() == scheduled
    assert (await container.repos.orders.get(order_id)).dispatch_attempts == rounds


async def test_a_missed_offer_comes_back_as_soon_as_the_wait_is_over(client, container):
    """One person testing with both apps on a phone misses offers while in the customer app: the next try is
    scheduled for when the rider may be asked again, not a fixed minute later."""
    container.dispatch.reoffer_after = timedelta(seconds=20)
    await only_online(container, "demo-rider-1")
    order_id = await paid_parcel(client)
    [offer] = await container.repos.assignments.find(where=[("order_id", "==", order_id)])
    container.tasks.tasks.clear()

    # The offer's 45 seconds are up (the timeout task runs when it expires).
    await container.repos.assignments.update(offer.id, {"expires_at": dispatch_mod.utcnow()})
    await container.dispatch.handle_offer_timeout({"assignment_id": offer.id})
    [(path, payload, delay)] = container.tasks.tasks
    assert path == dispatch_mod.TASK_DISPATCH_RETRY and payload == {"order_id": order_id}
    assert 1 <= delay <= 20


async def test_offers_say_how_many_seconds_are_left(client, container):
    """The rider app counts down from `expires_in_seconds` (the server's clock), not from its own clock: on a
    phone test the server's clock was 16 s slow, which cut every 45 s offer to 28 s on the phone."""
    await only_online(container, "demo-rider-1")
    order_id = await paid_parcel(client)
    r = await client.get("/v1/rider/offers", headers=auth("rider1"))
    assert r.status_code == 200, r.text
    [offer] = r.json()
    assert offer["order_id"] == order_id and offer["expires_at"]
    assert 40 <= offer["expires_in_seconds"] <= 45
