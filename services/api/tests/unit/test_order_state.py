import pytest

from gudmeal_api.domain.order_state import (
    TERMINAL,
    TRANSITIONS,
    ActorType,
    OrderStatus,
    allowed_targets,
    assert_transition,
    can_transition,
)
from gudmeal_api.errors import InvalidTransition, PermissionDenied

S, A = OrderStatus, ActorType


def test_every_status_is_reachable_from_draft():
    reachable, frontier = {S.DRAFT}, [S.DRAFT]
    while frontier:
        src = frontier.pop()
        for s, d in TRANSITIONS:
            if s == src and d not in reachable:
                reachable.add(d)
                frontier.append(d)
    assert reachable == set(OrderStatus)


def test_terminal_states_have_no_exits():
    for src, _dst in TRANSITIONS:
        assert src not in TERMINAL


def test_only_system_can_mark_paid():
    assert can_transition(S.PENDING_PAYMENT, S.PAID, A.SYSTEM)
    for actor in (A.CUSTOMER, A.RESTAURANT, A.RIDER, A.STAFF):
        assert not can_transition(S.PENDING_PAYMENT, S.PAID, actor)
        with pytest.raises(PermissionDenied):
            assert_transition(S.PENDING_PAYMENT, S.PAID, actor, "reason")


def test_customer_cannot_skip_kitchen():
    with pytest.raises(InvalidTransition):
        assert_transition(S.PAID, S.DELIVERED, A.CUSTOMER, None)


def test_rider_flow():
    assert allowed_targets(S.RIDER_ASSIGNED, A.RIDER) == {S.PICKED_UP}
    assert allowed_targets(S.PICKED_UP, A.RIDER) == {S.IN_TRANSIT, S.DELIVERED}
    assert allowed_targets(S.IN_TRANSIT, A.RIDER) == {S.DELIVERED}


def test_restaurant_cannot_assign_riders_or_complete_delivery():
    assert S.RIDER_ASSIGNED not in allowed_targets(S.PREPARING, A.RESTAURANT)
    assert not can_transition(S.IN_TRANSIT, S.DELIVERED, A.RESTAURANT)


def test_staff_requires_reason():
    with pytest.raises(InvalidTransition, match="reason"):
        assert_transition(S.DISPUTED, S.COMPLETED, A.STAFF, "  ")
    assert_transition(S.DISPUTED, S.COMPLETED, A.STAFF, "Customer confirmed items received")


def test_restaurant_rejection_requires_reason():
    with pytest.raises(InvalidTransition):
        assert_transition(S.SUBMITTED_TO_RESTAURANT, S.REFUND_PENDING, A.RESTAURANT, None)
    assert_transition(S.SUBMITTED_TO_RESTAURANT, S.REFUND_PENDING, A.RESTAURANT, "Out of jollof")


def test_terminal_rejects_everything():
    for actor in ActorType:
        with pytest.raises(InvalidTransition):
            assert_transition(S.REFUNDED, S.DISPUTED, actor, "x")
        with pytest.raises(InvalidTransition):
            assert_transition(S.CANCELLED, S.PENDING_PAYMENT, actor, "x")
