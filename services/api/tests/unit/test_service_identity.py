"""Gud Meal's own services (ADR-0017): the agents service may skip App Check with its service-account token, and
that token never opens the internal job and task endpoints. Cloud Tasks and Scheduler are the reverse."""

from __future__ import annotations

from types import SimpleNamespace

import pytest

from gudmeal_api.api.deps import trusted_service, verify_internal
from gudmeal_api.config import Settings
from gudmeal_api.errors import PermissionDenied, Unauthenticated

AUDIENCE = "https://api.example"
AGENTS = "gudmeal-agents@project.iam.gserviceaccount.com"
TASKS = "gudmeal-tasks@project.iam.gserviceaccount.com"


class FakeRequest:
    def __init__(self, headers: dict[str, str] | None = None) -> None:
        self.headers = {k.lower(): v for k, v in (headers or {}).items()}


@pytest.fixture
def google_tokens(monkeypatch):
    """Google's verifier, faked: each test token belongs to one service account."""

    def verify(token, request, audience):
        if audience != AUDIENCE:
            raise ValueError("wrong audience")
        email = {"agents-token": AGENTS, "tasks-token": TASKS}.get(token)
        if email is None:
            raise ValueError("not signed by Google")
        return {"email": email, "email_verified": True}

    monkeypatch.setattr("google.oauth2.id_token.verify_oauth2_token", verify)


def container(**overrides) -> SimpleNamespace:
    values = {
        "environment": "test",
        "internal_auth_mode": "oidc",
        "internal_oidc_audience": AUDIENCE,
        "internal_oidc_service_accounts": [TASKS],
        "trusted_service_accounts": [AGENTS],
    }
    return SimpleNamespace(settings=Settings(**{**values, **overrides}))


def service(token: str) -> FakeRequest:
    return FakeRequest({"X-Service-Authorization": f"Bearer {token}"})


async def test_only_the_agents_service_skips_app_check(google_tokens):
    c = container()
    assert await trusted_service(service("agents-token"), c)
    # The scheduler's account has no business on user routes.
    assert not await trusted_service(service("tasks-token"), c)
    assert not await trusted_service(service("forged-token"), c)
    assert not await trusted_service(FakeRequest({"Authorization": "Bearer agents-token"}), c)
    assert not await trusted_service(FakeRequest(), c)


async def test_the_agents_token_never_opens_internal_endpoints(google_tokens):
    c = container()
    assert await verify_internal(FakeRequest(), c, authorization="Bearer tasks-token") == TASKS
    with pytest.raises(PermissionDenied):
        await verify_internal(FakeRequest(), c, authorization="Bearer agents-token")
    with pytest.raises(Unauthenticated):
        await verify_internal(FakeRequest(), c, authorization="Bearer forged-token")


async def test_shared_secret_locally():
    c = container(internal_auth_mode="shared_secret", internal_shared_secret="local-secret")
    assert await trusted_service(FakeRequest({"X-Internal-Token": "local-secret"}), c)
    assert not await trusted_service(FakeRequest({"X-Internal-Token": "guess"}), c)
    assert not await trusted_service(FakeRequest(), c)


def test_enforcing_app_check_requires_the_agents_service_account():
    unsafe = Settings(environment="staging", app_check_enforced=True, trusted_service_accounts=[])
    with pytest.raises(RuntimeError, match="TRUSTED_SERVICE_ACCOUNTS"):
        unsafe.validate_for_environment()
    listed = Settings(environment="staging", app_check_enforced=True, trusted_service_accounts=[AGENTS])
    with pytest.raises(RuntimeError) as exc:  # other staging settings are missing in this test
        listed.validate_for_environment()
    assert "TRUSTED_SERVICE_ACCOUNTS" not in str(exc.value)
