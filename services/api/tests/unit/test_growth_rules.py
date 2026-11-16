"""Phase 4 rules (ADR-0016): Plus pricing, VAT-inclusive split, bill sharing, points, codes, postings."""

import random
import re
from datetime import UTC, datetime

import pytest

from gudmeal_api.domain.geo import GeoPoint
from gudmeal_api.domain.growth import (
    GROUP_CODE_PATTERN,
    REFERRAL_PATTERN,
    GrowthConfig,
    PlusConfig,
    new_code,
    normalise_code,
    points_for,
    referral_code_for,
)
from gudmeal_api.domain.models import Fulfillment, PricedLine, Restaurant, Voucher
from gudmeal_api.domain.money import allocate, apply_bps, naira
from gudmeal_api.domain.pricing import (
    PricingConfig,
    compute_price,
    delivery_fee,
    service_fee,
    split_bill,
    vat_inclusive_split,
)
from gudmeal_api.errors import ValidationFailed, VoucherInvalid
from gudmeal_api.ledger.ledger import plus_paid, validate_postings

NOW = datetime(2026, 11, 16, 12, 0, tzinfo=UTC)
CFG = PricingConfig()
PLUS = PlusConfig()
REST = Restaurant(
    id="r1",
    name="Test Kitchen",
    slug="test-kitchen",
    location=GeoPoint(lat=6.45, lng=3.47),
    address="1 Test St",
)


def lines(subtotal_kobo: int) -> list[PricedLine]:
    return [
        PricedLine(
            item_id="i1",
            name="Jollof",
            quantity=1,
            unit_price_kobo=subtotal_kobo,
            line_total_kobo=subtotal_kobo,
        )
    ]


def price(subtotal: int, *, plus: PlusConfig | None = None, voucher: Voucher | None = None, pickup=False):
    return compute_price(
        lines=lines(subtotal),
        restaurant=REST,
        fulfillment=Fulfillment.PICKUP if pickup else Fulfillment.DELIVERY,
        distance_km=None if pickup else 4.0,
        cfg=CFG,
        now=NOW,
        voucher=voucher,
        plus=plus,
    )


class TestPlusPricing:
    def test_members_get_free_delivery_and_half_the_service_fee_above_the_minimum(self):
        normal, member = price(naira(5000)), price(naira(5000), plus=PLUS)
        assert member.breakdown.delivery_fee_kobo == 0
        full_fee = service_fee(naira(5000), CFG)
        assert member.breakdown.service_fee_kobo == full_fee - apply_bps(full_fee, 5_000)
        assert member.breakdown.vat_kobo == apply_bps(member.breakdown.service_fee_kobo, CFG.vat_bps)
        # Savings are exactly the difference to the non-member price; the rider is still paid in full.
        assert member.breakdown.plus_savings_kobo == normal.breakdown.total_kobo - member.breakdown.total_kobo
        assert member.breakdown.plus_savings_kobo > delivery_fee(4.0, CFG)
        assert member.settlement.rider_pay_kobo == normal.settlement.rider_pay_kobo
        assert normal.breakdown.plus_savings_kobo == 0

    def test_below_the_minimum_only_the_service_fee_is_reduced(self):
        normal, member = price(naira(2500)), price(naira(2500), plus=PLUS)
        assert member.breakdown.delivery_fee_kobo == normal.breakdown.delivery_fee_kobo > 0
        assert member.breakdown.small_order_fee_kobo == normal.breakdown.small_order_fee_kobo
        assert member.breakdown.service_fee_kobo < normal.breakdown.service_fee_kobo
        assert member.breakdown.plus_savings_kobo == normal.breakdown.total_kobo - member.breakdown.total_kobo

    def test_pickup_orders_keep_the_service_fee_discount(self):
        member = price(naira(5000), plus=PLUS, pickup=True)
        assert member.breakdown.delivery_fee_kobo == 0
        assert member.breakdown.plus_savings_kobo == price(naira(5000), pickup=True).breakdown.total_kobo - (
            member.breakdown.total_kobo
        )

    def test_vouchers_still_apply_but_free_delivery_cannot_be_discounted_again(self):
        subtotal_voucher = Voucher(code="SAVE500", kind="fixed", value=naira(500))
        member = price(naira(5000), plus=PLUS, voucher=subtotal_voucher)
        assert member.breakdown.discount_kobo == naira(500)
        assert member.breakdown.total_kobo == price(naira(5000), plus=PLUS).breakdown.total_kobo - naira(500)
        delivery_voucher = Voucher(code="FREEDEL", kind="percent", value=10_000, target="delivery_fee")
        with pytest.raises(VoucherInvalid, match="already free"):
            price(naira(5000), plus=PLUS, voucher=delivery_voucher)
        assert price(naira(2500), plus=PLUS, voucher=delivery_voucher).breakdown.discount_kobo > 0

    @pytest.mark.parametrize("seed", range(10))
    def test_member_totals_balance(self, seed):
        rng = random.Random(seed)
        r = price(rng.randint(naira(500), naira(60_000)), plus=PLUS)
        b = r.breakdown
        assert (
            b.total_kobo
            == (
                b.subtotal_kobo
                + b.delivery_fee_kobo
                + b.service_fee_kobo
                + b.small_order_fee_kobo
                + b.vat_kobo
            )
            - b.discount_kobo
        )
        assert b.plus_savings_kobo >= 0


class TestMoneySplits:
    def test_vat_inclusive_split(self):
        assert vat_inclusive_split(150_000, 750) == (139_535, 10_465)
        assert vat_inclusive_split(150_000, 0) == (150_000, 0)
        for gross in (1, 99, 10_750, 123_457):
            net, vat = vat_inclusive_split(gross, 750)
            assert net + vat == gross and vat >= 0

    @pytest.mark.parametrize("seed", range(20))
    def test_allocate_adds_up_exactly_and_is_proportional(self, seed):
        rng = random.Random(seed)
        weights = {f"m{i}": rng.randint(1, 50_000) for i in range(rng.randint(1, 10))}
        amount = rng.randint(0, 5_000_000)
        parts = allocate(weights, amount)
        assert sum(parts.values()) == amount
        total = sum(weights.values())
        for k, w in weights.items():
            assert abs(parts[k] - amount * w / total) < 1
        assert parts == allocate(weights, amount)  # deterministic

    def test_bill_split(self):
        shares = split_bill({"ada": naira(3000), "tunde": naira(1500), "chi": naira(500)}, 612_345)
        assert sum(shares.values()) == 612_345
        assert shares["ada"] == 2 * shares["tunde"] or abs(shares["ada"] - 2 * shares["tunde"]) <= 1
        with pytest.raises(ValidationFailed):
            split_bill({"ada": naira(3000), "lurker": 0}, 612_345)
        with pytest.raises(ValidationFailed):
            split_bill({}, 100)

    def test_plus_postings_balance(self):
        validate_postings(plus_paid("cash:paystack", 150_000, 10_465))
        validate_postings(plus_paid("liability:wallet:cust-1", 150_000, 0))


class TestPointsAndCodes:
    def test_points(self):
        cfg = GrowthConfig()
        assert points_for(naira(4_599), cfg) == 45
        assert points_for(naira(4_599), cfg, multiplier=2) == 90
        assert points_for(naira(99), cfg) == 0
        assert points_for(naira(5_000), cfg.model_copy(update={"points_enabled": False})) == 0

    def test_codes(self):
        assert re.match(REFERRAL_PATTERN, referral_code_for("Ada Obi"))
        assert referral_code_for("Ada Obi").startswith("ADAO")
        assert referral_code_for("李").startswith("GUD")
        assert re.match(GROUP_CODE_PATTERN, new_code(6))
        assert normalise_code(" ada-7k2p ") == "ADA7K2P"
