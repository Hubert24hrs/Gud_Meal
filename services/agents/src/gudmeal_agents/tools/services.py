"""Gudy's multi-service tools: what Gud Meal offers, order totals, Package Delivery, navigation, support contacts.

As everywhere else, tools never take identity or amount arguments: prices and totals come from the API.
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Any, Literal

from pydantic import Field

from ..api_client import ApiError
from .customer import EVERYONE, LAGOS, delivery_address, lagos_time, naira
from .registry import ToolArgs, ToolContext, ToolError, ToolOutput, ToolRegistry, ToolSpec

SERVICE_NAMES = {"food": "Food", "beauty": "Beauty & Skin care", "parcel": "Package Delivery"}

Screen = Literal[
    "home",
    "food",
    "beauty",
    "parcel",
    "discover",
    "orders",
    "support",
    "profile",
    "merchant",
    "order",
]
SCREEN_LABELS: dict[str, str] = {
    "home": "Go to Home",
    "food": "Open Food",
    "beauty": "Open Beauty & Skin care",
    "parcel": "Send a package",
    "discover": "Open Discover",
    "orders": "Open my orders",
    "support": "Open Support",
    "profile": "Open my profile",
    "merchant": "Open the store",
    "order": "Track this order",
}


class NoArgs(ToolArgs):
    pass


class OpenScreenArgs(ToolArgs):
    screen: Screen = Field(description="Which part of the app to open for the customer")
    merchant_id: str | None = Field(default=None, max_length=64, description="For screen='merchant'")
    order_id: str | None = Field(default=None, max_length=64, description="For screen='order'")
    category: str | None = Field(
        default=None, max_length=30, description="Optional browse category for food/beauty, e.g. 'local'"
    )


PHONE = r"^\+?[0-9 ]{7,20}$"


class ParcelQuoteArgs(ToolArgs):
    dropoff_address: str = Field(
        min_length=3, max_length=200, description="Street address of the recipient, with the neighbourhood"
    )
    recipient_name: str = Field(min_length=2, max_length=80)
    recipient_phone: str = Field(pattern=PHONE)
    pickup_address: str | None = Field(
        default=None,
        max_length=200,
        description="Where the rider collects the package. Omit to use the customer's saved address.",
    )
    sender_name: str | None = Field(default=None, max_length=80, description="Defaults to the customer")
    sender_phone: str | None = Field(default=None, pattern=PHONE, description="Defaults to the customer")
    size: Literal["small", "medium", "large"] = Field(
        default="small",
        description="small: documents, phones, shoes (up to 5 kg); medium: up to 10 kg; large: up to 20 kg",
    )
    category: Literal["documents", "clothing", "electronics", "food", "cosmetics", "household", "other"] = (
        "other"
    )
    description: str = Field(default="", max_length=200, description="What is inside, briefly")
    pickup_time: str | None = Field(
        default=None,
        description="Omit for now. Otherwise HH:MM (24h, Lagos time, today or tomorrow) or ISO-8601.",
    )


class QuoteIdArgs(ToolArgs):
    quote_id: str = Field(min_length=6, max_length=64)


# ------------------------------------------------------------------------------------------------
async def list_services(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    addr = ctx.artifacts.get("delivery_address") or {}
    city = (addr.get("city") or "").strip().lower() or None
    services = await ctx.api.get("/v1/services", city=city if city in ("lagos", "enugu") else None)
    data = [
        {
            "service": s["id"],
            "name": s["name"],
            "what_it_is": s["tagline"],
            "available": s["available"],
            **({"partners": s["merchants"]} if "merchants" in s else {}),
            **({"options": s["options"], "coming_soon": s["coming_soon"]} if s["id"] == "parcel" else {}),
        }
        for s in services
    ]
    return ToolOutput(
        {"services": data, "cities": ["Lagos", "Enugu"]},
        card={"type": "services", "services": [{"id": s["service"], "name": s["name"]} for s in data]},
    )


async def get_order_totals(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    s = await ctx.api.get("/v1/me/order-summary")
    by_service = {
        SERVICE_NAMES[k]: {"orders": v["orders"], "spent": naira(v["spent_kobo"])}
        for k, v in s["by_vertical"].items()
        if v["orders"]
    }
    data = {
        "paid_orders": s["orders_count"],
        "completed": s["completed_count"],
        "in_progress": s["in_progress_count"],
        "total_spent": naira(s["total_spent_kobo"]),
        "spent_this_month": naira(s["this_month_spent_kobo"]),
        "refunded": naira(s["refunded_kobo"]) if s["refunded_kobo"] else None,
        "by_service": by_service,
        "favourite": s["favourite_merchant"]["name"] if s.get("favourite_merchant") else None,
        "note": "Totals are net of refunds and computed by Gud Meal; quote them exactly.",
    }
    return ToolOutput(data, card={"type": "order_totals", **{k: v for k, v in data.items() if k != "note"}})


async def open_screen(args: OpenScreenArgs, ctx: ToolContext) -> ToolOutput:
    if args.screen == "merchant" and not args.merchant_id:
        raise ToolError("invalid_arguments", "merchant_id is required to open a store")
    if args.screen == "order" and not (args.order_id or ctx.artifacts.get("last_order_id")):
        raise ToolError("invalid_arguments", "order_id is required to open an order")
    params = {
        k: v
        for k, v in {
            "merchant_id": args.merchant_id,
            "order_id": args.order_id
            or (ctx.artifacts.get("last_order_id") if args.screen == "order" else None),
            "category": args.category,
        }.items()
        if v
    }
    card = {"type": "navigate", "screen": args.screen, "params": params, "label": SCREEN_LABELS[args.screen]}
    return ToolOutput({"shown_button": card["label"]}, card=card)


async def get_support_contacts(args: NoArgs, ctx: ToolContext) -> ToolOutput:
    support = (await ctx.api.get("/v1/config/public"))["support"]
    data = {
        "whatsapp": support["whatsapp"],
        "phone": support["phone"],
        "email": support["email"],
        "hours": support["hours"],
        "in_app": "Support tab → Chat with us (a person replies in the app)",
    }
    if support.get("placeholders"):
        data["note"] = "These contacts are not live yet; suggest the in-app Support tab or a support ticket."
    return ToolOutput(data, card={"type": "support_contacts", **data})


# ------------------------------------------------------------------------------------------------ parcels
async def _place(ctx: ToolContext, text: str) -> dict[str, Any]:
    try:
        return await ctx.api.get("/v1/places/resolve", q=text)
    except ApiError as exc:
        if exc.status == 404:
            raise ToolError(
                "unknown_area",
                f"I couldn't place '{text}'. Ask for the neighbourhood, e.g. 'Yaba' or 'Independence Layout'.",
            ) from exc
        raise


def _pickup_time(text: str | None, now: datetime) -> str | None:
    if not text:
        return None
    text = text.strip()
    m = re.fullmatch(r"([01]?\d|2[0-3]):([0-5]\d)", text)
    if m:
        local_now = now.astimezone(LAGOS)
        target = local_now.replace(hour=int(m.group(1)), minute=int(m.group(2)), second=0, microsecond=0)
        if target <= local_now:
            target += timedelta(days=1)  # "16:00" after 4pm means tomorrow
        return target.isoformat()
    try:
        dt = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ToolError(
            "invalid_arguments", "pickup_time must be HH:MM (24h, Lagos time) or ISO-8601"
        ) from exc
    return (dt if dt.tzinfo else dt.replace(tzinfo=LAGOS)).isoformat()


def _quote_summary(q: dict[str, Any]) -> dict[str, Any]:
    d, b = q["details"], q["breakdown"]
    return {
        "quote_id": q["id"],
        "from": f"{d['pickup']['line1']} ({d['pickup']['name']})",
        "to": f"{d['dropoff']['line1']} ({d['dropoff']['name']}, {d['dropoff']['phone']})",
        "size": d["size"],
        "distance_km": round(q["distance_km"], 1),
        "delivery_fee": naira(b["delivery_fee_kobo"]),
        "service_fee": naira(b["service_fee_kobo"]),
        "vat": naira(b["vat_kobo"]),
        "total": naira(b["total_kobo"]),
        "pickup": f"Scheduled for {lagos_time(q['scheduled_for'])}"
        if q.get("scheduled_for")
        else "As soon as possible",
        "estimated_delivery": lagos_time(q["estimated_delivery_at"]),
        "valid_until": lagos_time(q["expires_at"]),
    }


async def get_parcel_quote(args: ParcelQuoteArgs, ctx: ToolContext) -> ToolOutput:
    if args.pickup_address:
        place = await _place(ctx, args.pickup_address)
        pickup_loc = {"lat": place["lat"], "lng": place["lng"]}
        pickup_line, pickup_city = args.pickup_address, place["city"].title()
    else:
        saved = await delivery_address(ctx)
        pickup_loc, pickup_line = saved["location"], saved["line1"]
        pickup_city = saved.get("city") or "Lagos"
    sender_name, sender_phone = args.sender_name, args.sender_phone
    if not sender_name or not sender_phone:
        me = await ctx.api.get("/v1/me")  # the verified account's own name and phone
        sender_name = sender_name or me.get("name") or ctx.caller.name
        sender_phone = sender_phone or me.get("phone")
    if not sender_name or not sender_phone:
        raise ToolError("missing_sender", "Ask for the sender's name and phone number for the rider.")
    drop = await _place(ctx, args.dropoff_address)
    body = {
        "pickup": {
            "name": sender_name,
            "phone": sender_phone,
            "line1": pickup_line,
            "city": pickup_city,
            "location": pickup_loc,
        },
        "dropoff": {
            "name": args.recipient_name,
            "phone": args.recipient_phone,
            "line1": args.dropoff_address,
            "city": drop["city"].title(),
            "location": {"lat": drop["lat"], "lng": drop["lng"]},
        },
        "size": args.size,
        "category": args.category,
        "description": args.description,
        "scheduled_for": _pickup_time(args.pickup_time, ctx.now),
    }
    quote = await ctx.api.post("/v1/parcels/quotes", body)
    summary = _quote_summary(quote)
    summary["next_step"] = (
        "Show the price and ask the customer to confirm, then call book_parcel with quote_id."
    )
    return ToolOutput(
        summary,
        card={"type": "parcel_quote", "quote": summary},
        artifacts={"last_parcel_quote_id": quote["id"]},
    )


async def preview_book_parcel(args: QuoteIdArgs, ctx: ToolContext) -> dict[str, Any]:
    q = _quote_summary(await ctx.api.get(f"/v1/parcels/quotes/{args.quote_id}"))
    return {
        "title": f"Book a {q['size']} package delivery for {q['total']}?",
        "parcel": q,
        "message": f"You'll pay {q['total']} securely on the payment page. A rider is assigned after payment.",
    }


async def book_parcel(args: QuoteIdArgs, ctx: ToolContext) -> ToolOutput:
    order = await ctx.api.post(
        "/v1/parcels",
        {"quote_id": args.quote_id, "channel": "ai_agent"},
        idempotency_key=ctx.idempotency_key("parcel"),
    )
    res = await ctx.api.post(
        f"/v1/orders/{order['id']}/checkout", {}, idempotency_key=ctx.idempotency_key("checkout")
    )
    data = {
        "order_id": order["id"],
        "short_code": order["short_code"],
        "amount": naira(res["amount_kobo"]),
        "payment_url": res["authorization_url"],
        "instruction": "Share the payment link. Gud Meal finds a rider as soon as the payment is verified. "
        "The recipient must give the rider the delivery code shown in the order.",
    }
    return ToolOutput(
        data,
        card={
            "type": "payment_link",
            "url": res["authorization_url"],
            "amount": data["amount"],
            "order_id": order["id"],
        },
        artifacts={"last_order_id": order["id"]},
    )


def register(reg: ToolRegistry) -> None:
    add = reg.register
    add(
        ToolSpec(
            "list_services",
            "What Gud Meal offers (Food, Beauty & Skin care, Package Delivery), where, "
            "and what is coming soon.",
            NoArgs,
            list_services,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_order_totals",
            "The customer's totals: number of paid orders, total spent (net of "
            "refunds), spend per service and this month, favourite store.",
            NoArgs,
            get_order_totals,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "open_screen",
            "Show the customer a button that opens a part of the app (Food, Beauty, "
            "Package Delivery, Orders, Support, Profile, a store or an order).",
            OpenScreenArgs,
            open_screen,
            EVERYONE,
            rate_per_minute=30,
        )
    )
    add(
        ToolSpec(
            "get_support_contacts",
            "Gud Meal support contacts (WhatsApp, phone, email) and hours.",
            NoArgs,
            get_support_contacts,
            EVERYONE,
        )
    )
    add(
        ToolSpec(
            "get_parcel_quote",
            "Price a Package Delivery within Lagos or within Enugu (bike courier), now "
            "or at a pickup time. Needs the drop-off address with its neighbourhood and the recipient's name "
            "and phone. Does not charge the customer.",
            ParcelQuoteArgs,
            get_parcel_quote,
            EVERYONE,
            mutating=True,
            rate_per_minute=10,
        )
    )
    add(
        ToolSpec(
            "book_parcel",
            "Book a priced Package Delivery and create a secure payment link. Requires the "
            "customer's explicit approval.",
            QuoteIdArgs,
            book_parcel,
            EVERYONE,
            requires_approval=True,
            preview=preview_book_parcel,
            mutating=True,
            rate_per_minute=6,
        )
    )


__all__ = ["register"]
