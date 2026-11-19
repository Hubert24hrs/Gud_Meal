"""Group orders with split bill end to end: joining, everyone's items, one order, shares paid by card or wallet,
the host paying the rest, expiry refunds, refunds split between payers, host-pays mode and the rules."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from conftest import ADDRESS, auth, idem

JOLLOF = {
    "item_id": "jj-party-jollof",
    "quantity": 1,
    "selections": [{"group_id": "r-jollof-junction-protein", "choice_ids": ["chicken"]}],
}
DRINK = {"item_id": "r-jollof-junction-drink-0", "quantity": 2}
FUNDS = 3_000_000  # ₦30,000 in a test wallet


async def create(client, who: str = "customer", **body) -> dict:
    payload = {
        "restaurant_id": "r-jollof-junction",
        "fulfillment": "delivery",
        "delivery_address": ADDRESS,
        "split_mode": "each",
        **body,
    }
    r = await client.post("/v1/group-orders", json=payload, headers=auth(who))
    assert r.status_code == 201, r.text
    return r.json()


async def join(client, code: str, who: str) -> dict:
    r = await client.post("/v1/group-orders/join", json={"code": code}, headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def add(client, gid: str, who: str, *lines: dict) -> dict:
    r = await client.put(f"/v1/group-orders/{gid}/lines", json={"lines": list(lines)}, headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def view(client, gid: str, who: str = "customer") -> dict:
    r = await client.get(f"/v1/group-orders/{gid}", headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def place(client, gid: str, who: str = "customer", **body) -> dict:
    r = await client.post(f"/v1/group-orders/{gid}/checkout", json=body, headers={**auth(who), **idem()})
    assert r.status_code == 201, r.text
    return r.json()


async def pay(client, gid: str, who: str, provider: str | None = None, *, rest: bool = False):
    body: dict = {"cover_rest": rest}
    if provider:
        body["provider"] = provider
    return await client.post(f"/v1/group-orders/{gid}/pay", json=body, headers={**auth(who), **idem()})


async def card(client, response) -> None:
    assert response.status_code == 200, response.text
    ref = response.json()["payment"]["reference"]
    r = await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")
    assert r.status_code == 303


async def top_up(client, amount_kobo: int, who: str) -> None:
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": amount_kobo}, headers={**auth(who), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")


async def balance(client, who: str) -> int:
    return (await client.get("/v1/wallet", headers=auth(who))).json()["balance_kobo"]


async def three_friends(client) -> dict:
    g = await create(client)
    await join(client, g["code"].lower(), "customer2")
    await join(client, g["code"], "customer3")
    await add(client, g["id"], "customer", JOLLOF)
    await add(client, g["id"], "customer2", DRINK)
    await add(client, g["id"], "customer3", {**JOLLOF, "quantity": 2}, DRINK)
    return g


async def test_split_bill_end_to_end(flow, client, container):
    g = await create(client)
    assert g["is_host"] and g["status"] == "open" and len(g["code"]) == 6
    joined = await join(client, g["code"].lower(), "customer2")
    assert joined["is_host"] is False and [m["name"] for m in joined["members"]] == ["Ada", "Bayo"]
    await join(client, g["code"], "customer2")  # joining twice changes nothing
    await join(client, g["code"], "customer3")
    assert (await client.get(f"/v1/group-orders/{g['id']}", headers=auth("finance"))).status_code == 404

    await add(client, g["id"], "customer", JOLLOF)
    await add(client, g["id"], "customer2", DRINK)
    v = await add(client, g["id"], "customer3", {**JOLLOF, "quantity": 2}, DRINK)
    assert {m["name"]: m["items"] for m in v["members"]} == {"Ada": 1, "Bayo": 2, "Chika": 4}
    assert v["estimated_items_kobo"] == sum(ln["line_total_kobo"] for ln in v["lines"]) > 0
    r = await client.put(
        f"/v1/group-orders/{g['id']}/lines",
        json={"lines": [{"item_id": "nope", "quantity": 1}]},
        headers=auth("customer2"),
    )
    assert r.status_code == 409  # not on this store's menu; Bayo's drinks stay
    assert {m["name"]: m["items"] for m in (await view(client, g["id"]))["members"]}["Bayo"] == 2
    mine = await client.get("/v1/group-orders", headers=auth("customer3"))
    assert [x["id"] for x in mine.json()] == [g["id"]]

    assert (
        await client.post(f"/v1/group-orders/{g['id']}/lock", headers=auth("customer2"))
    ).status_code == 403
    locked = (await client.post(f"/v1/group-orders/{g['id']}/lock", headers=auth("customer"))).json()
    assert locked["status"] == "locked"
    r = await client.put(
        f"/v1/group-orders/{g['id']}/lines", json={"lines": [DRINK]}, headers=auth("customer2")
    )
    assert r.status_code == 409 and "locked" in r.json()["error"]["message"]
    r = await client.post(
        f"/v1/group-orders/{g['id']}/checkout", json={}, headers={**auth("customer2"), **idem()}
    )
    assert r.status_code == 403

    placed = await place(client, g["id"])
    order = placed["order"]
    assert placed["status"] == "ordered" and order["status"] == "pending_payment"
    shares = {s["name"]: s for s in placed["shares"]}
    assert sum(s["amount_kobo"] for s in shares.values()) == order["total_kobo"] == placed["total_kobo"]
    assert shares["Chika"]["amount_kobo"] > shares["Ada"]["amount_kobo"]
    assert sum(s["items_kobo"] for s in shares.values()) == order["breakdown"]["subtotal_kobo"]
    notes = await container.repos.notifications.find(where=[("recipient_uid", "==", "cust-2")], limit=20)
    assert "Pay your share" in [n.title for n in notes]

    r = await client.post(
        f"/v1/orders/{order['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 409 and "own share" in r.json()["error"]["message"]
    options = (await client.get(f"/v1/orders/{order['id']}/payment-options", headers=auth("customer"))).json()
    cash = next(m for m in options["methods"] if m["id"] == "cash")
    assert cash["available"] is False and cash["reason"] == "Group orders are paid online"

    await top_up(client, FUNDS, "customer2")
    r = await pay(client, g["id"], "customer2", "wallet")
    assert r.status_code == 200, r.text
    assert r.json()["group"]["my_share"]["status"] == "paid"
    assert await balance(client, "customer2") == FUNDS - shares["Bayo"]["amount_kobo"]
    r = await pay(client, g["id"], "customer2", "wallet")
    assert r.status_code == 422 and "already paid" in r.json()["error"]["message"]

    await card(client, await pay(client, g["id"], "customer3"))
    middle = await view(client, g["id"])
    assert middle["remaining_kobo"] == shares["Ada"]["amount_kobo"] and middle["can_pay"] is True
    assert middle["order"]["status"] == "pending_payment"

    await card(client, await pay(client, g["id"], "customer"))
    final = await view(client, g["id"], "customer3")
    assert final["remaining_kobo"] == 0 and final["order"]["status"] == "submitted_to_restaurant"
    paid = await flow.get(order["id"])
    assert paid["payment"]["provider"] == "group" and paid["payment"]["status"] == "paid"
    payments = await container.payments.group_share_payments(order["id"])
    assert sorted(p["customer_id"] for p in payments) == ["cust-1", "cust-2", "cust-3"]
    assert sum(p["amount_kobo"] for p in payments) == order["total_kobo"]

    # Completed: every payer earns Yummy points on what they paid.
    await flow.deliver(order["id"])
    for who, name in (("customer", "Ada"), ("customer2", "Bayo"), ("customer3", "Chika")):
        points = (await client.get("/v1/rewards", headers=auth(who))).json()["points"]
        assert points == shares[name]["amount_kobo"] // 10_000


async def test_unpaid_shares_expire_and_paid_shares_come_back(client, container):
    g = await create(client)
    await join(client, g["code"], "customer2")
    await add(client, g["id"], "customer", JOLLOF)
    await add(client, g["id"], "customer2", DRINK)
    placed = await place(client, g["id"])
    order_id = placed["order"]["id"]
    await top_up(client, FUNDS, "customer2")
    assert (await pay(client, g["id"], "customer2", "wallet")).status_code == 200
    started = await pay(client, g["id"], "customer")  # Ada opens the card page but doesn't finish in time
    assert started.status_code == 200

    await container.orders.expire_unpaid({"order_id": order_id})
    v = await view(client, g["id"])
    assert v["status"] == "cancelled" and v["order"]["status"] == "cancelled"
    assert await balance(client, "customer2") == FUNDS  # Bayo's share is back in his wallet
    titles = [
        n.title
        for n in await container.repos.notifications.find(where=[("recipient_uid", "==", "cust-2")], limit=50)
    ]
    assert "Group order cancelled" in titles

    # Ada's card payment lands after the cancellation: it is refunded automatically.
    ref = started.json()["payment"]["reference"]
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")
    refunds = (await client.get("/v1/admin/refunds", headers=auth("finance"))).json()
    by_payer = {r["amount_kobo"]: r for r in refunds if r["order_id"] == order_id}
    mine = next(s for s in placed["shares"] if s["name"] == "Ada")["amount_kobo"]
    assert by_payer[mine]["status"] == "succeeded" and len(by_payer) == 2


async def test_host_pays_the_rest_and_a_late_share_payment_is_refunded(flow, client):
    g = await three_friends(client)
    placed = await place(client, g["id"])
    bayo_card = await pay(client, g["id"], "customer2")  # Bayo starts paying by card...
    await top_up(client, 5_000_000, "customer")
    r = await pay(client, g["id"], "customer", "wallet", rest=True)  # ...but Ada pays everything first
    assert r.status_code == 200, r.text
    v = await view(client, g["id"], "customer2")
    assert v["remaining_kobo"] == 0 and v["order"]["status"] == "submitted_to_restaurant"
    assert {s["name"]: s["paid_by_host"] for s in v["shares"]} == {"Ada": False, "Bayo": True, "Chika": True}
    assert await balance(client, "customer") == 5_000_000 - placed["total_kobo"]
    r = await pay(client, g["id"], "customer3", "wallet")
    assert r.status_code == 409 and "no longer waiting" in r.json()["error"]["message"]

    await card(client, bayo_card)  # Bayo finishes paying: his money goes straight back
    bayo_share = next(s for s in placed["shares"] if s["name"] == "Bayo")["amount_kobo"]
    refunds = (await client.get("/v1/admin/refunds", headers=auth("finance"))).json()
    assert [(r["amount_kobo"], r["status"], r["destination"]) for r in refunds] == [
        (bayo_share, "succeeded", "original")
    ]
    assert (await flow.get(placed["order"]["id"]))["status"] == "submitted_to_restaurant"


async def test_refunding_a_paid_group_order_pays_each_person_back(flow, client):
    g = await create(client)
    await join(client, g["code"], "customer2")
    await add(client, g["id"], "customer", JOLLOF)
    await add(client, g["id"], "customer2", DRINK)
    placed = await place(client, g["id"])
    for who in ("customer", "customer2"):
        await top_up(client, FUNDS, who)
        assert (await pay(client, g["id"], who, "wallet")).status_code == 200
    order_id = placed["order"]["id"]
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order_id}/reject",
        json={"reason": "Out of jollof"},
        headers=auth("owner"),
    )
    assert r.status_code == 200, r.text
    final = await flow.get(order_id)
    assert final["status"] == "refunded" and final["refund_total_kobo"] == placed["total_kobo"]
    assert await balance(client, "customer") == FUNDS and await balance(client, "customer2") == FUNDS
    ledger = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()["trial_balance"]
    assert ledger["debits_kobo"] == ledger["credits_kobo"]


async def test_host_pays_mode(flow, client):
    g = await create(client, split_mode="host")
    await join(client, g["code"], "customer2")
    await add(client, g["id"], "customer", JOLLOF)
    await add(client, g["id"], "customer2", DRINK)
    placed = await place(client, g["id"])
    assert placed["order"]["status"] == "draft" and placed["can_pay"] is False
    r = await pay(client, g["id"], "customer2", "wallet")
    assert r.status_code == 409 and "Ada is paying" in r.json()["error"]["message"]
    r = await client.post(
        f"/v1/orders/{placed['order']['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 200, r.text
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    await flow.deliver(placed["order"]["id"])
    host_points = (await client.get("/v1/rewards", headers=auth("customer"))).json()["points"]
    assert host_points == placed["total_kobo"] // 10_000
    assert (await client.get("/v1/rewards", headers=auth("customer2"))).json()["points"] == 0


async def test_group_rules(client, container):
    r = await client.post(
        "/v1/group-orders",
        json={"restaurant_id": "r-jollof-junction", "fulfillment": "delivery"},
        headers=auth("customer"),
    )
    assert r.status_code == 422 and "address" in r.json()["error"]["message"]
    r = await client.post(
        "/v1/group-orders", json={"restaurant_id": "nope", "fulfillment": "pickup"}, headers=auth("customer")
    )
    assert r.status_code == 404

    cfg = (await client.get("/v1/admin/config/growth", headers=auth("admin"))).json()
    await client.put("/v1/admin/config/growth", json={**cfg, "group_max_members": 2}, headers=auth("admin"))
    g = await create(client)
    await join(client, g["code"], "customer2")
    r = await client.post("/v1/group-orders/join", json={"code": g["code"]}, headers=auth("customer3"))
    assert r.status_code == 422 and "full" in r.json()["error"]["message"]
    for code, status in (("12", 422), ("AAAAAA", 404)):
        r = await client.post(
            "/v1/group-orders/join", json={"code": code.ljust(6, "!")}, headers=auth("customer3")
        )
        assert r.status_code == status, r.text

    # Leaving and removing members; the host can't leave.
    await add(client, g["id"], "customer2", DRINK)
    r = await client.delete(f"/v1/group-orders/{g['id']}/members/cust-1", headers=auth("customer2"))
    assert r.status_code == 403
    r = await client.delete(f"/v1/group-orders/{g['id']}/members/cust-1", headers=auth("customer"))
    assert r.status_code == 422
    r = await client.delete(f"/v1/group-orders/{g['id']}/members/cust-2", headers=auth("customer2"))
    assert r.status_code == 200 and r.json() == {"left": True}
    v = await view(client, g["id"])
    assert [m["name"] for m in v["members"]] == ["Ada"] and v["lines"] == []
    r = await client.post(
        f"/v1/group-orders/{g['id']}/checkout", json={}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 422 and "Add some items" in r.json()["error"]["message"]

    # Settings, expiry, cancelling, and the limit on open group orders.
    s = await client.put(
        f"/v1/group-orders/{g['id']}/settings", json={"split_mode": "host"}, headers=auth("customer")
    )
    assert s.json()["split_mode"] == "host"
    await container.repos.group_orders.update(
        g["id"], {"expires_at": datetime.now(UTC) - timedelta(minutes=1)}
    )
    assert (await view(client, g["id"]))["status"] == "expired"
    r = await client.post("/v1/group-orders/join", json={"code": g["code"]}, headers=auth("customer3"))
    assert r.status_code == 409 and "expired" in r.json()["error"]["message"]
    others = [await create(client) for _ in range(3)]
    r = await client.post(
        "/v1/group-orders",
        json={"restaurant_id": "r-jollof-junction", "fulfillment": "pickup"},
        headers=auth("customer"),
    )
    assert r.status_code == 422 and "already have open group orders" in r.json()["error"]["message"]
    cancelled = (
        await client.post(f"/v1/group-orders/{others[0]['id']}/cancel", headers=auth("customer"))
    ).json()
    assert cancelled["status"] == "cancelled"
    assert (await create(client, fulfillment="pickup", delivery_address=None))["fulfillment"] == "pickup"
