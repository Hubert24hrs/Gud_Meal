"""Role-aware views of domain objects — each audience sees only what it needs."""

from __future__ import annotations

from typing import Any

from ..domain.models import Order, Quote
from ..domain.order_state import CUSTOMER_PROGRESS
from ..security.rbac import Permission, Principal


def _progress(order: Order) -> dict[str, Any]:
    step, label = CUSTOMER_PROGRESS[order.status]
    return {"step": step, "total_steps": 5, "label": label}


def order_view(order: Order, principal: Principal) -> dict[str, Any]:
    data = order.model_dump(mode="json")
    data["progress"] = _progress(order)
    if principal.can(Permission.ORDERS_READ_ALL):
        data["audience"] = "staff"
        return data
    if order.customer_id == principal.uid:
        data.pop("settlement", None)
        data["audience"] = "customer"
        return data
    if principal.can_on_restaurant(order.restaurant_id, "orders"):
        settlement = data.pop("settlement")
        data.pop("customer_phone", None)
        addr = data.get("delivery_address")
        if addr:
            data["delivery_address"] = {"area": addr.get("area"), "city": addr.get("city")}
        data["restaurant_earning_kobo"] = settlement["restaurant_earning_kobo"]
        data["commission_kobo"] = settlement["commission_kobo"]
        data["audience"] = "restaurant"
        return data
    if order.rider_id == principal.uid:
        return {
            "id": order.id,
            "short_code": order.short_code,
            "status": order.status.value,
            "progress": data["progress"],
            "fulfillment": order.fulfillment.value,
            "restaurant_name": order.restaurant_name,
            "restaurant_address": order.restaurant_address,
            "restaurant_location": data["restaurant_location"],
            "customer_name": order.customer_name,
            "delivery_address": data["delivery_address"],
            "items": [{"name": ln.name, "quantity": ln.quantity} for ln in order.lines],
            "rider_pay_kobo": order.settlement.rider_pay_kobo,
            "ready_at": data["ready_at"],
            "picked_up_at": data["picked_up_at"],
            "estimated_delivery_at": data["estimated_delivery_at"],
            "audience": "rider",
        }
    raise PermissionError("no view")  # callers must check access first


def quote_view(quote: Quote) -> dict[str, Any]:
    data = quote.model_dump(mode="json")
    data.pop("settlement", None)
    return data
