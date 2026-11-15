"""Deterministic pricing engine. Pure functions, integer kobo, no I/O.

Quotes, orders, the AI meal planner and the ledger all use these functions, so the number a customer
sees is exactly the number charged and settled.
"""

from __future__ import annotations

import hashlib
from collections.abc import Mapping
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from ..errors import ItemUnavailable, ValidationFailed, VoucherInvalid
from .geo import GeoPoint, haversine_km
from .models import (
    CartLine,
    Fulfillment,
    MenuItem,
    OptionGroup,
    ParcelSize,
    PriceBreakdown,
    PricedLine,
    Restaurant,
    SettlementTerms,
    Voucher,
)
from .money import apply_bps, clamp, multiply_decimal


class DeliveryFeeConfig(BaseModel):
    base_kobo: int = Field(default=50_000, ge=0)  # ₦500
    per_km_kobo: int = Field(default=15_000, ge=0)  # ₦150 per road km
    min_kobo: int = Field(default=60_000, ge=0)  # ₦600
    max_kobo: int = Field(default=400_000, ge=0)  # ₦4,000
    road_factor: Decimal = Decimal("1.35")  # straight line → road distance (Lagos average)
    round_to_kobo: int = Field(default=5_000, ge=1)  # customer-facing fee rounded to ₦50


class RiderPayConfig(BaseModel):
    base_kobo: int = Field(default=40_000, ge=0)  # ₦400
    per_km_kobo: int = Field(default=10_000, ge=0)  # ₦100 per road km
    min_kobo: int = Field(default=50_000, ge=0)  # ₦500


class ParcelFeeConfig(BaseModel):
    """Package Delivery (courier) pricing. Customer fee = base for the size + per road km, rounded to ₦50."""

    base_by_size_kobo: dict[ParcelSize, int] = Field(
        default_factory=lambda: {
            ParcelSize.SMALL: 100_000,  # ₦1,000
            ParcelSize.MEDIUM: 150_000,  # ₦1,500
            ParcelSize.LARGE: 250_000,  # ₦2,500
        }
    )
    per_km_kobo: int = Field(default=15_000, ge=0)  # ₦150 per road km
    min_kobo: int = Field(default=100_000, ge=0)  # ₦1,000
    max_kobo: int = Field(default=1_500_000, ge=0)  # ₦15,000
    round_to_kobo: int = Field(default=5_000, ge=1)  # ₦50
    service_fee_kobo: int = Field(default=10_000, ge=0)  # ₦100 booking fee
    rider_bonus_by_size_kobo: dict[ParcelSize, int] = Field(
        default_factory=lambda: {ParcelSize.SMALL: 0, ParcelSize.MEDIUM: 20_000, ParcelSize.LARGE: 50_000}
    )
    max_distance_km: float = Field(default=40.0, gt=0)  # straight-line, within one city
    pickup_eta_minutes: int = Field(default=25, ge=0)  # typical time for a rider to reach the sender
    # Vendor cash-on-delivery: the sender pays a collection fee with the booking; riders carry at most cod_max.
    cod_fee_bps: int = Field(default=150, ge=0, le=2_000)  # 1.5% of the cash collected
    cod_fee_min_kobo: int = Field(default=10_000, ge=0)  # ₦100
    cod_fee_round_to_kobo: int = Field(default=1_000, ge=1)  # ₦10
    cod_max_kobo: int = Field(default=10_000_000, ge=0)  # ₦100,000 per package


class ZoneConfig(BaseModel):
    id: str
    name: str
    city: str = "lagos"
    center: GeoPoint
    radius_km: float = Field(gt=0)
    is_active: bool = True
    surge_bps: int = Field(default=10_000, ge=10_000, le=30_000)  # 1.0x – 3.0x


class PricingConfig(BaseModel):
    version: int = 1
    service_fee_bps: int = Field(default=500, ge=0, le=3_000)
    service_fee_min_kobo: int = Field(default=10_000, ge=0)
    service_fee_max_kobo: int = Field(default=150_000, ge=0)
    small_order_threshold_kobo: int = Field(default=300_000, ge=0)
    small_order_fee_kobo: int = Field(default=30_000, ge=0)
    vat_bps: int = Field(default=750, ge=0, le=5_000)  # VAT on platform fees
    default_commission_bps: int = Field(default=1_500, ge=0, le=5_000)
    delivery: DeliveryFeeConfig = Field(default_factory=DeliveryFeeConfig)
    rider_pay: RiderPayConfig = Field(default_factory=RiderPayConfig)
    parcel: ParcelFeeConfig = Field(default_factory=ParcelFeeConfig)
    avg_speed_kmh: Decimal = Decimal("18")
    dispatch_buffer_minutes: int = 8
    zones: list[ZoneConfig] = Field(default_factory=list)

    def zone_for(self, point: GeoPoint) -> ZoneConfig | None:
        best: tuple[float, ZoneConfig] | None = None
        for zone in self.zones:
            if not zone.is_active:
                continue
            d = haversine_km(point, zone.center)
            if d <= zone.radius_km and (best is None or d < best[0]):
                best = (d, zone)
        return best[1] if best else None


# ---------------------------------------------------------------------------------------------
# Line pricing
# ---------------------------------------------------------------------------------------------


def price_line(line: CartLine, item: MenuItem, groups: Mapping[str, OptionGroup]) -> PricedLine:
    if not item.is_active or not item.is_available:
        raise ItemUnavailable(f"{item.name} is not available right now", details={"item_id": item.id})

    selections_by_group: dict[str, list[str]] = {}
    for sel in line.selections:
        if sel.group_id in selections_by_group:
            raise ValidationFailed("Duplicate option group in selection", details={"group_id": sel.group_id})
        if sel.group_id not in item.option_group_ids:
            raise ValidationFailed(
                f"Option group does not belong to {item.name}", details={"group_id": sel.group_id}
            )
        if len(set(sel.choice_ids)) != len(sel.choice_ids):
            raise ValidationFailed("Duplicate option choice", details={"group_id": sel.group_id})
        selections_by_group[sel.group_id] = sel.choice_ids

    options_unit = 0
    labels: list[str] = []
    for group_id in item.option_group_ids:
        group = groups.get(group_id)
        if group is None:
            raise ItemUnavailable(f"Options for {item.name} are unavailable", details={"group_id": group_id})
        chosen = selections_by_group.get(group_id, [])
        if not (group.min_select <= len(chosen) <= group.max_select):
            raise ValidationFailed(
                f"Choose between {group.min_select} and {group.max_select} for '{group.name}'",
                details={"group_id": group_id, "item_id": item.id},
            )
        by_id = {c.id: c for c in group.choices}
        for choice_id in chosen:
            choice = by_id.get(choice_id)
            if choice is None:
                raise ValidationFailed("Unknown option choice", details={"choice_id": choice_id})
            if not choice.is_available:
                raise ItemUnavailable(f"{choice.name} is unavailable", details={"choice_id": choice_id})
            options_unit += choice.price_delta_kobo
            labels.append(f"{group.name}: {choice.name}")

    unit_total = item.price_kobo + options_unit
    return PricedLine(
        item_id=item.id,
        name=item.name,
        kind=item.kind,
        quantity=line.quantity,
        unit_price_kobo=item.price_kobo,
        options_unit_price_kobo=options_unit,
        line_total_kobo=unit_total * line.quantity,
        selections=line.selections,
        selection_labels=labels,
        notes=line.notes,
    )


def menu_fingerprint(lines: list[PricedLine]) -> str:
    raw = "|".join(f"{ln.item_id}:{ln.unit_price_kobo}:{ln.options_unit_price_kobo}" for ln in lines)
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


# ---------------------------------------------------------------------------------------------
# Fees
# ---------------------------------------------------------------------------------------------


def road_km(distance_km: float, cfg: PricingConfig) -> Decimal:
    return (Decimal(str(round(distance_km, 3))) * cfg.delivery.road_factor).quantize(Decimal("0.001"))


def round_to(amount_kobo: int, step_kobo: int) -> int:
    """Round half-up to a multiple of `step_kobo` (e.g. ₦50)."""
    return ((amount_kobo + step_kobo // 2) // step_kobo) * step_kobo


def delivery_fee(distance_km: float, cfg: PricingConfig, surge_bps: int = 10_000) -> int:
    d = cfg.delivery
    fee = d.base_kobo + multiply_decimal(d.per_km_kobo, road_km(distance_km, cfg))
    fee = clamp(fee, d.min_kobo, d.max_kobo)
    return round_to(apply_bps(fee, surge_bps), d.round_to_kobo)


def rider_pay(distance_km: float, cfg: PricingConfig) -> int:
    r = cfg.rider_pay
    return max(r.min_kobo, r.base_kobo + multiply_decimal(r.per_km_kobo, road_km(distance_km, cfg)))


def service_fee(subtotal_kobo: int, cfg: PricingConfig) -> int:
    if subtotal_kobo <= 0:
        return 0
    return clamp(
        apply_bps(subtotal_kobo, cfg.service_fee_bps), cfg.service_fee_min_kobo, cfg.service_fee_max_kobo
    )


def voucher_discount(
    voucher: Voucher,
    *,
    subtotal_kobo: int,
    delivery_fee_kobo: int,
    restaurant_id: str,
    now: datetime,
) -> int:
    if not voucher.is_active:
        raise VoucherInvalid("This voucher is no longer active")
    if voucher.starts_at and now < voucher.starts_at:
        raise VoucherInvalid("This voucher is not active yet")
    if voucher.ends_at and now >= voucher.ends_at:
        raise VoucherInvalid("This voucher has expired")
    if voucher.usage_limit is not None and voucher.used_count >= voucher.usage_limit:
        raise VoucherInvalid("This voucher has been fully redeemed")
    if voucher.restaurant_id and voucher.restaurant_id != restaurant_id:
        raise VoucherInvalid("This voucher is not valid for this restaurant")
    if subtotal_kobo < voucher.min_subtotal_kobo:
        raise VoucherInvalid(
            "Order does not meet the voucher minimum",
            details={"min_subtotal_kobo": voucher.min_subtotal_kobo},
        )
    base = subtotal_kobo if voucher.target == "subtotal" else delivery_fee_kobo
    amount = apply_bps(base, voucher.value) if voucher.kind == "percent" else voucher.value
    if voucher.max_discount_kobo is not None:
        amount = min(amount, voucher.max_discount_kobo)
    return max(0, min(amount, base))


def estimate_minutes(prep_minutes: int, distance_km: float | None, cfg: PricingConfig) -> int:
    if distance_km is None:
        return prep_minutes
    travel = road_km(distance_km, cfg) / cfg.avg_speed_kmh * 60
    return int(prep_minutes + cfg.dispatch_buffer_minutes + int(travel.to_integral_value()) + 1)


# ---------------------------------------------------------------------------------------------
# Full breakdown
# ---------------------------------------------------------------------------------------------


class PricingResult(BaseModel):
    breakdown: PriceBreakdown
    settlement: SettlementTerms


def compute_price(
    *,
    lines: list[PricedLine],
    restaurant: Restaurant,
    fulfillment: Fulfillment,
    distance_km: float | None,
    cfg: PricingConfig,
    surge_bps: int = 10_000,
    voucher: Voucher | None = None,
    now: datetime,
) -> PricingResult:
    subtotal = sum(ln.line_total_kobo for ln in lines)
    if subtotal <= 0:
        raise ValidationFailed("Order is empty")
    if subtotal < restaurant.min_order_kobo:
        raise ValidationFailed(
            "Order is below the restaurant minimum", details={"min_order_kobo": restaurant.min_order_kobo}
        )

    is_delivery = fulfillment == Fulfillment.DELIVERY
    if is_delivery and distance_km is None:
        raise ValidationFailed("Distance is required for delivery pricing")

    d_fee = delivery_fee(distance_km or 0.0, cfg, surge_bps) if is_delivery else 0
    s_fee = service_fee(subtotal, cfg)
    small_fee = cfg.small_order_fee_kobo if is_delivery and subtotal < cfg.small_order_threshold_kobo else 0

    discount = 0
    funded_by: Literal["platform", "restaurant"] | None = None
    delivery_discount = 0
    if voucher is not None:
        discount = voucher_discount(
            voucher, subtotal_kobo=subtotal, delivery_fee_kobo=d_fee, restaurant_id=restaurant.id, now=now
        )
        funded_by = voucher.funded_by
        if voucher.target == "delivery_fee":
            delivery_discount = discount

    vat_base = s_fee + small_fee + (d_fee - delivery_discount)
    vat = apply_bps(vat_base, cfg.vat_bps)
    total = subtotal + d_fee + s_fee + small_fee + vat - discount
    if total <= 0:
        raise ValidationFailed("Order total must be positive")

    commission_bps = (
        restaurant.commission_bps if restaurant.commission_bps is not None else cfg.default_commission_bps
    )
    commission = apply_bps(subtotal, commission_bps)
    restaurant_funded = discount if funded_by == "restaurant" else 0
    platform_funded = discount if funded_by == "platform" else 0
    restaurant_earning = subtotal - commission - restaurant_funded
    if restaurant_earning < 0:
        raise ValidationFailed("Restaurant-funded discount exceeds restaurant earnings")

    breakdown = PriceBreakdown(
        subtotal_kobo=subtotal,
        delivery_fee_kobo=d_fee,
        service_fee_kobo=s_fee,
        small_order_fee_kobo=small_fee,
        vat_kobo=vat,
        discount_kobo=discount,
        total_kobo=total,
        discount_funded_by=funded_by,
        voucher_code=voucher.code if voucher else None,
    )
    settlement = SettlementTerms(
        commission_bps=commission_bps,
        commission_kobo=commission,
        rider_pay_kobo=rider_pay(distance_km or 0.0, cfg) if is_delivery else 0,
        restaurant_funded_discount_kobo=restaurant_funded,
        platform_funded_discount_kobo=platform_funded,
        restaurant_earning_kobo=restaurant_earning,
    )
    return PricingResult(breakdown=breakdown, settlement=settlement)


# ---------------------------------------------------------------------------------------------
# Package Delivery
# ---------------------------------------------------------------------------------------------


def parcel_fee(distance_km: float, size: ParcelSize, cfg: PricingConfig, surge_bps: int = 10_000) -> int:
    p = cfg.parcel
    fee = p.base_by_size_kobo[size] + multiply_decimal(p.per_km_kobo, road_km(distance_km, cfg))
    fee = clamp(fee, p.min_kobo, p.max_kobo)
    return round_to(apply_bps(fee, surge_bps), p.round_to_kobo)


def parcel_rider_pay(distance_km: float, size: ParcelSize, cfg: PricingConfig) -> int:
    return rider_pay(distance_km, cfg) + cfg.parcel.rider_bonus_by_size_kobo.get(size, 0)


def cod_fee(cod_amount_kobo: int | None, cfg: PricingConfig) -> int:
    """Fee for collecting cash from the recipient on the sender's behalf (0 when there is no COD)."""
    if not cod_amount_kobo:
        return 0
    p = cfg.parcel
    if cod_amount_kobo > p.cod_max_kobo:
        raise ValidationFailed(
            "Cash-on-delivery amount is above the limit riders can carry",
            details={"cod_amount_kobo": cod_amount_kobo, "max_kobo": p.cod_max_kobo},
        )
    fee = max(p.cod_fee_min_kobo, apply_bps(cod_amount_kobo, p.cod_fee_bps))
    return round_to(fee, p.cod_fee_round_to_kobo)


def compute_parcel_price(
    *,
    distance_km: float,
    size: ParcelSize,
    cfg: PricingConfig,
    surge_bps: int = 10_000,
    cod_amount_kobo: int | None = None,
) -> PricingResult:
    """Price a courier job. There is no merchant: the whole fee is platform revenue less rider pay."""
    if distance_km > cfg.parcel.max_distance_km:
        raise ValidationFailed(
            "Pickup and drop-off are too far apart for bike delivery",
            details={"distance_km": round(distance_km, 2), "max_km": cfg.parcel.max_distance_km},
        )
    fee = parcel_fee(distance_km, size, cfg, surge_bps)
    s_fee = cfg.parcel.service_fee_kobo
    c_fee = cod_fee(cod_amount_kobo, cfg)
    vat = apply_bps(fee + s_fee + c_fee, cfg.vat_bps)
    breakdown = PriceBreakdown(
        subtotal_kobo=0,
        delivery_fee_kobo=fee,
        service_fee_kobo=s_fee,
        cod_fee_kobo=c_fee,
        vat_kobo=vat,
        total_kobo=fee + s_fee + c_fee + vat,
    )
    settlement = SettlementTerms(
        commission_bps=0,
        commission_kobo=0,
        rider_pay_kobo=parcel_rider_pay(distance_km, size, cfg),
        restaurant_earning_kobo=0,
    )
    return PricingResult(breakdown=breakdown, settlement=settlement)


def parcel_minutes(distance_km: float, cfg: PricingConfig) -> int:
    """Minutes from booking to drop-off for an on-demand parcel (rider reaches sender, then rides)."""
    travel = road_km(distance_km, cfg) / cfg.avg_speed_kmh * 60
    return int(cfg.parcel.pickup_eta_minutes + int(travel.to_integral_value()) + 1)
