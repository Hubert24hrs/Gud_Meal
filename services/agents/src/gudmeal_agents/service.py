"""AgentService: per-request identity binding, thread ownership, graph invocation, approvals, accounting."""

from __future__ import annotations

import time
from collections import defaultdict, deque
from collections.abc import Iterator
from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Any, Literal

import httpx
from langchain_core.messages import AIMessage, HumanMessage
from langgraph.types import Command

from .api_client import GudMealApi, current_api
from .config import Settings
from .graph import current_caller
from .guardrails import CARD_WARNING, check_input
from .identity import Caller
from .llm import text_of
from .store import AgentStore, ThreadAccessError


class RateLimitedError(Exception):
    pass


class NoPendingApprovalError(Exception):
    pass


@dataclass
class ChatResult:
    thread_id: str
    status: Literal["completed", "approval_required", "blocked"]
    reply: str | None = None
    agent: str | None = None
    cards: list[dict[str, Any]] = field(default_factory=list)
    approval: dict[str, Any] | None = None
    warnings: list[str] = field(default_factory=list)


class AgentService:
    def __init__(
        self, *, settings: Settings, graph: Any, store: AgentStore, http: httpx.AsyncClient, model_name: str
    ) -> None:
        self.settings = settings
        self.graph = graph
        self.store = store
        self.http = http
        self.model_name = model_name
        self._rate: dict[str, deque[float]] = defaultdict(deque)

    # ------------------------------------------------------------------------------------------
    @contextmanager
    def _bind(self, caller: Caller) -> Iterator[None]:
        api = GudMealApi(self.http, self.settings.api_base_url, caller.token)
        t1, t2 = current_caller.set(caller), current_api.set(api)
        try:
            yield
        finally:
            current_caller.reset(t1)
            current_api.reset(t2)

    def _check_rate(self, uid: str) -> None:
        now = time.monotonic()
        q = self._rate[uid]
        while q and now - q[0] > 60:
            q.popleft()
        if len(q) >= self.settings.chat_rate_per_minute:
            raise RateLimitedError("You're sending messages too quickly. Please wait a moment.")
        q.append(now)

    def _config(self, thread_id: str) -> dict[str, Any]:
        return {
            "configurable": {"thread_id": thread_id},
            "recursion_limit": 4 * self.settings.max_graph_steps + 10,
        }

    async def _pending(self, thread_id: str) -> dict[str, Any] | None:
        snapshot = await self.graph.aget_state(self._config(thread_id))
        interrupts = list(getattr(snapshot, "interrupts", ()) or ())
        if not interrupts:
            for task in getattr(snapshot, "tasks", ()) or ():
                interrupts.extend(getattr(task, "interrupts", ()) or ())
        return interrupts[0].value if interrupts else None

    async def _usage(self, thread_id: str) -> dict[str, Any]:
        snapshot = await self.graph.aget_state(self._config(thread_id))
        return dict((snapshot.values or {}).get("usage") or {})

    # ------------------------------------------------------------------------------------------
    async def chat(
        self,
        caller: Caller,
        message: str,
        *,
        thread_id: str | None = None,
        channel: str = "app",
        delivery_address: dict[str, Any] | None = None,
    ) -> ChatResult:
        self._check_rate(caller.uid)
        guard = check_input(message, max_chars=self.settings.max_message_chars)
        if thread_id:
            await self.store.assert_owner(thread_id, caller.uid)
            if await self._pending(thread_id):
                raise NoPendingApprovalError("Please approve or decline the pending action first")
        else:
            thread_id = await self.store.create_thread(caller.uid, channel, guard.text[:80])
        payload: dict[str, Any] = {
            "messages": [HumanMessage(content=guard.text)],  # redacted text only is ever persisted
            "caller": caller.public_dict(),
            "turn_cards": [],
            "steps": 0,
            "blocked": False,
        }
        if delivery_address:
            payload["artifacts"] = {"delivery_address": delivery_address}
        return await self._run(caller, thread_id, payload, warnings=guard.warnings)

    async def resume(
        self, caller: Caller, thread_id: str, *, approved: bool, tool_call_id: str | None
    ) -> ChatResult:
        await self.store.assert_owner(thread_id, caller.uid)
        pending = await self._pending(thread_id)
        if pending is None:
            raise NoPendingApprovalError("There is no action waiting for approval")
        if tool_call_id and pending.get("tool_call_id") != tool_call_id:
            raise NoPendingApprovalError("This approval is out of date; please review the latest request")
        return await self._run(
            caller,
            thread_id,
            Command(resume={"approved": approved, "tool_call_id": pending.get("tool_call_id")}),
        )

    async def _run(
        self, caller: Caller, thread_id: str, payload: Any, *, warnings: list[str] | None = None
    ) -> ChatResult:
        config = self._config(thread_id)
        before = await self._usage(thread_id)
        started = time.perf_counter()
        status, error = "completed", None
        try:
            with self._bind(caller):
                result = await self.graph.ainvoke(payload, config)
        except Exception as exc:
            status, error = "error", type(exc).__name__
            await self._record(caller, thread_id, None, before, {}, started, status, error)
            raise
        pending = await self._pending(thread_id)
        after = dict(result.get("usage") or {})
        agent = result.get("active_agent")
        if pending is not None:
            status = "approval_required"
            out = ChatResult(
                thread_id=thread_id,
                status="approval_required",
                agent=agent,
                cards=result.get("turn_cards") or [],
                approval=pending,
            )
        else:
            last_ai = next(
                (m for m in reversed(result.get("messages", [])) if isinstance(m, AIMessage)), None
            )
            reply = text_of(last_ai) if last_ai else ""
            if "card_number_removed" in (warnings or []) or "secret_removed" in (warnings or []):
                reply = f"{CARD_WARNING}\n\n{reply}".strip()
            status = "blocked" if result.get("blocked") else "completed"
            out = ChatResult(
                thread_id=thread_id,
                status=status,
                reply=reply,
                agent=agent,  # type: ignore[arg-type]
                cards=result.get("turn_cards") or [],
                warnings=warnings or [],
            )
        await self._record(caller, thread_id, agent, before, after, started, status, error)
        await self.store.touch(thread_id)
        return out

    async def _record(
        self,
        caller: Caller,
        thread_id: str,
        agent: str | None,
        before: dict[str, Any],
        after: dict[str, Any],
        started: float,
        status: str,
        error: str | None,
    ) -> None:
        def delta(key: str) -> float:
            return float(after.get(key, 0) or 0) - float(before.get(key, 0) or 0)

        await self.store.record_run(
            thread_id=thread_id,
            uid=caller.uid,
            agent=agent,
            model=self.model_name,
            status=status,
            input_tokens=int(delta("input_tokens")),
            output_tokens=int(delta("output_tokens")),
            llm_calls=int(delta("llm_calls")),
            cost_usd=max(0.0, round(delta("cost_usd"), 8)),
            latency_ms=round((time.perf_counter() - started) * 1000, 1),
            error=error,
        )

    async def history(self, caller: Caller, thread_id: str) -> list[dict[str, Any]]:
        await self.store.assert_owner(thread_id, caller.uid)
        snapshot = await self.graph.aget_state(self._config(thread_id))
        out = []
        for m in (snapshot.values or {}).get("messages", []):
            if isinstance(m, HumanMessage):
                out.append(
                    {"role": "user", "text": m.content if isinstance(m.content, str) else str(m.content)}
                )
            elif isinstance(m, AIMessage) and not m.tool_calls and text_of(m):
                out.append({"role": "assistant", "text": text_of(m)})
        return out


__all__ = ["AgentService", "ChatResult", "NoPendingApprovalError", "RateLimitedError", "ThreadAccessError"]
