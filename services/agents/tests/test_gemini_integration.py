"""Gemini integration checks.

* Offline: every tool schema converts into Gemini function declarations via langchain-google-genai
  (the exact code path used in production) — catches unsupported JSON-schema constructs early.
* Live (opt-in): `pytest -m live_gemini` with GOOGLE_API_KEY set runs one real routed tool call.
"""

from __future__ import annotations

import os

import pytest
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_google_genai._function_utils import convert_to_genai_function_declarations

from gudmeal_agents.agents import AGENTS, RouteDecision, router_prompt
from gudmeal_agents.main import build_registry


def test_all_tool_schemas_convert_to_gemini_declarations():
    registry = build_registry()
    converted = convert_to_genai_function_declarations([t.schema() for t in registry.tools.values()])
    tools = converted if isinstance(converted, list) else [converted]
    declarations = [d for t in tools for d in t.function_declarations]
    assert {d.name for d in declarations} == set(registry.tools)
    draft = next(d for d in declarations if d.name == "create_order_draft")
    assert "items" in draft.parameters.properties


def test_models_bind_without_network():
    llm = ChatGoogleGenerativeAI(model="gemini-flash-latest", google_api_key="offline-check")
    registry = build_registry()
    for spec in AGENTS.values():
        llm.bind_tools([registry.get(n).schema() for n in spec.tools])
    llm.with_structured_output(RouteDecision)


@pytest.mark.live_gemini
@pytest.mark.skipif(not os.environ.get("GOOGLE_API_KEY"), reason="GOOGLE_API_KEY not set")
async def test_live_router_and_tool_call():
    model = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")
    llm = ChatGoogleGenerativeAI(model=model, temperature=0)
    decision = await llm.with_structured_output(RouteDecision).ainvoke(
        [
            SystemMessage(content=router_prompt(["customer", "support", "delivery"], None)),
            HumanMessage(content="My jollof arrived cold and one drink is missing"),
        ]
    )
    assert decision.agent == "support"
    registry = build_registry()
    bound = llm.bind_tools([registry.get(n).schema() for n in AGENTS["customer"].tools])
    msg = await bound.ainvoke([HumanMessage(content="I have ₦10,000, find the best meal for 2 before 20:00")])
    assert msg.tool_calls and msg.tool_calls[0]["name"] == "plan_meal_within_budget"
    assert msg.tool_calls[0]["args"]["budget_naira"] == 10_000
