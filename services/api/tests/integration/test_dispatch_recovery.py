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


async def paid_parcel(client) -> str:
    r = await client.post(
        "/v1/parcels/quotes",
        json={"pickup": PICKUP, "dropoff": DROPOFF, "size": "small", "category": "documents"},
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
