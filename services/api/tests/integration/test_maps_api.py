"""Maps in the API: address search, route-priced quotes, live tracking privacy (fake Google, no network)."""

from __future__ import annotations

import httpx

from conftest import ADDRESS, auth, idem
from gudmeal_api.domain.geo import geohash_decode, geohash_encode
from gudmeal_api.maps.google import GoogleMapsClient

RIDERS = {f"demo-rider-{n}": f"rider{n}" for n in range(1, 5)}


class FakeGoogle:
    """Answers like Google Maps Platform and counts calls per API."""

    def __init__(self, *, route_m: int = 10_000, route_s: int = 1500, fail: bool = False) -> None:
        self.route_m, self.route_s, self.fail = route_m, route_s, fail
        self.calls: list[str] = []

    def __call__(self, request: httpx.Request) -> httpx.Response:
        url = str(request.url)
        self.calls.append(url)
        if self.fail:
            return httpx.Response(503, json={"error": {"message": "backend error"}})
        if "computeRoutes" in url:
            return httpx.Response(
                200,
                json={
                    "routes": [
                        {
                            "distanceMeters": self.route_m,
                            "duration": f"{self.route_s}s",
                            "polyline": {"encodedPolyline": "abc"},
                        }
                    ]
                },
            )
        if "places:autocomplete" in url:
            return httpx.Response(
                200,
                json={
                    "suggestions": [
                        {
                            "placePrediction": {
                                "placeId": "ChIJ_admiralty",
                                "text": {"text": "12 Admiralty Way, Lekki Phase 1"},
                                "structuredFormat": {
                                    "mainText": {"text": "12 Admiralty Way"},
                                    "secondaryText": {"text": "Lekki Phase 1, Lagos"},
                                },
                            }
                        }
                    ]
                },
            )
        if "/v1/places/" in url:
            return httpx.Response(
                200,
                json={
                    "id": "ChIJ_admiralty",
                    "formattedAddress": "12 Admiralty Way, Lekki Phase 1, Lagos, Nigeria",
                    "location": {"latitude": 6.4479, "longitude": 3.4721},
                    "types": ["street_address"],
                    "addressComponents": [
                        {"longText": "Lekki Phase 1", "shortText": "Lekki Phase 1", "types": ["neighborhood"]}
                    ],
                },
            )
        return httpx.Response(404, json={"error": {"message": "unexpected"}})

    def count(self, fragment: str) -> int:
        return sum(fragment in u for u in self.calls)


def use_google(container, fake: FakeGoogle) -> FakeGoogle:
    container.maps.google = GoogleMapsClient(
        "test-key", httpx.AsyncClient(transport=httpx.MockTransport(fake))
    )
    return fake


# ------------------------------------------------------------------------------------- places
async def test_places_need_sign_in_and_fall_back_without_a_key(client):
    assert (await client.get("/v1/places/autocomplete", params={"q": "lekki"})).status_code == 401

    r = await client.get(
        "/v1/places/autocomplete", params={"q": "lekki", "session": "s-1"}, headers=auth("customer")
    )
    body = r.json()
    assert r.status_code == 200 and body["provider"] == "local"
    first = body["suggestions"][0]
    assert first["title"] == "Lekki Phase 1" and first["source"] == "local"

    d = (
        await client.get(
            "/v1/places/details", params={"place_id": first["place_id"]}, headers=auth("customer")
        )
    ).json()
    assert d["serviceable"] and d["city"] == "lagos" and d["place"]["precision"] == "area"

    rev = await client.get(
        "/v1/places/reverse", params={"lat": 6.5100, "lng": 3.3720}, headers=auth("customer")
    )
    assert rev.json()["place"]["formatted_address"] == "Near Yaba, Lagos" and rev.json()["serviceable"]
    far = await client.get(
        "/v1/places/reverse", params={"lat": 9.0765, "lng": 7.3986}, headers=auth("customer")
    )
    assert far.status_code == 404  # Abuja: not a city we serve

    bad = await client.get(
        "/v1/places/autocomplete", params={"q": "lekki", "session": "no spaces!"}, headers=auth("customer")
    )
    assert bad.status_code == 422


async def test_places_use_google_when_configured_and_status_is_staff_only(client, container):
    fake = use_google(container, FakeGoogle())
    r = await client.get(
        "/v1/places/autocomplete",
        params={"q": "12 admiralty", "session": "s-2", "lat": 6.44, "lng": 3.47},
        headers=auth("customer"),
    )
    assert r.json()["provider"] == "google" and r.json()["suggestions"][0]["place_id"] == "ChIJ_admiralty"
    d = (
        await client.get(
            "/v1/places/details",
            params={"place_id": "ChIJ_admiralty", "session": "s-2"},
            headers=auth("customer"),
        )
    ).json()
    assert d["place"]["precision"] == "rooftop" and d["place"]["area"] == "Lekki Phase 1" and d["serviceable"]
    assert fake.count("places:autocomplete") == 1 and fake.count("/v1/places/ChIJ") == 1

    assert (await client.get("/v1/admin/maps/status", headers=auth("customer"))).status_code == 403
    status = (await client.get("/v1/admin/maps/status", headers=auth("admin"))).json()
    assert status["provider"] == "google" and status["requests_today"] == 2


# ------------------------------------------------------------------------------------- pricing
async def test_quotes_are_priced_on_the_measured_road_and_orders_reuse_it(flow, client, container):
    estimate = await flow.quote()
    assert estimate["route_source"] == "estimate"

    fake = use_google(container, FakeGoogle(route_m=10_000, route_s=1500))
    quote = await flow.quote()
    assert quote["route_source"] == "google" and quote["road_distance_km"] == 10.0
    # ₦500 base + ₦150/km x 10 km = ₦2,000 (Lekki zone has no surge); estimate priced the straight line instead
    assert quote["breakdown"]["delivery_fee_kobo"] == 200_000
    assert quote["breakdown"]["delivery_fee_kobo"] != estimate["breakdown"]["delivery_fee_kobo"]
    routes_before = fake.count("computeRoutes")

    fake.route_m = 14_000  # traffic changes the road between quote and order: the customer pays what they saw
    r = await client.post(
        "/v1/orders", json={"quote_id": quote["id"]}, headers={**auth("customer"), **idem()}
    )
    assert r.status_code == 201, r.text
    assert fake.count("computeRoutes") == routes_before, "the order reuses the quote's kilometres"


async def test_google_outage_falls_back_to_the_estimate_price(flow, container):
    keyless = await flow.quote()
    use_google(container, FakeGoogle(fail=True))
    outage = await flow.quote()
    assert outage["route_source"] == "estimate"
    assert outage["breakdown"] == keyless["breakdown"], "same price as before Maps"


# ------------------------------------------------------------------------------------- tracking
async def _assigned(flow, client, container) -> tuple[dict, str, str]:
    order = await flow.paid_order()
    r = await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/accept",
        json={"prep_minutes": 15},
        headers=auth("kitchen"),
    )
    assert r.status_code == 200, r.text
    offer = (await container.repos.assignments.find(where=[("order_id", "==", order["id"])]))[0]
    rider = RIDERS[offer.rider_id]
    assert (await client.post(f"/v1/rider/offers/{offer.id}/accept", headers=auth(rider))).status_code == 200
    return order, rider, offer.rider_id


async def test_rider_location_privacy_and_live_tracking(flow, client, container):
    # Offline riders are not tracked at all.
    await client.put("/v1/rider/availability", json={"online": False}, headers=auth("rider4"))
    r = await client.post("/v1/rider/location", json={"lat": 6.4401, "lng": 3.4602}, headers=auth("rider4"))
    assert r.status_code == 409

    # Online but idle: only a coarse cell is kept, never the exact fix.
    await client.put("/v1/rider/availability", json={"online": True}, headers=auth("rider4"))
    assert (
        await client.post("/v1/rider/location", json={"lat": 6.44013, "lng": 3.46027}, headers=auth("rider4"))
    ).status_code == 204
    idle = await container.repos.riders.get("demo-rider-4")
    cell_lat, cell_lng, _, _ = geohash_decode(geohash_encode(6.44013, 3.46027, 6))
    assert (idle.last_location.lat, idle.last_location.lng) == (round(cell_lat, 5), round(cell_lng, 5))
    assert (idle.last_location.lat, idle.last_location.lng) != (6.44013, 3.46027)

    # On a delivery: precise position and an ETA for the customer, then nothing once delivered.
    order, rider, _ = await _assigned(flow, client, container)
    await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/ready", headers=auth("owner")
    )
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    assert (
        await client.post("/v1/rider/location", json={"lat": 6.443, "lng": 3.465}, headers=auth(rider))
    ).status_code == 204
    t = (await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth("customer"))).json()
    assert t["rider_location"] == {"lat": 6.443, "lng": 3.465}
    assert t["eta_minutes"] >= 1 and t["eta_source"] == "estimate"
    assert t["pickup_location"] and t["dropoff_location"] == ADDRESS["location"]

    codes = (await client.get(f"/v1/orders/{order['id']}/codes", headers=auth("customer"))).json()
    await client.post(f"/v1/rider/deliveries/{order['id']}/in-transit", headers=auth(rider))
    r = await client.post(
        f"/v1/rider/deliveries/{order['id']}/deliver",
        json={"code": codes["delivery_code"]},
        headers=auth(rider),
    )
    assert r.status_code == 200, r.text
    after = (await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth("customer"))).json()
    assert (
        after["rider_location"] is None and after["route_polyline"] is None and after["eta_minutes"] is None
    )
    stored = await container.repos.get_tracking(order["id"])
    assert stored["rider_location"] is None and stored["active"] is False


async def test_live_eta_uses_routes_but_not_on_every_ping(flow, client, container):
    fake = use_google(container, FakeGoogle(route_m=6_000, route_s=900))
    order, rider, _ = await _assigned(flow, client, container)
    await client.post(
        f"/v1/partner/restaurants/r-jollof-junction/orders/{order['id']}/ready", headers=auth("owner")
    )
    await client.post(f"/v1/rider/deliveries/{order['id']}/pickup", headers=auth(rider))
    before = fake.count("computeRoutes")
    for lat in (6.4430, 6.4436, 6.4442):  # three pings a few seconds apart
        await client.post("/v1/rider/location", json={"lat": lat, "lng": 3.465}, headers=auth(rider))
    assert fake.count("computeRoutes") - before == 1, "re-measured at most every 90 seconds"
    t = (await client.get(f"/v1/orders/{order['id']}/tracking", headers=auth("customer"))).json()
    assert t["eta_source"] == "google" and t["eta_minutes"] == 15 and t["route_polyline"] == "abc"


# ------------------------------------------------------------------------------------- kitchens & ops
async def test_delivery_estimates_compare_kitchens_for_one_address(client, container):
    keyless = (
        await client.get(
            "/v1/delivery/estimates",
            params={"restaurant_ids": "r-jollof-junction,r-suya-lane,r-nope", "lat": 6.4410, "lng": 3.4600},
            headers=auth("customer"),
        )
    ).json()
    assert keyless["provider"] == "local"
    assert [e["restaurant_id"] for e in keyless["estimates"]] == ["r-jollof-junction", "r-suya-lane"]
    assert all(
        e["source"] == "estimate" and e["eta_minutes"] > e["travel_minutes"] for e in keyless["estimates"]
    )

    fake = use_google(container, FakeGoogle())
    fake_matrix = httpx.Response(
        200,
        json=[
            {
                "originIndex": 0,
                "destinationIndex": 0,
                "distanceMeters": 3000,
                "duration": "600s",
                "condition": "ROUTE_EXISTS",
            },
            {
                "originIndex": 1,
                "destinationIndex": 0,
                "distanceMeters": 9000,
                "duration": "1800s",
                "condition": "ROUTE_EXISTS",
            },
        ],
    )
    original = fake.__call__

    def with_matrix(request):
        return fake_matrix if "computeRouteMatrix" in str(request.url) else original(request)

    container.maps.google = GoogleMapsClient(
        "test-key", httpx.AsyncClient(transport=httpx.MockTransport(with_matrix))
    )
    measured = (
        await client.get(
            "/v1/delivery/estimates",
            params={"restaurant_ids": "r-jollof-junction,r-suya-lane", "lat": 6.4410, "lng": 3.4600},
            headers=auth("customer"),
        )
    ).json()["estimates"]
    assert [(e["road_distance_km"], e["travel_minutes"], e["source"]) for e in measured] == [
        (3.0, 10, "google"),
        (9.0, 30, "google"),
    ]
    assert measured[0]["delivery_fee_kobo"] < measured[1]["delivery_fee_kobo"]


async def test_partners_manage_their_pin_with_validation_and_audit(client, container):
    path = "/v1/partner/restaurants/r-jollof-junction/location"
    assert (await client.get(path, headers=auth("customer"))).status_code == 403
    current = (await client.get(path, headers=auth("owner"))).json()
    assert current["in_service_area"] and current["delivery_radius_km"] > 0

    small_move = {"address": "14 Admiralty Way, Lekki Phase 1", "location": {"lat": 6.4490, "lng": 3.4730}}
    r = await client.put(path, json=small_move, headers=auth("owner"))
    assert r.status_code == 200, r.text
    assert r.json()["location"] == {"lat": 6.4490, "lng": 3.4730}
    stored = await container.repos.restaurants.get("r-jollof-junction")
    assert stored.address.startswith("14 Admiralty Way") and stored.geohash == geohash_encode(
        6.4490, 3.4730, 9
    )

    far = {"address": "4 Herbert Macaulay Way, Yaba", "location": {"lat": 6.5095, "lng": 3.3711}}
    r = await client.put(path, json=far, headers=auth("owner"))
    assert r.status_code == 403 and "2 km" in r.json()["error"]["message"]
    radius = {**small_move, "delivery_radius_km": 20}
    assert (await client.put(path, json=radius, headers=auth("owner"))).status_code == 403
    assert (await client.put(path, json=far, headers=auth("admin"))).status_code == 200, (
        "staff can move kitchens"
    )

    outside = {"address": "Wuse 2, Abuja", "location": {"lat": 9.0765, "lng": 7.3986}}
    assert (await client.put(path, json=outside, headers=auth("admin"))).status_code == 422

    # With Google: a pin far from the street address is refused unless the partner confirms it.
    use_google(container, FakeGoogle())
    container.maps.google._send = _geocode_to(6.4479, 3.4721, container.maps.google._send)
    mismatch = {"address": "12 Admiralty Way, Lekki Phase 1", "location": {"lat": 6.5000, "lng": 3.3900}}
    r = await client.put(path, json=mismatch, headers=auth("admin"))
    assert r.status_code == 422 and r.json()["error"]["details"]["suggested_location"] == {
        "lat": 6.4479,
        "lng": 3.4721,
    }
    assert (
        await client.put(path, json={**mismatch, "confirm_pin": True}, headers=auth("admin"))
    ).status_code == 200

    events = (
        await client.get(
            "/v1/admin/audit", params={"resource_id": "r-jollof-junction"}, headers=auth("admin")
        )
    ).json()
    assert sum(e["action"] == "restaurant.location_updated" for e in events) == 3


def _geocode_to(lat: float, lng: float, send):
    async def fake_send(method, url, **kw):
        if "geocode/json" in url:
            return {
                "status": "OK",
                "results": [
                    {
                        "formatted_address": "12 Admiralty Way, Lekki Phase 1, Lagos, Nigeria",
                        "geometry": {"location": {"lat": lat, "lng": lng}, "location_type": "ROOFTOP"},
                        "types": ["street_address"],
                        "address_components": [],
                    }
                ],
            }
        return await send(method, url, **kw)

    return fake_send


async def test_live_rider_map_is_for_operations_staff(client):
    await client.put("/v1/rider/availability", json={"online": True}, headers=auth("rider2"))
    await client.post("/v1/rider/location", json={"lat": 6.43011, "lng": 3.42022}, headers=auth("rider2"))
    assert (await client.get("/v1/admin/riders/live", headers=auth("customer"))).status_code == 403
    live = (await client.get("/v1/admin/riders/live", headers=auth("admin"))).json()
    me = next(x for x in live if x["rider_id"] == "demo-rider-2")
    assert me["precision"] == "coarse" and not me["on_delivery"]
    assert me["location"] != {"lat": 6.43011, "lng": 3.42022}
