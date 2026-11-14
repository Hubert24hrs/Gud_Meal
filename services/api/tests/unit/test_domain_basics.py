from datetime import UTC, datetime
from decimal import Decimal

import pytest

from gudmeal_api.domain.geo import GeoPoint, geohash_decode, geohash_encode, geohash_neighbors, haversine_km
from gudmeal_api.domain.hours import OpeningHours, TimeRange, is_open, next_opening
from gudmeal_api.domain.money import apply_bps, format_naira, naira, naira_decimal_to_kobo


class TestMoney:
    def test_naira_to_kobo_exact(self):
        assert naira(10_000) == 1_000_000
        assert naira("1500.50") == 150_050

    def test_naira_rejects_sub_kobo(self):
        with pytest.raises(ValueError):
            naira("1.005")

    def test_apply_bps_rounds_half_up(self):
        assert apply_bps(1_000, 750) == 75
        assert apply_bps(1, 5_000) == 1  # 0.5 kobo → 1
        assert apply_bps(3, 5_000) == 2  # 1.5 → 2

    def test_provider_decimal_amounts(self):
        assert naira_decimal_to_kobo("9450.25") == 945_025
        assert naira_decimal_to_kobo(Decimal("100")) == 10_000
        with pytest.raises(ValueError):
            naira_decimal_to_kobo("1.001")

    def test_format(self):
        assert format_naira(1_000_000) == "₦10,000"
        assert format_naira(150_050) == "₦1,500.50"
        assert format_naira(-500) == "-₦5"


class TestHours:
    # 2026-11-16 is a Monday. Lagos is UTC+1.
    def test_regular_hours(self):
        hours = OpeningHours.every_day("10:00", "22:00")
        assert is_open(hours, datetime(2026, 11, 16, 9, 30, tzinfo=UTC))  # 10:30 Lagos
        assert not is_open(hours, datetime(2026, 11, 16, 8, 30, tzinfo=UTC))  # 09:30 Lagos
        assert not is_open(hours, datetime(2026, 11, 16, 21, 0, tzinfo=UTC))  # 22:00 Lagos (closing)

    def test_overnight_hours_cross_midnight(self):
        hours = OpeningHours.every_day("16:00", "02:00")
        assert is_open(hours, datetime(2026, 11, 16, 23, 30, tzinfo=UTC))  # 00:30 Tue Lagos
        assert not is_open(hours, datetime(2026, 11, 17, 2, 0, tzinfo=UTC))  # 03:00 Lagos

    def test_closed_dates_and_next_opening(self):
        hours = OpeningHours(
            weekly={0: [TimeRange(open="10:00", close="20:00")]}, closed_dates=["2026-11-16"]
        )
        monday_noon = datetime(2026, 11, 16, 11, 0, tzinfo=UTC)
        assert not is_open(hours, monday_noon)
        nxt = next_opening(hours, monday_noon)
        assert nxt == datetime(2026, 11, 23, 9, 0, tzinfo=UTC)

    def test_requires_aware_datetime(self):
        with pytest.raises(ValueError):
            is_open(OpeningHours.every_day("10:00", "22:00"), datetime(2026, 11, 16, 10, 0))


class TestGeo:
    def test_haversine_lekki_to_yaba(self):
        d = haversine_km(GeoPoint(lat=6.4478, lng=3.4723), GeoPoint(lat=6.5095, lng=3.3711))
        assert 12.5 < d < 13.5

    def test_geohash_roundtrip(self):
        gh = geohash_encode(6.4478, 3.4723, 9)
        lat, lng, _, _ = geohash_decode(gh)
        assert abs(lat - 6.4478) < 1e-3 and abs(lng - 3.4723) < 1e-3

    def test_neighbors_include_self(self):
        gh = geohash_encode(6.45, 3.47, 5)
        n = geohash_neighbors(gh)
        assert gh in n and len(n) == 9
