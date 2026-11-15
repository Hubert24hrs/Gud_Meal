"""Interstate waybill endpoints: public routes and tracking, customer quotes and booking, hub operations."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Header, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from ...domain.logistics import WaybillNetwork
from ...domain.models import WaybillQuoteRequest
from ...security.rate_limit import LIMITS
from ...services.cash import CarrierPayoutInput
from ...services.waybills import CollectInput, DepartInput, HubScanInput, waybill_quote_view
from ..deps import Ctr, CurrentPrincipal, client_ip, limit, run_idempotent
from ..serializers import order_view

public = APIRouter(prefix="/v1", tags=["waybills"])
router = APIRouter(prefix="/v1", tags=["waybills"])
admin = APIRouter(prefix="/v1/admin", tags=["admin"])
IdemKey = Annotated[str | None, Header(alias="Idempotency-Key")]


class CreateWaybillInput(BaseModel):
    quote_id: str
    channel: Literal["app", "web", "ai_agent"] = "app"


# ---------------------------------------------------------------- public
@public.get("/waybill/origins")
async def waybill_origins(c: Ctr) -> list[dict[str, Any]]:
    """Cities you can send from, with home pickup availability and drop-off hubs."""
    return await c.waybills.origins()


@public.get("/waybill/destinations")
async def waybill_destinations(c: Ctr, origin: str) -> dict[str, Any]:
    """Where a city sends to: transit days, door delivery or collection, and prices from."""
    return await c.waybills.destinations(origin)


@public.get("/track/{tracking_code}")
async def track(tracking_code: str, request: Request, c: Ctr) -> dict[str, Any]:
    """Public tracking for the sender and recipient (progress only; no names, phones or addresses)."""
    capacity, refill = LIMITS["track"]
    c.rate_limiter.check(
        f"track:{client_ip(request) or 'unknown'}", capacity=capacity, refill_per_second=refill
    )
    return await c.waybills.track(tracking_code)


# ---------------------------------------------------------------- customers
@router.post("/waybills/quotes", status_code=201, dependencies=[Depends(limit("quote"))])
async def create_waybill_quote(
    req: WaybillQuoteRequest, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return waybill_quote_view(await c.waybills.create_quote(principal, req))


@router.get("/waybills/quotes/{quote_id}")
async def get_waybill_quote(quote_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return waybill_quote_view(await c.waybills.get_quote(principal, quote_id))


@router.post("/waybills", status_code=201, dependencies=[Depends(limit("order_create"))])
async def create_waybill(
    data: CreateWaybillInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    """Book the waybill from a quote; pay with `POST /v1/orders/{id}/checkout` (card or wallet)."""

    async def run() -> dict[str, Any]:
        order = await c.waybills.create_order(principal, data.quote_id, channel=data.channel)
        return order_view(order, principal)

    return await run_idempotent(
        c,
        scope=f"waybills.create:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


# ---------------------------------------------------------------- hubs (hub agents, operations)
@admin.get("/hubs")
async def hubs(c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    return await c.waybills.hubs(principal)


@admin.get("/hubs/{hub_id}/board")
async def hub_board(hub_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    """Packages expected, at the hub, incoming, out for delivery and waiting for collection."""
    return await c.waybills.hub_board(principal, hub_id)


@admin.post("/waybills/receive")
async def receive(data: HubScanInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.waybills.receive(principal, data)


@admin.post("/waybills/depart")
async def depart(data: DepartInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.waybills.depart(principal, data)


@admin.post("/waybills/arrive")
async def arrive(data: HubScanInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.waybills.arrive(principal, data)


@admin.post("/waybills/collect")
async def collect(data: CollectInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    c.rate_limiter.check(f"code:{principal.uid}", capacity=5, refill_per_second=0.02)
    return await c.waybills.collect(principal, data)


@admin.get("/config/logistics")
async def get_logistics(c: Ctr, principal: CurrentPrincipal) -> WaybillNetwork:
    return await c.waybills.get_config(principal)


@admin.put("/config/logistics")
async def put_logistics(data: WaybillNetwork, c: Ctr, principal: CurrentPrincipal) -> WaybillNetwork:
    return await c.waybills.save_config(principal, data)


@admin.post("/carriers/{carrier_id}/payouts", status_code=201)
async def carrier_payout(
    carrier_id: str,
    data: CarrierPayoutInput,
    c: Ctr,
    principal: CurrentPrincipal,
    idempotency_key: IdemKey = None,
) -> JSONResponse:
    async def run() -> Any:
        return await c.cash.record_carrier_payout(principal, carrier_id, data, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"admin.carrier_payout:{carrier_id}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )
