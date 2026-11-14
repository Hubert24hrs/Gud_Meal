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
