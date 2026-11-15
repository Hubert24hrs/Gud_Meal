"""Gud points and referrals end to end: earning, Plus double points, redeeming, refunds, referral rewards."""

from __future__ import annotations

from datetime import UTC, datetime

from conftest import auth, idem


async def rewards(client, who: str = "customer") -> dict:
    r = await client.get("/v1/rewards", headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def quote_with(client, voucher: str, who: str = "customer"):
    from conftest import ADDRESS

    body = {
        "restaurant_id": "r-jollof-junction",
        "lines": [
            {
                "item_id": "jj-party-jollof",
                "quantity": 2,
                "selections": [{"group_id": "r-jollof-junction-protein", "choice_ids": ["chicken"]}],
            }
        ],
        "fulfillment": "delivery",
        "delivery_address": ADDRESS,
        "voucher_code": voucher,
    }
    return await client.post("/v1/quotes", json=body, headers=auth(who))


async def ledger(client) -> dict[str, int]:
    data = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert data["trial_balance"]["debits_kobo"] == data["trial_balance"]["credits_kobo"]
    return {a["account"]: a["balance_kobo"] for a in data["accounts"]}


async def test_points_on_completed_orders_double_for_plus_and_redeeming(flow, client, container):
    start = await rewards(client)
    assert start["points"] == 0 and start["referral"]["code"].startswith("ADAO")
    assert (await rewards(client))["referral"]["code"] == start["referral"]["code"]  # stable

    order = await flow.paid_order()
    assert (await rewards(client))["points"] == 0  # points come when the order is completed
    done = await flow.deliver(order["id"])
    assert done["status"] == "completed"
    earned = done["breakdown"]["total_kobo"] // 10_000
    now = await rewards(client)
    assert now["points"] == earned == now["lifetime_points"]
    assert now["history"][0]["kind"] == "earned" and now["history"][0]["order_id"] == order["id"]
    await container.handlers.dispatch("order.completed", {"order_id": order["id"]})  # replayed event
    assert (await rewards(client))["points"] == earned

    # Plus members earn double.
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": 150_000}, headers={**auth("customer"), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    r = await client.post(
        "/v1/plus/subscribe", json={"provider": "wallet"}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 201, r.text
    second = await flow.deliver((await flow.paid_order())["id"])
    double = 2 * (second["breakdown"]["total_kobo"] // 10_000)
    after = await rewards(client)
    assert after["points"] == earned + double and after["earn"]["member"] is True

    # Redeem in steps of 500 points for a personal ₦500 voucher.
    r = await client.post("/v1/rewards/redeem", json={"points": 300}, headers={**auth("customer"), **idem()})
    assert r.status_code == 422 and "steps of 500" in r.json()["error"]["message"]
    if after["points"] < 500:
        await container.rewards.earn("cust-1", "bonus-for-test", 5_000_000)  # top up points for the test
    balance = (await rewards(client))["points"]
    key = idem()["Idempotency-Key"]
    r = await client.post(
        "/v1/rewards/redeem", json={"points": 500}, headers={**auth("customer"), "Idempotency-Key": key}
    )
    assert r.status_code == 201, r.text
    again = await client.post(
        "/v1/rewards/redeem", json={"points": 500}, headers={**auth("customer"), "Idempotency-Key": key}
    )
    voucher = r.json()["voucher"]
    assert again.json()["voucher"]["code"] == voucher["code"]  # replay: redeemed once
    assert voucher["value_kobo"] == 50_000 and voucher["min_subtotal_kobo"] == 200_000
    assert (await rewards(client))["points"] == balance - 500
    r = await client.post(
        "/v1/rewards/redeem", json={"points": 1_000_000}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 422 and "enough Gud points" in r.json()["error"]["message"]

    # The voucher is personal: it works in my quote, and nobody else's.
    mine = (await client.get("/v1/rewards/vouchers", headers=auth("customer"))).json()
    assert [v["code"] for v in mine] == [voucher["code"]]
    assert (await quote_with(client, voucher["code"], "customer2")).status_code == 422
    q = await quote_with(client, voucher["code"])
    assert q.status_code == 201 and q.json()["breakdown"]["discount_kobo"] == 50_000
    promotions_before = (await ledger(client)).get("expense:promotions", 0)
    used = await flow.deliver((await flow.paid_order(voucher=voucher["code"]))["id"])
    assert used["breakdown"]["discount_kobo"] == 50_000
    assert (await ledger(client))["expense:promotions"] == promotions_before + 50_000  # platform-funded
    assert (await client.get("/v1/rewards/vouchers", headers=auth("customer"))).json() == []


async def test_refunds_after_completion_take_points_back(flow, client, container):
    done = await flow.deliver((await flow.paid_order())["id"])
    earned = done["breakdown"]["total_kobo"] // 10_000
    item = done["lines"][1]
    r = await client.post(
        "/v1/support/tickets",
        headers=auth("customer"),
        json={
            "order_id": done["id"],
            "category": "missing_item",
            "description": "The drinks were missing",
            "missing_item_ids": [item["item_id"]],
        },
    )
    ticket = r.json()
    r = await client.patch(
        f"/v1/admin/support/tickets/{ticket['id']}",
        headers=auth("support"),
        json={
            "status": "resolved",
            "resolution": "Refunding missing drinks",
            "refund_amount_kobo": item["line_total_kobo"],
            "refund_liability": "restaurant",
        },
    )
    assert r.status_code == 200, r.text
    refund = (await client.get("/v1/admin/refunds?status=requested", headers=auth("finance"))).json()[0]
    r = await client.post(
        f"/v1/admin/refunds/{refund['id']}/decision", json={"approve": True}, headers=auth("finance")
    )
    assert r.status_code == 200, r.text
    assert (await flow.get(done["id"]))["status"] == "partially_refunded"
    taken = earned * item["line_total_kobo"] // done["breakdown"]["total_kobo"]
    now = await rewards(client)
    assert now["points"] == earned - taken and now["lifetime_points"] == earned
    assert now["history"][0]["kind"] == "reversed" and now["history"][0]["points"] == -taken
    await container.handlers.dispatch("order.partially_refunded", {"order_id": done["id"]})  # replay
    assert (await rewards(client))["points"] == earned - taken


async def test_referrals(flow, client, container):
    code = (await rewards(client))["referral"]["code"]  # Ada invites Bayo
    for bad, message in ((code, "your own"), ("NOPE1234", "don't recognise"), ("!!!!", "doesn't look like")):
        who = "customer" if bad == code else "customer2"
        r = await client.post("/v1/rewards/referral", json={"code": bad}, headers=auth(who))
        assert r.status_code == 422 and message in r.json()["error"]["message"], r.text

    r = await client.post("/v1/rewards/referral", json={"code": code.lower()}, headers=auth("customer2"))
    assert r.status_code == 200, r.text
    gift = r.json()["voucher"]
    assert gift["value_kobo"] == 100_000 and gift["min_subtotal_kobo"] == 300_000
    r = await client.post("/v1/rewards/referral", json={"code": code}, headers=auth("customer2"))
    assert r.status_code == 422 and "already used" in r.json()["error"]["message"]
    bayo = await rewards(client, "customer2")
    assert bayo["referral"]["applied"] is True and bayo["referral"]["can_apply"] is False
    notes = await container.repos.notifications.find(where=[("recipient_uid", "==", "cust-1")], limit=20)
    assert "Someone used your referral code" in [n.title for n in notes]

    # Bayo's first completed order (with the gift) rewards Ada once.
    order = await flow.paid_order("customer2", voucher=gift["code"])
    assert order["breakdown"]["discount_kobo"] == 100_000
    assert (await rewards(client))["vouchers"] == []
    await flow.deliver(order["id"], "customer2")
    ada = await rewards(client)
    assert ada["referral"]["friends_rewarded"] == 1
    assert [v["source"] for v in ada["vouchers"]] == ["referrer"]
    await flow.deliver((await flow.paid_order("customer2"))["id"], "customer2")  # second order: no reward
    assert len((await rewards(client))["vouchers"]) == 1

    # A customer who has already ordered can't use a code.
    chika = await rewards(client, "customer3")
    await flow.paid_order("customer3")
    r = await client.post("/v1/rewards/referral", json={"code": code}, headers=auth("customer3"))
    assert r.status_code == 422 and "new customers" in r.json()["error"]["message"]
    assert chika["referral"]["can_apply"] is True


async def test_monthly_cap_settings_and_staff_view(flow, client, container):
    cfg = (await client.get("/v1/admin/config/growth", headers=auth("admin"))).json()
    assert (
        await client.put("/v1/admin/config/growth", json=cfg, headers=auth("customer"))
    ).status_code == 403
    r = await client.put(
        "/v1/admin/config/growth", json={**cfg, "referrer_monthly_cap": 1}, headers=auth("admin")
    )
    assert r.status_code == 200 and r.json()["version"] == cfg["version"] + 1
    code = (await rewards(client))["referral"]["code"]
    for who in ("customer2", "customer3"):
        assert (
            await client.post("/v1/rewards/referral", json={"code": code}, headers=auth(who))
        ).status_code == 200
        await flow.deliver((await flow.paid_order(who))["id"], who)
    ada = await rewards(client)
    assert ada["referral"]["friends_rewarded"] == 2 and len(ada["vouchers"]) == 1  # capped at 1 a month
    account = await container.repos.rewards.get("cust-1")
    assert account.month_key == datetime.now(UTC).strftime("%Y-%m") and account.month_rewards == 1

    assert (await client.get("/v1/admin/growth", headers=auth("customer"))).status_code == 403
    stats = (await client.get("/v1/admin/growth", headers=auth("finance"))).json()["rewards"]
    assert stats["referred_customers"] == 2 and stats["referrals_rewarded"] == 2
    assert stats["vouchers"]["referral"]["issued"] == 2 and stats["vouchers"]["referrer"]["issued"] == 1
    assert stats["points_outstanding"] > 0
    audit = (await client.get("/v1/admin/audit?resource_type=config", headers=auth("admin"))).json()
    assert audit[0]["action"] == "growth_config.saved"
