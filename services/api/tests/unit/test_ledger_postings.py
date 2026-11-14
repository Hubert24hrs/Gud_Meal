import random
from datetime import UTC, datetime

import pytest

from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.models import Fulfillment, Order, PriceBreakdown, SettlementTerms
from gudmeal_api.domain.order_state import OrderStatus
from gudmeal_api.ledger.ledger import (
    LedgerError,
    Posting,
    order_completed,
    payment_captured,
    payout_made,
    refund_issued,
    validate_postings,
)


def make_order(rng: random.Random, *, rider: bool = True, funded_by: str | None = None) -> Order:
    subtotal = rng.randint(1_000, 5_000_000)
    delivery = rng.randint(0, 400_000) if rider else 0
    service = rng.randint(0, 150_000)
    small = rng.choice([0, 30_000])
    vat = rng.randint(0, 50_000)
    commission = subtotal * rng.randint(0, 3000) // 10_000
    discount = rng.randint(0, min(subtotal - commission, 200_000)) if funded_by else 0
    total = subtotal + delivery + service + small + vat - discount
    return Order(
        id="o1",
        short_code="ABC123",
        customer_id="c1",
        restaurant_id="r1",
        restaurant_name="R",
        restaurant_location=GeoPoint(lat=6.4, lng=3.4),
        status=OrderStatus.COMPLETED,
        fulfillment=Fulfillment.DELIVERY if rider else Fulfillment.PICKUP,
        lines=[],
        breakdown=PriceBreakdown(
            subtotal_kobo=subtotal,
            delivery_fee_kobo=delivery,
            service_fee_kobo=service,
            small_order_fee_kobo=small,
            vat_kobo=vat,
            discount_kobo=discount,
            total_kobo=total,
            discount_funded_by=funded_by,
        ),  # type: ignore[arg-type]
        settlement=SettlementTerms(
            commission_bps=1500,
            commission_kobo=commission,
            rider_pay_kobo=rng.randint(0, 500_000) if rider else 0,
            restaurant_funded_discount_kobo=discount if funded_by == "restaurant" else 0,
            platform_funded_discount_kobo=discount if funded_by == "platform" else 0,
            restaurant_earning_kobo=subtotal - commission - (discount if funded_by == "restaurant" else 0),
        ),
        rider_id="rider1" if rider else None,
        quote_id="q",
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )


@pytest.mark.parametrize("seed", range(300))
def test_completion_postings_always_balance(seed):
    rng = random.Random(seed)
    order = make_order(rng, rider=rng.random() > 0.2, funded_by=rng.choice([None, "platform", "restaurant"]))
    entries = order_completed(order)
    validate_postings(entries)
    debit = sum(p.amount_kobo for p in entries if p.direction == "debit")
    assert any(
        p.account == "liability:customer_funds" and p.amount_kobo == order.breakdown.total_kobo
        for p in entries
    )
    assert debit == sum(p.amount_kobo for p in entries if p.direction == "credit")


def test_subsidised_delivery_uses_expense_account():
    rng = random.Random(1)
    order = make_order(rng)
    order.settlement.rider_pay_kobo = order.breakdown.delivery_fee_kobo + 10_000
    entries = order_completed(order)
    assert Posting("expense:delivery_subsidy", "debit", 10_000) in entries


def test_other_builders_balance():
    validate_postings(payment_captured("paystack", 945_000))
    validate_postings(payout_made("rider", "r1", 50_000))
    for stage in ("before_completion", "after_completion"):
        for liability in ("restaurant", "platform"):
            validate_postings(
                refund_issued(
                    provider="paystack",
                    amount_kobo=1000,
                    stage=stage,  # type: ignore[arg-type]
                    liability=liability,
                    restaurant_id="r1",
                )
            )  # type: ignore[arg-type]


@pytest.mark.parametrize(
    "bad",
    [
        [Posting("cash:paystack", "debit", 100)],
        [Posting("cash:paystack", "debit", 100), Posting("liability:customer_funds", "credit", 99)],
        [Posting("cash:paystack", "debit", 0), Posting("liability:customer_funds", "credit", 0)],
        [Posting("cash:paystack", "debit", -5), Posting("liability:customer_funds", "credit", -5)],
        [Posting("unknown:x", "debit", 5), Posting("liability:customer_funds", "credit", 5)],
    ],
)
def test_invalid_postings_rejected(bad):
    with pytest.raises(LedgerError):
        validate_postings(bad)
