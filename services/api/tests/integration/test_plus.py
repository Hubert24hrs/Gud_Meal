"""Gud Meal Plus end to end: joining by wallet or card, member prices, renewals, cancelling, staff view."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

from conftest import auth, idem

PRICE = 150_000  # ₦1,500 per 30 days, VAT included
VAT = 10_465


async def ledger(client) -> dict[str, int]:
    data = (await client.get("/v1/admin/ledger", headers=auth("finance"))).json()
    assert data["trial_balance"]["debits_kobo"] == data["trial_balance"]["credits_kobo"]
    return {a["account"]: a["balance_kobo"] for a in data["accounts"]}


async def top_up(client, amount_kobo: int, who: str = "customer") -> None:
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": amount_kobo}, headers={**auth(who), **idem()}
    )
    assert r.status_code == 201, r.text
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")


async def subscribe(client, who: str = "customer", key: str | None = None, **body) -> dict:
    r = await client.post(
        "/v1/plus/subscribe",
        json=body,
        headers={**auth(who), "Idempotency-Key": key or idem()["Idempotency-Key"]},
    )
    assert r.status_code == 201, r.text
    return r.json()


async def plus(client, who: str = "customer") -> dict:
    r = await client.get("/v1/plus", headers=auth(who))
    assert r.status_code == 200, r.text
    return r.json()


async def notes(container, uid: str) -> list[str]:
    found = await container.repos.notifications.find(where=[("recipient_uid", "==", uid)], limit=100)
    return [n.title for n in found]


async def test_join_from_the_wallet_and_get_member_prices(flow, client, container):
    before = await plus(client)
    assert before["member"] is False and before["membership"] is None
    assert before["plan"]["price_kobo"] == PRICE and before["plan"]["vat_kobo"] == VAT
    assert any("Free delivery" in b for b in before["plan"]["benefits"])
    normal = await flow.quote()

    r = await client.post(
        "/v1/plus/subscribe", json={"provider": "wallet"}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 422 and "too low" in r.json()["error"]["message"]

    await top_up(client, 200_000)
    key = idem()["Idempotency-Key"]
    joined = await subscribe(client, key=key, provider="wallet")
    again = await subscribe(client, key=key, provider="wallet")  # replay: charged once
    assert joined["payment"]["reference"] == again["payment"]["reference"]
    assert joined["member"] is True and joined["membership"]["auto_renew"] is True
    assert joined["membership"]["days_left"] in (29, 30)
    assert (await client.get("/v1/wallet", headers=auth("customer"))).json()["balance_kobo"] == 50_000
    accounts = await ledger(client)
    assert accounts["revenue:plus"] == PRICE - VAT and accounts["liability:vat"] >= VAT
    assert "Welcome to Gud Meal Plus" in await notes(container, "cust-1")

    member = await flow.quote()
    b, n = member["breakdown"], normal["breakdown"]
    assert b["delivery_fee_kobo"] == 0 and n["delivery_fee_kobo"] > 0
    assert b["service_fee_kobo"] < n["service_fee_kobo"]
    assert b["plus_savings_kobo"] == n["total_kobo"] - b["total_kobo"] > 0
    assert (await flow.quote("customer2"))["breakdown"]["plus_savings_kobo"] == 0  # not a member

    order = await flow.paid_order()  # creating the order re-prices with the same benefits
    assert order["breakdown"]["plus_savings_kobo"] == b["plus_savings_kobo"]

    r = await client.post(
        "/v1/plus/subscribe", json={"provider": "wallet"}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 422  # one paid period ahead at most
    assert "already a Gud Meal Plus member" in r.json()["error"]["message"]

    config = (await client.get("/v1/config/public")).json()["plus"]
    assert config["price_kobo"] == PRICE and config["free_delivery_min_subtotal_kobo"] == 300_000


async def test_join_by_card_and_renew_early(client, container):
    started = await subscribe(client, auto_renew=False)
    assert started["payment"]["authorization_url"] and started["member"] is False
    ref = started["payment"]["reference"]
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")
    await client.post(f"/v1/dev/sandbox-checkout/{ref}/complete?outcome=success")  # webhook replay
    now = await plus(client)
    assert now["member"] is True and now["membership"]["periods"] == 1
    assert now["membership"]["auto_renew"] is False
    first_end = datetime.fromisoformat(now["membership"]["paid_through"])

    assert now["membership"]["can_renew"] is False
    r = await client.post("/v1/plus/subscribe", json={}, headers={**auth("customer"), **idem()})
    assert r.status_code == 422 and "already a Gud Meal Plus member" in r.json()["error"]["message"]

    # In the last week of a period, paying again extends from the current end date.
    five_days = datetime.now(UTC) + timedelta(days=5)
    await container.repos.memberships.update("cust-1", {"paid_through": five_days})
    assert (await plus(client))["membership"]["can_renew"] is True
    renewed = await subscribe(client)
    await client.post(f"/v1/dev/sandbox-checkout/{renewed['payment']['reference']}/complete?outcome=success")
    later = await plus(client)
    assert later["membership"]["periods"] == 2
    assert datetime.fromisoformat(later["membership"]["paid_through"]) == five_days + timedelta(days=30)
    assert first_end > datetime.now(UTC) + timedelta(days=29)
    assert "Gud Meal Plus renewed" in await notes(container, "cust-1")


async def test_wallet_auto_renewal_reminders_and_cancelling(client, container):
    await top_up(client, PRICE)
    await subscribe(client, provider="wallet")
    m = await container.repos.memberships.get("cust-1")
    soon = datetime.now(UTC) + timedelta(hours=3)
    await container.repos.memberships.update("cust-1", {"paid_through": soon})

    # Empty wallet: one reminder, however often the job runs.
    assert await container.membership.renew_due() == {"renewed": 0, "reminded": 1}
    assert await container.membership.renew_due() == {"renewed": 0, "reminded": 0}
    assert (await notes(container, "cust-1")).count("Keep Gud Meal Plus") == 1

    await top_up(client, PRICE)
    assert (await client.post("/internal/jobs/renew-plus")).status_code == 403  # Cloud Scheduler only
    r = await client.post("/internal/jobs/renew-plus", headers={"X-Internal-Token": "test-internal-secret"})
    assert r.status_code == 200 and r.json() == {"renewed": 1, "reminded": 0}
    renewed = await container.repos.memberships.get("cust-1")
    assert renewed.periods == m.periods + 1 and renewed.paid_through == soon + timedelta(days=30)
    assert await container.membership.renew_due() == {"renewed": 0, "reminded": 0}  # not due any more
    assert (await ledger(client))["revenue:plus"] == 2 * (PRICE - VAT)

    # Cancelling = auto-renew off: benefits stay until the end, no more charges.
    r = await client.put("/v1/plus/auto-renew", json={"auto_renew": False}, headers=auth("customer"))
    assert r.status_code == 200 and r.json()["member"] is True
    assert r.json()["membership"]["auto_renew"] is False
    await container.repos.memberships.update(
        "cust-1", {"paid_through": datetime.now(UTC) + timedelta(hours=2)}
    )
    await top_up(client, PRICE)
    assert await container.membership.renew_due() == {"renewed": 0, "reminded": 0}

    # A lapsed membership is not charged again automatically, even with auto-renew back on.
    await container.repos.memberships.update(
        "cust-1", {"paid_through": datetime.now(UTC) - timedelta(days=3), "auto_renew": True}
    )
    assert await container.membership.renew_due() == {"renewed": 0, "reminded": 0}
    assert (await plus(client))["member"] is False


async def test_permissions_and_staff_view(client):
    r = await client.put("/v1/plus/auto-renew", json={"auto_renew": False}, headers=auth("customer2"))
    assert r.status_code == 404  # not a member
    await top_up(client, PRICE, "customer2")
    await subscribe(client, "customer2", provider="wallet")
    assert (await client.get("/v1/admin/growth", headers=auth("customer"))).status_code == 403
    stats = (await client.get("/v1/admin/growth", headers=auth("finance"))).json()["plus"]
    assert stats["active_members"] == 1 and stats["auto_renew_on"] == 1
    assert stats["revenue_kobo"] == PRICE - VAT
