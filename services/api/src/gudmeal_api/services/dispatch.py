"""Rider dispatch: offers with timeouts, acceptance, decline, manual assignment, rider availability & location."""

from __future__ import annotations

import logging
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

from ..domain.dispatch import DispatchConfig, rank_riders
from ..domain.geo import GeoPoint, geohash_encode, haversine_km
from ..domain.models import (
    AssignmentStatus,
    DeliveryAssignment,
    Fulfillment,
    Order,
    RiderProfile,
    RiderStatus,
)
from ..domain.order_state import ActorType, OrderStatus
from ..errors import InvalidTransition, NotFound, PermissionDenied, ValidationFailed
from ..logging_setup import log_event
from ..repositories import Repositories, Transaction, to_doc
from ..security.rbac import Permission, Principal, require, require_rider
from .infra import Emitter, Notifier, TaskQueue
from .orders import OrderService

logger = logging.getLogger(__name__)
S = OrderStatus
TASK_OFFER_TIMEOUT = "/internal/tasks/dispatch-offer-timeout"
TASK_DISPATCH_RETRY = "/internal/tasks/dispatch-retry"
DISPATCHABLE = {S.RESTAURANT_ACCEPTED, S.PREPARING, S.READY_FOR_PICKUP}
MAX_ATTEMPTS = 8


def utcnow() -> datetime:
    return datetime.now(UTC)


class DispatchService:
    def __init__(
        self,
        repos: Repositories,
        orders: OrderService,
        *,
        tasks: TaskQueue,
        notifier: Notifier,
        emitter: Emitter,
        offer_timeout_seconds: int = 45,
        config: DispatchConfig | None = None,
        rider_cash_limit_kobo: int = 5_000_000,
    ) -> None:
        self.repos = repos
        self.orders = orders
        self.tasks = tasks
        self.notifier = notifier
        self.emitter = emitter
        self.offer_timeout = offer_timeout_seconds
        self.cfg = config or DispatchConfig()
        self.cash_limit = rider_cash_limit_kobo

    # ============================================================================ rider self-service
    async def rider_profile(self, principal: Principal) -> RiderProfile:
        require_rider(principal)
        profile = await self.repos.riders.get(principal.uid)
        if profile is None:
            raise NotFound("Rider profile not found")
        return profile

    async def set_availability(self, principal: Principal, online: bool) -> RiderProfile:
        profile = await self.rider_profile(principal)
        if online and profile.status != RiderStatus.ACTIVE:
            raise PermissionDenied("Your rider account is not active yet")
        await self.repos.riders.update(principal.uid, {"is_online": online})
        return profile.model_copy(update={"is_online": online})

    async def update_location(
        self, principal: Principal, point: GeoPoint, accuracy_m: float | None = None
    ) -> None:
        profile = await self.rider_profile(principal)
        now = utcnow()
        await self.repos.riders.update(
            principal.uid,
            {
                "last_location": to_doc(point),
                "last_location_at": now,
                "geohash": geohash_encode(point.lat, point.lng, 7),
            },
        )
        for order_id in profile.active_order_ids[:3]:
            order = await self.repos.orders.get(order_id)
            if (
                order
                and order.status in (S.RIDER_ASSIGNED, S.PICKED_UP, S.IN_TRANSIT)
                and order.rider_id == principal.uid
            ):
                eta = None
                if order.delivery_address and order.status != S.RIDER_ASSIGNED:
                    km = haversine_km(point, order.delivery_address.location) * 1.35
                    eta = max(1, round(km / 18 * 60))
                await self.repos.set_tracking(
                    order_id,
                    {
                        "rider_location": to_doc(point),
                        "updated_at": now,
                        "status": order.status.value,
                        "eta_minutes": eta,
                        "accuracy_m": accuracy_m,
                        "customer_id": order.customer_id,
                    },
                )

    async def pending_offers(self, principal: Principal) -> list[DeliveryAssignment]:
        require_rider(principal)
        offers = await self.repos.assignments.find(
            where=[("rider_id", "==", principal.uid), ("status", "==", AssignmentStatus.OFFERED.value)],
            limit=5,
        )
        now = utcnow()
        return [o for o in offers if o.expires_at > now]

    # ============================================================================ dispatch engine
    async def start(self, order_id: str, *, exclude: set[str] | None = None) -> DeliveryAssignment | None:
        order = await self.repos.orders.get(order_id)
        if order is None or order.fulfillment != Fulfillment.DELIVERY or order.status not in DISPATCHABLE:
            return None
        if order.rider_id:
            return None
        open_offers = await self.repos.assignments.find(
            where=[("order_id", "==", order_id), ("status", "==", AssignmentStatus.OFFERED.value)]
        )
        now = utcnow()
        if any(o.expires_at > now for o in open_offers):
            return None  # an offer is already outstanding
        previous = await self.repos.assignments.find(where=[("order_id", "==", order_id)])
        excluded = (exclude or set()) | {a.rider_id for a in previous}
        riders = await self.repos.riders.find(
            where=[("is_online", "==", True), ("status", "==", RiderStatus.ACTIVE.value)], limit=500
        )
        cash_due = order.cash_to_collect_kobo
        if cash_due:  # don't send riders out with more cash than they may carry
            riders = [r for r in riders if r.cash_held_kobo + cash_due <= self.cash_limit]
        ranked = rank_riders(
            riders,
            restaurant_location=order.restaurant_location,
            delivery_distance_km=order.distance_km or 0.0,
            now=now,
            cfg=self.cfg,
            exclude=excluded,
        )
        attempt = len(previous) + 1
        if not ranked:
            await self.repos.orders.update(order_id, {"dispatch_attempts": order.dispatch_attempts + 1})
            if order.dispatch_attempts + 1 >= MAX_ATTEMPTS:
                await self.emitter.emit(
                    "dispatch.unassigned", {"order_id": order_id, "attempts": attempts_label(order)}
                )
                log_event(logger, "dispatch exhausted", logging.WARNING, order_id=order_id)
            else:
                await self.tasks.enqueue(TASK_DISPATCH_RETRY, {"order_id": order_id}, delay_seconds=60)
            return None
        best = ranked[0]
        assignment = DeliveryAssignment(
            id=uuid.uuid4().hex,
            order_id=order_id,
            rider_id=best.rider_id,
            status=AssignmentStatus.OFFERED,
            attempt=attempt,
            score=best.score,
            distance_to_restaurant_km=best.distance_to_restaurant_km,
            restaurant_name=order.restaurant_name,
            pickup=order.restaurant_location,
            dropoff=order.delivery_address.location if order.delivery_address else None,
            dropoff_area=order.delivery_address.area if order.delivery_address else None,
            payout_kobo=order.settlement.rider_pay_kobo,
            offered_at=now,
            expires_at=now + timedelta(seconds=self.offer_timeout),
        )
        await self.repos.assignments.create(assignment)
        rider = next(r for r in riders if r.uid == best.rider_id)
        await self.repos.riders.update(rider.uid, {"offers_received": rider.offers_received + 1})
        await self.tasks.enqueue(
            TASK_OFFER_TIMEOUT, {"assignment_id": assignment.id}, delay_seconds=self.offer_timeout
        )
        await self.notifier.notify_user(
            best.rider_id,
            "New delivery offer",
            f"Pickup at {order.restaurant_name} · {best.distance_to_restaurant_km} km away",
            {"assignment_id": assignment.id, "order_id": order_id},
        )
        return assignment

    async def accept_offer(self, principal: Principal, assignment_id: str) -> Order:
        require_rider(principal)
        now = utcnow()
        captured: dict[str, Any] = {}

        async def fn(tx: Transaction) -> Order:
            adoc = await tx.get(f"delivery_assignments/{assignment_id}")
            if adoc is None:
                raise NotFound("Offer not found")
            assignment = DeliveryAssignment.model_validate(adoc)
            if assignment.rider_id != principal.uid:
                raise NotFound("Offer not found")
            odoc = await tx.get(f"orders/{assignment.order_id}")
            rdoc = await tx.get(f"rider_profiles/{principal.uid}")
            if odoc is None or rdoc is None:
                raise NotFound("Order not found")
            order = Order.model_validate(odoc)
            rider = RiderProfile.model_validate(rdoc)
            if assignment.status != AssignmentStatus.OFFERED or assignment.expires_at <= now:
                raise InvalidTransition("This offer is no longer available")
            if order.rider_id:
                raise InvalidTransition("This order already has a rider")
            if len(rider.active_order_ids) >= self.cfg.max_active_deliveries:
                raise InvalidTransition("You have reached the maximum number of active deliveries")
            updates, event = OrderService.build_transition(
                order,
                S.RIDER_ASSIGNED,
                actor_type=ActorType.SYSTEM,
                actor_id="dispatch",
                patch={"rider_id": rider.uid, "rider_name": rider.name, "assignment_id": assignment.id},
                metadata={"rider_id": rider.uid, "assignment_id": assignment.id},
                now=now,
            )
            OrderService.write_transition(tx, order.id, updates, event)
            tx.update(
                f"delivery_assignments/{assignment.id}",
                {"status": AssignmentStatus.ACCEPTED.value, "responded_at": now},
            )
            accepted = rider.offers_accepted + 1
            tx.update(
                f"rider_profiles/{rider.uid}",
                {
                    "active_order_ids": [*rider.active_order_ids, order.id],
                    "offers_accepted": accepted,
                    "acceptance_rate": round(accepted / max(1, rider.offers_received), 3),
                },
            )
            captured.update(previous=order.status, event=event)
            return Order.model_validate({**order.model_dump(), **updates})

        order = await self.repos.store.run_transaction(fn)
        await self.orders.after_transition(order, captured["previous"], captured["event"])
        await self.notifier.notify_restaurant(
            order.restaurant_id,
            "Rider assigned",
            f"{order.rider_name} is coming for order {order.short_code}",
            {"order_id": order.id},
        )
        return order

    async def decline_offer(self, principal: Principal, assignment_id: str, reason: str | None) -> None:
        require_rider(principal)
        assignment = await self.repos.assignments.get(assignment_id)
        if assignment is None or assignment.rider_id != principal.uid:
            raise NotFound("Offer not found")
        if not await self._close_offer(assignment_id, AssignmentStatus.DECLINED, reason):
            return
        rider = await self.repos.riders.get(principal.uid)
        if rider:
            await self.repos.riders.update(
                rider.uid,
                {"acceptance_rate": round(rider.offers_accepted / max(1, rider.offers_received), 3)},
            )
        await self.start(assignment.order_id)

    async def _close_offer(
        self, assignment_id: str, status: AssignmentStatus, reason: str | None = None
    ) -> bool:
        now = utcnow()

        async def fn(tx: Transaction) -> bool:
            doc = await tx.get(f"delivery_assignments/{assignment_id}")
            if doc is None or doc.get("status") != AssignmentStatus.OFFERED.value:
                return False
            tx.update(
                f"delivery_assignments/{assignment_id}",
                {"status": status.value, "responded_at": now, "decline_reason": reason},
            )
            return True

        return await self.repos.store.run_transaction(fn)

    async def handle_offer_timeout(self, payload: dict[str, Any]) -> None:
        assignment = await self.repos.assignments.get(str(payload["assignment_id"]))
        if assignment is None or assignment.status != AssignmentStatus.OFFERED:
            return
        if await self._close_offer(assignment.id, AssignmentStatus.EXPIRED):
            await self.start(assignment.order_id)

    async def retry(self, payload: dict[str, Any]) -> None:
        await self.start(str(payload["order_id"]))

    async def manual_assign(self, principal: Principal, order_id: str, rider_uid: str, reason: str) -> Order:
        require(principal, Permission.DISPATCH_MANUAL)
        rider = await self.repos.riders.get(rider_uid)
        if rider is None or rider.status != RiderStatus.ACTIVE:
            raise ValidationFailed("Rider is not active")
        order = await self.orders.get(order_id)
        if order.rider_id:
            raise InvalidTransition("Order already has a rider; unassign first")
        now = utcnow()
        assignment = DeliveryAssignment(
            id=uuid.uuid4().hex,
            order_id=order_id,
            rider_id=rider_uid,
            status=AssignmentStatus.ACCEPTED,
            attempt=0,
            score=0.0,
            distance_to_restaurant_km=round(haversine_km(rider.last_location, order.restaurant_location), 2)
            if rider.last_location
            else 0.0,
            restaurant_name=order.restaurant_name,
            pickup=order.restaurant_location,
            dropoff=order.delivery_address.location if order.delivery_address else None,
            payout_kobo=order.settlement.rider_pay_kobo,
            offered_at=now,
            expires_at=now,
            responded_at=now,
        )
        await self.repos.assignments.create(assignment)
        updated = await self.orders.transition(
            order_id,
            S.RIDER_ASSIGNED,
            actor_type=ActorType.STAFF,
            actor_id=principal.uid,
            reason=reason,
            patch={"rider_id": rider_uid, "rider_name": rider.name, "assignment_id": assignment.id},
            metadata={"manual": True, "rider_id": rider_uid},
        )
        await self.repos.riders.update(rider_uid, {"active_order_ids": [*rider.active_order_ids, order_id]})
        await self.notifier.notify_user(
            rider_uid, "Delivery assigned", f"Pickup at {order.restaurant_name}", {"order_id": order_id}
        )
        return updated

    async def unassign(self, principal: Principal, order_id: str, reason: str) -> Order:
        """Rider can't complete (or ops reassigns): restore kitchen state and re-dispatch."""
        order = await self.orders.get(order_id)
        if order.rider_id is None or order.status != S.RIDER_ASSIGNED:
            raise InvalidTransition("Order has no rider to unassign before pickup")
        is_assigned_rider = principal.uid == order.rider_id
        if not is_assigned_rider:
            require(principal, Permission.DISPATCH_MANUAL)
        rider_id = order.rider_id
        target = S.READY_FOR_PICKUP if order.ready_at else S.PREPARING
        actor = ActorType.SYSTEM if is_assigned_rider else ActorType.STAFF
        updated = await self.orders.transition(
            order_id,
            target,
            actor_type=actor,
            actor_id=principal.uid,
            reason=reason,
            patch={"rider_id": None, "rider_name": None, "assignment_id": None},
            metadata={"unassigned_rider": rider_id},
        )
        if order.assignment_id:
            await self.repos.assignments.update(
                order.assignment_id, {"status": AssignmentStatus.CANCELLED.value, "decline_reason": reason}
            )
        await self.release_rider(rider_id, order_id, completed=False)
        await self.start(order_id, exclude={rider_id})
        return updated

    async def release_rider(self, rider_id: str, order_id: str, *, completed: bool) -> None:
        async def fn(tx: Transaction) -> None:
            doc = await tx.get(f"rider_profiles/{rider_id}")
            if doc is None:
                return
            rider = RiderProfile.model_validate(doc)
            changes: dict[str, Any] = {
                "active_order_ids": [o for o in rider.active_order_ids if o != order_id]
            }
            if completed:
                changes["completed_deliveries"] = rider.completed_deliveries + 1
            tx.update(f"rider_profiles/{rider_id}", changes)

        await self.repos.store.run_transaction(fn)

    async def on_order_called_off(self, payload: dict[str, Any]) -> None:
        """Cancelled or refunded before delivery: free the rider and tell them not to pick up."""
        if payload.get("from") not in (S.RIDER_ASSIGNED.value, S.PICKED_UP.value, S.IN_TRANSIT.value):
            return
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order is None or not order.rider_id:
            return
        await self.release_rider(order.rider_id, order.id, completed=False)
        if order.assignment_id:
            await self.repos.assignments.update(
                order.assignment_id,
                {"status": AssignmentStatus.CANCELLED.value, "decline_reason": "order called off"},
            )
        await self.notifier.notify_user(
            order.rider_id,
            "Delivery cancelled",
            f"Order {order.short_code} was cancelled. Please contact support if you already collected it.",
            {"order_id": order.id},
        )

    async def on_order_delivered(self, payload: dict[str, Any]) -> None:
        order = await self.repos.orders.get(str(payload["order_id"]))
        if order and order.rider_id:
            await self.release_rider(order.rider_id, order.id, completed=True)
            if order.assignment_id:
                await self.repos.assignments.update(
                    order.assignment_id, {"status": AssignmentStatus.COMPLETED.value}
                )


def attempts_label(order: Order) -> int:
    return order.dispatch_attempts + 1
