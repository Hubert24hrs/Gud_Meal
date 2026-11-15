"""Browse categories for each service (the round "bubbles" under the search bar on the Food and Beauty pages).

A merchant belongs to a category when one of its cuisines/categories (case-insensitive) is in the category's
set. "promotions" is special: merchants with an active merchant-specific voucher.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class BrowseCategory:
    id: str
    name: str
    emoji: str
    matches: frozenset[str] = field(default_factory=frozenset)


PROMOTIONS = "promotions"

FOOD_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory(
        "local",
        "Local food",
        "🍲",
        frozenset(
            {
                "nigerian",
                "yoruba",
                "igbo",
                "efik",
                "northern nigerian",
                "rice dishes",
                "swallow",
                "soups",
                "native",
            }
        ),
    ),
    BrowseCategory(
        "international",
        "International",
        "🌍",
        frozenset(
            {"fast food", "shawarma", "pizza", "burgers", "chinese", "italian", "lebanese", "continental"}
        ),
    ),
    BrowseCategory(
        "snacks", "Snacks", "🥟", frozenset({"snacks", "party food", "small chops", "pastries", "bakery"})
    ),
    BrowseCategory("grills", "Grills & suya", "🍢", frozenset({"grills", "suya", "barbecue", "seafood"})),
    BrowseCategory("healthy", "Healthy", "🥗", frozenset({"healthy", "vegetarian", "salads"})),
    BrowseCategory("drinks", "Drinks", "🥤", frozenset({"drinks", "smoothies", "juice", "zobo"})),
)

BEAUTY_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory("skincare", "Skincare", "🧴", frozenset({"skincare", "face care", "sun care"})),
    BrowseCategory("bodycare", "Body care", "🧼", frozenset({"body care", "bath", "natural oils"})),
    BrowseCategory("haircare", "Hair care", "💇🏾‍♀️", frozenset({"hair care", "natural hair", "wigs"})),
    BrowseCategory("makeup", "Make-up", "💄", frozenset({"make-up", "makeup", "cosmetics"})),
    BrowseCategory("fragrance", "Fragrance", "🌸", frozenset({"fragrance", "perfume", "perfume oils"})),
    BrowseCategory("men", "Men's grooming", "🧔🏾", frozenset({"men's grooming", "beard care"})),
)

CATEGORIES_BY_VERTICAL: dict[str, tuple[BrowseCategory, ...]] = {
    "food": FOOD_CATEGORIES,
    "beauty": BEAUTY_CATEGORIES,
}


def category_matches(category: BrowseCategory, cuisines: list[str]) -> bool:
    return any(c.lower() in category.matches for c in cuisines)


def find_category(vertical: str, category_id: str) -> BrowseCategory | None:
    return next((c for c in CATEGORIES_BY_VERTICAL.get(vertical, ()) if c.id == category_id), None)
