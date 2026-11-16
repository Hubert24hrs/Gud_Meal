"""FastAPI dependencies: container access, authentication, rate limiting, idempotency, internal auth."""

from __future__ import annotations

import asyncio
import hmac
from collections.abc import Awaitable, Callable
from typing import Annotated, Any

from fastapi import Depends, Header, Request
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse

from ..container import Container
from ..errors import DomainError, PermissionDenied, Unauthenticated
from ..ledger.idempotency import request_hash, validate_key
from ..security.rate_limit import LIMITS
from ..security.rbac import Principal


def get_container(request: Request) -> Container:
    return request.app.state.container  # type: ignore[no-any-return]


Ctr = Annotated[Container, Depends(get_container)]


async def get_principal(
    request: Request,
    c: Ctr,
    authorization: Annotated[str | None, Header()] = None,
    x_firebase_appcheck: Annotated[str | None, Header()] = None,
) -> Principal:
    if c.app_check is not None:
        if x_firebase_appcheck:
            await c.app_check.verify(x_firebase_appcheck)
        elif not await trusted_service(request, c):
            # App Check proves a genuine client app; Gud Meal's own services (Gudy's tool calls, the WhatsApp
            # channel) prove themselves with a service credential instead. The user's token is still required.
            raise Unauthenticated("App Check token required")
    if not authorization or not authorization.lower().startswith("bearer "):
        raise Unauthenticated("Sign in required")
    principal = await c.verifier.verify(authorization[7:].strip())
    request.state.principal = principal
    return principal


CurrentPrincipal = Annotated[Principal, Depends(get_principal)]


def limit(name: str) -> Callable[..., Awaitable[None]]:
    capacity, refill = LIMITS[name]

    async def _check(c: Ctr, principal: CurrentPrincipal) -> None:
        c.rate_limiter.check(f"{name}:{principal.uid}", capacity=capacity, refill_per_second=refill)

    return _check


def client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else None


async def run_idempotent(
    c: Container,
    *,
    scope: str,
    key: str | None,
    payload: Any,
    fn: Callable[[], Awaitable[Any]],
    success_status: int = 200,
) -> JSONResponse:
    """Execute `fn` at most once per (scope, Idempotency-Key); replays return the stored response."""
    key = validate_key(key)
    req_hash = request_hash(jsonable_encoder(payload))
    replay = await c.idempotency.begin(scope, key, req_hash)
    if replay is not None:
        return JSONResponse(
            replay.body, status_code=replay.status_code, headers={"Idempotent-Replayed": "true"}
        )
    try:
        result = await fn()
    except DomainError as exc:
        if exc.status_code < 500:
            body = {"error": exc.to_dict()}
            await c.idempotency.finish(scope, key, exc.status_code, body)
            return JSONResponse(body, status_code=exc.status_code)
        await c.idempotency.release(scope, key)
        raise
    except BaseException:
        await asyncio.shield(c.idempotency.release(scope, key))
        raise
    body = jsonable_encoder(result)
    await c.idempotency.finish(scope, key, success_status, body)
    return JSONResponse(body, status_code=success_status)


async def _verify_service_oidc(token: str, c: Container) -> str:
    """Google-signed OIDC token of an allowed service account (Cloud Tasks, Pub/Sub, Scheduler, our services)."""
    s = c.settings
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token

    try:
        claims = await asyncio.to_thread(
            id_token.verify_oauth2_token, token, google_requests.Request(), s.internal_oidc_audience
        )
    except ValueError as exc:
        raise Unauthenticated("Invalid OIDC token") from exc
    email = claims.get("email")
    if not claims.get("email_verified") or email not in s.internal_oidc_service_accounts:
        raise PermissionDenied("Caller is not an allowed service account")
    return str(email)


async def trusted_service(request: Request, c: Container) -> bool:
    """A call made by one of Gud Meal's own services (shared secret locally, service-account OIDC in the cloud)."""
    s = c.settings
    if s.internal_auth_mode == "shared_secret":
        expected = s.internal_shared_secret.get_secret_value() if s.internal_shared_secret else None
        given = request.headers.get("x-internal-token")
        return bool(expected and given and hmac.compare_digest(expected, given))
    header = request.headers.get("x-service-authorization") or ""
    if not header.lower().startswith("bearer "):
        return False
    try:
        await _verify_service_oidc(header[7:].strip(), c)
    except (Unauthenticated, PermissionDenied):
        return False
    return True


async def verify_internal(
    request: Request,
    c: Ctr,
    authorization: Annotated[str | None, Header()] = None,
    x_internal_token: Annotated[str | None, Header()] = None,
) -> str:
    """Authenticate Cloud Tasks / Pub/Sub push / Scheduler calls."""
    s = c.settings
    if s.internal_auth_mode == "shared_secret":
        expected = s.internal_shared_secret.get_secret_value() if s.internal_shared_secret else None
        if not expected or not x_internal_token or not hmac.compare_digest(expected, x_internal_token):
            raise PermissionDenied("Internal endpoint")
        return "shared-secret"
    if not authorization or not authorization.lower().startswith("bearer "):
        raise Unauthenticated("Missing OIDC token")
    return await _verify_service_oidc(authorization[7:].strip(), c)


InternalCaller = Annotated[str, Depends(verify_internal)]
