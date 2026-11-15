"""wallet top-ups, refund destination, cash and seller payouts

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-15 12:00:00

- payment_records.purpose ('order' | 'wallet_topup'); order_id becomes optional (top-ups have no order).
- refund_records.destination ('original' | 'wallet').
- vendor_payouts: sellers withdrawing cash-on-delivery money (finance-reviewed).

Downgrade refuses to run while wallet top-ups exist (order_id cannot become NOT NULL again), which is
the intended behaviour: it never deletes payment data.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "payment_records",
        sa.Column("purpose", sa.String(length=16), server_default="order", nullable=False),
    )
    op.alter_column("payment_records", "order_id", existing_type=sa.String(length=64), nullable=True)
    op.create_check_constraint("ck_payment_purpose", "payment_records", "purpose IN ('order','wallet_topup')")
    op.create_check_constraint(
        "ck_payment_order_ref", "payment_records", "purpose <> 'order' OR order_id IS NOT NULL"
    )

    op.add_column(
        "refund_records",
        sa.Column("destination", sa.String(length=16), server_default="original", nullable=False),
    )
    op.create_check_constraint("ck_refund_destination", "refund_records", "destination IN ('original','wallet')")

    op.create_table(
        "vendor_payouts",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("vendor_id", sa.String(length=128), nullable=False),
        sa.Column("amount_kobo", sa.BigInteger(), nullable=False),
        sa.Column("bank_name", sa.String(length=80), nullable=False),
        sa.Column("account_number", sa.String(length=10), nullable=False),
        sa.Column("account_name", sa.String(length=120), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("idempotency_key", sa.String(length=200), nullable=False),
        sa.Column("decided_by", sa.String(length=128), nullable=True),
        sa.Column("decision_note", sa.Text(), nullable=True),
        sa.Column("reference", sa.String(length=120), nullable=True),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("amount_kobo > 0", name="ck_vendor_payout_positive"),
        sa.CheckConstraint("status IN ('requested','paid','rejected')", name="ck_vendor_payout_status"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("idempotency_key"),
    )
    op.create_index(op.f("ix_vendor_payouts_vendor_id"), "vendor_payouts", ["vendor_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_vendor_payouts_vendor_id"), table_name="vendor_payouts")
    op.drop_table("vendor_payouts")
    op.drop_constraint("ck_refund_destination", "refund_records", type_="check")
    op.drop_column("refund_records", "destination")
    op.drop_constraint("ck_payment_order_ref", "payment_records", type_="check")
    op.drop_constraint("ck_payment_purpose", "payment_records", type_="check")
    op.alter_column("payment_records", "order_id", existing_type=sa.String(length=64), nullable=False)
    op.drop_column("payment_records", "purpose")
