"""Authenticated customer endpoints: profile, quotes, orders, payments, reviews, support, meal plans."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Header, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from ...domain.models import CartLine, DeliveryAddress, QuoteRequest
from ...errors import NotFound
from ...services.engagement import (
    MealPlanInput,
    ProfileUpdate,
    RestaurantApplicationInput,
    ReviewInput,
    RiderApplicationInput,
    TicketInput,
)
from ..deps import Ctr, CurrentPrincipal, limit, run_idempotent
from ..serializers import order_view, quote_view

router = APIRouter(prefix="/v1", tags=["customer"])
IdemKey = Annotated[str | None, Header(alias="Idempotency-Key")]


class CreateOrderInput(BaseModel):
    quote_id: str
    contact_phone: str | None = Field(default=None, max_length=20)
    channel: Literal["app", "web", "ai_agent"] = "app"


class CheckoutInput(BaseModel):
    provider: Literal["paystack", "flutterwave", "local_sandbox"] | None = None


class ReasonInput(BaseModel):
    reason: str | None = Field(default=None, max_length=500)


class VerifyInput(BaseModel):
    reference: str = Field(min_length=6, max_length=100)


class FavouriteInput(BaseModel):
    favourite: bool


class DeviceInput(BaseModel):
    token: str = Field(min_length=10, max_length=4096)
    platform: Literal["android", "ios", "web"]


class ReorderInput(BaseModel):
    delivery_address: DeliveryAddress | None = None


# ---------------------------------------------------------------- identity & profile ------------
@router.get("/me")
async def me(principal: CurrentPrincipal) -> dict[str, Any]:
    return {
        "uid": principal.uid,
        "email": principal.email,
        "phone": principal.phone,
        "name": principal.name,
        "roles": sorted(principal.roles),
        "restaurant_roles": dict(principal.restaurant_roles),
        "permissions": sorted(p.value for p in principal.permissions()),
    }


@router.get("/me/profile")
async def get_profile(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.get(principal)


@router.patch("/me/profile")
async def update_profile(data: ProfileUpdate, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.update(principal, data)


@router.get("/me/addresses")
async def list_addresses(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.addresses(principal)


@router.post("/me/addresses", status_code=201)
async def add_address(data: DeliveryAddress, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.save_address(principal, data)


@router.put("/me/addresses/{address_id}")
async def update_address(address_id: str, data: DeliveryAddress, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.save_address(principal, data, address_id)


@router.delete("/me/addresses/{address_id}", status_code=204)
async def delete_address(address_id: str, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.profiles.delete_address(principal, address_id)


@router.put("/me/favourites/{restaurant_id}")
async def set_favourite(restaurant_id: str, data: FavouriteInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.toggle_favourite(principal, restaurant_id, data.favourite)


@router.post("/me/devices", status_code=204)
async def register_device(data: DeviceInput, c: Ctr, principal: CurrentPrincipal) -> None:
    await c.profiles.register_device(principal, data.token, data.platform)


@router.get("/me/export")
async def export_data(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.profiles.export(principal, c.orders)


@router.get("/me/notifications")
async def notifications(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.repos.notifications.find(
        where=[("recipient_uid", "==", principal.uid)], order_by=[("created_at", "desc")], limit=50
    )


# ---------------------------------------------------------------- quotes & orders ---------------
@router.post("/quotes", status_code=201, dependencies=[Depends(limit("quote"))])
async def create_quote(req: QuoteRequest, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return quote_view(await c.quotes.create_quote(principal, req))


@router.get("/quotes/{quote_id}")
async def get_quote(quote_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return quote_view(await c.quotes.get_quote(principal, quote_id))


@router.post("/orders", status_code=201, dependencies=[Depends(limit("order_create"))])
async def create_order(
    data: CreateOrderInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        order = await c.orders.create_from_quote(
            principal, data.quote_id, channel=data.channel, contact_phone=data.contact_phone
        )
        return order_view(order, principal)

    return await run_idempotent(
        c,
        scope=f"orders.create:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.get("/orders")
async def my_orders(
    c: Ctr, principal: CurrentPrincipal, limit_: Annotated[int, Query(alias="limit", ge=1, le=100)] = 20
) -> list[dict[str, Any]]:
    return [order_view(o, principal) for o in await c.orders.list_for_customer(principal.uid, limit_)]


@router.get("/orders/{order_id}")
async def get_order(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return order_view(await c.orders.get_for(principal, order_id), principal)


@router.get("/orders/{order_id}/events")
async def order_events(order_id: str, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.orders.events(principal, order_id)


@router.get("/orders/{order_id}/codes")
async def order_codes(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.orders.customer_codes(principal, order_id)


@router.get("/orders/{order_id}/tracking")
async def order_tracking(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    order = await c.orders.get_for(principal, order_id)
    tracking = await c.repos.get_tracking(order_id) or {}
    return {
        "order_id": order.id,
        "status": order.status.value,
        "rider_name": order.rider_name,
        "rider_location": tracking.get("rider_location"),
        "eta_minutes": tracking.get("eta_minutes"),
        "updated_at": tracking.get("updated_at"),
        "estimated_delivery_at": order.estimated_delivery_at,
    }


@router.post("/orders/{order_id}/checkout", dependencies=[Depends(limit("checkout"))])
async def checkout(
    order_id: str, data: CheckoutInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.orders.checkout(
            principal, order_id, provider=data.provider, idempotency_key=str(idempotency_key)
        )

    return await run_idempotent(
        c, scope=f"orders.checkout:{order_id}", key=idempotency_key, payload=data.model_dump(), fn=run
    )


@router.post("/orders/{order_id}/cancel")
async def cancel_order(
    order_id: str, data: ReasonInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return order_view(await c.orders.cancel_by_customer(principal, order_id, data.reason), principal)


@router.post("/orders/{order_id}/dispute")
async def dispute_order(
    order_id: str, data: ReasonInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return order_view(
        await c.orders.dispute(principal, order_id, data.reason or "Customer dispute"), principal
    )


@router.post("/orders/{order_id}/review", status_code=201)
async def review_order(order_id: str, data: ReviewInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.reviews.create(principal, order_id, data)


@router.post("/orders/{order_id}/reorder", status_code=201, dependencies=[Depends(limit("quote"))])
async def reorder(order_id: str, data: ReorderInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    order = await c.orders.get(order_id)
    if order.customer_id != principal.uid:
        raise NotFound("Order not found")
    req = QuoteRequest(
        restaurant_id=order.restaurant_id,
        lines=[
            CartLine(item_id=ln.item_id, quantity=ln.quantity, selections=ln.selections, notes=ln.notes)
            for ln in order.lines
        ],
        fulfillment=order.fulfillment,
        delivery_address=data.delivery_address or order.delivery_address,
    )
    return quote_view(await c.quotes.create_quote(principal, req))


# ---------------------------------------------------------------- payments --------------------
@router.post("/payments/verify", dependencies=[Depends(limit("payment_verify"))])
async def verify_payment(data: VerifyInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    view = await c.payments.verify_for_customer(principal, data.reference)
    view.pop("authorization_url", None)
    return view


@router.get("/orders/{order_id}/payments")
async def order_payments(order_id: str, c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    order = await c.orders.get(order_id)
    if order.customer_id != principal.uid:
        raise NotFound("Order not found")
    return await c.payments.payments_for_order(order_id)


# ---------------------------------------------------------------- AI-facing helpers -----------
@router.post("/meal-plans", dependencies=[Depends(limit("meal_plan"))])
async def meal_plans(data: MealPlanInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.meal_plans.plan(principal, data)


# ---------------------------------------------------------------- support & onboarding --------
@router.post("/support/tickets", status_code=201, dependencies=[Depends(limit("support"))])
async def open_ticket(data: TicketInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.support.open(principal, data)


@router.get("/support/tickets")
async def my_tickets(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.support.mine(principal)


@router.post("/applications/restaurant", status_code=201, dependencies=[Depends(limit("application"))])
async def apply_restaurant(data: RestaurantApplicationInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.applications.submit(principal, "restaurant", data)


@router.post("/applications/rider", status_code=201, dependencies=[Depends(limit("application"))])
async def apply_rider(data: RiderApplicationInput, c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.applications.submit(principal, "rider", data)


@router.get("/applications/mine")
async def my_applications(c: Ctr, principal: CurrentPrincipal) -> Any:
    return await c.applications.mine(principal)
