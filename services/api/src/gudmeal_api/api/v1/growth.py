"""Growth (ADR-0016): Gud Meal Plus, Gud points and referrals, group orders."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Header
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from ...domain.growth import GrowthConfig
from ...services.group_orders import (
    GroupCheckoutInput,
    GroupCreateInput,
    GroupJoinInput,
    GroupLinesInput,
    GroupPayInput,
    GroupReadyInput,
    GroupSettingsInput,
)
from ...services.rewards import RedeemInput, ReferralInput, voucher_view
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


# ------------------------------------------------------------------------------------------- rewards
@router.get("/rewards")
async def rewards(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.rewards.overview(principal)


@router.get("/rewards/vouchers")
async def my_vouchers(c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    return [voucher_view(v) for v in await c.rewards.my_vouchers(principal.uid)]


@router.post("/rewards/referral", dependencies=[Depends(limit("rewards"))])
async def apply_referral(data: ReferralInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.rewards.apply_referral(principal, data.code)


@router.post("/rewards/redeem", status_code=201, dependencies=[Depends(limit("rewards"))])
async def redeem_points(
    data: RedeemInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.rewards.redeem(principal, data.points)

    return await run_idempotent(
        c,
        scope=f"rewards.redeem:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


# ------------------------------------------------------------------------------------------- group orders
@router.get("/group-orders")
async def my_group_orders(c: Ctr, principal: CurrentPrincipal) -> list[dict[str, Any]]:
    return await c.groups.mine(principal)


@router.post("/group-orders", status_code=201)
async def create_group_order(data: GroupCreateInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.create(principal, data)


@router.post("/group-orders/join", dependencies=[Depends(limit("group_join"))])
async def join_group_order(data: GroupJoinInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.join(principal, data.code)


@router.get("/group-orders/{group_id}")
async def group_order(group_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.get(principal, group_id)


@router.put("/group-orders/{group_id}/lines")
async def set_group_lines(
    group_id: str, data: GroupLinesInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return await c.groups.set_lines(principal, group_id, data.lines)


@router.put("/group-orders/{group_id}/ready")
async def set_group_ready(
    group_id: str, data: GroupReadyInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return await c.groups.set_ready(principal, group_id, data.ready)


@router.put("/group-orders/{group_id}/settings")
async def group_settings(
    group_id: str, data: GroupSettingsInput, c: Ctr, principal: CurrentPrincipal
) -> dict[str, Any]:
    return await c.groups.settings(principal, group_id, data)


@router.post("/group-orders/{group_id}/lock")
async def lock_group(group_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.set_locked(principal, group_id, True)


@router.post("/group-orders/{group_id}/unlock")
async def unlock_group(group_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.set_locked(principal, group_id, False)


@router.delete("/group-orders/{group_id}/members/{uid}")
async def remove_group_member(group_id: str, uid: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.remove_member(principal, group_id, uid)


@router.post(
    "/group-orders/{group_id}/checkout", status_code=201, dependencies=[Depends(limit("order_create"))]
)
async def group_checkout(
    group_id: str,
    data: GroupCheckoutInput,
    c: Ctr,
    principal: CurrentPrincipal,
    idempotency_key: IdemKey = None,
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.groups.checkout(principal, group_id, data)

    return await run_idempotent(
        c,
        scope=f"group.checkout:{principal.uid}:{group_id}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.post("/group-orders/{group_id}/pay", dependencies=[Depends(limit("checkout"))])
async def pay_group_share(
    group_id: str, data: GroupPayInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.groups.pay(principal, group_id, data, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"group.pay:{principal.uid}:{group_id}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=200,
    )


@router.post("/group-orders/{group_id}/cancel")
async def cancel_group(group_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.groups.cancel(principal, group_id)


# ------------------------------------------------------------------------------------------- staff
@admin.get("/growth")
async def growth_overview(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return {
        "plus": await c.membership.admin_stats(principal),
        "rewards": await c.rewards.admin_stats(principal),
    }


@admin.get("/config/growth")
async def growth_config(c: Ctr, principal: CurrentPrincipal) -> GrowthConfig:
    return await c.rewards.get_config(principal)


@admin.put("/config/growth")
async def save_growth_config(data: GrowthConfig, c: Ctr, principal: CurrentPrincipal) -> GrowthConfig:
    return await c.rewards.save_config(principal, data)
