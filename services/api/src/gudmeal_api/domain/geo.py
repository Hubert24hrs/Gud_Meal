"""Geospatial helpers: great-circle distance and geohashes for proximity queries."""

from __future__ import annotations

import math

from pydantic import BaseModel, Field

EARTH_RADIUS_KM = 6371.0088
_BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"


class GeoPoint(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


def haversine_km(a: GeoPoint, b: GeoPoint) -> float:
    lat1, lng1, lat2, lng2 = map(math.radians, (a.lat, a.lng, b.lat, b.lng))
    dlat, dlng = lat2 - lat1, lng2 - lng1
    h = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng / 2) ** 2
    return 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(h))


def geohash_encode(lat: float, lng: float, precision: int = 9) -> str:
    lat_range, lng_range = [-90.0, 90.0], [-180.0, 180.0]
    bits, bit, ch, even = [16, 8, 4, 2, 1], 0, 0, True
    out: list[str] = []
    while len(out) < precision:
        if even:
            mid = (lng_range[0] + lng_range[1]) / 2
            if lng > mid:
                ch |= bits[bit]
                lng_range[0] = mid
            else:
                lng_range[1] = mid
        else:
            mid = (lat_range[0] + lat_range[1]) / 2
            if lat > mid:
                ch |= bits[bit]
                lat_range[0] = mid
            else:
                lat_range[1] = mid
        even = not even
        if bit < 4:
            bit += 1
        else:
            out.append(_BASE32[ch])
            bit, ch = 0, 0
    return "".join(out)


def geohash_decode(gh: str) -> tuple[float, float, float, float]:
    """Return (lat, lng, lat_error, lng_error) for the centre of a geohash cell."""
    lat_range, lng_range, even = [-90.0, 90.0], [-180.0, 180.0], True
    for c in gh:
        cd = _BASE32.index(c)
        for mask in (16, 8, 4, 2, 1):
            rng = lng_range if even else lat_range
            mid = (rng[0] + rng[1]) / 2
            if cd & mask:
                rng[0] = mid
            else:
                rng[1] = mid
            even = not even
    lat = (lat_range[0] + lat_range[1]) / 2
    lng = (lng_range[0] + lng_range[1]) / 2
    return lat, lng, (lat_range[1] - lat_range[0]) / 2, (lng_range[1] - lng_range[0]) / 2


def geohash_neighbors(gh: str) -> list[str]:
    """The cell itself plus its 8 neighbours (same precision)."""
    lat, lng, lat_err, lng_err = geohash_decode(gh)
    cells = []
    for dlat in (-2 * lat_err, 0.0, 2 * lat_err):
        for dlng in (-2 * lng_err, 0.0, 2 * lng_err):
            nlat = max(-89.999999, min(89.999999, lat + dlat))
            nlng = ((lng + dlng + 180) % 360) - 180
            cells.append(geohash_encode(nlat, nlng, len(gh)))
    return sorted(set(cells))


def precision_for_radius_km(radius_km: float) -> int:
    """Pick the longest geohash precision whose cell (plus neighbours) covers the radius."""
    # Approximate cell heights in km for precisions 1..7.
    heights = {1: 4992.6, 2: 624.1, 3: 156.0, 4: 19.5, 5: 4.9, 6: 0.61, 7: 0.153}
    for precision in range(7, 0, -1):
        if heights[precision] >= radius_km:
            return precision
    return 1


def proximity_prefixes(center: GeoPoint, radius_km: float) -> list[str]:
    precision = precision_for_radius_km(radius_km)
    return geohash_neighbors(geohash_encode(center.lat, center.lng, precision))
