"""Append-only audit trail for privileged and financial actions."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..logging_setup import redact, request_id_var
from .db import Database
from .tables import AuditEvent


class AuditLog:
    def __init__(self, db: Database) -> None:
        self.db = db

    @staticmethod
    def add(
        session: AsyncSession,
        *,
        actor_id: str,
        actor_roles: list[str] | None,
        action: str,
        resource_type: str,
        resource_id: str,
        details: dict[str, Any] | None = None,
    ) -> None:
        session.add(
            AuditEvent(
                occurred_at=datetime.now(UTC),
                actor_id=actor_id,
                actor_roles=sorted(actor_roles or []),
                action=action,
                resource_type=resource_type,
                resource_id=resource_id,
                details=redact(details or {}),  # type: ignore[arg-type]
                request_id=request_id_var.get(),
            )
        )

    async def record(self, **kwargs: Any) -> None:
        async with self.db.transaction() as s:
            self.add(s, **kwargs)

    async def list(
        self,
        *,
        resource_type: str | None = None,
        resource_id: str | None = None,
        actor_id: str | None = None,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        stmt = select(AuditEvent).order_by(AuditEvent.occurred_at.desc()).limit(min(limit, 500))
        if resource_type:
            stmt = stmt.where(AuditEvent.resource_type == resource_type)
        if resource_id:
            stmt = stmt.where(AuditEvent.resource_id == resource_id)
        if actor_id:
            stmt = stmt.where(AuditEvent.actor_id == actor_id)
        async with self.db.session() as s:
            rows = (await s.execute(stmt)).scalars().all()
        return [
            {
                "id": r.id,
                "occurred_at": r.occurred_at,
                "actor_id": r.actor_id,
                "actor_roles": r.actor_roles,
                "action": r.action,
                "resource_type": r.resource_type,
                "resource_id": r.resource_id,
                "details": r.details,
                "request_id": r.request_id,
            }
            for r in rows
        ]
