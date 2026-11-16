"""Runtime configuration (12-factor). Every value can be set through environment variables.

Secrets are `SecretStr` so they never appear in logs or reprs. In staging/production the
settings are validated strictly at startup (see `Settings.validate_for_environment`).
"""

from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

Environment = Literal["local", "test", "development", "staging", "production"]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    # --- service ---------------------------------------------------------------------------
    environment: Environment = "local"
    service_name: str = "gudmeal-api"
    log_level: str = "INFO"
    public_base_url: str = "http://localhost:8000"
    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:3000",  # customer web
            "http://localhost:3001",  # partner dashboard
            "http://localhost:3002",  # command centre
            "http://localhost:5050",  # Flutter customer app (web debug)
        ]
    )

    # --- data ------------------------------------------------------------------------------
    data_backend: Literal["memory", "firestore"] = "memory"
    seed_demo_data: bool = True  # only honoured with the memory backend
    gcp_project_id: str = "demo-gudmeal"
    database_url: str = "sqlite+aiosqlite:///./gudmeal_local.db"
    database_echo: bool = False

    # --- auth ------------------------------------------------------------------------------
    firebase_project_id: str = "demo-gudmeal"
    app_check_enforced: bool = False
    check_token_revocation: bool = True

    # --- payments --------------------------------------------------------------------------
    payment_default_provider: Literal["paystack", "flutterwave"] = "paystack"
    payment_callback_url: str = "http://localhost:3000/checkout/callback"
    paystack_secret_key: SecretStr | None = None
    paystack_base_url: str = "https://api.paystack.co"
    paystack_webhook_ip_allowlist: list[str] = Field(default_factory=list)
    flutterwave_secret_key: SecretStr | None = None
    flutterwave_secret_hash: SecretStr | None = None
    flutterwave_base_url: str = "https://api.flutterwave.com/v3"
    customer_email_fallback_domain: str = "customers.gudmeal.ng"
    refund_auto_approve_limit_kobo: int = 0  # 0 = every refund needs finance approval
    payment_http_timeout_seconds: float = 15.0
    # Backup gateway tried when the default one fails to start a checkout (only if it is configured).
    payment_failover_provider: str | None = "flutterwave"

    # --- Gud Meal wallet (closed-loop stored value: spend on Gud Meal only, no cash withdrawal) ---------
    # Limits are product defaults pending legal/CBN review (see docs/adr/0013-wallet-and-cash.md).
    wallet_enabled: bool = True
    wallet_min_topup_kobo: int = 50_000  # ₦500
    wallet_max_topup_kobo: int = 10_000_000  # ₦100,000 per top-up
    wallet_max_balance_kobo: int = 30_000_000  # ₦300,000

    # --- pay on delivery (cash to the rider) --------------------------------------------------------
    pay_on_delivery_enabled: bool = True  # the `pay_on_delivery` feature flag can switch it off live
    pay_on_delivery_max_kobo: int = 2_500_000  # ₦25,000 per order
    pay_on_delivery_min_completed_orders: int = 1  # build trust with one prepaid order first
    rider_cash_limit_kobo: int = 5_000_000  # riders carry at most ₦50,000 of collected cash

    # --- internal endpoints (Pub/Sub push, Cloud Tasks, Scheduler) -----------------------------
    internal_auth_mode: Literal["shared_secret", "oidc"] = "shared_secret"
    internal_shared_secret: SecretStr | None = None
    internal_oidc_audience: str | None = None
    internal_oidc_service_accounts: list[str] = Field(default_factory=list)

    # --- async infrastructure ----------------------------------------------------------------
    event_bus: Literal["inprocess", "pubsub"] = "inprocess"
    pubsub_topic: str = "gudmeal-domain-events"
    task_queue: Literal["inprocess", "cloudtasks"] = "inprocess"
    cloud_tasks_location: str = "europe-west1"
    cloud_tasks_queue: str = "gudmeal-default"
    cloud_tasks_service_account: str | None = None

    # --- notifications -------------------------------------------------------------------------
    notifier: Literal["log", "fcm"] = "log"

    # --- customer support contacts (shown in the apps' Support tab) -------------------------------
    # Placeholders until the owner provides real ones; `support_contacts_are_placeholders` lets apps flag them.
    support_whatsapp: str = "+234 000 000 0000"
    support_phone: str = "+234 000 000 0000"
    support_email: str = "support@example.com"
    support_hours: str = "Every day, 8am to 10pm"
    support_contacts_are_placeholders: bool = True

    # --- business rules -----------------------------------------------------------------------
    quote_ttl_seconds: int = 600
    unpaid_order_ttl_seconds: int = 1800
    restaurant_accept_timeout_seconds: int = 480
    dispatch_offer_timeout_seconds: int = 45
    delivery_code_max_attempts: int = 5
    code_pepper: SecretStr = SecretStr("local-dev-pepper-change-me")

    # --- maps ---------------------------------------------------------------------------------
    google_maps_api_key: SecretStr | None = None

    # --- Gudy on WhatsApp (ADR-0017): off until the Meta account, number and keys exist -----------
    whatsapp_enabled: bool = False
    whatsapp_provider: Literal["sandbox", "cloud"] = "sandbox"
    whatsapp_access_token: SecretStr | None = None  # permanent system-user token (Secret Manager)
    whatsapp_app_secret: SecretStr | None = None  # signs Meta's webhooks (X-Hub-Signature-256)
    whatsapp_verify_token: SecretStr | None = None  # chosen by us, entered in the Meta webhook settings
    whatsapp_phone_number_id: str | None = None
    whatsapp_business_number: str = "+234 000 000 0000"
    whatsapp_graph_version: str = "v21.0"
    # Delegated customer-only tokens for chat channels; shared with the agents service.
    channel_token_secret: SecretStr = SecretStr("local-dev-channel-secret-change-me")
    agents_base_url: str = "http://localhost:8100"
    public_web_url: str = "http://localhost:3000"

    @property
    def is_cloud(self) -> bool:
        return self.environment in ("development", "staging", "production")

    def validate_for_environment(self) -> None:
        """Fail fast on unsafe configuration outside local/test."""
        if self.environment not in ("staging", "production"):
            return
        problems: list[str] = []
        if self.data_backend != "firestore":
            problems.append("DATA_BACKEND must be 'firestore'")
        if self.database_url.startswith("sqlite"):
            problems.append("DATABASE_URL must point to PostgreSQL")
        if self.internal_auth_mode != "oidc":
            problems.append("INTERNAL_AUTH_MODE must be 'oidc'")
        if not self.internal_oidc_audience or not self.internal_oidc_service_accounts:
            problems.append("INTERNAL_OIDC_AUDIENCE and INTERNAL_OIDC_SERVICE_ACCOUNTS are required")
        if self.code_pepper.get_secret_value() == "local-dev-pepper-change-me":
            problems.append("CODE_PEPPER must be set from Secret Manager")
        if self.payment_default_provider == "paystack" and not self.paystack_secret_key:
            problems.append("PAYSTACK_SECRET_KEY is required")
        if self.event_bus != "pubsub" or self.task_queue != "cloudtasks":
            problems.append("EVENT_BUS=pubsub and TASK_QUEUE=cloudtasks are required")
        if self.seed_demo_data:
            problems.append("SEED_DEMO_DATA must be false")
        if self.environment == "production" and not self.app_check_enforced:
            problems.append("APP_CHECK_ENFORCED must be true in production")
        if self.channel_token_secret.get_secret_value() == "local-dev-channel-secret-change-me":
            problems.append("CHANNEL_TOKEN_SECRET must be set from Secret Manager")
        if self.whatsapp_enabled and not (
            self.whatsapp_provider == "cloud"
            and self.whatsapp_access_token
            and self.whatsapp_app_secret
            and self.whatsapp_verify_token
            and self.whatsapp_phone_number_id
        ):
            problems.append(
                "WHATSAPP_ENABLED needs WHATSAPP_PROVIDER=cloud and the WhatsApp access token, app secret, "
                "verify token and phone number id"
            )
        if problems:
            raise RuntimeError("Unsafe configuration: " + "; ".join(problems))


@lru_cache
def get_settings() -> Settings:
    return Settings()
