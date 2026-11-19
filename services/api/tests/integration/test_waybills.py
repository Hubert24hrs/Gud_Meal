"""Interstate waybill end to end: quotes, booking, rider legs, hubs, collection, tracking, ledger, cancellations."""

from __future__ import annotations

import json
import re

from conftest import auth, idem

RIDERS = {f"demo-rider-{n}": f"rider{n}" for n in range(1, 7)}
SENDER = {
    "name": "Ada Obi",
    "phone": "+2348022222222",
    "line1": "5 Bisola Durosinmi-Etti Drive",
    "area": "Lekki Phase 1",
    "location": {"lat": 6.4410, "lng": 3.4600},
}
ENUGU_RECIPIENT = {
    "name": "Chika Eze",
    "phone": "+2348066666666",
    "line1": "21 Nike Lake Road",
    "area": "Independence Layout",
    "location": {"lat": 6.4473, "lng": 7.5214},
}
ABUJA_RECIPIENT = {"name": "Musa Bello", "phone": "+2348077777777"}
ENUGU_SENDER = {
    "name": "Obinna Okeke",
    "phone": "+2348088888888",
    "line1": "3 Ogui Road",
    "area": "Ogui",
    "location": {"lat": 6.4420, "lng": 7.4980},
}


async def ledger(client) -> dict[str, int]:
    data = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert data["trial_balance"]["debits_kobo"] == data["trial_balance"]["credits_kobo"]
    return {a["account"]: a["balance_kobo"] for a in data["accounts"]}


async def quote(client, who: str = "customer", expect: int = 201, **body) -> dict:
    payload = {
        "origin_city": "lagos",
        "destination_city": "enugu",
        "first_mile": "pickup",
        "last_mile": "door",
        "sender": SENDER,
        "recipient": ENUGU_RECIPIENT,
        "size": "small",
        "weight_kg": 3.2,
        "category": "clothing",
        "description": "Two ankara dresses",
        **body,
    }
    r = await client.post("/v1/waybills/quotes", json=payload, headers=auth(who))
    assert r.status_code == expect, r.text
    return r.json()


async def book_and_pay(client, q: dict, provider: str | None = None, who: str = "customer") -> dict:
    r = await client.post(
        "/v1/waybills", json={"quote_id": q["id"], "channel": "web"}, headers={**auth(who), **idem()}
    )
    assert r.status_code == 201, r.text
    order = r.json()
    body = {"provider": provider} if provider else {}
    r = await client.post(f"/v1/orders/{order['id']}/checkout", json=body, headers={**auth(who), **idem()})
    assert r.status_code == 200, r.text
    if r.json().get("authorization_url"):
        await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    return (await client.get(f"/v1/orders/{order['id']}", headers=auth(who))).json()


async def accept_leg(client, container, leg_id: str) -> str:
    offers = await container.repos.assignments.find(where=[("order_id", "==", leg_id)])
    offer = next(o for o in offers if o.status == "offered")
    rider = RIDERS[offer.rider_id]
    r = await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))
    assert r.status_code == 200, r.text
    return rider


async def hub(client, action: str, body: dict, who: str = "hub", expect: int = 200) -> dict:
    r = await client.post(f"/v1/admin/waybills/{action}", json=body, headers=auth(who))
    assert r.status_code == expect, r.text
    return r.json()


# ------------------------------------------------------------------------------------------- catalogue
async def test_origins_and_destinations(client):
    origins = (await client.get("/v1/waybill/origins")).json()
    assert [(o["id"], o["home_pickup"]) for o in origins] == [("enugu", True), ("lagos", True)]
    assert {h["id"] for h in origins[1]["dropoff_hubs"]} == {"lagos-ikeja", "lagos-lekki"}

    dest = (await client.get("/v1/waybill/destinations?origin=lagos")).json()
    by_city = {d["city"]: d for d in dest["destinations"]}
    assert set(by_city) == {"enugu", "abuja", "port-harcourt"}
    assert by_city["enugu"]["door_delivery"] and not by_city["abuja"]["door_delivery"]
    assert by_city["abuja"]["transit_days"] == [1, 2] and by_city["abuja"]["from_kobo"] > 0
    assert [h["id"] for h in by_city["abuja"]["collection_hubs"]] == ["abuja-utako"]
    assert by_city["enugu"]["carrier"] == "Sample Carrier East"
    assert (await client.get("/v1/waybill/destinations?origin=abuja")).status_code == 404


async def test_quote_validation(client):
    async def rejected(status: int, **body) -> str:
        return (await quote(client, expect=status, **body))["error"]["message"]

    assert "same city" in await rejected(422, destination_city="lagos")
    assert "route" in await rejected(409, origin_city="abuja", destination_city="lagos")
    assert "Door delivery isn't available in Abuja" in await rejected(422, destination_city="abuja")
    assert "needs door delivery" in await rejected(
        422, destination_city="abuja", last_mile="collect", recipient=ABUJA_RECIPIENT, cod_amount_kobo=500_000
    )
    assert "up to 5 kg" in await rejected(422, weight_kg=7)
    assert "pickup address" in await rejected(422, sender={"name": "Ada Obi", "phone": "+2348022222222"})
    far = {**SENDER, "location": {"lat": 7.40, "lng": 3.90}}  # Ibadan: outside our Lagos zones
    assert "outside our Lagos delivery area" in await rejected(409, sender=far)
    assert "collection point" in await rejected(
        422,
        destination_city="abuja",
        last_mile="collect",
        recipient=ABUJA_RECIPIENT,
        destination_hub_id="lagos-lekki",
    )


# --------------------------------------------------------------------------------- door to door + COD
async def test_door_to_door_waybill_with_riders_hubs_cod_and_ledger(client, container):
    q = await quote(client, cod_amount_kobo=2_500_000)
    b = q["breakdown"]
    assert "settlement" not in q and q["details"]["origin_hub_id"] == "lagos-lekki"
    assert b["linehaul_fee_kobo"] == 510_000 and b["pickup_fee_kobo"] > 0 and b["delivery_fee_kobo"] > 0
    assert b["cod_fee_kobo"] == 38_000
    assert b["total_kobo"] == (
        b["linehaul_fee_kobo"]
        + b["pickup_fee_kobo"]
        + b["delivery_fee_kobo"]
        + b["service_fee_kobo"]
        + b["cod_fee_kobo"]
        + b["vat_kobo"]
    )
    assert q["eta_text"]

    order = await book_and_pay(client, q)
    w = order["waybill"]
    code = w["tracking_code"]
    assert re.fullmatch(r"GMW[2-9A-HJ-NP-Z]{8}", code)
    assert order["vertical"] == "waybill" and order["status"] == "paid" and w["stage"] == "pickup_scheduled"
    assert order["progress"]["label"] == "Rider pickup booked" and order["progress"]["total_steps"] == 5
    leg_id = w["first_mile_order_id"]
    leg = await container.repos.orders.get(leg_id)
    assert (
        leg.leg_kind == "first_mile"
        and leg.status == "ready_for_pickup"
        and leg.payment.provider == "internal"
    )
    mine = (await client.get("/v1/orders", headers=auth("customer"))).json()
    assert [o["id"] for o in mine] == [order["id"]]  # rider jobs are internal

    rider = await accept_leg(client, container, leg_id)
    rider_view = (await client.get(f"/v1/orders/{leg_id}", headers=auth(rider))).json()
    assert rider_view["leg_kind"] == "first_mile" and rider_view["hub_handover"] is True
    assert rider_view["parcel"]["dropoff"]["name"].startswith("Yummy Chops Hub, Lekki")
    assert (
        await client.post(f"/v1/rider/deliveries/{leg_id}/pickup", headers=auth(rider))
    ).status_code == 200
    assert (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()["waybill"][
        "stage"
    ] == "picked_up"
    r = await client.post(
        f"/v1/rider/deliveries/{leg_id}/deliver", json={"code": "1234"}, headers=auth(rider)
    )
    assert r.status_code == 409 and "hub staff" in r.json()["error"]["message"]
    r = await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 409 and "contact support" in r.json()["error"]["message"]

    board = (await client.get("/v1/admin/hubs/lagos-lekki/board", headers=auth("hub"))).json()
    assert [x["tracking_code"] for x in board["expected"]] == [code]
    assert board["expected"][0]["recipient"]["name"] == "Chika Eze" and "total_kobo" not in json.dumps(board)
    await hub(client, "receive", {"hub_id": "lagos-ikeja", "tracking_code": code}, expect=422)
    received = await hub(client, "receive", {"hub_id": "lagos-lekki", "tracking_code": code})
    assert received["status"] == "in_transit" and received["stage"] == "at_origin_hub"
    leg = await container.repos.orders.get(leg_id)
    assert leg.status == "completed" and leg.settled_at is not None
    rider_uid = next(uid for uid, name in RIDERS.items() if name == rider)
    books = await ledger(client)
    assert books[f"liability:rider:{rider_uid}"] == leg.settlement.rider_pay_kobo
    assert books["expense:waybill_riders"] == leg.settlement.rider_pay_kobo
    assert books["liability:customer_funds"] == b["total_kobo"]  # the customer's money waits for delivery

    departed = await hub(
        client,
        "depart",
        {"hub_id": "lagos-lekki", "tracking_codes": [code, "GMW22222222"], "trip_reference": "LAG-ENU-118"},
    )
    assert departed == {
        "departed": [code],
        "skipped": [{"tracking_code": "GMW22222222", "reason": "Not found"}],
    }
    incoming = (await client.get("/v1/admin/hubs/enugu-independence/board", headers=auth("hub"))).json()[
        "incoming"
    ]
    assert [x["tracking_code"] for x in incoming] == [code] and incoming[0]["trip_reference"] == "LAG-ENU-118"

    arrived = await hub(client, "arrive", {"hub_id": "enugu-independence", "tracking_code": code})
    assert arrived["stage"] == "at_destination_hub"
    parent = await container.orders.get(order["id"])
    last_id = parent.waybill.last_mile_order_id
    last = await container.repos.orders.get(last_id)
    assert last.leg_kind == "last_mile" and last.parcel.cod_amount_kobo == 2_500_000
    enugu_rider = await accept_leg(client, container, last_id)
    assert enugu_rider in ("rider5", "rider6")
    view = (await client.get(f"/v1/orders/{last_id}", headers=auth(enugu_rider))).json()
    assert view["collect_cash_kobo"] == 2_500_000 and view["hub_handover"] is False
    assert (
        await client.post(f"/v1/rider/deliveries/{last_id}/pickup", headers=auth(enugu_rider))
    ).status_code == 200
    stage = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()["waybill"][
        "stage"
    ]
    assert stage == "out_for_delivery"
    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    r = await client.post(
        f"/v1/rider/deliveries/{last_id}/deliver",
        json={"code": codes["delivery_code"], "cash_collected": True},
        headers=auth(enugu_rider),
    )
    assert r.status_code == 200, r.text

    done = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert done["status"] == "completed" and done["settled_at"] and done["waybill"]["stage"] == "delivered"
    assert [m["stage"] for m in done["waybill"]["milestones"]] == [
        "pickup_scheduled",
        "picked_up",
        "at_origin_hub",
        "departed",
        "at_destination_hub",
        "out_for_delivery",
        "delivered",
    ]
    s = (await container.orders.get(order["id"])).settlement
    enugu_uid = next(uid for uid, name in RIDERS.items() if name == enugu_rider)
    books = await ledger(client)
    assert books["liability:customer_funds"] == 0
    assert books["revenue:waybill"] == b["total_kobo"] - b["vat_kobo"] - b["cod_fee_kobo"]
    assert books["liability:carrier:sample-east"] == s.carrier_cost_kobo == books["expense:linehaul"]
    assert books["liability:vendor:cust-1"] == 2_500_000
    assert books[f"receivable:rider_cash:{enugu_uid}"] == 2_500_000
    assert books[f"liability:rider:{enugu_uid}"] == last.settlement.rider_pay_kobo

    tracked = (await client.get(f"/v1/track/{code}")).json()
    assert tracked["delivered"] and tracked["label"] == "Delivered" and tracked["step"] == 4
    assert tracked["origin"] == "Lagos" and tracked["destination"] == "Enugu"
    assert [m["place"] for m in tracked["milestones"]][2].startswith("Yummy Chops Hub, Lekki")
    text = json.dumps(tracked)
    assert "Chika" not in text and "+234" not in text and "Nike Lake" not in text
    assert (await client.get("/v1/track/GMW22222222")).status_code == 404

    cash = (await client.get("/v1/admin/cash", headers=auth("finance"))).json()
    assert cash["carriers"] == [
        {"carrier_id": "sample-east", "name": "Sample Carrier East", "owed_kobo": s.carrier_cost_kobo}
    ]
    url = "/v1/admin/carriers/sample-east/payouts"
    too_much = {"amount_kobo": s.carrier_cost_kobo + 1, "bank_reference": "NIP-1"}
    assert (await client.post(url, json=too_much, headers={**auth("finance"), **idem()})).status_code == 422
    paid = await client.post(
        url,
        json={"amount_kobo": s.carrier_cost_kobo, "bank_reference": "NIP-12345"},
        headers={**auth("finance"), **idem()},
    )
    assert paid.status_code == 201 and paid.json()["owed_kobo"] == 0
    assert (
        await client.post(
            url, json={"amount_kobo": 1, "bank_reference": "NIP-1"}, headers={**auth("hub"), **idem()}
        )
    ).status_code == 403


# ------------------------------------------------------------------------------- drop-off + collection
async def test_dropoff_and_hub_collection_paid_from_the_wallet(client, container):
    q = await quote(
        client,
        origin_city="enugu",
        destination_city="abuja",
        first_mile="dropoff",
        last_mile="collect",
        sender=ENUGU_SENDER,
        recipient=ABUJA_RECIPIENT,
        size="medium",
        weight_kg=6,
    )
    b = q["breakdown"]
    assert (
        b["pickup_fee_kobo"] == 0
        and b["delivery_fee_kobo"] == 0
        and b["linehaul_fee_kobo"] == 650_000 + 30_000
    )
    assert (
        q["details"]["destination_hub_id"] == "abuja-utako"
        and q["details"]["origin_hub_id"] == "enugu-independence"
    )
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": b["total_kobo"]}, headers={**auth("customer"), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")

    order = await book_and_pay(client, q, provider="wallet")
    w = order["waybill"]
    code = w["tracking_code"]
    assert order["status"] == "paid" and w["stage"] == "awaiting_dropoff" and w["first_mile_order_id"] is None
    assert order["fulfillment"] == "pickup" and order["delivery_address"] is None

    await hub(client, "receive", {"hub_id": "enugu-independence", "tracking_code": code})
    await hub(
        client,
        "depart",
        {"hub_id": "enugu-independence", "tracking_codes": [code], "trip_reference": "ENU-ABJ-7"},
    )
    await hub(client, "arrive", {"hub_id": "enugu-independence", "tracking_code": code}, expect=422)
    ready = await hub(client, "arrive", {"hub_id": "abuja-utako", "tracking_code": code})
    assert ready["stage"] == "ready_for_collection"
    tracked = (await client.get(f"/v1/track/{code}")).json()
    assert tracked["collection_point"]["name"].startswith("Partner terminal, Utako")
    assert tracked["label"].startswith("Ready for collection")

    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    wrong = "0000" if codes["pickup_code"] != "0000" else "1111"
    await hub(client, "collect", {"hub_id": "abuja-utako", "tracking_code": code, "code": wrong}, expect=422)
    collected = await hub(
        client, "collect", {"hub_id": "abuja-utako", "tracking_code": code, "code": codes["pickup_code"]}
    )
    assert collected["stage"] == "delivered"
    done = await container.orders.get(order["id"])
    assert done.status == "completed" and done.settled_at is not None
    books = await ledger(client)
    assert books["revenue:waybill"] == b["total_kobo"] - b["vat_kobo"]
    assert books["liability:carrier:sample-north"] == done.settlement.carrier_cost_kobo
    assert "expense:waybill_riders" not in books or books["expense:waybill_riders"] == 0
    summary = (await client.get("/v1/me/order-summary", headers=auth("customer"))).json()
    assert summary["by_vertical"]["waybill"] == {"orders": 1, "spent_kobo": b["total_kobo"]}


# ------------------------------------------------------------------------------------- cancellations
async def test_cancellation_before_pickup_refunds_and_calls_off_the_rider_job(client, container):
    order = await book_and_pay(client, await quote(client))
    leg_id = order["waybill"]["first_mile_order_id"]
    offers = await container.repos.assignments.find(where=[("order_id", "==", leg_id)])
    r = await client.post(f"/v1/orders/{leg_id}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 409 and "cancel the waybill" in r.json()["error"]["message"]

    r = await client.post(
        f"/v1/orders/{order['id']}/cancel", json={"reason": "Changed plans"}, headers=auth("customer")
    )
    assert r.status_code == 200, r.text
    after = (await client.get(f"/v1/orders/{order['id']}", headers=auth("customer"))).json()
    assert after["status"] == "refunded" and after["waybill"]["stage"] == "cancelled"
    assert after["progress"]["step"] == -1
    assert (await container.repos.orders.get(leg_id)).status == "cancelled"
    rider = RIDERS[offers[0].rider_id]
    r = await client.post(f"/v1/rider/offers/{offers[0].id}/accept", headers=auth(rider))
    assert r.status_code == 409  # the job was called off
    assert (await ledger(client))["liability:customer_funds"] == 0
    tracked = (await client.get(f"/v1/track/{after['waybill']['tracking_code']}")).json()
    assert tracked["label"] == "Cancelled"


async def test_dropoff_waybill_cannot_be_cancelled_once_at_the_hub(client, container):
    order = await book_and_pay(client, await quote(client, first_mile="dropoff"))
    code = order["waybill"]["tracking_code"]
    await hub(client, "receive", {"hub_id": order["waybill"]["origin_hub_id"], "tracking_code": code})
    r = await client.post(f"/v1/orders/{order['id']}/cancel", json={}, headers=auth("customer"))
    assert r.status_code == 409


# ---------------------------------------------------------------------------------- permissions & config
async def test_waybills_are_paid_at_booking_and_rider_jobs_are_not_payable(client, container):
    container.cash.min_completed_orders = 0  # pay on delivery would otherwise be open to this customer
    q = await quote(client)  # door to door, under the pay-on-delivery limit
    r = await client.post(
        "/v1/waybills", json={"quote_id": q["id"], "channel": "web"}, headers={**auth("customer"), **idem()}
    )
    waybill = r.json()
    options = await client.get(f"/v1/orders/{waybill['id']}/payment-options", headers=auth("customer"))
    cash = next(m for m in options.json()["methods"] if m["id"] == "cash")
    assert cash == {**cash, "available": False, "reason": "Package deliveries are paid when you book"}
    r = await client.post(
        f"/v1/orders/{waybill['id']}/checkout",
        json={"provider": "cash"},
        headers={**auth("customer"), **idem()},
    )
    assert r.status_code == 422 and "paid when you book" in r.json()["error"]["message"]

    paid = await book_and_pay(client, q)
    leg_id = paid["waybill"]["first_mile_order_id"]
    for provider in (None, "wallet", "cash"):
        body = {"provider": provider} if provider else {}
        r = await client.post(
            f"/v1/orders/{leg_id}/checkout", json=body, headers={**auth("customer"), **idem()}
        )
        assert r.status_code == 409 and "part of a waybill" in r.json()["error"]["message"], r.text


async def test_hub_permissions_and_network_configuration(client, container):
    assert (await client.get("/v1/admin/hubs/lagos-lekki/board", headers=auth("customer"))).status_code == 403
    assert (await client.get("/v1/admin/hubs/lagos-lekki/board", headers=auth("ops"))).status_code == 200
    assert (await client.get("/v1/admin/hubs/nowhere/board", headers=auth("hub"))).status_code == 404
    hubs = (await client.get("/v1/admin/hubs", headers=auth("hub"))).json()
    assert {h["city_name"] for h in hubs} == {"Lagos", "Enugu", "Abuja", "Port Harcourt"}
    await hub(
        client,
        "receive",
        {"hub_id": "lagos-lekki", "tracking_code": "GMW23456789"},
        who="customer",
        expect=403,
    )

    net = (await client.get("/v1/admin/config/logistics", headers=auth("ops"))).json()
    assert (await client.put("/v1/admin/config/logistics", json=net, headers=auth("ops"))).status_code == 403
    bad = json.loads(json.dumps(net))
    bad["lanes"][0]["carrier_id"] = "unknown"
    assert (
        await client.put("/v1/admin/config/logistics", json=bad, headers=auth("admin"))
    ).status_code == 422
    q = await quote(client)
    net["lanes"][0]["base_by_size_kobo"]["small"] = 470_000  # Lagos → Enugu price rise after the quote
    saved = await client.put("/v1/admin/config/logistics", json=net, headers=auth("admin"))
    assert saved.status_code == 200 and saved.json()["version"] == net["version"] + 1
    r = await client.post("/v1/waybills", json={"quote_id": q["id"]}, headers={**auth("customer"), **idem()})
    assert r.status_code == 409 and r.json()["error"]["code"] == "price_changed"
    audit = (await client.get("/v1/admin/audit?resource_type=config", headers=auth("admin"))).json()
    assert any(a["action"] == "config.waybill_network_updated" for a in audit)
