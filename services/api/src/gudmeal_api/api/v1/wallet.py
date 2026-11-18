"""GudMeals wallet, payment options and sellers' cash-on-delivery balances (signed-in customers)."""

from __future__ import annotations

from typing import Annotated, Any, Literal

from fastapi import APIRouter, Depends, Header, Query
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from ...errors import NotFound
from ...services.wallet import SellerPayoutInput
from ..deps import Ctr, CurrentPrincipal, limit, run_idempotent

router = APIRouter(prefix="/v1", tags=["wallet"])
IdemKey = Annotated[str | None, Header(alias="Idempotency-Key")]


class TopUpInput(BaseModel):
    amount_kobo: int = Field(gt=0, le=1_000_000_000)
    provider: Literal["paystack", "flutterwave", "local_sandbox"] | None = None


class WalletSettingsInput(BaseModel):
    refund_to_wallet: bool


class AmountInput(BaseModel):
    amount_kobo: int = Field(gt=0, le=100_000_000)


@router.get("/wallet")
async def wallet(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.wallet.overview(principal)


@router.get("/wallet/transactions")
async def wallet_transactions(
    c: Ctr, principal: CurrentPrincipal, limit_: Annotated[int, Query(alias="limit", ge=1, le=200)] = 50
) -> list[dict[str, Any]]:
    return await c.wallet.transactions(principal, limit_)


@router.post("/wallet/topups", status_code=201, dependencies=[Depends(limit("wallet_topup"))])
async def wallet_topup(
    data: TopUpInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.wallet.start_topup(principal, data.amount_kobo, data.provider, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"wallet.topup:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.put("/wallet/settings")
async def wallet_settings(data: WalletSettingsInput, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.wallet.set_refund_preference(principal, data.refund_to_wallet)


@router.get("/orders/{order_id}/payment-options")
async def payment_options(order_id: str, c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    order = await c.orders.get(order_id)
    if order.customer_id != principal.uid:
        raise NotFound("Order not found")
    return await c.wallet.payment_options(principal, order)


# ---------------------------------------------------------------- sellers (cash on delivery)
@router.get("/seller/balance")
async def seller_balance(c: Ctr, principal: CurrentPrincipal) -> dict[str, Any]:
    return await c.wallet.seller_overview(principal)


@router.post("/seller/payouts", status_code=201, dependencies=[Depends(limit("payout"))])
async def seller_payout(
    data: SellerPayoutInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.wallet.request_seller_payout(principal, data, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"seller.payout:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
        success_status=201,
    )


@router.post("/seller/move-to-wallet", dependencies=[Depends(limit("payout"))])
async def seller_move_to_wallet(
    data: AmountInput, c: Ctr, principal: CurrentPrincipal, idempotency_key: IdemKey = None
) -> JSONResponse:
    async def run() -> dict[str, Any]:
        return await c.wallet.move_cod_to_wallet(principal, data.amount_kobo, str(idempotency_key))

    return await run_idempotent(
        c,
        scope=f"seller.to_wallet:{principal.uid}",
        key=idempotency_key,
        payload=data.model_dump(),
        fn=run,
    )
