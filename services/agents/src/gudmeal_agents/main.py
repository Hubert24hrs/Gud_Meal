"""HTTP API for the agents service."""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import AsyncExitStack, asynccontextmanager
from typing import Annotated, Any, Literal

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from .config import Settings, get_settings
from .graph import build_graph
from .identity import AuthError, Caller, ChannelTokenVerifier, FirebaseVerifier, Verifier
from .llm import GeminiFactory, ModelFactory
from .offline import OfflineModels
from .service import AgentService, NoPendingApprovalError, RateLimitedError
from .store import AgentStore, ThreadAccessError
from .tools import customer, operations, services
from .tools.registry import ToolRegistry

logger = logging.getLogger("gudmeal_agents")


def build_registry() -> ToolRegistry:
    registry = ToolRegistry()
    customer.register(registry)
    operations.register(registry)
    services.register(registry)
    return registry


async def make_checkpointer(settings: Settings, stack: AsyncExitStack) -> Any:
    if settings.checkpointer == "postgres":
        from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver

        if settings.checkpoint_postgres_url is None:
            raise RuntimeError("CHECKPOINT_POSTGRES_URL is required for CHECKPOINTER=postgres")
        saver = await stack.enter_async_context(
            AsyncPostgresSaver.from_conn_string(settings.checkpoint_postgres_url.get_secret_value())
        )
        await saver.setup()
        return saver
    if settings.checkpointer == "sqlite":
        from langgraph.checkpoint.sqlite.aio import AsyncSqliteSaver

        return await stack.enter_async_context(
            AsyncSqliteSaver.from_conn_string(settings.checkpoint_sqlite_path)
        )
    from langgraph.checkpoint.memory import InMemorySaver

    return InMemorySaver()


class ChatAddress(BaseModel):
    label: str | None = Field(default=None, max_length=40)
    line1: str = Field(min_length=3, max_length=200)
    area: str | None = Field(default=None, max_length=80)
    city: str = "Lagos"
    state: str = "Lagos"
    location: dict[str, float]
    instructions: str | None = Field(default=None, max_length=300)
    contact_phone: str | None = Field(default=None, max_length=20)


class ChatInput(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    thread_id: str | None = Field(default=None, max_length=64)
    channel: Literal["app", "web", "partner", "admin", "whatsapp"] = "app"
    delivery_address: ChatAddress | None = None


class ApprovalInput(BaseModel):
    approved: bool
    tool_call_id: str | None = Field(default=None, max_length=128)


async def caller_dep(request: Request, authorization: Annotated[str | None, Header()] = None) -> Caller:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Sign in required")
    try:
        return await request.app.state.verifier.verify(authorization[7:].strip())
    except AuthError as exc:
        raise HTTPException(401, str(exc)) from exc


CallerDep = Annotated[Caller, Depends(caller_dep)]


def create_app(
    settings: Settings | None = None,
    *,
    verifier: Verifier | None = None,
    models: ModelFactory | None = None,
    http: httpx.AsyncClient | None = None,
    checkpointer: Any = None,
    store: AgentStore | None = None,
) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        async with AsyncExitStack() as stack:
            if not hasattr(app.state, "service"):
                await _wire(app, stack)
            yield
            await app.state.store.close()

    async def _wire(app: FastAPI, stack: AsyncExitStack | None) -> None:
        settings.validate_for_environment()
        agent_store = store or AgentStore(settings.database_url)
        await agent_store.create_all()
        model_factory = models
        if model_factory is None and settings.llm_configured:
            model_factory = GeminiFactory(settings)
        if model_factory is None:
            # No Gemini key: Gudy still works in rule-based offline mode (same tools, approvals and audit).
            model_factory = OfflineModels()
        saver = checkpointer
        if saver is None:
            assert stack is not None
            saver = await make_checkpointer(settings, stack)
        client = http or httpx.AsyncClient(timeout=settings.api_timeout_seconds)
        graph = build_graph(
            models=model_factory,
            registry=build_registry(),
            audit=agent_store,
            settings=settings,
            checkpointer=saver,
        )
        app.state.store = agent_store
        app.state.verifier = ChannelTokenVerifier(
            settings.channel_token_secret.get_secret_value(),
            verifier or FirebaseVerifier(settings.firebase_project_id, settings.check_token_revocation),
        )
        app.state.service = AgentService(
            settings=settings,
            graph=graph,
            store=agent_store,
            http=client,
            model_name=model_factory.model_name if model_factory else "unconfigured",
        )
        app.state.llm_ready = not isinstance(model_factory, OfflineModels)
        app.state.ai_mode = "offline" if isinstance(model_factory, OfflineModels) else "llm"

    app = FastAPI(
        title="GudMeals Agents",
        version="0.1.0",
        lifespan=lifespan,
        docs_url=None if settings.environment == "production" else "/docs",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
        allow_credentials=False,
    )
    app.state.wire = _wire

    def service(request: Request) -> AgentService:
        return request.app.state.service  # type: ignore[no-any-return]

    def result_json(result: Any) -> dict[str, Any]:
        return {
            "thread_id": result.thread_id,
            "status": result.status,
            "reply": result.reply,
            "agent": result.agent,
            "cards": result.cards,
            "approval": result.approval,
            "warnings": result.warnings,
        }

    @app.get("/health")
    async def health(request: Request) -> dict[str, Any]:
        return {
            "status": "ok",
            "llm_configured": bool(getattr(request.app.state, "llm_ready", False)),
            "ai_mode": getattr(request.app.state, "ai_mode", "unknown"),
            "assistant": "Gudy",
        }

    @app.post("/v1/chat")
    async def chat(data: ChatInput, caller: CallerDep, request: Request) -> dict[str, Any]:
        try:
            result = await service(request).chat(
                caller,
                data.message,
                thread_id=data.thread_id,
                channel=data.channel,
                delivery_address=data.delivery_address.model_dump() if data.delivery_address else None,
            )
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc
        except RateLimitedError as exc:
            raise HTTPException(429, str(exc)) from exc
        except NoPendingApprovalError as exc:
            raise HTTPException(409, str(exc)) from exc
        return result_json(result)

    @app.post("/v1/chat/{thread_id}/approval")
    async def approval(
        thread_id: str, data: ApprovalInput, caller: CallerDep, request: Request
    ) -> dict[str, Any]:
        try:
            result = await service(request).resume(
                caller, thread_id, approved=data.approved, tool_call_id=data.tool_call_id
            )
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc
        except NoPendingApprovalError as exc:
            raise HTTPException(409, str(exc)) from exc
        return result_json(result)

    @app.get("/v1/threads")
    async def threads(caller: CallerDep, request: Request) -> list[dict[str, Any]]:
        return await request.app.state.store.list_threads(caller.uid)

    @app.get("/v1/threads/{thread_id}/messages")
    async def messages(thread_id: str, caller: CallerDep, request: Request) -> list[dict[str, Any]]:
        try:
            return await service(request).history(caller, thread_id)
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc

    @app.delete("/v1/threads/{thread_id}", status_code=204)
    async def delete_thread(thread_id: str, caller: CallerDep, request: Request) -> None:
        try:
            await request.app.state.store.delete_thread(thread_id, caller.uid)
            await request.app.state.service.graph.checkpointer.adelete_thread(thread_id)
        except ThreadAccessError as exc:
            raise HTTPException(404, str(exc)) from exc

    def _require_ai_monitor(caller: Caller) -> None:
        if not caller.roles & {"operations_manager", "super_admin"}:
            raise HTTPException(403, "AI monitoring requires operations or super admin")

    @app.get("/v1/admin/metrics")
    async def metrics(
        caller: CallerDep, request: Request, days: Annotated[int, Query(ge=1, le=90)] = 7
    ) -> dict[str, Any]:
        _require_ai_monitor(caller)
        data = await request.app.state.store.metrics(days)
        return {**data, "model": request.app.state.service.model_name}

    @app.get("/v1/admin/tool-invocations")
    async def invocations(
        caller: CallerDep, request: Request, limit: Annotated[int, Query(ge=1, le=500)] = 100
    ) -> list[dict[str, Any]]:
        _require_ai_monitor(caller)
        return await request.app.state.store.recent_invocations(limit)

    return app


def app_factory() -> FastAPI:
    return create_app()
