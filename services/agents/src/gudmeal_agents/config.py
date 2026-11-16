"""Agents service configuration (environment variables)."""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    environment: Literal["local", "test", "development", "staging", "production"] = "local"
    log_level: str = "INFO"
    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:3000",
            "http://localhost:3001",
            "http://localhost:3002",
            "http://localhost:5050",
        ]
    )

    # gudmeal-api (tools call it on behalf of the user)
    api_base_url: str = "http://localhost:8000"
    api_timeout_seconds: float = 15.0
    # How this service proves itself to the API (App Check is for client apps): a service-account OIDC token
    # in the cloud, the shared internal secret locally, or nothing when App Check is not enforced.
    internal_auth_mode: Literal["none", "shared_secret", "oidc"] = "none"
    internal_shared_secret: SecretStr | None = None
    api_oidc_audience: str | None = None  # defaults to api_base_url

    # Chat channels (ADR-0017): customer-only tokens minted by the API for WhatsApp conversations.
    channel_token_secret: SecretStr = SecretStr("local-dev-channel-secret-change-me")

    # Firebase (ID token verification)
    firebase_project_id: str = "demo-gudmeal"
    check_token_revocation: bool = False

    # Gemini — pin an explicit stable model id in staging/production (ADR-0011)
    google_api_key: SecretStr | None = None
    gemini_model: str = "gemini-flash-latest"
    gemini_fallback_model: str | None = None
    llm_temperature: float = 0.2
    llm_timeout_seconds: float = 30.0
    llm_max_retries: int = 2
    # Prices (USD per 1M tokens) used for cost tracking — set from the current price list.
    price_input_per_million_usd: float = 0.30
    price_output_per_million_usd: float = 2.50

    # Persistence
    checkpointer: Literal["memory", "sqlite", "postgres"] = "sqlite"
    checkpoint_sqlite_path: str = "./agents_checkpoints.sqlite"
    checkpoint_postgres_url: SecretStr | None = None  # postgresql://user:pass@host/db (psycopg)
    database_url: str = "sqlite+aiosqlite:///./gudmeal_agents.db"  # threads, audit, usage

    # Guardrails & limits
    max_message_chars: int = 2000
    max_graph_steps: int = 12
    tool_timeout_seconds: float = 20.0
    chat_rate_per_minute: int = 12
    history_messages: int = 30

    @property
    def llm_configured(self) -> bool:
        return self.google_api_key is not None

    def validate_for_environment(self) -> None:
        if self.environment not in ("staging", "production"):
            return
        problems = []
        if self.gemini_model.endswith("-latest"):
            problems.append("GEMINI_MODEL must be a pinned stable model id (not an alias)")
        if self.checkpointer != "postgres" or not self.checkpoint_postgres_url:
            problems.append("CHECKPOINTER=postgres and CHECKPOINT_POSTGRES_URL are required")
        if self.database_url.startswith("sqlite"):
            problems.append("DATABASE_URL must point to PostgreSQL")
        if not self.check_token_revocation:
            problems.append("CHECK_TOKEN_REVOCATION must be true")
        if self.channel_token_secret.get_secret_value() == "local-dev-channel-secret-change-me":
            problems.append("CHANNEL_TOKEN_SECRET must be set from Secret Manager (same value as the API)")
        if self.internal_auth_mode != "oidc":
            problems.append("INTERNAL_AUTH_MODE must be 'oidc' (service-account identity for API calls)")
        if problems:
            raise RuntimeError("Unsafe configuration: " + "; ".join(problems))


@lru_cache
def get_settings() -> Settings:
    return Settings()
