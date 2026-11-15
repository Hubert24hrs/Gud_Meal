"""Maps: Google Maps Platform client (mocked HTTP, documented shapes), keyless fallback, caching and caps."""

from __future__ import annotations

import json
import math

import httpx
import pytest

from gudmeal_api.domain.geo import GeoPoint, haversine_km
from gudmeal_api.domain.pricing import PricingConfig
from gudmeal_api.maps import MapsError, MapsService, served_city
from gudmeal_api.maps.google import GoogleMapsClient

KEY = "test-server-key"
LEKKI = GeoPoint(lat=6.4478, lng=3.4723)
YABA = GeoPoint(lat=6.5095, lng=3.3711)
CFG = PricingConfig()


class Recorder:
    """httpx transport that answers like Google and records every request."""

    def __init__(self, routes: dict[str, httpx.Response] | None = None, fail: int | None = None) -> None:
        self.routes = routes or {}
        self.fail = fail
        self.requests: list[httpx.Request] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        if self.fail:
            return httpx.Response(
                self.fail,
                json={
                    "error": {"code": self.fail, "message": "API key not valid", "status": "INVALID_ARGUMENT"}
                },
            )
        for fragment, response in self.routes.items():
            if fragment in str(request.url):
                return response
        return httpx.Response(404, json={"error": {"message": "unexpected"}})


def client(rec: Recorder, **kw) -> GoogleMapsClient:
    return GoogleMapsClient(KEY, httpx.AsyncClient(transport=httpx.MockTransport(rec)), **kw)


AUTOCOMPLETE = {
    "suggestions": [
        {
            "placePrediction": {
                "place": "places/ChIJ_admiralty",
                "placeId": "ChIJ_admiralty",
                "text": {"text": "12 Admiralty Way, Lekki Phase 1, Lagos, Nigeria"},
                "structuredFormat": {
                    "mainText": {"text": "12 Admiralty Way"},
                    "secondaryText": {"text": "Lekki Phase 1, Lagos, Nigeria"},
                },
                "types": ["street_address"],
                "distanceMeters": 412,
            }
        },
        {"queryPrediction": {"text": {"text": "admiralty way restaurants"}}},
    ]
}
DETAILS = {
    "id": "ChIJ_admiralty",
    "formattedAddress": "12 Admiralty Way, Lekki Phase 1, Lagos 106104, Lagos, Nigeria",
    "location": {"latitude": 6.4479, "longitude": 3.4721},
    "types": ["street_address"],
    "addressComponents": [
        {"longText": "12", "shortText": "12", "types": ["street_number"]},
        {"longText": "Admiralty Way", "shortText": "Admiralty Way", "types": ["route"]},
        {"longText": "Lekki Phase 1", "shortText": "Lekki Phase 1", "types": ["neighborhood", "political"]},
        {"longText": "Lagos", "shortText": "Lagos", "types": ["locality", "political"]},
    ],
}
GEOCODE = {
    "status": "OK",
    "results": [
        {
            "formatted_address": "Herbert Macaulay Way, Yaba, Lagos 101245, Lagos, Nigeria",
            "geometry": {"location": {"lat": 6.5096, "lng": 3.3712}, "location_type": "GEOMETRIC_CENTER"},
            "place_id": "ChIJ_herbert",
            "types": ["route"],
            "address_components": [
                {
                    "long_name": "Herbert Macaulay Way",
                    "short_name": "Herbert Macaulay Way",
                    "types": ["route"],
                },
                {
                    "long_name": "Yaba",
                    "short_name": "Yaba",
                    "types": ["sublocality_level_1", "sublocality", "political"],
                },
            ],
        }
    ],
}
ROUTE = {
    "routes": [
        {"distanceMeters": 7300, "duration": "1260s", "polyline": {"encodedPolyline": "_p~iF~ps|U_ulLnnqC"}}
    ]
}
MATRIX = [
    {
        "originIndex": 1,
        "destinationIndex": 0,
        "status": {},
        "distanceMeters": 5200,
        "duration": "900s",
        "condition": "ROUTE_EXISTS",
    },
    {"originIndex": 0, "destinationIndex": 0, "status": {}, "condition": "ROUTE_NOT_FOUND"},
]


async def test_autocomplete_sends_session_bias_and_nigeria_only():
    rec = Recorder({"places:autocomplete": httpx.Response(200, json=AUTOCOMPLETE)})
    found = await client(rec).autocomplete("12 admiralty", session_token="sess-1", near=LEKKI)
    req = rec.requests[0]
    assert req.headers["X-Goog-Api-Key"] == KEY
    assert "key=" not in str(req.url), "Places (New) takes the key in a header, not the URL"
    body = json.loads(req.content)
    assert body["includedRegionCodes"] == ["ng"] and body["sessionToken"] == "sess-1"
    assert body["locationBias"]["circle"]["center"] == {"latitude": LEKKI.lat, "longitude": LEKKI.lng}
    assert body["origin"] == {"latitude": LEKKI.lat, "longitude": LEKKI.lng}
    assert len(found) == 1, "query predictions are not places"
    s = found[0]
    assert (s.place_id, s.title, s.subtitle, s.distance_m, s.source) == (
        "ChIJ_admiralty",
        "12 Admiralty Way",
        "Lekki Phase 1, Lagos, Nigeria",
        412,
        "google",
    )


async def test_place_details_uses_an_essentials_field_mask():
    rec = Recorder({"/v1/places/ChIJ_admiralty": httpx.Response(200, json=DETAILS)})
    place = await client(rec).place("ChIJ_admiralty", session_token="sess-1")
    req = rec.requests[0]
    assert req.headers["X-Goog-FieldMask"] == "id,formattedAddress,location,addressComponents,types"
    assert req.url.params["sessionToken"] == "sess-1"
    assert place.location == GeoPoint(lat=6.4479, lng=3.4721)
    assert (place.area, place.city, place.precision, place.source) == (
        "Lekki Phase 1",
        "lagos",
        "rooftop",
        "google",
    )


async def test_geocoding_forward_reverse_and_statuses():
    rec = Recorder({"geocode/json": httpx.Response(200, json=GEOCODE)})
    g = client(rec)
    found = await g.geocode("Herbert Macaulay Way, Yaba")
    params = rec.requests[0].url.params
    assert params["components"] == "country:NG" and params["region"] == "ng" and params["key"] == KEY
    assert (found.area, found.city, found.precision) == ("Yaba", "lagos", "street")

    await g.reverse_geocode(YABA)
    assert rec.requests[1].url.params["latlng"] == "6.509500,3.371100"

    none = Recorder({"geocode/json": httpx.Response(200, json={"status": "ZERO_RESULTS", "results": []})})
    assert await client(none).geocode("nowhere at all") is None
    denied = Recorder({"geocode/json": httpx.Response(200, json={"status": "REQUEST_DENIED", "results": []})})
    with pytest.raises(MapsError):
        await client(denied).geocode("Yaba")


async def test_routes_traffic_aware_with_minimal_field_mask():
    rec = Recorder({"computeRoutes": httpx.Response(200, json=ROUTE)})
    route = await client(rec).route(LEKKI, YABA)
    req = rec.requests[0]
    assert (
        req.headers["X-Goog-FieldMask"]
        == "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline"
    )
    body = json.loads(req.content)
    assert body["travelMode"] == "DRIVE" and body["routingPreference"] == "TRAFFIC_AWARE"
    assert body["origin"]["location"]["latLng"] == {"latitude": LEKKI.lat, "longitude": LEKKI.lng}
    assert (route.distance_km, route.duration_minutes, route.traffic_aware, route.source) == (
        7.3,
        21,
        True,
        "google",
    )
    assert route.polyline


async def test_route_matrix_maps_indices_and_missing_routes():
    rec = Recorder({"computeRouteMatrix": httpx.Response(200, json=MATRIX)})
    out = await client(rec, travel_mode="TWO_WHEELER").route_matrix([YABA, LEKKI], LEKKI)
    body = json.loads(rec.requests[0].content)
    assert body["travelMode"] == "TWO_WHEELER" and len(body["origins"]) == 2
    assert out[0] is None, "ROUTE_NOT_FOUND"
    assert (out[1].distance_km, out[1].duration_minutes) == (5.2, 15)


async def test_errors_raise_maps_error_without_leaking_the_key():
    rec = Recorder(fail=403)
    with pytest.raises(MapsError) as err:
        await client(rec).route(LEKKI, YABA)
    assert KEY not in str(err.value)

    async def boom(request):
        raise httpx.ConnectTimeout("timed out", request=request)

    slow = GoogleMapsClient(KEY, httpx.AsyncClient(transport=httpx.MockTransport(boom)))
    with pytest.raises(MapsError):
        await slow.autocomplete("lekki")


# ---------------------------------------------------------------------------------------- service
def test_served_city():
    assert served_city(LEKKI) == "lagos"
    assert served_city(GeoPoint(lat=6.45, lng=7.51)) == "enugu"
    assert served_city(GeoPoint(lat=9.0765, lng=7.3986)) is None  # Abuja


async def test_without_a_key_everything_uses_the_labelled_fallback():
    maps = MapsService(None)
    assert maps.provider == "local" and maps.status()["routes"] == "estimate"

    sugg = await maps.autocomplete("lekki", near=LEKKI)
    assert sugg and sugg[0].title == "Lekki Phase 1" and sugg[0].source == "local"
    place = await maps.place(sugg[0].place_id)
    assert place.city == "lagos" and place.precision == "area" and place.source == "local"

    rev = await maps.reverse(GeoPoint(lat=6.5100, lng=3.3720))
    assert rev.formatted_address == "Near Yaba, Lagos" and rev.precision == "approximate"
    assert rev.location == GeoPoint(lat=6.5100, lng=3.3720), "keeps the device's own fix"
    assert await maps.reverse(GeoPoint(lat=9.0765, lng=7.3986)) is None  # not near anywhere we serve

    est = await maps.route(LEKKI, YABA, CFG)
    km = haversine_km(LEKKI, YABA) * 1.35
    assert est.source == "estimate" and est.polyline is None
    assert est.distance_km == pytest.approx(km, abs=0.001)
    assert est.duration_minutes == math.ceil(km / 18 * 60)

    geo = await maps.geocode("4 Herbert Macaulay Way, Yaba")
    assert geo.area == "Yaba" and geo.source == "local"


async def test_google_failures_fall_back_to_estimates():
    maps = MapsService(client(Recorder(fail=500)))
    assert (await maps.route(LEKKI, YABA, CFG)).source == "estimate"
    assert (await maps.autocomplete("yaba"))[0].source == "local"
    assert (await maps.geocode("Yaba")).source == "local"
    assert await maps.place("ChIJ_unknown") is None


async def test_routes_and_places_are_cached_briefly():
    now = [0.0]
    rec = Recorder(
        {"computeRoutes": httpx.Response(200, json=ROUTE), "/v1/places/": httpx.Response(200, json=DETAILS)}
    )
    maps = MapsService(client(rec), clock=lambda: now[0])
    a = await maps.route(LEKKI, YABA, CFG)
    b = await maps.route(GeoPoint(lat=6.44781, lng=3.47231), YABA, CFG)  # a few metres away: same cache cell
    assert a == b and len(rec.requests) == 1
    now[0] += 301  # routes expire after five minutes (traffic changes)
    await maps.route(LEKKI, YABA, CFG)
    assert len(rec.requests) == 2

    await maps.place("ChIJ_admiralty")
    await maps.place("ChIJ_admiralty")
    assert len(rec.requests) == 3, "place coordinates are cached"


async def test_daily_cap_switches_to_estimates_and_resets_next_day():
    day = ["2026-11-15"]
    rec = Recorder({"computeRoutes": httpx.Response(200, json=ROUTE)})
    maps = MapsService(client(rec), daily_cap=2, today=lambda: day[0])
    await maps.route(LEKKI, YABA, CFG)
    await maps.route(YABA, LEKKI, CFG)
    third = await maps.route(LEKKI, GeoPoint(lat=6.43, lng=3.42), CFG)
    assert third.source == "estimate" and len(rec.requests) == 2
    assert maps.status()["requests_today"] == 2
    day[0] = "2026-11-16"
    assert (await maps.route(LEKKI, GeoPoint(lat=6.43, lng=3.42), CFG)).source == "google"


async def test_routes_to_many_kitchens_uses_one_matrix_call():
    rec = Recorder({"computeRouteMatrix": httpx.Response(200, json=MATRIX)})
    maps = MapsService(client(rec))
    out = await maps.routes_to([YABA, LEKKI], LEKKI, CFG)
    assert len(rec.requests) == 1
    assert out[0].source == "estimate", "no road route found: estimate, clearly labelled"
    assert out[1].source == "google" and out[1].distance_km == 5.2
