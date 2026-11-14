"""Request idempotency backed by PostgreSQL (`idempotency_records`).

Usage: `begin()` claims (scope, key) or returns a stored replay; `finish()` stores the response;
`release()` frees the key after an unexpected failure so the client can retry.
"""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError

from ..errors import Conflict, IdempotencyConflict, ValidationFailed
from .db import Database
from .tables import IdempotencyRecord

KEY_PATTERN = re.compile(r"^[A-Za-z0-9_\-:.]{8,200}$")
STALE_IN_PROGRESS = timedelta(seconds=90)


def request_hash(payload: Any) -> str:
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


def validate_key(key: str | None) -> str:
    if not key or not KEY_PATTERN.match(key):
        raise ValidationFailed(
            "A valid Idempotency-Key header is required (8-200 chars: letters, digits, _ - : .)"
        )
    return key


@dataclass(frozen=True)
class Replay:
    status_code: int
    body: Any


class IdempotencyService:
    def __init__(self, db: Database, ttl: timedelta = timedelta(hours=24)) -> None:
        self.db = db
        self.ttl = ttl

    async def begin(self, scope: str, key: str, req_hash: str) -> Replay | None:
        now = datetime.now(UTC)
        async with self.db.transaction() as s:
            rec = await s.scalar(
                select(IdempotencyRecord)
                .where(IdempotencyRecord.scope == scope, IdempotencyRecord.key == key)
                .with_for_update()
            )
            if rec is not None:
                if _aware(rec.expires_at) < now:
                    await s.delete(rec)
                    await s.flush()
                else:
                    if rec.request_hash != req_hash:
                        raise IdempotencyConflict("Idempotency-Key was already used with a different request")
                    if rec.status == "completed":
                        return Replay(rec.response_status or 200, rec.response_body)
                    if now - _aware(rec.created_at) < STALE_IN_PROGRESS:
                        raise Conflict("A request with this Idempotency-Key is still being processed")
                    rec.created_at = now  # take over a stale claim
                    return None
            try:
                async with s.begin_nested():
                    s.add(
                        IdempotencyRecord(
                            scope=scope,
                            key=key,
                            request_hash=req_hash,
                            status="in_progress",
                            created_at=now,
                            expires_at=now + self.ttl,
                        )
                    )
                    await s.flush()
            except IntegrityError as exc:
                raise Conflict("A request with this Idempotency-Key is still being processed") from exc
        return None

    async def finish(self, scope: str, key: str, status_code: int, body: Any) -> None:
        async with self.db.transaction() as s:
            rec = await s.scalar(
                select(IdempotencyRecord).where(
                    IdempotencyRecord.scope == scope, IdempotencyRecord.key == key
                )
            )
            if rec is not None:
                rec.status = "completed"
                rec.response_status = status_code
                rec.response_body = body

    async def release(self, scope: str, key: str) -> None:
        async with self.db.transaction() as s:
            await s.execute(
                delete(IdempotencyRecord).where(
                    IdempotencyRecord.scope == scope,
                    IdempotencyRecord.key == key,
                    IdempotencyRecord.status == "in_progress",
                )
            )

    async def purge_expired(self) -> int:
        async with self.db.transaction() as s:
            result = await s.execute(
                delete(IdempotencyRecord).where(IdempotencyRecord.expires_at < datetime.now(UTC))
            )
            return int(result.rowcount or 0)  # type: ignore[attr-defined]


def _aware(dt: datetime) -> datetime:
    # SQLite returns naive datetimes; they are stored in UTC.
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)
