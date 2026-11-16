"""Caller identity for the agents service (Firebase ID tokens), mirroring gudmeal-api's role model."""

from __future__ import annotations

import asyncio
import base64
import hashlib
import hmac
import json
import time
from dataclasses import dataclass, field
from typing import Any, Protocol

STAFF_ROLES = {"support_agent", "operations_manager", "finance_manager", "marketing_manager", "super_admin"}
KNOWN_ROLES = STAFF_ROLES | {
    "customer",
    "restaurant_owner",
    "restaurant_manager",
    "restaurant_staff",
    "rider",
}


class AuthError(Exception):
    pass


@dataclass(frozen=True)
class Caller:
    uid: str
    roles: frozenset[str]
    restaurant_roles: dict[str, str] = field(default_factory=dict)
    name: str | None = None
    token: str = field(default="", repr=False, compare=False)

    @property
    def is_staff(self) -> bool:
        return bool(self.roles & STAFF_ROLES)

    def public_dict(self) -> dict[str, Any]:
        """Safe to persist in graph state: no token."""
        return {
            "uid": self.uid,
            "roles": sorted(self.roles),
            "restaurant_roles": dict(self.restaurant_roles),
            "name": self.name,
        }


class Verifier(Protocol):
    async def verify(self, token: str) -> Caller: ...


def caller_from_claims(claims: dict[str, Any], token: str) -> Caller:
    roles = {r for r in claims.get("roles") or [] if r in KNOWN_ROLES} | {"customer"}
    rr = claims.get("restaurant_roles") or {}
    return Caller(
        uid=str(claims.get("uid") or claims.get("sub")),
        roles=frozenset(roles),
        restaurant_roles={str(k): str(v) for k, v in rr.items()} if isinstance(rr, dict) else {},
        name=claims.get("name"),
        token=token,
    )


class FirebaseVerifier:
    def __init__(self, project_id: str, check_revoked: bool) -> None:
        import firebase_admin

        try:
            self._app = firebase_admin.get_app()
        except ValueError:
            self._app = firebase_admin.initialize_app(options={"projectId": project_id})
        self._check_revoked = check_revoked

    async def verify(self, token: str) -> Caller:
        from firebase_admin import auth

        try:
            claims = await asyncio.to_thread(
                auth.verify_id_token, token, app=self._app, check_revoked=self._check_revoked
            )
        except Exception as exc:
            raise AuthError("Invalid or expired ID token") from exc
        return caller_from_claims(claims, token)


CHANNEL_PREFIX = "gmc1"


def verify_channel_token(secret: str, token: str, now: float | None = None) -> dict[str, Any]:
    """Same rules as gudmeal-api's security.channel_tokens.verify (ADR-0017); raises ValueError."""
    parts = token.split(".")
    if len(parts) != 3 or parts[0] != CHANNEL_PREFIX:
        raise ValueError("Not a channel token")
    signed = f"{parts[0]}.{parts[1]}"
    expected = base64.urlsafe_b64encode(hmac.new(secret.encode(), signed.encode(), hashlib.sha256).digest())
    if not hmac.compare_digest(expected.rstrip(b"=").decode(), parts[2]):
        raise ValueError("Bad signature")
    try:
        claims = json.loads(base64.urlsafe_b64decode(parts[1] + "=" * (-len(parts[1]) % 4)))
    except ValueError as exc:
        raise ValueError("Bad payload") from exc
    t = now if now is not None else time.time()
    if not isinstance(claims, dict) or not claims.get("uid") or claims.get("ch") != "whatsapp":
        raise ValueError("Bad claims")
    if int(claims.get("exp", 0)) <= t or int(claims.get("iat", 0)) > t + 60:
        raise ValueError("Expired")
    return claims


class ChannelTokenVerifier:
    """Accepts the API's WhatsApp channel tokens (customer only); other tokens go to the Firebase verifier."""

    def __init__(self, secret: str, fallback: Verifier) -> None:
        self._secret = secret
        self._fallback = fallback

    async def verify(self, token: str) -> Caller:
        if not token.startswith(f"{CHANNEL_PREFIX}."):
            return await self._fallback.verify(token)
        try:
            claims = verify_channel_token(self._secret, token)
        except ValueError as exc:
            raise AuthError("Invalid or expired channel token") from exc
        return Caller(
            uid=str(claims["uid"]), roles=frozenset({"customer"}), name=claims.get("name"), token=token
        )


class StaticVerifier:
    """Test double mapping opaque tokens to callers."""

    def __init__(self, callers: dict[str, Caller]) -> None:
        self.callers = callers

    async def verify(self, token: str) -> Caller:
        caller = self.callers.get(token)
        if caller is None:
            raise AuthError("Invalid or expired ID token")
        return Caller(caller.uid, caller.roles, caller.restaurant_roles, caller.name, token)
