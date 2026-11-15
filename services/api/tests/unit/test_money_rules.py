"""Wallet, pay on delivery and vendor cash-on-delivery: postings, fees, state rules and the money guard."""

import random
from datetime import UTC, datetime

import pytest

from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.models import (
    Fulfillment,
    Order,
    ParcelDetails,
    ParcelSize,
    ParcelStop,
    PaymentSummary,
    PriceBreakdown,
    SettlementTerms,
    Vertical,
)
from gudmeal_api.domain.money import apply_bps
from gudmeal_api.domain.order_state import ActorType, OrderStatus, can_transition
from gudmeal_api.domain.pricing import PricingConfig, cod_fee, compute_parcel_price
from gudmeal_api.errors import InvalidTransition, ValidationFailed
from gudmeal_api.ledger.ledger import (
    _owner,
    cash_collected,
    cod_collected,
    order_completed,
    payout_made,
    refund_issued,
    rider_cash_remitted,
    validate_postings,
    vendor_to_wallet,
    wallet_payment,
    wallet_topup,
)
from gudmeal_api.services.orders import OrderService

S = OrderStatus
A = ActorType
NOW = datetime(2026, 11, 15, 12, tzinfo=UTC)


def _stop(name: str) -> ParcelStop:
    return ParcelStop(
        name=name, phone="+2348022222222", line1="1 Test Road", location=GeoPoint(lat=6.44, lng=3.46)
    )


def _order(
    *,
    status: OrderStatus = S.SUBMITTED_TO_RESTAURANT,
    provider: str | None = "cash",
    pay_status: str = "pending",
    cod: int | None = None,
    collected: bool = False,
) -> Order:
    parcel = None
    if cod is not None:
        parcel = ParcelDetails(
            pickup=_stop("Ada"),
            dropoff=_stop("Tunde"),
            size=ParcelSize.SMALL,
            category="other",
            cod_amount_kobo=cod,
        )
    return Order(
        id="o1",
        short_code="ABC123",
        vertical=Vertical.PARCEL if parcel else Vertical.FOOD,
        customer_id="c1",
        restaurant_id="r1",
        restaurant_name="R",
        restaurant_location=GeoPoint(lat=6.4, lng=3.4),
        status=status,
        fulfillment=Fulfillment.DELIVERY,
        lines=[],
        breakdown=PriceBreakdown(subtotal_kobo=900_000, delivery_fee_kobo=100_000, total_kobo=1_000_000),
        settlement=SettlementTerms(
            commission_bps=1500, commission_kobo=135_000, restaurant_earning_kobo=765_000
        ),
        quote_id="q1",
        payment=PaymentSummary(provider=provider, status=pay_status),  # type: ignore[arg-type]
        parcel=parcel,
        cash_collected_at=NOW if collected else None,
        created_at=NOW,
        updated_at=NOW,
    )


# ------------------------------------------------------------------------------------ postings
@pytest.mark.parametrize("seed", range(25))
def test_wallet_and_cash_postings_always_balance(seed):
    rng = random.Random(seed)
    amount = rng.randint(1, 50_000_000)
    for postings in (
        wallet_topup("paystack", "c1", amount),
        wallet_payment("c1", amount),
        cash_collected("rider-1", amount),
        cod_collected("rider-1", "seller-1", amount),
        rider_cash_remitted("rider-1", amount, "bank_transfer"),
        rider_cash_remitted("rider-1", amount, "earnings_offset"),
        vendor_to_wallet("seller-1", amount),
        payout_made("vendor", "seller-1", amount),
        refund_issued(
            provider="paystack",
            amount_kobo=amount,
            stage="before_completion",
            liability="platform",
            restaurant_id="r1",
            to_wallet_of="c1",
        ),
    ):
        validate_postings(postings)


def test_postings_move_money_between_the_right_accounts():
    assert {(p.account, p.direction) for p in wallet_topup("flutterwave", "c1", 5)} == {
        ("cash:flutterwave", "debit"),
        ("liability:wallet:c1", "credit"),
    }
    assert {(p.account, p.direction) for p in wallet_payment("c1", 5)} == {
        ("liability:wallet:c1", "debit"),
        ("liability:customer_funds", "credit"),
    }
    assert {(p.account, p.direction) for p in cod_collected("r9", "s1", 5)} == {
        ("receivable:rider_cash:r9", "debit"),
        ("liability:vendor:s1", "credit"),
    }
    offset = {(p.account, p.direction) for p in rider_cash_remitted("r9", 5, "earnings_offset")}
    assert offset == {("liability:rider:r9", "debit"), ("receivable:rider_cash:r9", "credit")}
    bank = {(p.account, p.direction) for p in rider_cash_remitted("r9", 5, "cash_deposit")}
    assert bank == {("cash:bank", "debit"), ("receivable:rider_cash:r9", "credit")}
    # Refund into the wallet keeps the cash at the provider and credits the customer's wallet instead.
    to_wallet = refund_issued(
        provider="paystack",
        amount_kobo=7,
        stage="after_completion",
        liability="restaurant",
        restaurant_id="r1",
        to_wallet_of="c1",
    )
    assert {(p.account, p.direction) for p in to_wallet} == {
        ("liability:restaurant:r1", "debit"),
        ("liability:wallet:c1", "credit"),
    }


def test_owned_accounts_record_their_owner():
    assert _owner("liability:wallet:cust-1") == ("wallet", "cust-1")
    assert _owner("liability:vendor:cust-1") == ("vendor", "cust-1")
    assert _owner("receivable:rider_cash:demo-rider-1") == ("rider_cash", "demo-rider-1")
    assert _owner("liability:restaurant:r1") == ("restaurant", "r1")
    assert _owner("liability:customer_funds") == (None, None)
    assert _owner("receivable:other:x") == (None, None)


def test_parcel_settlement_with_cod_fee_balances():
    cfg = PricingConfig()
    result = compute_parcel_price(distance_km=6.0, size=ParcelSize.SMALL, cfg=cfg, cod_amount_kobo=2_500_000)
    order = _order(status=S.COMPLETED, provider="local_sandbox", pay_status="paid", cod=2_500_000).model_copy(
        update={"breakdown": result.breakdown, "settlement": result.settlement, "rider_id": "rider-1"}
    )
    postings = order_completed(order)
    validate_postings(postings)
    assert ("revenue:cod_fee", "credit", result.breakdown.cod_fee_kobo) in {
        (p.account, p.direction, p.amount_kobo) for p in postings
    }


# ------------------------------------------------------------------------------------ COD fee
def test_cod_fee_minimum_percentage_rounding_and_limit():
    cfg = PricingConfig()
    assert cod_fee(None, cfg) == 0 and cod_fee(0, cfg) == 0
    assert cod_fee(100_000, cfg) == 10_000  # ₦1,000 → 1.5% is ₦15, minimum ₦100 applies
    assert cod_fee(2_500_000, cfg) == 38_000  # ₦25,000 → 1.5% is ₦375, rounded to ₦380
    assert cod_fee(1_234_567, cfg) == 19_000  # ₦185.19 → rounded to ₦190 (₦10 steps)
    assert cod_fee(cfg.parcel.cod_max_kobo, cfg) == 150_000
    with pytest.raises(ValidationFailed):
        cod_fee(cfg.parcel.cod_max_kobo + 1, cfg)


def test_cod_fee_is_added_to_the_booking_with_vat():
    cfg = PricingConfig()
    plain = compute_parcel_price(distance_km=6.0, size=ParcelSize.SMALL, cfg=cfg).breakdown
    cod = compute_parcel_price(
        distance_km=6.0, size=ParcelSize.SMALL, cfg=cfg, cod_amount_kobo=2_500_000
    ).breakdown
    assert plain.cod_fee_kobo == 0 and cod.cod_fee_kobo == 38_000
    assert cod.vat_kobo == apply_bps(cod.delivery_fee_kobo + cod.service_fee_kobo + 38_000, cfg.vat_bps)
    assert cod.total_kobo == cod.delivery_fee_kobo + cod.service_fee_kobo + 38_000 + cod.vat_kobo


# ------------------------------------------------------------------------------------ order rules
def test_pay_on_delivery_state_rules():
    assert can_transition(S.PENDING_PAYMENT, S.SUBMITTED_TO_RESTAURANT, A.SYSTEM)
    assert not can_transition(S.PENDING_PAYMENT, S.SUBMITTED_TO_RESTAURANT, A.CUSTOMER)
    assert can_transition(S.SUBMITTED_TO_RESTAURANT, S.CANCELLED, A.CUSTOMER)
    assert can_transition(S.PREPARING, S.CANCELLED, A.RESTAURANT)
    assert can_transition(S.IN_TRANSIT, S.CANCELLED, A.STAFF)
    assert not can_transition(S.IN_TRANSIT, S.CANCELLED, A.RIDER)
    assert not can_transition(S.DELIVERED, S.CANCELLED, A.STAFF)


def test_cash_to_collect_covers_pay_on_delivery_and_cod():
    assert _order().cash_to_collect_kobo == 1_000_000
    assert _order(pay_status="paid").cash_to_collect_kobo == 0
    assert _order(provider="paystack", pay_status="paid", cod=250_000).cash_to_collect_kobo == 250_000
    assert _order(cod=250_000).cash_to_collect_kobo == 1_250_000
    assert _order(cod=250_000, collected=True).cash_to_collect_kobo == 0
    assert _order(provider="wallet", pay_status="paid").cash_to_collect_kobo == 0


def _move(order: Order, to: OrderStatus, actor: ActorType = A.STAFF, **patch) -> None:
    OrderService.build_transition(
        order, to, actor_type=actor, actor_id="x", reason="test", patch=patch, now=NOW
    )


def test_money_guard_keeps_status_consistent_with_money():
    paid = _order(status=S.PREPARING, provider="paystack", pay_status="paid")
    with pytest.raises(InvalidTransition, match="refunded rather than cancelled"):
        _move(paid, S.CANCELLED)
    _move(paid, S.REFUND_PENDING)

    unpaid_cash = _order(status=S.PREPARING)
    _move(unpaid_cash, S.CANCELLED)
    with pytest.raises(InvalidTransition, match="cancel it instead"):
        _move(unpaid_cash, S.REFUND_PENDING)

    collected = _order(status=S.COMPLETED, pay_status="paid")
    _move(collected, S.REFUND_PENDING)  # cash was taken at the door: refunds are allowed (into the wallet)

    pending_card = _order(status=S.PENDING_PAYMENT, provider="paystack", pay_status="pending")
    with pytest.raises(InvalidTransition, match="Only pay-on-delivery"):
        _move(pending_card, S.SUBMITTED_TO_RESTAURANT, A.SYSTEM)
    _move(
        pending_card,
        S.SUBMITTED_TO_RESTAURANT,
        A.SYSTEM,
        payment={"provider": "cash", "reference": "R", "status": "pending"},
    )
