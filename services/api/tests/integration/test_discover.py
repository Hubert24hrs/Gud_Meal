"""Discover tab feed: most loved dishes, new kitchens and top-rated kitchens."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from conftest import LEKKI
from gudmeal_api.domain.models import MenuItem
from gudmeal_api.services.discover import NEW_KITCHEN_DAYS, plate_art


async def _age_kitchens(container, *, new: set[str]) -> None:
    """Make the given kitchens 10 days old and every other kitchen two years old (tests must not depend on today)."""
    now = datetime.now(UTC)
    for r in await container.repos.restaurants.find():
        joined = now - timedelta(days=10) if r.id in new else now - timedelta(days=730)
        await container.repos.restaurants.update(r.id, {"created_at": joined})


def _section(feed: dict, section_id: str) -> dict:
    return next(s for s in feed["sections"] if s["id"] == section_id)


async def test_most_loved_ranks_signature_dishes_by_popularity(client, container):
    await _age_kitchens(container, new=set())
    r = await client.get("/v1/discover/dishes", params={"city": "lagos"})
    assert r.status_code == 200, r.text
    feed = r.json()
    assert feed["city"] == "lagos"
    assert [s["id"] for s in feed["sections"]] == ["most_loved", "top_rated"]  # nothing is new

    loved = _section(feed, "most_loved")["dishes"]
    assert 1 <= len(loved) <= 6
    assert [d["eyebrow"] for d in loved] == [f"#{n} Most loved dish" for n in range(1, len(loved) + 1)]
    likes = [d["likes"] for d in loved]
    assert likes == sorted(likes, reverse=True)
    assert len({d["restaurant_id"] for d in loved}) == len(loved), "one dish per kitchen"
    assert all(d["city"] == "lagos" for d in loved)
    assert all(d["kind"] not in {"drink", "extra", "product"} for d in loved)

    # The top dish is the most ordered hero dish of any Lagos kitchen, priced exactly as on the menu.
    best = loved[0]
    items = await container.repos.list_items(best["restaurant_id"])
    item = next(i for i in items if i.id == best["item_id"])
    assert best["price_kobo"] == item.price_kobo and best["likes"] == item.popularity
    assert best["art"] != "" and best["rating"] > 0


async def test_new_kitchens_use_join_date_and_fill_the_carousel(client, container):
    await _age_kitchens(container, new={"r-kiln-and-crust"})
    feed = (await client.get("/v1/discover/dishes", params={"city": "lagos"})).json()
    fresh = _section(feed, "new_kitchens")
    assert fresh["dishes"], fresh
    assert {d["restaurant_id"] for d in fresh["dishes"]} == {"r-kiln-and-crust"}
    assert len(fresh["dishes"]) == 2, "a single newcomer headlines two dishes"
    assert all(d["is_new_kitchen"] and d["eyebrow"].startswith("New kitchen") for d in fresh["dishes"])
    assert all(d["art"] == "pizza" for d in fresh["dishes"])
    assert str(NEW_KITCHEN_DAYS // 30) in fresh["subtitle"]

    # Kitchens that joined long ago never appear as new.
    old = _section(feed, "most_loved")["dishes"]
    assert all(not d["is_new_kitchen"] for d in old if d["restaurant_id"] != "r-kiln-and-crust")


async def test_top_rated_kitchens_and_city_filter(client, container):
    await _age_kitchens(container, new=set())
    lagos = (await client.get("/v1/discover/dishes", params={"city": "lagos", "limit": 3})).json()
    top = _section(lagos, "top_rated")["dishes"]
    assert len(top) == 3
    ratings = [d["rating"] for d in top]
    assert ratings == sorted(ratings, reverse=True)
    assert all(d["eyebrow"].startswith("Top-rated kitchen") for d in top)

    enugu = (await client.get("/v1/discover/dishes", params={"city": "enugu"})).json()
    assert enugu["sections"]
    assert all(d["city"] == "enugu" for s in enugu["sections"] for d in s["dishes"])


async def test_location_adds_delivery_fee_and_eta(client, container):
    await _age_kitchens(container, new=set())
    feed = (await client.get("/v1/discover/dishes", params={"city": "lagos", **LEKKI})).json()
    dishes = [d for s in feed["sections"] for d in s["dishes"]]
    assert dishes
    assert all(d["distance_km"] is not None and d["eta_minutes"] for d in dishes)
    assert any(d["delivery_fee_kobo"] for d in dishes if d["delivers_to_location"])


async def test_sold_out_signature_dish_steps_aside(client, container):
    await _age_kitchens(container, new=set())
    before = (await client.get("/v1/discover/dishes", params={"city": "lagos"})).json()
    top = _section(before, "most_loved")["dishes"][0]
    await container.repos.items.update(top["item_id"], {"is_available": False})

    after = (await client.get("/v1/discover/dishes", params={"city": "lagos", "limit": 12})).json()
    same_kitchen = [
        d for d in _section(after, "most_loved")["dishes"] if d["restaurant_id"] == top["restaurant_id"]
    ]
    assert same_kitchen and same_kitchen[0]["item_id"] != top["item_id"]
    assert same_kitchen[0]["is_available"]


@pytest.mark.parametrize(
    ("params", "status"),
    [({"city": "abuja"}, 422), ({"lat": 6.4}, 422), ({"limit": 0}, 422), ({"limit": 13}, 422)],
)
async def test_invalid_requests(client, params, status):
    r = await client.get("/v1/discover/dishes", params=params)
    assert r.status_code == status, r.text


@pytest.mark.parametrize(
    ("name", "family"),
    [
        ("Party Jollof Rice", "rice"),
        ("Ofada rice & ayamase", "rice"),
        ("Beef Suya (250g)", "skewers"),
        ("Asun (spicy goat)", "skewers"),
        ("Amala, Gbegiri & Ewedu", "soup_swallow"),
        ("Ofe onugbu (bitterleaf soup)", "soup_swallow"),
        ("Catfish Pepper Soup", "broth"),
        ("Suya pizza (medium)", "pizza"),
        ("Chicken Shawarma", "wrap"),
        ("Small Chops Platter (serves 2)", "bites"),
        ("Jollof Quinoa Bowl", "bowl"),
        ("Abacha with ugba & fried fish", "bowl"),
        ("Whole Grilled Croaker (serves 2)", "grill"),
        ("Chapman", "plate"),
    ],
)
def test_plate_art_families(name, family):
    item = MenuItem(id="i", restaurant_id="r", category_id="c", name=name, price_kobo=100)
    assert plate_art(item) == family
