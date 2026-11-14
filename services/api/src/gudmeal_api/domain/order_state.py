"""The order state machine — the single source of truth for legal order status changes.

Only `OrderService.transition` may apply these rules (inside a Firestore transaction). Clients and the
AI can request actions through API endpoints, which map onto transitions performed by a specific actor.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from ..errors import InvalidTransition, PermissionDenied


class OrderStatus(StrEnum):
    DRAFT = "draft"
    PENDING_PAYMENT = "pending_payment"
    PAID = "paid"
    SUBMITTED_TO_RESTAURANT = "submitted_to_restaurant"
    RESTAURANT_ACCEPTED = "restaurant_accepted"
    PREPARING = "preparing"
    READY_FOR_PICKUP = "ready_for_pickup"
    RIDER_ASSIGNED = "rider_assigned"
    PICKED_UP = "picked_up"
    IN_TRANSIT = "in_transit"
    DELIVERED = "delivered"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    REFUND_PENDING = "refund_pending"
    PARTIALLY_REFUNDED = "partially_refunded"
    REFUNDED = "refunded"
    DISPUTED = "disputed"


class ActorType(StrEnum):
    CUSTOMER = "customer"
    RESTAURANT = "restaurant"
    RIDER = "rider"
    SYSTEM = "system"
    STAFF = "staff"  # support / operations / super admin — always audited, reason required


S = OrderStatus
A = ActorType


@dataclass(frozen=True, slots=True)
class TransitionRule:
    actors: frozenset[ActorType]
    reason_required_for: frozenset[ActorType] = frozenset({A.STAFF})


def _rule(*actors: ActorType, reason_for: tuple[ActorType, ...] = (A.STAFF,)) -> TransitionRule:
    return TransitionRule(frozenset(actors), frozenset(reason_for))


# (from, to) -> who may perform it. Anything absent is illegal.
TRANSITIONS: dict[tuple[OrderStatus, OrderStatus], TransitionRule] = {
    # checkout & payment
    (S.DRAFT, S.PENDING_PAYMENT): _rule(A.CUSTOMER, A.SYSTEM),
    (S.DRAFT, S.CANCELLED): _rule(A.CUSTOMER, A.SYSTEM, A.STAFF),
    (S.PENDING_PAYMENT, S.PAID): _rule(A.SYSTEM),  # only the payment verifier
    (S.PENDING_PAYMENT, S.CANCELLED): _rule(A.CUSTOMER, A.SYSTEM, A.STAFF),
    # hand-off to the kitchen
    (S.PAID, S.SUBMITTED_TO_RESTAURANT): _rule(A.SYSTEM),
    (S.PAID, S.REFUND_PENDING): _rule(A.SYSTEM, A.STAFF),
    (S.SUBMITTED_TO_RESTAURANT, S.RESTAURANT_ACCEPTED): _rule(A.RESTAURANT, A.STAFF),
    (S.SUBMITTED_TO_RESTAURANT, S.REFUND_PENDING): _rule(
        A.RESTAURANT, A.CUSTOMER, A.SYSTEM, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)
    ),
    # kitchen
    (S.RESTAURANT_ACCEPTED, S.PREPARING): _rule(A.RESTAURANT, A.STAFF),
    (S.RESTAURANT_ACCEPTED, S.READY_FOR_PICKUP): _rule(A.RESTAURANT, A.STAFF),
    (S.RESTAURANT_ACCEPTED, S.RIDER_ASSIGNED): _rule(A.SYSTEM, A.STAFF),
    (S.RESTAURANT_ACCEPTED, S.REFUND_PENDING): _rule(
        A.RESTAURANT, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)
    ),
    (S.PREPARING, S.READY_FOR_PICKUP): _rule(A.RESTAURANT, A.STAFF),
    (S.PREPARING, S.RIDER_ASSIGNED): _rule(A.SYSTEM, A.STAFF),
    (S.PREPARING, S.REFUND_PENDING): _rule(A.RESTAURANT, A.STAFF, reason_for=(A.RESTAURANT, A.STAFF)),
    (S.READY_FOR_PICKUP, S.RIDER_ASSIGNED): _rule(A.SYSTEM, A.STAFF),
    (S.READY_FOR_PICKUP, S.COMPLETED): _rule(A.RESTAURANT, A.STAFF),  # pickup orders, code checked
    (S.READY_FOR_PICKUP, S.REFUND_PENDING): _rule(A.STAFF),
    # delivery
    (S.RIDER_ASSIGNED, S.PICKED_UP): _rule(A.RIDER, A.STAFF),
    (S.RIDER_ASSIGNED, S.PREPARING): _rule(A.SYSTEM, A.STAFF),  # rider unassigned, food not ready
    (S.RIDER_ASSIGNED, S.READY_FOR_PICKUP): _rule(A.SYSTEM, A.STAFF),  # rider unassigned, food ready
    (S.RIDER_ASSIGNED, S.REFUND_PENDING): _rule(A.STAFF),
    (S.PICKED_UP, S.IN_TRANSIT): _rule(A.RIDER, A.STAFF),
    (S.PICKED_UP, S.DELIVERED): _rule(A.RIDER, A.STAFF),
    (S.PICKED_UP, S.DISPUTED): _rule(A.STAFF),
    (S.IN_TRANSIT, S.DELIVERED): _rule(A.RIDER, A.STAFF),
    (S.IN_TRANSIT, S.DISPUTED): _rule(A.STAFF),
    (S.DELIVERED, S.COMPLETED): _rule(A.SYSTEM, A.STAFF),
    (S.DELIVERED, S.DISPUTED): _rule(A.CUSTOMER, A.STAFF, reason_for=(A.CUSTOMER, A.STAFF)),
    # after-sales
    (S.COMPLETED, S.DISPUTED): _rule(A.CUSTOMER, A.STAFF, reason_for=(A.CUSTOMER, A.STAFF)),
    (S.COMPLETED, S.REFUND_PENDING): _rule(A.STAFF, A.SYSTEM),
    (S.DISPUTED, S.COMPLETED): _rule(A.STAFF),
    (S.DISPUTED, S.REFUND_PENDING): _rule(A.STAFF, A.SYSTEM),
    (S.REFUND_PENDING, S.REFUNDED): _rule(A.SYSTEM),
    (S.REFUND_PENDING, S.PARTIALLY_REFUNDED): _rule(A.SYSTEM),
    (S.REFUND_PENDING, S.COMPLETED): _rule(A.STAFF),  # refund rejected after completion
    (S.PARTIALLY_REFUNDED, S.DISPUTED): _rule(A.CUSTOMER, A.STAFF, reason_for=(A.CUSTOMER, A.STAFF)),
    (S.PARTIALLY_REFUNDED, S.REFUND_PENDING): _rule(A.STAFF, A.SYSTEM),
}

TERMINAL: frozenset[OrderStatus] = frozenset({S.CANCELLED, S.REFUNDED})

# Orders in these states hold customer money that has not been earned yet.
ACTIVE_FULFILMENT: frozenset[OrderStatus] = frozenset(
    {
        S.PAID,
        S.SUBMITTED_TO_RESTAURANT,
        S.RESTAURANT_ACCEPTED,
        S.PREPARING,
        S.READY_FOR_PICKUP,
        S.RIDER_ASSIGNED,
        S.PICKED_UP,
        S.IN_TRANSIT,
    }
)

# Coarse progress used by customer UIs.
CUSTOMER_PROGRESS: dict[OrderStatus, tuple[int, str]] = {
    S.DRAFT: (0, "Draft"),
    S.PENDING_PAYMENT: (0, "Awaiting payment"),
    S.PAID: (1, "Payment confirmed"),
    S.SUBMITTED_TO_RESTAURANT: (1, "Sent to restaurant"),
    S.RESTAURANT_ACCEPTED: (2, "Restaurant accepted"),
    S.PREPARING: (2, "Preparing your food"),
    S.READY_FOR_PICKUP: (3, "Ready for pickup"),
    S.RIDER_ASSIGNED: (3, "Rider on the way to restaurant"),
    S.PICKED_UP: (4, "Picked up"),
    S.IN_TRANSIT: (4, "On the way to you"),
    S.DELIVERED: (5, "Delivered"),
    S.COMPLETED: (5, "Completed"),
    S.CANCELLED: (-1, "Cancelled"),
    S.REFUND_PENDING: (-1, "Refund in progress"),
    S.PARTIALLY_REFUNDED: (5, "Partially refunded"),
    S.REFUNDED: (-1, "Refunded"),
    S.DISPUTED: (-1, "Under review"),
}


def can_transition(src: OrderStatus, dst: OrderStatus, actor: ActorType) -> bool:
    rule = TRANSITIONS.get((src, dst))
    return rule is not None and actor in rule.actors


def allowed_targets(src: OrderStatus, actor: ActorType) -> set[OrderStatus]:
    return {dst for (s, dst), rule in TRANSITIONS.items() if s == src and actor in rule.actors}


def assert_transition(src: OrderStatus, dst: OrderStatus, actor: ActorType, reason: str | None) -> None:
    """Raise if `actor` may not move an order from `src` to `dst`."""
    if src in TERMINAL:
        raise InvalidTransition(f"Order is {src.value}; no further changes are allowed")
    rule = TRANSITIONS.get((src, dst))
    if rule is None:
        raise InvalidTransition(
            f"Cannot move order from {src.value} to {dst.value}",
            details={"from": src.value, "to": dst.value},
        )
    if actor not in rule.actors:
        raise PermissionDenied(
            f"{actor.value} may not move an order from {src.value} to {dst.value}",
            details={"from": src.value, "to": dst.value, "actor": actor.value},
        )
    if actor in rule.reason_required_for and not (reason and reason.strip()):
        raise InvalidTransition("A reason is required for this action", details={"to": dst.value})
