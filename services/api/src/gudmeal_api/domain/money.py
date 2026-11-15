"""Money helpers. All amounts are integers in kobo (₦1 = 100 kobo). Never use floats for money."""

from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal

KOBO_PER_NAIRA = 100
BPS_DENOMINATOR = 10_000  # basis points: 10_000 bps = 100 %


def naira(amount: int | str | Decimal) -> int:
    """Convert a naira amount to kobo, exactly. `naira("1500.50") == 150050`."""
    value = Decimal(str(amount)) * KOBO_PER_NAIRA
    if value != value.to_integral_value():
        raise ValueError(f"{amount!r} has more precision than 1 kobo")
    return int(value)


def kobo_to_naira_decimal(kobo: int) -> Decimal:
    return (Decimal(kobo) / KOBO_PER_NAIRA).quantize(Decimal("0.01"))


def naira_decimal_to_kobo(value: Decimal | str | int | float) -> int:
    """Convert a provider-reported naira amount (e.g. Flutterwave) to kobo, rejecting sub-kobo values."""
    dec = Decimal(str(value)) * KOBO_PER_NAIRA
    if dec != dec.to_integral_value():
        raise ValueError(f"Amount {value!r} is not a whole number of kobo")
    return int(dec)


def apply_bps(amount_kobo: int, bps: int) -> int:
    """`amount × bps / 10_000`, rounded half-up to the nearest kobo."""
    if amount_kobo < 0 or bps < 0:
        raise ValueError("apply_bps expects non-negative inputs")
    result = (Decimal(amount_kobo) * Decimal(bps) / Decimal(BPS_DENOMINATOR)).quantize(
        Decimal(1), rounding=ROUND_HALF_UP
    )
    return int(result)


def multiply_decimal(amount_kobo: int, factor: Decimal | str) -> int:
    """`amount × factor` rounded half-up — used for per-km fees."""
    result = (Decimal(amount_kobo) * Decimal(str(factor))).quantize(Decimal(1), rounding=ROUND_HALF_UP)
    return int(result)


def clamp(value: int, lower: int, upper: int) -> int:
    if lower > upper:
        raise ValueError("lower bound exceeds upper bound")
    return max(lower, min(upper, value))


def allocate(weights: dict[str, int], amount_kobo: int) -> dict[str, int]:
    """Split `amount_kobo` in proportion to non-negative integer weights (largest remainder method).

    The parts always add up exactly to the amount; ties go to the earlier key, so the result is deterministic.
    """
    if amount_kobo < 0 or any(w < 0 for w in weights.values()):
        raise ValueError("allocate expects non-negative amounts and weights")
    total = sum(weights.values())
    if total <= 0:
        raise ValueError("allocate needs at least one positive weight")
    raw = {k: amount_kobo * w for k, w in weights.items()}
    parts = {k: r // total for k, r in raw.items()}
    left = amount_kobo - sum(parts.values())
    keys = list(weights)
    for k in sorted(keys, key=lambda k: (-(raw[k] % total), keys.index(k)))[:left]:
        parts[k] += 1
    return parts


def format_naira(kobo: int) -> str:
    """Human formatting used in notifications and AI summaries: 1_000_000 -> '₦10,000'."""
    sign = "-" if kobo < 0 else ""
    kobo = abs(kobo)
    whole, frac = divmod(kobo, KOBO_PER_NAIRA)
    if frac:
        return f"{sign}₦{whole:,}.{frac:02d}"
    return f"{sign}₦{whole:,}"
