"""Payment webhooks, internal (Cloud Tasks / Pub/Sub / Scheduler) endpoints and the local payment sandbox."""

from __future__ import annotations

import html
from datetime import timedelta
from typing import Any

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ...domain.money import format_naira
from ...errors import NotFound
from ...services.infra import decode_pubsub_push
from ..deps import Ctr, InternalCaller, client_ip

webhooks = APIRouter(prefix="/v1/webhooks", tags=["webhooks"])
internal = APIRouter(prefix="/internal", tags=["internal"], include_in_schema=False)
dev = APIRouter(prefix="/v1/dev", tags=["dev"], include_in_schema=False)


@webhooks.post("/{provider}")
async def payment_webhook(provider: str, request: Request, c: Ctr) -> dict[str, str]:
    raw = await request.body()
    headers = {k.lower(): v for k, v in request.headers.items()}
    return await c.payments.handle_webhook(provider, raw, headers, client_ip(request))


# ------------------------------------------------------------------------------------------------
# Internal
# ------------------------------------------------------------------------------------------------


@internal.post("/tasks/{name}")
async def run_task(name: str, payload: dict[str, Any], c: Ctr, _caller: InternalCaller) -> dict[str, str]:
    await c.task_router.run(f"/internal/tasks/{name}", payload)
    return {"status": "ok"}


@internal.post("/events")
async def pubsub_push(body: dict[str, Any], c: Ctr, _caller: InternalCaller) -> dict[str, str]:
    topic, payload = decode_pubsub_push(body)
    await c.handlers.dispatch(topic, payload)  # errors → 500 → Pub/Sub retries with backoff
    return {"status": "ok"}


@internal.post("/jobs/relay-outbox")
async def relay_outbox(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    return {"published": await c.relay.relay_pending(limit=200)}


@internal.post("/jobs/reconcile-payments")
async def reconcile_payments(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    return await c.payments.reconcile_stale()


@internal.post("/jobs/sweep")
async def sweep(c: Ctr, _caller: InternalCaller) -> dict[str, int]:
    """Repairs work whose triggering event may have been lost (idempotent)."""
    settled = 0
    for order in await c.orders.unsettled_completed(timedelta(minutes=5)):
        if await c.payments.settle_completed_order(order):
            settled += 1
    purged = await c.idempotency.purge_expired()
    return {"settled": settled, "idempotency_purged": purged}


# ------------------------------------------------------------------------------------------------
# Local payment sandbox (ENVIRONMENT=local|test only — router is not mounted elsewhere)
# ------------------------------------------------------------------------------------------------


@dev.get("/sandbox-checkout/{reference}", response_class=HTMLResponse)
async def sandbox_checkout(reference: str, c: Ctr) -> HTMLResponse:
    if c.sandbox is None or reference not in c.sandbox.charges:
        raise NotFound("Unknown sandbox payment")
    charge = c.sandbox.charges[reference]
    ref = html.escape(reference)
    return HTMLResponse(f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Gud Meal · Sandbox checkout</title>
<style>body{{font-family:system-ui,sans-serif;background:#FFF9F3;color:#202521;display:grid;place-items:center;
min-height:100vh;margin:0}}.card{{background:#fff;border-radius:16px;padding:32px;max-width:380px;width:90%;
box-shadow:0 8px 30px rgba(0,0,0,.08)}}.amt{{font-size:32px;font-weight:700;margin:8px 0 24px}}
button{{width:100%;padding:14px;border-radius:12px;border:0;font-size:16px;font-weight:600;margin-top:10px;cursor:pointer}}
.pay{{background:#E85D32;color:#fff}}.fail{{background:#f1f1f1;color:#202521}}.note{{font-size:12px;color:#777F79;margin-top:18px}}</style>
</head><body><div class="card"><div>Local payment sandbox</div><div class="amt">{format_naira(charge.amount_kobo)}</div>
<div>Reference <code>{ref}</code></div>
<form method="post" action="/v1/dev/sandbox-checkout/{ref}/complete?outcome=success"><button class="pay">Approve payment</button></form>
<form method="post" action="/v1/dev/sandbox-checkout/{ref}/complete?outcome=failure"><button class="fail">Decline</button></form>
<p class="note">Development only. No real money moves. Approving sends a signed webhook through the same
verification and ledger pipeline used for Paystack.</p></div></body></html>""")


@dev.post("/sandbox-checkout/{reference}/complete")
async def sandbox_complete(reference: str, outcome: str, c: Ctr) -> RedirectResponse:
    if c.sandbox is None:
        raise NotFound("Sandbox disabled")
    body, signature, callback = c.sandbox.complete(reference, success=outcome == "success")
    await c.payments.handle_webhook("local_sandbox", body, {"x-sandbox-signature": signature}, "127.0.0.1")
    sep = "&" if "?" in callback else "?"
    return RedirectResponse(f"{callback}{sep}reference={reference}", status_code=303)
