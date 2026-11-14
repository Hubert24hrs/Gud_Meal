"""Structured JSON logging compatible with Cloud Logging (severity / message / trace fields)."""

from __future__ import annotations

import contextvars
import json
import logging
import sys
from datetime import UTC, datetime

request_id_var: contextvars.ContextVar[str | None] = contextvars.ContextVar("request_id", default=None)

_REDACT_EXACT = {
    "authorization",
    "password",
    "otp",
    "delivery_code",
    "pickup_code",
    "cvv",
    "pin",
    "card_number",
    "account_number",
    "bvn",
    "nin",
}
_REDACT_SUBSTR = ("secret", "api_key", "apikey", "id_token", "access_token", "refresh_token")


def _is_sensitive(key: str) -> bool:
    k = key.lower()
    return k in _REDACT_EXACT or any(s in k for s in _REDACT_SUBSTR)


def redact(value: object) -> object:
    """Recursively redact sensitive keys in log payloads."""
    if isinstance(value, dict):
        return {k: ("[REDACTED]" if _is_sensitive(str(k)) else redact(v)) for k, v in value.items()}
    if isinstance(value, list):
        return [redact(v) for v in value]
    return value


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "severity": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "time": datetime.fromtimestamp(record.created, UTC).isoformat(),
        }
        rid = request_id_var.get()
        if rid:
            payload["request_id"] = rid
        extra = getattr(record, "extra_fields", None)
        if isinstance(extra, dict):
            payload.update(redact(extra))  # type: ignore[arg-type]
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def configure_logging(level: str = "INFO") -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    root = logging.getLogger()
    root.handlers[:] = [handler]
    root.setLevel(level.upper())
    for noisy in ("httpx", "httpcore", "google", "urllib3", "aiosqlite", "asyncio"):
        logging.getLogger(noisy).setLevel("WARNING")


def log_event(logger: logging.Logger, message: str, level: int = logging.INFO, **fields: object) -> None:
    logger.log(level, message, extra={"extra_fields": fields})
