"""Cloud Firestore adapter for the DocumentStore port (google-cloud-firestore async client)."""

from __future__ import annotations

from collections.abc import Awaitable, Callable, Iterable, Sequence
from typing import Any, TypeVar

from google.api_core import exceptions as gexc
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from ..errors import Conflict, NotFound
from .store import SUPPORTED_OPS, Filter, OrderBy, Transaction, to_doc

T = TypeVar("T")

_OPS = {"array_contains": "array_contains", "array_contains_any": "array_contains_any"}


class _FirestoreTxn:
    def __init__(self, client: firestore.AsyncClient, tx: firestore.AsyncTransaction) -> None:
        self._client = client
        self._tx = tx

    async def get(self, path: str) -> dict[str, Any] | None:
        snap = await self._client.document(path).get(transaction=self._tx)
        return snap.to_dict() if snap.exists else None

    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        self._tx.set(self._client.document(path), to_doc(data), merge=merge)

    def create(self, path: str, data: dict[str, Any]) -> None:
        self._tx.create(self._client.document(path), to_doc(data))

    def update(self, path: str, data: dict[str, Any]) -> None:
        self._tx.update(self._client.document(path), to_doc(data))

    def delete(self, path: str) -> None:
        self._tx.delete(self._client.document(path))


class FirestoreDocumentStore:
    def __init__(self, client: firestore.AsyncClient) -> None:
        self._client = client

    @classmethod
    def from_project(cls, project_id: str) -> FirestoreDocumentStore:
        # Honours FIRESTORE_EMULATOR_HOST automatically.
        return cls(firestore.AsyncClient(project=project_id))

    async def get(self, path: str) -> dict[str, Any] | None:
        snap = await self._client.document(path).get()
        return snap.to_dict() if snap.exists else None

    async def get_many(self, paths: Sequence[str]) -> list[dict[str, Any] | None]:
        if not paths:
            return []
        refs = [self._client.document(p) for p in paths]
        found: dict[str, dict[str, Any] | None] = {}
        async for snap in self._client.get_all(refs):
            found[snap.reference.path] = snap.to_dict() if snap.exists else None
        return [found.get(ref.path) for ref in refs]

    async def set(self, path: str, data: dict[str, Any], *, merge: bool = False) -> None:
        await self._client.document(path).set(to_doc(data), merge=merge)

    async def create(self, path: str, data: dict[str, Any]) -> None:
        try:
            await self._client.document(path).create(to_doc(data))
        except gexc.AlreadyExists as exc:
            raise Conflict("Document already exists", details={"path": path}) from exc

    async def update(self, path: str, data: dict[str, Any]) -> None:
        try:
            await self._client.document(path).update(to_doc(data))
        except gexc.NotFound as exc:
            raise NotFound("Document not found", details={"path": path}) from exc

    async def delete(self, path: str) -> None:
        await self._client.document(path).delete()

    async def query(
        self,
        collection: str,
        *,
        where: Iterable[Filter] = (),
        order_by: Iterable[OrderBy] = (),
        limit: int | None = None,
    ) -> list[dict[str, Any]]:
        q: Any = self._client.collection(collection)
        for field, op, value in where:
            if op not in SUPPORTED_OPS:
                raise ValueError(f"Unsupported operator {op}")
            q = q.where(filter=FieldFilter(field, _OPS.get(op, op), to_doc(value)))
        for field, direction in order_by:
            q = q.order_by(
                field,
                direction=firestore.Query.DESCENDING if direction == "desc" else firestore.Query.ASCENDING,
            )
        if limit is not None:
            q = q.limit(limit)
        return [snap.to_dict() async for snap in q.stream()]

    async def run_transaction(self, fn: Callable[[Transaction], Awaitable[T]]) -> T:
        transaction = self._client.transaction()

        @firestore.async_transactional
        async def _run(tx: firestore.AsyncTransaction) -> T:
            return await fn(_FirestoreTxn(self._client, tx))

        try:
            return await _run(transaction)
        except gexc.AlreadyExists as exc:
            raise Conflict("Document already exists") from exc
        except gexc.NotFound as exc:
            raise NotFound("Document not found") from exc
