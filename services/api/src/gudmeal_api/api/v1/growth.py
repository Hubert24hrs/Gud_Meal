"""Growth (ADR-0016): Gud Meal Plus, Gud points and referrals, group orders."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from ..deps import Ctr, CurrentPrincipal, limit, run_idempotent

router = APIRouter(prefix="/v1", tags=["growth"])
admin = APIRouter(prefix="/v1/admin", tags=["admin"])
IdemKey = Annotated[str | None, Header(alias="Idempotency-Key")]


# ------------------------------------------------------------------------------------------- Plus
class SubscribeInput(BaseModel):
    provider: Literal["wallet", "paystack", "flutterwave", "local_sandbox"] | None = None
    auto_renew: bool = True  # renew from the Gud Meal wallet at the end of each period


class AutoRenewInput(BaseModel):
    auto_renew: bool


@router.get("/plus")
async def plus(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.membership.overview(principal)


@router.post("/plus/subscribe", status_code=201, dependencies=[Depends(limit("plus"))])
async def plus_subscribe(
    data: SubscribeInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.membership.subscribe(
            principal, data.provider, str(idempotency_key), auto_renew=data.auto_renew
        )

    return await run_idempotent(
        c,
        scope=f"plus.subscribe:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.put("/plus/auto-renew")
async def plus_auto_renew(data: AutoRenewInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.membership.set_auto_renew(principal, data.auto_renew)


# ------------------------------------------------------------------------------------------- staff
@admin.get("/growth")
async def growth_overview(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return {"plus": await c.membership.admin_stats(principal)}
