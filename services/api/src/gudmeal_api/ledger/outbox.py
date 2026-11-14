"""Transactional outbox: events are written in the same DB transaction as the money change, then relayed."""

from __future__ import annotations

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..logging_setup import log_event
from .db import Database
from .tables import OutboxEvent, new_id

logger = logging.getLogger(__name__)
CLAIM_TTL = timedelta(seconds=60)


def add_outbox_event(session: AsyncSession, topic: str, payload: dict[str, Any]) -> str:
    event_id = new_id()
    session.add(OutboxEvent(id=event_id, topic=topic, payload={**payload, "event_id": event_id}))
    return event_id


class OutboxRelay:
    def __init__(self, db: Database, bus: Any) -> None:
        self.db = db
        self.bus = bus

    async def relay_pending(self, limit: int = 50) -> int:
        now = datetime.now(UTC)
        async with self.db.transaction() as s:
            stmt = (
                select(OutboxEvent)
                .where(
                    OutboxEvent.published_at.is_(None),
                    or_(OutboxEvent.claimed_until.is_(None), OutboxEvent.claimed_until < now),
                )
                .order_by(OutboxEvent.created_at)
                .limit(limit)
            )
            if self.db.dialect == "postgresql":
                stmt = stmt.with_for_update(skip_locked=True)
            rows = list((await s.execute(stmt)).scalars())
            claimed = [(r.id, r.topic, dict(r.payload)) for r in rows]
            for r in rows:
                r.claimed_until = now + CLAIM_TTL

        published = 0
        for event_id, topic, payload in claimed:
            error: str | None = None
            try:
                await self.bus.publish(topic, payload)
            except Exception as exc:  # handlers are retried by the next relay run
                error = f"{type(exc).__name__}: {exc}"[:1000]
                log_event(
                    logger,
                    "outbox publish failed",
                    logging.WARNING,
                    topic=topic,
                    event_id=event_id,
                    error=error,
                )
            async with self.db.transaction() as s:
                row = await s.get(OutboxEvent, event_id)
                if row is None:
                    continue
                row.attempts += 1
                row.claimed_until = None
                if error is None:
                    row.published_at = datetime.now(UTC)
                    published += 1
                else:
                    row.last_error = error
        return published
