"""Database-level money guarantees that only PostgreSQL enforces (run with TEST_DATABASE_URL)."""

from __future__ import annotations

import os
import uuid

import pytest
from sqlalchemy import text

pytestmark = pytest.mark.skipif(
    not os.environ.get("TEST_DATABASE_URL", "").startswith("postgresql"), reason="requires PostgreSQL"
)


async def test_unbalanced_transaction_is_rejected_at_commit(container):
    db = container.db
    txn_id, a1, a2 = str(uuid.uuid4()), str(uuid.uuid4()), str(uuid.uuid4())
    async with db.transaction() as s:
        await s.execute(
            text(
                "INSERT INTO financial_accounts (id, code, type, currency, is_active, created_at) "
                "VALUES (:a1, 'cash:test', 'asset', 'NGN', true, now()), "
                "(:a2, 'liability:test', 'liability', 'NGN', true, now())"
            ),
            {"a1": a1, "a2": a2},
        )
    with pytest.raises(Exception, match="unbalanced"):
        async with db.transaction() as s:
            await s.execute(
                text(
                    "INSERT INTO financial_transactions (id, kind, idempotency_key, description, created_by, metadata, "
                    "created_at) VALUES (:t, 'test', :k, '', 'test', '{}'::jsonb, now())"
                ),
                {"t": txn_id, "k": txn_id},
            )
            await s.execute(
                text(
                    "INSERT INTO ledger_entries (id, transaction_id, account_id, direction, amount_kobo, currency, "
                    "created_at) VALUES (:e1, :t, :a1, 'debit', 1000, 'NGN', now()), "
                    "(:e2, :t, :a2, 'credit', 999, 'NGN', now())"
                ),
                {"e1": str(uuid.uuid4()), "e2": str(uuid.uuid4()), "t": txn_id, "a1": a1, "a2": a2},
            )
    async with db.session() as s:
        count = (
            await s.execute(text("SELECT count(*) FROM financial_transactions WHERE id = :t"), {"t": txn_id})
        ).scalar()
    assert count == 0  # whole transaction rolled back


async def test_negative_amounts_rejected(container):
    with pytest.raises(Exception, match="ck_entry_positive"):
        async with container.db.transaction() as s:
            await s.execute(
                text(
                    "INSERT INTO ledger_entries (id, transaction_id, account_id, direction, amount_kobo, currency, created_at) "
                    "VALUES ('x', 'y', 'z', 'debit', -5, 'NGN', now())"
                )
            )


async def test_concurrent_wallet_payments_cannot_overspend(flow, client, container, monkeypatch):
    """Two orders paid from one wallet at the same moment: the account row lock lets only one through."""
    import asyncio

    from conftest import PRINCIPALS, auth, idem
    from gudmeal_api.ledger.ledger import LedgerService

    original_balance = LedgerService.balance

    async def slow_balance(self, session, code):  # widen the gap between reading the balance and debiting it
        value = await original_balance(self, session, code)
        if code.startswith("liability:wallet:"):
            await asyncio.sleep(0.2)
        return value

    monkeypatch.setattr(LedgerService, "balance", slow_balance)

    first, second = await flow.order(), await flow.order()
    total = first["breakdown"]["total_kobo"]
    assert second["breakdown"]["total_kobo"] == total
    r = await client.post(
        "/v1/wallet/topups", json={"amount_kobo": total}, headers={**auth("customer"), **idem()}
    )
    await client.post(f"/v1/dev/sandbox-checkout/{r.json()['reference']}/complete?outcome=success")
    for o in (first, second):
        await container.orders.transition(
            o["id"], "pending_payment", actor_type="customer", actor_id="cust-1"
        )
    orders = [await container.orders.get(o["id"]) for o in (first, second)]
    results = await asyncio.gather(
        *(container.payments.pay_with_wallet(o, PRINCIPALS["customer"], f"race-{o.id}") for o in orders),
        return_exceptions=True,
    )
    assert sum(1 for x in results if not isinstance(x, BaseException)) == 1
    assert sum(1 for x in results if isinstance(x, BaseException) and "too low" in str(x)) == 1
    assert await container.wallet.balance("cust-1") == 0
