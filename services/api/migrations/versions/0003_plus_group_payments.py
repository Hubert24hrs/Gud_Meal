"""Yummy Chops Plus and group-order share payments

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-15 18:00:00

- payment_records.purpose also accepts 'plus' (membership, no order) and 'group_share' (one member's share of a
  group order; several succeeded payments may then belong to one order).

Downgrade refuses to run while such payments exist (the old constraint would reject them): it never deletes
payment data.
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_constraint("ck_payment_order_ref", "payment_records", type_="check")
    op.drop_constraint("ck_payment_purpose", "payment_records", type_="check")
    op.create_check_constraint(
        "ck_payment_purpose", "payment_records", "purpose IN ('order','wallet_topup','plus','group_share')"
    )
    op.create_check_constraint(
        "ck_payment_order_ref",
        "payment_records",
        "purpose NOT IN ('order','group_share') OR order_id IS NOT NULL",
    )


def downgrade() -> None:
    op.drop_constraint("ck_payment_order_ref", "payment_records", type_="check")
    op.drop_constraint("ck_payment_purpose", "payment_records", type_="check")
    op.create_check_constraint("ck_payment_purpose", "payment_records", "purpose IN ('order','wallet_topup')")
    op.create_check_constraint(
        "ck_payment_order_ref", "payment_records", "purpose <> 'order' OR order_id IS NOT NULL"
    )
