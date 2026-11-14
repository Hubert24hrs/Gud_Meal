"""Model access (Gemini via langchain-google-genai) with fallback, plus usage/cost accounting."""

from __future__ import annotations

from typing import Any, Protocol

from langchain_core.messages import AIMessage

from .config import Settings


class Invocable(Protocol):
    async def ainvoke(self, input: Any, config: Any | None = None, **kwargs: Any) -> Any: ...


class ModelFactory(Protocol):
    model_name: str

    def for_tools(self, tools: list[dict[str, Any]]) -> Invocable: ...

    def for_structured(self, schema: type) -> Invocable: ...


class GeminiFactory:
    def __init__(self, settings: Settings) -> None:
        from langchain_google_genai import ChatGoogleGenerativeAI

        if settings.google_api_key is None:
            raise RuntimeError("GOOGLE_API_KEY is not set")
        common = {
            "temperature": settings.llm_temperature,
            "max_retries": settings.llm_max_retries,
            "timeout": settings.llm_timeout_seconds,
            "google_api_key": settings.google_api_key.get_secret_value(),
        }
        self.model_name = settings.gemini_model
        self._primary = ChatGoogleGenerativeAI(model=settings.gemini_model, **common)
        self._fallback = (
            ChatGoogleGenerativeAI(model=settings.gemini_fallback_model, **common)
            if settings.gemini_fallback_model
            else None
        )

    def for_tools(self, tools: list[dict[str, Any]]) -> Invocable:
        primary: Any = self._primary.bind_tools(tools) if tools else self._primary
        if self._fallback is not None:
            fb = self._fallback.bind_tools(tools) if tools else self._fallback
            return primary.with_fallbacks([fb])  # type: ignore[no-any-return]
        return primary  # type: ignore[no-any-return]

    def for_structured(self, schema: type) -> Invocable:
        primary: Any = self._primary.with_structured_output(schema)
        if self._fallback is not None:
            return primary.with_fallbacks([self._fallback.with_structured_output(schema)])  # type: ignore[no-any-return]
        return primary  # type: ignore[no-any-return]


def usage_of(message: AIMessage) -> tuple[int, int]:
    meta = getattr(message, "usage_metadata", None) or {}
    return int(meta.get("input_tokens", 0) or 0), int(meta.get("output_tokens", 0) or 0)


def cost_usd(input_tokens: int, output_tokens: int, settings: Settings) -> float:
    return round(
        input_tokens / 1e6 * settings.price_input_per_million_usd
        + output_tokens / 1e6 * settings.price_output_per_million_usd,
        8,
    )


def text_of(message: AIMessage) -> str:
    content = message.content
    if isinstance(content, str):
        return content
    parts = []
    for part in content:
        if isinstance(part, str):
            parts.append(part)
        elif isinstance(part, dict) and part.get("type") == "text":
            parts.append(str(part.get("text", "")))
    return "".join(parts)
