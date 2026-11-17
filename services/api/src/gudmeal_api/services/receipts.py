"""Receipts (ADR-0019): a customer prints the receipt of an order they paid for, and it is then kept under
"My receipts" on every device they sign in to.

The receipt is built from the order (see `domain/receipts.py`); printing stores that document once per order,
under the customer's own profile, and counts further prints. No money moves here.
"""

from __future__ import annotations

from datetime import UTC, datetime

from ..domain.models import Order
from ..domain.receipts import Receipt, build_receipt, is_paid
from ..errors import Conflict, NotFound
from ..repositories import Repositories
from ..repositories.repos import TypedCollection
from ..security.rbac import Principal


class OrderNotPaid(Conflict):
    code = "order_not_paid"


def utcnow() -> datetime:
    return datetime.now(UTC)


class ReceiptService:
    def __init__(self, repos: Repositories) -> None:
        self.repos = repos

    def _kept(self, uid: str) -> TypedCollection[Receipt]:
        return TypedCollection(self.repos.store, f"customer_profiles/{uid}/receipts", Receipt)

    async def _paid_order(self, principal: Principal, order_id: str) -> Order:
        order = await self.repos.orders.get(order_id)
        # Only the customer who placed the order has a receipt for it; rider jobs of a waybill are internal.
        if order is None or order.customer_id != principal.uid or order.is_leg:
            raise NotFound("Order not found")
        if not is_paid(order):
            raise OrderNotPaid(
                "This order has not been paid for yet, so there is no receipt",
                details={"payment_status": order.payment.status},
            )
        return order

    async def get(self, principal: Principal, order_id: str) -> Receipt:
        """The receipt to show: the kept one if the customer has printed it, else a fresh one (not kept yet)."""
        order = await self._paid_order(principal, order_id)
        kept = await self._kept(principal.uid).get(order_id)
        if kept is None:
            return build_receipt(order, utcnow())
        return kept.model_copy(update={"saved": True, "refunded_kobo": order.refund_total_kobo})

    async def print(self, principal: Principal, order_id: str) -> Receipt:
        """The customer pressed PRINT: keep the receipt (once per order) and count the print."""
        order = await self._paid_order(principal, order_id)
        now = utcnow()
        kept = self._kept(principal.uid)
        receipt = await kept.get(order_id) or build_receipt(order, now)
        receipt = receipt.model_copy(
            update={
                "saved": True,
                "printed_at": now,
                "print_count": receipt.print_count + 1,
                "refunded_kobo": order.refund_total_kobo,
            }
        )
        await kept.save(receipt)
        return receipt

    async def list(self, principal: Principal, limit: int = 50) -> list[Receipt]:
        """My receipts, newest first."""
        return await self._kept(principal.uid).find(order_by=[("issued_at", "desc")], limit=min(limit, 100))
