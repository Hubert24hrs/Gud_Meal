"""Payment orchestration: initiation, server-side verification, webhooks, refunds, settlement postings."""

from __future__ import annotations

import logging
import secrets
from collections.abc import Mapping
from datetime import UTC, datetime, timedelta
from typing import Any, Literal

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from ..domain.models import Order
from ..errors import NotFound, PaymentProviderError, Unauthenticated, ValidationFailed
from ..ledger import ledger as postings
from ..ledger.audit import AuditLog
from ..ledger.db import Database
from ..ledger.ledger import LedgerService
from ..ledger.outbox import OutboxRelay, add_outbox_event
from ..ledger.tables import CommissionRecord, PaymentEvent, PaymentRecord, RefundRecord, new_id
from ..logging_setup import log_event
from ..payments.base import PaymentProvider
from ..repositories import Repositories
from ..security.rbac import Permission, Principal, require

logger = logging.getLogger(__name__)
REUSE_WINDOW = timedelta(minutes=25)


def utcnow() -> datetime:
    return datetime.now(UTC)


def payment_view(rec: PaymentRecord) -> dict[str, Any]:
    return {
        "id": rec.id,
        "order_id": rec.order_id,
        "provider": rec.provider,
        "reference": rec.reference,
        "amount_kobo": rec.amount_kobo,
        "currency": rec.currency,
        "status": rec.status,
        "authorization_url": rec.authorization_url,
        "channel": rec.channel,
        "paid_at": rec.paid_at,
        "refunded_kobo": rec.refunded_kobo,
        "created_at": rec.created_at,
        "failure_reason": rec.failure_reason,
    }


def refund_view(rec: RefundRecord) -> dict[str, Any]:
    return {
        "id": rec.id,
        "order_id": rec.order_id,
        "payment_id": rec.payment_id,
        "amount_kobo": rec.amount_kobo,
        "reason": rec.reason,
        "liability": rec.liability,
        "stage": rec.stage,
        "status": rec.status,
        "requested_by": rec.requested_by,
        "decided_by": rec.decided_by,
        "decision_note": rec.decision_note,
        "created_at": rec.created_at,
        "decided_at": rec.decided_at,
        "completed_at": rec.completed_at,
    }


class PaymentService:
    def __init__(
        self,
        *,
        db: Database,
        ledger: LedgerService,
        audit: AuditLog,
        relay: OutboxRelay,
        repos: Repositories,
        providers: Mapping[str, PaymentProvider],
        default_provider: str,
        callback_url: str,
        email_fallback_domain: str,
        refund_auto_approve_limit_kobo: int = 0,
    ) -> None:
        self.db = db
        self.ledger = ledger
        self.audit = audit
        self.relay = relay
        self.repos = repos
        self.providers = dict(providers)
        self.default_provider = default_provider
        self.callback_url = callback_url
        self.email_fallback_domain = email_fallback_domain
        self.refund_auto_approve_limit = refund_auto_approve_limit_kobo

    def provider(self, name: str | None) -> PaymentProvider:
        key = name or self.default_provider
        provider = self.providers.get(key)
        if provider is None:
            raise ValidationFailed(
                f"Payment provider '{key}' is not configured",
                details={"available": sorted(self.providers)},
            )
        return provider

    # ============================================================================ initiation
    async def initiate(
        self, order: Order, principal: Principal, provider_name: str | None, idempotency_key: str
    ) -> dict[str, Any]:
        provider = self.provider(provider_name)
        now = utcnow()
        async with self.db.transaction() as s:
            existing = await s.scalar(
                select(PaymentRecord)
                .where(
                    PaymentRecord.order_id == order.id, PaymentRecord.status.in_(("initialized", "pending"))
                )
                .order_by(PaymentRecord.created_at.desc())
                .limit(1)
            )
            if existing is not None and existing.status == "succeeded":
                raise ValidationFailed("This order is already paid")
            if (
                existing is not None
                and existing.provider == provider.name
                and existing.authorization_url
                and existing.amount_kobo == order.breakdown.total_kobo
                and now - _aware(existing.created_at) < REUSE_WINDOW
            ):
                return self._init_view(existing)
            paid = await s.scalar(
                select(func.count())
                .select_from(PaymentRecord)
                .where(PaymentRecord.order_id == order.id, PaymentRecord.status == "succeeded")
            )
            if paid:
                raise ValidationFailed("This order is already paid")
            rec = PaymentRecord(
                id=new_id(),
                order_id=order.id,
                customer_id=order.customer_id,
                provider=provider.name,
                reference=f"GM-{order.short_code}-{secrets.token_hex(4).upper()}",
                amount_kobo=order.breakdown.total_kobo,
                currency="NGN",
                status="initialized",
                idempotency_key=f"{order.id}:{idempotency_key}",
                created_at=now,
                updated_at=now,
            )
            s.add(rec)

        email = principal.email or f"{principal.uid}@{self.email_fallback_domain}"
        try:
            init = await provider.initialize(
                reference=rec.reference,
                amount_kobo=rec.amount_kobo,
                email=email,
                currency="NGN",
                callback_url=f"{self.callback_url}?order_id={order.id}",
                metadata={
                    "order_id": order.id,
                    "short_code": order.short_code,
                    "customer_id": order.customer_id,
                },
                customer_name=principal.name,
                customer_phone=principal.phone,
            )
        except PaymentProviderError as exc:
            async with self.db.transaction() as s:
                row = await s.get(PaymentRecord, rec.id)
                if row is not None:
                    row.status = "failed"
                    row.failure_reason = exc.message[:500]
                    row.updated_at = utcnow()
            raise
        async with self.db.transaction() as s:
            row = await s.get(PaymentRecord, rec.id)
            assert row is not None
            row.status = "pending"
            row.authorization_url = init.authorization_url
            row.access_code = init.access_code
            row.updated_at = utcnow()
            return self._init_view(row)

    @staticmethod
    def _init_view(rec: PaymentRecord) -> dict[str, Any]:
        return {
            "provider": rec.provider,
            "reference": rec.reference,
            "authorization_url": rec.authorization_url,
            "access_code": rec.access_code,
            "amount_kobo": rec.amount_kobo,
            "currency": rec.currency,
        }

    # ============================================================================ verification
    async def get_payment(self, reference: str) -> PaymentRecord:
        async with self.db.session() as s:
            rec = await s.scalar(select(PaymentRecord).where(PaymentRecord.reference == reference))
        if rec is None:
            raise NotFound("Payment not found")
        return rec

    async def verify_for_customer(self, principal: Principal, reference: str) -> dict[str, Any]:
        rec = await self.get_payment(reference)
        if rec.customer_id != principal.uid and not principal.can(Permission.PAYMENTS_READ):
            raise NotFound("Payment not found")
        return await self.verify_reference(reference, source="client")

    async def verify_reference(
        self, reference: str, *, source: Literal["webhook", "client", "reconcile"]
    ) -> dict[str, Any]:
        rec = await self.get_payment(reference)
        if rec.status == "succeeded":
            return payment_view(rec)
        provider = self.provider(rec.provider)
        result = await provider.verify(reference)
        now = utcnow()
        async with self.db.transaction() as s:
            row = await s.scalar(
                select(PaymentRecord).where(PaymentRecord.reference == reference).with_for_update()
            )
            assert row is not None
            if row.status == "succeeded":
                return payment_view(row)
            s.add(
                PaymentEvent(
                    payment_id=row.id,
                    provider=row.provider,
                    dedupe_key=f"verify:{new_id()}",
                    event_type=f"verify.{result.status}",
                    source=source,
                    payload=result.raw,
                )
            )
            if result.status == "success":
                problems = []
                if result.reference and result.reference != row.reference:
                    problems.append("reference_mismatch")
                if result.amount_kobo != row.amount_kobo:
                    problems.append("amount_mismatch")
                if result.currency != row.currency:
                    problems.append("currency_mismatch")
                if problems:
                    row.status = "flagged"
                    row.failure_reason = ",".join(problems)
                    row.updated_at = now
                    AuditLog.add(
                        s,
                        actor_id="system",
                        actor_roles=["system"],
                        action="payment.flagged",
                        resource_type="payment",
                        resource_id=row.id,
                        details={"problems": problems, "reported_amount_kobo": result.amount_kobo},
                    )
                    log_event(
                        logger, "payment flagged", logging.ERROR, reference=reference, problems=problems
                    )
                else:
                    row.status = "succeeded"
                    row.paid_at = result.paid_at or now
                    row.provider_transaction_id = result.provider_transaction_id
                    row.channel = result.channel
                    row.updated_at = now
                    await self.ledger.post(
                        s,
                        kind="payment_captured",
                        idempotency_key=f"payment:{row.id}:captured",
                        postings=postings.payment_captured(row.provider, row.amount_kobo),
                        created_by=f"payments:{source}",
                        reference=row.reference,
                        order_id=row.order_id,
                        description=f"Payment {row.reference} captured",
                    )
                    add_outbox_event(
                        s,
                        "payment.succeeded",
                        {
                            "order_id": row.order_id,
                            "payment_id": row.id,
                            "provider": row.provider,
                            "reference": row.reference,
                            "amount_kobo": row.amount_kobo,
                            "paid_at": (row.paid_at or now).isoformat(),
                        },
                    )
            elif result.status in ("failed", "abandoned", "reversed"):
                row.status = "abandoned" if result.status == "abandoned" else "failed"
                row.failure_reason = (result.gateway_message or result.status)[:500]
                row.updated_at = now
            view = payment_view(row)
        await self.relay.relay_pending()
        return view

    async def handle_webhook(
        self, provider_name: str, raw_body: bytes, headers: Mapping[str, str], client_ip: str | None
    ) -> dict[str, str]:
        provider = self.providers.get(provider_name)
        if provider is None:
            raise NotFound("Unknown payment provider")
        if not provider.verify_webhook(raw_body, headers, client_ip):
            log_event(
                logger, "webhook signature rejected", logging.WARNING, provider=provider_name, ip=client_ip
            )
            raise Unauthenticated("Invalid webhook signature")
        event = provider.parse_webhook(raw_body)
        async with self.db.session() as s:
            seen = await s.scalar(
                select(PaymentEvent.id).where(
                    PaymentEvent.provider == provider.name, PaymentEvent.dedupe_key == event.dedupe_key
                )
            )
        if seen:
            return {"status": "duplicate"}

        if event.event_type in ("charge.success", "charge.failed") and event.reference:
            try:
                await self.verify_reference(event.reference, source="webhook")
            except NotFound:
                log_event(logger, "webhook for unknown reference", logging.WARNING, reference=event.reference)
        elif event.event_type in ("refund.processed", "refund.failed"):
            await self._apply_refund_webhook(event.event_type, event.data)

        try:
            async with self.db.transaction() as s:
                s.add(
                    PaymentEvent(
                        provider=provider.name,
                        dedupe_key=event.dedupe_key,
                        event_type=event.raw_event,
                        source="webhook",
                        payload=event.data,
                    )
                )
        except IntegrityError:
            return {"status": "duplicate"}
        return {"status": "processed"}

    async def reconcile_stale(
        self, older_than: timedelta = timedelta(minutes=10), limit: int = 100
    ) -> dict[str, int]:
        cutoff = utcnow() - older_than
        async with self.db.session() as s:
            refs = list(
                (
                    await s.execute(
                        select(PaymentRecord.reference)
                        .where(
                            PaymentRecord.status.in_(("initialized", "pending")),
                            PaymentRecord.created_at < cutoff,
                        )
                        .order_by(PaymentRecord.created_at)
                        .limit(limit)
                    )
                ).scalars()
            )
        checked = errors = 0
        for ref in refs:
            try:
                await self.verify_reference(ref, source="reconcile")
                checked += 1
            except Exception:
                errors += 1
                logger.exception("reconcile failed", extra={"extra_fields": {"reference": ref}})
        return {"checked": checked, "errors": errors}

    # ============================================================================ refunds
    async def create_refund(
        self,
        *,
        order_id: str,
        amount_kobo: int,
        reason: str,
        liability: Literal["restaurant", "platform"],
        stage: Literal["before_completion", "after_completion"],
        requested_by: str,
        idempotency_key: str,
        auto_approve: bool,
    ) -> dict[str, Any]:
        async with self.db.transaction() as s:
            existing = await s.scalar(
                select(RefundRecord).where(RefundRecord.idempotency_key == idempotency_key)
            )
            if existing is not None:
                return refund_view(existing)
            payment = await s.scalar(
                select(PaymentRecord)
                .where(PaymentRecord.order_id == order_id, PaymentRecord.status == "succeeded")
                .with_for_update()
            )
            if payment is None:
                raise ValidationFailed("Order has no captured payment to refund")
            open_total = await s.scalar(
                select(func.coalesce(func.sum(RefundRecord.amount_kobo), 0)).where(
                    RefundRecord.payment_id == payment.id,
                    RefundRecord.status.in_(("requested", "approved", "processing")),
                )
            )
            refundable = payment.amount_kobo - payment.refunded_kobo - int(open_total or 0)
            if amount_kobo <= 0 or amount_kobo > refundable:
                raise ValidationFailed(
                    "Refund exceeds the refundable amount", details={"refundable_kobo": refundable}
                )
            approved = auto_approve or (0 < amount_kobo <= self.refund_auto_approve_limit)
            refund = RefundRecord(
                id=new_id(),
                payment_id=payment.id,
                order_id=order_id,
                amount_kobo=amount_kobo,
                reason=reason[:1000],
                liability=liability,
                stage=stage,
                status="approved" if approved else "requested",
                requested_by=requested_by,
                decided_by="system" if approved else None,
                decided_at=utcnow() if approved else None,
                idempotency_key=idempotency_key,
            )
            s.add(refund)
            AuditLog.add(
                s,
                actor_id=requested_by,
                actor_roles=[],
                action="refund.requested",
                resource_type="order",
                resource_id=order_id,
                details={"amount_kobo": amount_kobo, "auto_approved": approved},
            )
        if approved:
            return await self.process_refund(refund.id)
        return refund_view(refund)

    async def decide_refund(
        self, principal: Principal, refund_id: str, *, approve: bool, note: str | None
    ) -> dict[str, Any]:
        require(principal, Permission.REFUNDS_APPROVE)
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id, with_for_update=True)
            if rec is None:
                raise NotFound("Refund not found")
            if rec.status != "requested":
                raise ValidationFailed(f"Refund is already {rec.status}")
            rec.status = "approved" if approve else "rejected"
            rec.decided_by = principal.uid
            rec.decided_at = utcnow()
            rec.decision_note = (note or "")[:1000] or None
            AuditLog.add(
                s,
                actor_id=principal.uid,
                actor_roles=principal.audit_roles(),
                action="refund.approved" if approve else "refund.rejected",
                resource_type="refund",
                resource_id=rec.id,
                details={"order_id": rec.order_id, "amount_kobo": rec.amount_kobo},
            )
            if not approve:
                add_outbox_event(
                    s,
                    "refund.rejected",
                    {
                        "order_id": rec.order_id,
                        "refund_id": rec.id,
                        "decided_by": principal.uid,
                        "note": rec.decision_note,
                    },
                )
            view = refund_view(rec)
        if approve:
            return await self.process_refund(refund_id)
        await self.relay.relay_pending()
        return view

    async def process_refund(self, refund_id: str) -> dict[str, Any]:
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id, with_for_update=True)
            if rec is None:
                raise NotFound("Refund not found")
            if rec.status != "approved":
                return refund_view(rec)
            payment = await s.get(PaymentRecord, rec.payment_id)
            assert payment is not None
            rec.status = "processing"
            ref, txid, provider_name, amount = (
                payment.reference,
                payment.provider_transaction_id,
                payment.provider,
                rec.amount_kobo,
            )
        try:
            result = await self.provider(provider_name).refund(
                reference=ref, provider_transaction_id=txid, amount_kobo=amount
            )
        except PaymentProviderError as exc:
            async with self.db.transaction() as s:
                rec = await s.get(RefundRecord, refund_id)
                assert rec is not None
                rec.status = "failed"
                rec.decision_note = f"provider error: {exc.message}"[:1000]
                return refund_view(rec)
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id)
            assert rec is not None
            rec.provider_refund_id = result.provider_refund_id
        if result.status == "processed":
            return await self.complete_refund(refund_id)
        if result.status == "failed":
            async with self.db.transaction() as s:
                rec = await s.get(RefundRecord, refund_id)
                assert rec is not None
                rec.status = "failed"
                return refund_view(rec)
        async with self.db.session() as s:
            rec = await s.get(RefundRecord, refund_id)
            assert rec is not None
            return refund_view(rec)  # processing: completed by the refund.processed webhook

    async def complete_refund(self, refund_id: str) -> dict[str, Any]:
        async with self.db.transaction() as s:
            rec = await s.get(RefundRecord, refund_id, with_for_update=True)
            if rec is None:
                raise NotFound("Refund not found")
            if rec.status == "succeeded":
                return refund_view(rec)
            payment = await s.get(PaymentRecord, rec.payment_id, with_for_update=True)
            assert payment is not None
            order = await self.repos.orders.get(rec.order_id)
            rec.status = "succeeded"
            rec.completed_at = utcnow()
            payment.refunded_kobo += rec.amount_kobo
            payment.updated_at = utcnow()
            await self.ledger.post(
                s,
                kind="refund",
                idempotency_key=f"refund:{rec.id}",
                postings=postings.refund_issued(
                    provider=payment.provider,
                    amount_kobo=rec.amount_kobo,
                    stage=rec.stage,  # type: ignore[arg-type]
                    liability=rec.liability,
                    restaurant_id=order.restaurant_id if order else "unknown",  # type: ignore[arg-type]
                ),
                created_by="payments",
                reference=payment.reference,
                order_id=rec.order_id,
                description=f"Refund {rec.id}",
            )
            add_outbox_event(
                s,
                "refund.succeeded",
                {
                    "order_id": rec.order_id,
                    "refund_id": rec.id,
                    "amount_kobo": rec.amount_kobo,
                    "total_refunded_kobo": payment.refunded_kobo,
                    "fully_refunded": payment.refunded_kobo >= payment.amount_kobo,
                },
            )
            view = refund_view(rec)
        await self.relay.relay_pending()
        return view

    async def _apply_refund_webhook(self, event_type: str, data: dict[str, Any]) -> None:
        provider_refund_id = str(data.get("id")) if data.get("id") is not None else None
        if not provider_refund_id:
            return
        async with self.db.session() as s:
            rec = await s.scalar(
                select(RefundRecord).where(RefundRecord.provider_refund_id == provider_refund_id)
            )
        if rec is None:
            return
        if event_type == "refund.processed":
            await self.complete_refund(rec.id)
        else:
            async with self.db.transaction() as s:
                row = await s.get(RefundRecord, rec.id)
                if row is not None and row.status == "processing":
                    row.status = "failed"

    async def list_refunds(
        self, principal: Principal, status: str | None = None, limit: int = 100
    ) -> list[dict[str, Any]]:
        require(principal, Permission.REFUNDS_REQUEST)
        stmt = select(RefundRecord).order_by(RefundRecord.created_at.desc()).limit(min(limit, 500))
        if status:
            stmt = stmt.where(RefundRecord.status == status)
        async with self.db.session() as s:
            return [refund_view(r) for r in (await s.execute(stmt)).scalars()]

    async def list_payments(
        self, principal: Principal, status: str | None = None, limit: int = 100
    ) -> list[dict[str, Any]]:
        require(principal, Permission.PAYMENTS_READ)
        stmt = select(PaymentRecord).order_by(PaymentRecord.created_at.desc()).limit(min(limit, 500))
        if status:
            stmt = stmt.where(PaymentRecord.status == status)
        async with self.db.session() as s:
            return [payment_view(r) for r in (await s.execute(stmt)).scalars()]

    async def payments_for_order(self, order_id: str) -> list[dict[str, Any]]:
        async with self.db.session() as s:
            rows = (
                await s.execute(
                    select(PaymentRecord)
                    .where(PaymentRecord.order_id == order_id)
                    .order_by(PaymentRecord.created_at)
                )
            ).scalars()
            return [payment_view(r) for r in rows]

    # ============================================================================ settlement
    async def settle_completed_order(self, order: Order) -> bool:
        async with self.db.transaction() as s:
            _, created = await self.ledger.post(
                s,
                kind="order_settlement",
                idempotency_key=f"order:{order.id}:settlement",
                postings=postings.order_completed(order),
                created_by="system",
                reference=order.short_code,
                order_id=order.id,
                description=f"Order {order.short_code} completed",
                metadata={"restaurant_id": order.restaurant_id, "rider_id": order.rider_id},
            )
            if created:
                s.add(
                    CommissionRecord(
                        order_id=order.id,
                        restaurant_id=order.restaurant_id,
                        base_kobo=order.breakdown.subtotal_kobo,
                        commission_bps=order.settlement.commission_bps,
                        commission_kobo=order.settlement.commission_kobo,
                    )
                )
        await self.repos.orders.update(order.id, {"settled_at": utcnow()})
        return created


def _aware(dt: datetime) -> datetime:
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)
