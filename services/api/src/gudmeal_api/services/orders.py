"""Order lifecycle orchestration. All status changes go through `transition()` (Firestore transaction)."""

from __future__ import annotations

import hmac
import logging
import secrets
import uuid
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

from ..domain.models import Fulfillment, Order, OrderEvent, PaymentSummary
from ..domain.money import format_naira
from ..domain.order_state import ACTIVE_FULFILMENT, ActorType, OrderStatus, assert_transition
from ..errors import (
    InvalidTransition,
    NotFound,
    PermissionDenied,
    PriceChanged,
    QuoteExpired,
    ValidationFailed,
)
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, require, require_restaurant
from .infra import Emitter, Notifier, TaskQueue
from .quotes import QuoteService

logger = logging.getLogger(__name__)
S = OrderStatus
A = ActorType
_SHORT_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"

TASK_RESTAURANT_TIMEOUT = "/internal/tasks/restaurant-accept-timeout"
TASK_UNPAID_EXPIRY = "/internal/tasks/unpaid-order-expiry"

CUSTOMER_NOTIFY: dict[OrderStatus, tuple[str, str]] = {
    S.RESTAURANT_ACCEPTED: ("Order accepted", "{restaurant} is preparing your order"),
    S.READY_FOR_PICKUP: ("Ready", "Your order from {restaurant} is ready"),
    S.RIDER_ASSIGNED: ("Rider assigned", "{rider} is heading to {restaurant}"),
    S.PICKED_UP: ("On the way", "{rider} has picked up your order"),
    S.DELIVERED: ("Delivered", "Enjoy your meal from {restaurant}!"),
    S.REFUND_PENDING: ("Refund started", "We're refunding your order from {restaurant}"),
    S.REFUNDED: ("Refunded", "Your refund has been processed"),
    S.CANCELLED: ("Order cancelled", "Your order from {restaurant} was cancelled"),
}


def utcnow() -> datetime:
    return datetime.now(UTC)


def short_code() -> str:
    return "".join(secrets.choice(_SHORT_ALPHABET) for _ in range(6))


def new_code() -> str:
    return f"{secrets.randbelow(10_000):04d}"


Patch = dict[str, Any] | Callable[[Order], dict[str, Any]]


class OrderService:
    def __init__(
        self,
        repos: Repositories,
        quotes: QuoteService,
        *,
        emitter: Emitter,
        notifier: Notifier,
        tasks: TaskQueue,
        payments: Any,
        restaurant_accept_timeout_seconds: int = 480,
        unpaid_order_ttl_seconds: int = 1800,
        code_max_attempts: int = 5,
    ) -> None:
        self.repos = repos
        self.quotes = quotes
        self.emitter = emitter
        self.notifier = notifier
        self.tasks = tasks
        self.payments = payments
        self.accept_timeout = restaurant_accept_timeout_seconds
        self.unpaid_ttl = unpaid_order_ttl_seconds
        self.code_max_attempts = code_max_attempts

    # ============================================================================ core transition
    @staticmethod
    def build_transition(
        order: Order,
        to: OrderStatus,
        *,
        actor_type: ActorType,
        actor_id: str,
        reason: str | None = None,
        patch: Patch | None = None,
        metadata: dict[str, Any] | None = None,
        now: datetime,
    ) -> tuple[dict[str, Any], OrderEvent]:
        assert_transition(order.status, to, actor_type, reason)
        updates: dict[str, Any] = {"status": to, "updated_at": now, "version": order.version + 1}
        if patch:
            updates.update(patch(order) if callable(patch) else patch)
        event = OrderEvent(
            id=uuid.uuid4().hex,
            order_id=order.id,
            from_status=order.status,
            to_status=to,
            actor_type=actor_type,
            actor_id=actor_id,
            reason=reason,
            at=now,
            metadata=metadata or {},
        )
        return updates, event

    @staticmethod
    def write_transition(tx: Transaction, order_id: str, updates: dict[str, Any], event: OrderEvent) -> None:
        tx.update(f"orders/{order_id}", to_doc(updates))
        tx.create(f"order_events/{event.id}", to_doc(event))

    async def transition(
        self,
        order_id: str,
        to: OrderStatus,
        *,
        actor_type: ActorType,
        actor_id: str,
        reason: str | None = None,
        patch: Patch | None = None,
        metadata: dict[str, Any] | None = None,
        check: Callable[[Order], None] | None = None,
    ) -> Order:
        now = utcnow()
        captured: dict[str, Any] = {}

        async def fn(tx: Transaction) -> Order:
            data = await tx.get(f"orders/{order_id}")
            if data is None:
                raise NotFound("Order not found")
            order = Order.model_validate(data)
            if check:
                check(order)
            updates, event = self.build_transition(
                order,
                to,
                actor_type=actor_type,
                actor_id=actor_id,
                reason=reason,
                patch=patch,
                metadata=metadata,
                now=now,
            )
            self.write_transition(tx, order_id, updates, event)
            captured["from"] = order.status
            captured["event"] = event
            return Order.model_validate({**order.model_dump(), **updates})

        updated = await self.repos.store.run_transaction(fn)
        await self.after_transition(updated, captured["from"], captured["event"])
        return updated

    async def after_transition(self, order: Order, previous: OrderStatus, event: OrderEvent) -> None:
        payload = {
            "order_id": order.id,
            "from": previous.value,
            "to": order.status.value,
            "event_id": event.id,
            "metadata": {**event.metadata, "reason": event.reason},
            "fulfillment": order.fulfillment.value,
            "actor_type": event.actor_type.value,
        }
        await self.emitter.emit(f"order.{order.status.value}", payload)
        template = CUSTOMER_NOTIFY.get(order.status)
        if template:
            title, body = template
            await self.notifier.notify_user(
                order.customer_id,
                title,
                body.format(restaurant=order.restaurant_name, rider=order.rider_name or "Your rider"),
                {"order_id": order.id, "status": order.status.value},
            )

    # ============================================================================ reads
    async def get(self, order_id: str) -> Order:
        order = await self.repos.orders.get(order_id)
        if order is None:
            raise NotFound("Order not found")
        return order

    def assert_can_view(self, principal: Principal, order: Order) -> None:
        if order.customer_id == principal.uid:
            return
        if principal.can_on_restaurant(order.restaurant_id, "orders"):
            return
        if order.rider_id and order.rider_id == principal.uid:
            return
        if principal.can(Permission.ORDERS_READ_ALL):
            return
        raise NotFound("Order not found")  # do not reveal existence

    async def get_for(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        self.assert_can_view(principal, order)
        return order

    async def list_for_customer(self, uid: str, limit: int = 20) -> list[Order]:
        return await self.repos.orders.find(
            where=[("customer_id", "==", uid)], order_by=[("created_at", "desc")], limit=min(limit, 100)
        )

    async def list_for_restaurant(
        self,
        principal: Principal,
        restaurant_id: str,
        statuses: list[OrderStatus] | None = None,
        limit: int = 50,
    ) -> list[Order]:
        require_restaurant(principal, restaurant_id, "orders")
        where: list[Any] = [("restaurant_id", "==", restaurant_id)]
        if statuses:
            where.append(("status", "in", [s.value for s in statuses][:10]))
        return await self.repos.orders.find(
            where=where, order_by=[("created_at", "desc")], limit=min(limit, 200)
        )

    async def list_for_rider(
        self, uid: str, statuses: list[OrderStatus] | None = None, limit: int = 30
    ) -> list[Order]:
        where: list[Any] = [("rider_id", "==", uid)]
        if statuses:
            where.append(("status", "in", [s.value for s in statuses][:10]))
        return await self.repos.orders.find(
            where=where, order_by=[("created_at", "desc")], limit=min(limit, 100)
        )

    async def list_all(
        self, principal: Principal, status: OrderStatus | None = None, limit: int = 100
    ) -> list[Order]:
        require(principal, Permission.ORDERS_READ_ALL)
        where = [("status", "==", status.value)] if status else []
        return await self.repos.orders.find(
            where=where, order_by=[("created_at", "desc")], limit=min(limit, 500)
        )

    async def events(self, principal: Principal, order_id: str) -> list[OrderEvent]:
        await self.get_for(principal, order_id)
        return await self.repos.order_events.find(
            where=[("order_id", "==", order_id)], order_by=[("at", "asc")]
        )

    async def customer_codes(self, principal: Principal, order_id: str) -> dict[str, Any]:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        codes = await self.repos.store.get(self.repos.codes_path(order_id)) or {}
        return {"delivery_code": codes.get("delivery_code"), "pickup_code": codes.get("pickup_code")}

    # ============================================================================ customer flows
    async def create_from_quote(
        self,
        principal: Principal,
        quote_id: str,
        *,
        channel: Literal["app", "web", "ai_agent", "admin"] = "app",
        contact_phone: str | None = None,
    ) -> Order:
        quote = await self.quotes.get_quote(principal, quote_id)
        if quote.order_id:
            return await self.get(quote.order_id)  # creating twice from one quote is idempotent
        now = utcnow()
        if quote.expires_at < now:
            raise QuoteExpired("Your price quote expired; please review your cart again")

        # Re-validate against live data: availability, opening hours and unchanged prices.
        from ..domain.models import CartLine, QuoteRequest

        req = QuoteRequest(
            restaurant_id=quote.restaurant_id,
            lines=[
                CartLine(item_id=ln.item_id, quantity=ln.quantity, selections=ln.selections, notes=ln.notes)
                for ln in quote.lines
            ],
            fulfillment=quote.fulfillment,
            delivery_address=quote.delivery_address,
            scheduled_for=quote.scheduled_for,
            voucher_code=quote.breakdown.voucher_code,
        )
        restaurant, result, _, _, _, _ = await self.quotes.price_request(
            req, customer_id=principal.uid, now=now
        )
        if result.breakdown.total_kobo != quote.breakdown.total_kobo:
            raise PriceChanged(
                "Prices changed since your quote; please review your cart",
                details={
                    "quoted_total_kobo": quote.breakdown.total_kobo,
                    "new_total_kobo": result.breakdown.total_kobo,
                },
            )

        order_id = uuid.uuid4().hex
        address = quote.delivery_address
        if address and contact_phone:
            address = address.model_copy(update={"contact_phone": contact_phone})
        order = Order(
            id=order_id,
            short_code=short_code(),
            customer_id=principal.uid,
            customer_name=principal.name,
            customer_phone=contact_phone or principal.phone,
            restaurant_id=restaurant.id,
            restaurant_name=restaurant.name,
            restaurant_location=restaurant.location,
            restaurant_address=restaurant.address,
            status=S.DRAFT,
            fulfillment=quote.fulfillment,
            lines=quote.lines,
            breakdown=quote.breakdown,
            settlement=quote.settlement,
            delivery_address=address,
            distance_km=quote.distance_km,
            scheduled_for=quote.scheduled_for,
            quote_id=quote.id,
            estimated_delivery_at=quote.estimated_delivery_at,
            channel=channel,
            created_at=now,
            updated_at=now,
        )
        event = OrderEvent(
            id=uuid.uuid4().hex,
            order_id=order_id,
            from_status=None,
            to_status=S.DRAFT,
            actor_type=A.CUSTOMER,
            actor_id=principal.uid,
            at=now,
            metadata={"channel": channel},
        )

        async def fn(tx: Transaction) -> str:
            qdata = await tx.get(f"quotes/{quote.id}")
            if qdata and qdata.get("order_id"):
                return str(qdata["order_id"])
            tx.update(f"quotes/{quote.id}", {"order_id": order_id})
            tx.create(f"orders/{order_id}", to_doc(order))
            tx.create(f"order_events/{event.id}", to_doc(event))
            return order_id

        created_id = await self.repos.store.run_transaction(fn)
        if created_id != order_id:
            return await self.get(created_id)
        await self.tasks.enqueue(TASK_UNPAID_EXPIRY, {"order_id": order_id}, delay_seconds=self.unpaid_ttl)
        return order

    async def checkout(
        self, principal: Principal, order_id: str, *, provider: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        if order.status == S.DRAFT:
            order = await self.transition(
                order_id, S.PENDING_PAYMENT, actor_type=A.CUSTOMER, actor_id=principal.uid
            )
        elif order.status != S.PENDING_PAYMENT:
            raise InvalidTransition(f"Order is already {order.status.value}")
        payment = await self.payments.initiate(order, principal, provider, idempotency_key)
        await self.repos.orders.update(
            order_id,
            {
                "payment": to_doc(
                    PaymentSummary(
                        provider=payment["provider"], reference=payment["reference"], status="pending"
                    )
                ),
                "updated_at": utcnow(),
            },
        )
        return {"order_id": order_id, "status": S.PENDING_PAYMENT.value, **payment}

    async def cancel_by_customer(self, principal: Principal, order_id: str, reason: str | None) -> Order:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        reason = (reason or "Cancelled by customer").strip()[:300]
        if order.status in (S.DRAFT, S.PENDING_PAYMENT):
            return await self.transition(
                order_id,
                S.CANCELLED,
                actor_type=A.CUSTOMER,
                actor_id=principal.uid,
                reason=reason,
                patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
            )
        if order.status == S.SUBMITTED_TO_RESTAURANT:
            return await self.transition(
                order_id,
                S.REFUND_PENDING,
                actor_type=A.CUSTOMER,
                actor_id=principal.uid,
                reason=reason,
                patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
                metadata=refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
                check=lambda o: _expect(o, {S.SUBMITTED_TO_RESTAURANT}),
            )
        raise InvalidTransition("This order can no longer be cancelled in the app; please contact support")

    async def dispute(self, principal: Principal, order_id: str, reason: str) -> Order:
        order = await self.get(order_id)
        if order.customer_id != principal.uid:
            raise NotFound("Order not found")
        if order.completed_at and utcnow() - order.completed_at > timedelta(days=2):
            raise InvalidTransition("Disputes must be raised within 48 hours of delivery")
        return await self.transition(
            order_id, S.DISPUTED, actor_type=A.CUSTOMER, actor_id=principal.uid, reason=reason
        )

    # ============================================================================ payment hooks
    async def on_payment_succeeded(self, payload: dict[str, Any]) -> None:
        order_id = str(payload["order_id"])
        order = await self.get(order_id)
        paid_at = payload.get("paid_at") or utcnow().isoformat()
        payment_patch = {
            "payment": to_doc(
                PaymentSummary(
                    provider=payload.get("provider"),
                    reference=payload.get("reference"),
                    status="paid",
                    paid_at=datetime.fromisoformat(str(paid_at)),
                )
            )
        }
        if order.status == S.CANCELLED:
            # Customer paid after the order was cancelled/expired → refund automatically.
            await self.emitter.emit(
                "payment.orphaned",
                {
                    "order_id": order_id,
                    "payment_id": payload.get("payment_id"),
                    **refund_meta(int(payload["amount_kobo"]), "platform", "before_completion", auto=True),
                },
            )
            return
        if order.status == S.DRAFT:
            order = await self.transition(
                order_id, S.PENDING_PAYMENT, actor_type=A.SYSTEM, actor_id="payments"
            )
        if order.status == S.PENDING_PAYMENT:
            if int(payload["amount_kobo"]) != order.breakdown.total_kobo:
                logger.error(
                    "paid amount differs from order total", extra={"extra_fields": {"order_id": order_id}}
                )
                return
            order = await self.transition(
                order_id,
                S.PAID,
                actor_type=A.SYSTEM,
                actor_id="payments",
                patch=payment_patch,
                metadata={"reference": payload.get("reference")},
            )
            await self.repos.store.set(
                self.repos.codes_path(order_id),
                {
                    "order_id": order_id,
                    "customer_id": order.customer_id,
                    "delivery_code": new_code(),
                    "pickup_code": new_code(),
                    "attempts": 0,
                    "locked": False,
                },
            )
            await self._record_voucher_use(order)
        if order.status == S.PAID:
            await self.transition(
                order_id, S.SUBMITTED_TO_RESTAURANT, actor_type=A.SYSTEM, actor_id="payments"
            )
            await self.notifier.notify_restaurant(
                order.restaurant_id,
                "New order",
                f"Order {order.short_code} · {format_naira(order.breakdown.subtotal_kobo)}",
                {"order_id": order_id},
            )
            await self.tasks.enqueue(
                TASK_RESTAURANT_TIMEOUT, {"order_id": order_id}, delay_seconds=self.accept_timeout
            )

    async def _record_voucher_use(self, order: Order) -> None:
        code = order.breakdown.voucher_code
        if not code:
            return

        async def fn(tx: Transaction) -> None:
            vdoc = await tx.get(f"vouchers/{code}")
            rdoc = await tx.get(f"vouchers/{code}/redemptions/{order.customer_id}")
            if vdoc is not None:
                tx.update(f"vouchers/{code}", {"used_count": int(vdoc.get("used_count", 0)) + 1})
            tx.set(
                f"vouchers/{code}/redemptions/{order.customer_id}",
                {"count": int((rdoc or {}).get("count", 0)) + 1, "last_order_id": order.id},
            )

        await self.repos.store.run_transaction(fn)

    async def on_refund_succeeded(self, payload: dict[str, Any]) -> None:
        order = await self.get(str(payload["order_id"]))
        if order.status != S.REFUND_PENDING:
            return
        full = bool(payload.get("fully_refunded"))
        total_refunded = int(payload.get("total_refunded_kobo", order.refund_total_kobo))
        await self.transition(
            order.id,
            S.REFUNDED if full else S.PARTIALLY_REFUNDED,
            actor_type=A.SYSTEM,
            actor_id="payments",
            patch={
                "refund_total_kobo": total_refunded,
                "payment.status": "refunded" if full else "partially_refunded",
            },
            metadata={"refund_id": payload.get("refund_id")},
        )

    async def on_refund_rejected(self, payload: dict[str, Any]) -> None:
        order = await self.get(str(payload["order_id"]))
        if order.status == S.REFUND_PENDING and order.completed_at:
            await self.transition(
                order.id,
                S.COMPLETED,
                actor_type=A.STAFF,
                actor_id=str(payload.get("decided_by")),
                reason=str(payload.get("note") or "Refund rejected"),
            )

    async def expire_unpaid(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.status not in (S.DRAFT, S.PENDING_PAYMENT):
            return
        if order.payment.reference:
            await self.payments.verify_reference(order.payment.reference, source="reconcile")
            order = await self.get(order.id)
            if order.status not in (S.DRAFT, S.PENDING_PAYMENT):
                return
        await self.transition(
            order.id,
            S.CANCELLED,
            actor_type=A.SYSTEM,
            actor_id="scheduler",
            reason="Payment not completed in time",
            patch={"cancelled_at": utcnow(), "cancellation_reason": "payment_timeout"},
        )

    # ============================================================================ restaurant flows
    def _restaurant_actor(self, principal: Principal, order: Order) -> tuple[ActorType, str]:
        if principal.can_on_restaurant(order.restaurant_id, "orders"):
            return A.RESTAURANT, principal.uid
        if principal.can(Permission.ORDERS_INTERVENE):
            return A.STAFF, principal.uid
        raise PermissionDenied("You do not have access to this restaurant's orders")

    async def accept(self, principal: Principal, order_id: str, prep_minutes: int) -> Order:
        if not 1 <= prep_minutes <= 180:
            raise ValidationFailed("Preparation time must be between 1 and 180 minutes")
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        now = utcnow()
        return await self.transition(
            order_id,
            S.RESTAURANT_ACCEPTED,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Accepted on behalf of restaurant",
            patch={"accepted_at": now, "prep_minutes": prep_minutes},
            metadata={"prep_minutes": prep_minutes},
        )

    async def reject(self, principal: Principal, order_id: str, reason: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        return await self.transition(
            order_id,
            S.REFUND_PENDING,
            actor_type=actor,
            actor_id=actor_id,
            reason=reason,
            patch={"cancelled_at": utcnow(), "cancellation_reason": reason},
            metadata=refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
            check=lambda o: _expect(o, {S.SUBMITTED_TO_RESTAURANT, S.RESTAURANT_ACCEPTED, S.PREPARING}),
        )

    async def mark_preparing(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        return await self.transition(
            order_id,
            S.PREPARING,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Updated by staff",
        )

    async def mark_ready(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        now = utcnow()
        if order.status == S.RIDER_ASSIGNED:
            # Rider already assigned: record readiness without changing the lifecycle status.
            await self.repos.orders.update(order_id, {"ready_at": now, "updated_at": now})
            if order.rider_id:
                await self.notifier.notify_user(
                    order.rider_id,
                    "Order ready",
                    f"Order {order.short_code} is ready",
                    {"order_id": order_id},
                )
            return order.model_copy(update={"ready_at": now})
        return await self.transition(
            order_id,
            S.READY_FOR_PICKUP,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Updated by staff",
            patch={"ready_at": now},
        )

    async def complete_pickup(self, principal: Principal, order_id: str, code: str) -> Order:
        order = await self.get(order_id)
        actor, actor_id = self._restaurant_actor(principal, order)
        if order.fulfillment != Fulfillment.PICKUP:
            raise InvalidTransition("Only pickup orders are handed over at the counter")
        await self.verify_code(order_id, "pickup_code", code)
        now = utcnow()
        return await self.transition(
            order_id,
            S.COMPLETED,
            actor_type=actor,
            actor_id=actor_id,
            reason=None if actor == A.RESTAURANT else "Handover by staff",
            patch={"completed_at": now, "picked_up_at": now},
        )

    async def restaurant_timeout(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.status != S.SUBMITTED_TO_RESTAURANT:
            return
        await self.transition(
            order.id,
            S.REFUND_PENDING,
            actor_type=A.SYSTEM,
            actor_id="scheduler",
            reason="Restaurant did not respond in time",
            patch={"cancelled_at": utcnow(), "cancellation_reason": "restaurant_timeout"},
            metadata=refund_meta(order.breakdown.total_kobo, "platform", "before_completion", auto=True),
        )

    # ============================================================================ rider flows
    async def _rider_order(self, principal: Principal, order_id: str) -> Order:
        order = await self.get(order_id)
        if order.rider_id != principal.uid:
            raise NotFound("Order not found")
        return order

    async def rider_pickup(self, principal: Principal, order_id: str) -> Order:
        await self._rider_order(principal, order_id)
        return await self.transition(
            order_id,
            S.PICKED_UP,
            actor_type=A.RIDER,
            actor_id=principal.uid,
            patch={"picked_up_at": utcnow()},
            check=lambda o: _rider_check(o, principal.uid),
        )

    async def rider_in_transit(self, principal: Principal, order_id: str) -> Order:
        await self._rider_order(principal, order_id)
        return await self.transition(
            order_id,
            S.IN_TRANSIT,
            actor_type=A.RIDER,
            actor_id=principal.uid,
            check=lambda o: _rider_check(o, principal.uid),
        )

    async def rider_deliver(self, principal: Principal, order_id: str, code: str) -> Order:
        await self._rider_order(principal, order_id)
        await self.verify_code(order_id, "delivery_code", code)
        order = await self.transition(
            order_id,
            S.DELIVERED,
            actor_type=A.RIDER,
            actor_id=principal.uid,
            patch={"delivered_at": utcnow()},
            check=lambda o: _rider_check(o, principal.uid),
        )
        return order

    async def verify_code(
        self, order_id: str, field: Literal["delivery_code", "pickup_code"], code: str
    ) -> None:
        path = self.repos.codes_path(order_id)
        max_attempts = self.code_max_attempts

        async def fn(tx: Transaction) -> str:
            doc = await tx.get(path)
            if doc is None:
                return "missing"
            if doc.get("locked"):
                return "locked"
            if hmac.compare_digest(str(doc.get(field, "")), (code or "").strip()):
                tx.update(path, {"attempts": 0})
                return "ok"
            attempts = int(doc.get("attempts", 0)) + 1
            tx.update(path, {"attempts": attempts, "locked": attempts >= max_attempts})
            return "wrong"

        outcome = await self.repos.store.run_transaction(fn)
        if outcome == "ok":
            return
        if outcome == "locked":
            raise PermissionDenied("Too many incorrect codes. Please contact support.")
        if outcome == "missing":
            raise InvalidTransition("This order has no confirmation code")
        raise ValidationFailed("Incorrect code")

    async def complete_after_delivery(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or order.status != S.DELIVERED:
            return
        await self.transition(
            order.id, S.COMPLETED, actor_type=A.SYSTEM, actor_id="system", patch={"completed_at": utcnow()}
        )

    # ============================================================================ staff flows
    async def intervene(
        self,
        principal: Principal,
        order_id: str,
        to: OrderStatus,
        reason: str,
        refund_amount_kobo: int | None = None,
        liability: Literal["restaurant", "platform"] = "platform",
    ) -> Order:
        require(principal, Permission.ORDERS_INTERVENE)
        order = await self.get(order_id)
        metadata: dict[str, Any] = {"intervention": True}
        patch: dict[str, Any] = {}
        if to == S.REFUND_PENDING:
            amount = refund_amount_kobo or order.breakdown.total_kobo - order.refund_total_kobo
            if amount <= 0 or amount > order.breakdown.total_kobo - order.refund_total_kobo:
                raise ValidationFailed("Refund amount exceeds the refundable balance")
            stage = "after_completion" if order.completed_at else "before_completion"
            if stage == "before_completion":
                amount = order.breakdown.total_kobo  # pre-completion refunds are always full
            metadata.update(refund_meta(amount, liability, stage, auto=False))
        if to == S.CANCELLED:
            patch = {"cancelled_at": utcnow(), "cancellation_reason": reason}
        if to == S.COMPLETED and order.status == S.DISPUTED:
            patch = {"completed_at": order.completed_at or utcnow()}
        return await self.transition(
            order_id,
            to,
            actor_type=A.STAFF,
            actor_id=principal.uid,
            reason=reason,
            patch=patch,
            metadata=metadata,
        )

    async def unsettled_completed(self, older_than: timedelta = timedelta(minutes=5)) -> list[Order]:
        cutoff = utcnow() - older_than
        orders = await self.repos.orders.find(
            where=[("status", "in", [S.COMPLETED.value, S.PARTIALLY_REFUNDED.value])], limit=500
        )
        return [o for o in orders if o.settled_at is None and o.completed_at and o.completed_at < cutoff]


def refund_meta(amount_kobo: int, liability: str, stage: str, *, auto: bool) -> dict[str, Any]:
    return {
        "refund_amount_kobo": amount_kobo,
        "refund_liability": liability,
        "refund_stage": stage,
        "refund_auto_approve": auto,
    }


def _expect(order: Order, allowed: set[OrderStatus]) -> None:
    if order.status not in allowed:
        raise InvalidTransition(f"Order is {order.status.value}")


def _rider_check(order: Order, uid: str) -> None:
    if order.rider_id != uid:
        raise PermissionDenied("This delivery is assigned to another rider")


__all__ = ["ACTIVE_FULFILMENT", "OrderService", "refund_meta"]
