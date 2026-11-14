"""Gud Meal Partner (restaurant dashboard) endpoints."""

from __future__ import annotations

from typing import Annotated, Any

from fastapi import APIRouter, Query
from pydantic import BaseModel, Field

from ...domain.order_state import OrderStatus
from ...services.catalog import ItemInput, OptionGroupInput, RestaurantSettingsInput
from ..deps import Ctr, CurrentPrincipal
from ..serializers import order_view

router = APIRouter(prefix="/v1/partner", tags=["partner"])


class AcceptInput(BaseModel):
    prep_minutes: int = Field(ge=1, le=180)


class RejectInput(BaseModel):
    reason: str = Field(min_length=3, max_length=300)


class CodeInput(BaseModel):
    code: str = Field(pattern=r"^\d{4}$")


class AvailabilityInput(BaseModel):
    available: bool


class AcceptingInput(BaseModel):
    accepting: bool


class CategoriesInput(BaseModel):
    names: list[str] = Field(min_length=1, max_length=40)


@router.get("/restaurants")
async def my_restaurants(c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    ids = list(principal.restaurant_roles)
    found = await c.repos.restaurants.get_many(ids)
    return [{"restaurant": found[i], "role": principal.restaurant_roles[i]} for i in ids if i in found]


@router.get("/restaurants/{restaurant_id}/menu")
async def menu(restaurant_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.catalog.menu_for_partner(principal, restaurant_id)


@router.put("/restaurants/{restaurant_id}/categories")
async def set_categories(
    restaurant_id: str, data: CategoriesInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.set_categories(principal, restaurant_id, data.names)


@router.post("/restaurants/{restaurant_id}/items", status_code=201)
async def create_item(restaurant_id: str, data: ItemInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.catalog.create_item(principal, restaurant_id, data)


@router.put("/restaurants/{restaurant_id}/items/{item_id}")
async def update_item(
    restaurant_id: str, item_id: str, data: ItemInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.update_item(principal, restaurant_id, item_id, data)


@router.patch("/restaurants/{restaurant_id}/items/{item_id}/availability")
async def item_availability(
    restaurant_id: str, item_id: str, data: AvailabilityInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.set_item_availability(principal, restaurant_id, item_id, data.available)


@router.delete("/restaurants/{restaurant_id}/items/{item_id}", status_code=204)
async def delete_item(restaurant_id: str, item_id: str, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.catalog.delete_item(principal, restaurant_id, item_id)


@router.post("/restaurants/{restaurant_id}/option-groups", status_code=201)
async def create_group(
    restaurant_id: str, data: OptionGroupInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.upsert_option_group(principal, restaurant_id, data)


@router.put("/restaurants/{restaurant_id}/option-groups/{group_id}")
async def update_group(
    restaurant_id: str, group_id: str, data: OptionGroupInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.upsert_option_group(principal, restaurant_id, data, group_id)


@router.patch("/restaurants/{restaurant_id}/settings")
async def update_settings(
    restaurant_id: str, data: RestaurantSettingsInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    return await c.catalog.update_settings(principal, restaurant_id, data)


@router.put("/restaurants/{restaurant_id}/accepting")
async def set_accepting(restaurant_id: str, data: AcceptingInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.catalog.set_accepting_orders(principal, restaurant_id, data.accepting)


@router.get("/restaurants/{restaurant_id}/orders")
async def restaurant_orders(
    restaurant_id: str,
    c: Ctr,
    principal: CurrentPrincipal,
    status: Annotated[list[OrderStatus] | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
) -> list[dict[str, Any]]:
    orders = await c.orders.list_for_restaurant(principal, restaurant_id, status, limit)
    return [order_view(o, principal) for o in orders]


async def _restaurant_order(c: Any, principal: Any, restaurant_id: str, order_id: str) -> None:
    order = await c.orders.get_for(principal, order_id)
    if order.restaurant_id != restaurant_id:
        from ...errors import NotFound

        raise NotFound("Order not found")


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/accept")
async def accept(
    restaurant_id: str, order_id: str, data: AcceptInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.accept(principal, order_id, data.prep_minutes), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/reject")
async def reject(
    restaurant_id: str, order_id: str, data: RejectInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.reject(principal, order_id, data.reason), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/preparing")
async def preparing(restaurant_id: str, order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.mark_preparing(principal, order_id), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/ready")
async def ready(restaurant_id: str, order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    return order_view(await c.orders.mark_ready(principal, order_id), principal)


@router.post("/restaurants/{restaurant_id}/orders/{order_id}/handover")
async def handover(
    restaurant_id: str, order_id: str, data: CodeInput, c: Ctr, principal: CurrentPrincipal
) -> Any:
    await _restaurant_order(c, principal, restaurant_id, order_id)
    c.rate_limiter.check(f"code:{principal.uid}", capacity=5, refill_per_second=0.02)
    return order_view(await c.orders.complete_pickup(principal, order_id, data.code), principal)


@router.get("/restaurants/{restaurant_id}/analytics")
async def analytics(
    restaurant_id: str, c: Ctr, principal: CurrentPrincipal, days: Annotated[int, Query(ge=1, le=90)] = 14
) -> Any:
    return await c.analytics.restaurant(principal, restaurant_id, days)


@router.get("/restaurants/{restaurant_id}/settlements")
async def settlements(restaurant_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.admin.list_settlements(principal, restaurant_id)
