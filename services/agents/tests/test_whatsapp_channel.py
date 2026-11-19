"""Yummy on WhatsApp (ADR-0017): the API's channel tokens work end to end, customer-only; Yummy proves itself to the
API with a service credential; WhatsApp chats get a short-reply hint."""

from __future__ import annotations

import time
from datetime import UTC, datetime

import pytest
from gudmeal_api.security.channel_tokens import mint

from gudmeal_agents.agents import AGENTS
from gudmeal_agents.api_client import ServiceAuth
from gudmeal_agents.identity import (
    AuthError,
    Caller,
    ChannelTokenVerifier,
    StaticVerifier,
    verify_channel_token,
)

DEV_SECRET = "local-dev-channel-secret-change-me"  # both services' local default


def channel_token(uid: str, *, secret: str = DEV_SECRET, name: str | None = "Ada", **kw) -> str:
    return mint(secret, uid=uid, name=name, channel="whatsapp", **kw)


async def test_whatsapp_chat_runs_as_the_linked_customer_end_to_end(offline_stack):
    client = offline_stack["client"]
    token = channel_token("cust-1")  # minted by the API, verified by Yummy, accepted again by the API's tools
    r = await client.post(
        "/v1/chat",
        json={"message": "How much have I spent on Yummy Chops?", "channel": "whatsapp"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    # Yummy called the spending tool as cust-1 and the API accepted the same token (a new account: no orders).
    assert body["reply"] == "You haven't placed any orders yet. Shall I find you something nice?"
    assert body["status"] == "completed"
    threads = await client.get("/v1/threads", headers={"Authorization": f"Bearer {token}"})
    assert [t["thread_id"] for t in threads.json()] == [body["thread_id"]]

    for bad in (
        channel_token("cust-1", secret="wrong"),
        channel_token("cust-1", now=time.time() - 3600),
        "gmc1.x.y",
    ):
        r = await client.post(
            "/v1/chat",
            json={"message": "hi", "channel": "whatsapp"},
            headers={"Authorization": f"Bearer {bad}"},
        )
        assert r.status_code == 401


async def test_channel_tokens_never_carry_staff_or_merchant_powers():
    owner = Caller(
        uid="demo-owner-1",
        roles=frozenset({"customer", "restaurant_owner"}),
        restaurant_roles={"r1": "owner"},
    )
    verifier = ChannelTokenVerifier(DEV_SECRET, StaticVerifier({"tok-owner": owner}))
    caller = await verifier.verify(channel_token("demo-owner-1", name="Owner"))
    assert caller.roles == frozenset({"customer"}) and caller.restaurant_roles == {} and not caller.is_staff
    assert (await verifier.verify("tok-owner")).roles == owner.roles  # app sign-ins are unchanged
    with pytest.raises(AuthError):
        await verifier.verify(channel_token("cust-1", secret="other"))
    claims = verify_channel_token(DEV_SECRET, channel_token("cust-9"))
    assert claims["uid"] == "cust-9" and claims["roles"] == ["customer"]


async def test_service_credentials_for_api_calls(monkeypatch):
    assert await ServiceAuth("none").headers() == {}
    assert await ServiceAuth("shared_secret", secret="s3cret").headers() == {"X-Internal-Token": "s3cret"}
    fetched: list[str] = []

    def fake_fetch(request, audience):
        fetched.append(audience)
        return "google-signed-id-token"

    monkeypatch.setattr("google.oauth2.id_token.fetch_id_token", fake_fetch)
    auth = ServiceAuth("oidc", audience="https://api.example")
    assert await auth.headers() == {"X-Service-Authorization": "Bearer google-signed-id-token"}
    await auth.headers()
    assert fetched == ["https://api.example"]  # cached until shortly before it expires


def test_whatsapp_chats_ask_for_short_plain_replies():
    caller = Caller(uid="cust-1", roles=frozenset({"customer"}), name="Ada")
    now = datetime(2026, 11, 16, 12, tzinfo=UTC)
    prompt = AGENTS["customer"].system_prompt(caller, now, {"channel": "whatsapp"})
    assert "Channel: WhatsApp" in prompt and "Yes/No buttons" in prompt
    assert "Channel: WhatsApp" not in AGENTS["customer"].system_prompt(caller, now, {"channel": "app"})


def test_food_requests_return_to_the_customer_agent():
    from gudmeal_agents.agents import keyword_route

    ada = Caller(uid="cust-1", roles=frozenset({"customer"}), name="Ada")
    assert keyword_route("What do you offer?", ada).agent == "growth"  # "offer" is a growth keyword
    follow = keyword_route("I have ₦10,000, find me food for 2 people", ada, previous="growth")
    assert follow.agent == "customer"  # the planner lives with the customer agent
    assert keyword_route("where is my order", ada, previous="growth").agent == "delivery"
    assert keyword_route("refund for my food please", ada).agent == "support"
    assert keyword_route("tell me more", ada, previous="growth").agent == "growth"
    for text in (
        "find me food for 2 people",
        "jollof rice for 2",
        "can you deliver to Yaba",
    ):
        assert keyword_route(text, ada, previous="growth").agent == "customer", text
    assert keyword_route("foodies unite", ada, previous="growth").agent == "growth"  # whole words only


async def test_whatsapp_orders_are_tagged_and_approvals_say_where_they_go(stack):
    import json

    from conftest import LEKKI_ADDRESS, bearer, last_tool_data, tool_call

    client, api, models = stack["client"], stack["api"], stack["models"]
    r = await api.post("/v1/me/addresses", json=LEKKI_ADDRESS, headers=bearer("customer"))
    assert r.status_code == 201, r.text
    script = [
        tool_call("plan_meal_within_budget", {"budget_naira": 10_000, "party_size": 2}, "call_plan"),
        lambda msgs: tool_call(
            "create_order_draft",
            {"plan_ref": last_tool_data(msgs)["data"]["plans"][0]["plan_ref"]},
            "call_draft",
        ),
        lambda msgs: tool_call(
            "confirm_order", {"order_id": last_tool_data(msgs)["data"]["order_id"]}, "call_confirm"
        ),
    ]
    channels = {}
    for channel in ("whatsapp", "app"):
        models.steps = list(script)
        r = await client.post(
            "/v1/chat",
            json={"message": "I have ₦10,000, find me food for 2 people", "channel": channel},
            headers=bearer("customer"),
        )
        assert r.status_code == 200, r.text
        body = r.json()
        assert body["status"] == "approval_required"
        draft = next(c for c in body["cards"] if c["type"] == "order_draft")["order"]
        order = (await api.get(f"/v1/orders/{draft['order_id']}", headers=bearer("customer"))).json()
        channels[channel] = order["channel"]
        # WhatsApp has no order screen, so the Yes/No approval spells out the destination...
        preview = body["approval"]["preview"]
        where = "5 Bisola Durosinmi-Etti Drive, Lekki Phase 1, Lagos"
        assert preview["deliver_to"] == where and preview["message"].startswith(f"Delivering to {where}. ")
        # ...while the order summaries the model reads still leave the street address out.
        assert "Bisola" not in json.dumps(draft)
    # The owner can count WhatsApp orders; Yummy in the app and on the website stays "ai_agent".
    assert channels == {"whatsapp": "whatsapp", "app": "ai_agent"}
