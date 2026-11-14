"""Document store port (Firestore-shaped) and the in-memory adapter.

The in-memory adapter mirrors Firestore semantics that the services rely on: document paths,
`create` failing on existing documents, `update` failing on missing documents, dotted-path updates,
equality/range/array filters, ordering, limits and serialisable transactions.
"""

from __future__ import annotations

import asyncio
import copy
from collections import defaultdict
from collections.abc import Awaitable, Callable, Iterable, Sequence
from datetime import date, datetime
from decimal import Decimal
from enum import Enum
from typing import Any, Literal, Protocol, TypeVar

from pydantic import BaseModel

from ..errors import Conflict, NotFound

T = TypeVar("T")
Filter = tuple[str, str, Any]
OrderBy = tuple[str, Literal["asc", "desc"]]

SUPPORTED_OPS = {"==", "!=", "<", "<=", ">", ">=", "in", "not-in", "array_contains", "array_contains_any"}


def to_doc(value: Any) -> Any:
    """Convert models/enums/decimals into Firestore-compatible primitives (keeps datetimes)."""
    if isinstance(value, BaseModel):
        return to_doc(value.model_dump(mode="python"))
    if isinstance(value, Enum):
        return value.value
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, dict):
        return {str(k): to_doc(v) for k, v in value.items()}
    if isinstance(value, (list, tuple, set, frozenset)):
        return [to_doc(v) for v in value]
    if isinstance(value, date) and not isinstance(value, datetime):
        return value.isoformat()
    return value


def split_path(path: str) -> tuple[str, str]:
    parts = path.strip("/").split("/")
    if len(parts) < 2 or len(parts) % 2:
        raise ValueError(f"Not a document path: {path!r}")
    return "/".join(parts[:-1]), parts[-1]


def _get_field(doc: dict[str, Any], field_path: str) -> Any:
    cur: Any = doc
    for part in field_path.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur


def _set_field(doc: dict[str, Any], field_path: str, value: Any) -> None:
    parts = field_path.split(".")
    cur = doc
    for part in parts[:-1]:
        nxt = cur.get(part)
        if not isinstance(nxt, dict):
            nxt = {}
            cur[part] = nxt
        cur = nxt
    cur[parts[-1]] = value


def _matches(doc: dict[str, Any], flt: Filter) -> bool:
    field, op, expected = flt
    actual = _get_field(doc, field)
    try:
        if op == "==":
            return actual == expected
        if op == "!=":
            return actual is not None and actual != expected
        if op == "in":
            return actual in expected
        if op == "not-in":
            return actual is not None and actual not in expected
        if op == "array_contains":
            return isinstance(actual, list) and expected in actual
        if op == "array_contains_any":
            return isinstance(actual, list) and any(v in actual for v in expected)
        if actual is None:
            return False
        if op == "<":
            return actual < expected
        if op == "<=":
            return actual <= expected
        if op == ">":
            return actual > expected
        if op == ">=":
            return actual >= expected
    except TypeError:
        return False
    raise ValueError(f"Unsupported operator {op}")


def _sort_key(value: Any) -> tuple[int, Any]:
    # Firestore orders null first, then numbers/strings/timestamps. Mixed types are rare in practice.
    if value is None:
        return (0, 0)
    if isinstance(value, bool):
        return (1, int(value))
    if isinstance(value, (int, float)):
        return (2, value)
    if isinstance(value, datetime):
        return (3, value.timestamp())
    return (4, str(value))


class Transaction(Protocol):
    async def get(self, path: str) -> dict[str, Any] | None: ...
    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None: ...
    def create(self, path: str, data: dict[str, Any]) -> None: ...
    def update(self, path: str, data: dict[str, Any]) -> None: ...
    def delete(self, path: str) -> None: ...


class DocumentStore(Protocol):
    async def get(self, path: str) -> dict[str, Any] | None: ...
    async def get_many(self, paths: Sequence[str]) -> list[dict[str, Any] | None]: ...
    async def set(self, path: str, data: dict[str, Any], *, merge: bool = False) -> None: ...
    async def create(self, path: str, data: dict[str, Any]) -> None: ...
    async def update(self, path: str, data: dict[str, Any]) -> None: ...
    async def delete(self, path: str) -> None: ...
    async def query(
        self,
        collection: str,
        *,
        where: Iterable[Filter] = (),
        order_by: Iterable[OrderBy] = (),
        limit: int | None = None,
    ) -> list[dict[str, Any]]: ...
    async def run_transaction(self, fn: Callable[[Transaction], Awaitable[T]]) -> T: ...


# ------------------------------------------------------------------------------------------------
# In-memory adapter
# ------------------------------------------------------------------------------------------------


class _MemoryTxn:
    def __init__(self, store: MemoryDocumentStore) -> None:
        self._store = store
        self._writes: list[tuple[str, str, dict[str, Any] | None, bool]] = []
        self._wrote = False

    async def get(self, path: str) -> dict[str, Any] | None:
        if self._wrote:
            raise RuntimeError("Firestore transactions require all reads before writes")
        return self._store._read(path)

    def set(self, path: str, data: dict[str, Any], merge: bool = False) -> None:
        self._wrote = True
        self._writes.append(("set", path, to_doc(data), merge))

    def create(self, path: str, data: dict[str, Any]) -> None:
        self._wrote = True
        self._writes.append(("create", path, to_doc(data), False))

    def update(self, path: str, data: dict[str, Any]) -> None:
        self._wrote = True
        self._writes.append(("update", path, to_doc(data), False))

    def delete(self, path: str) -> None:
        self._wrote = True
        self._writes.append(("delete", path, None, False))


class MemoryDocumentStore:
    """Thread-unsafe, process-local store for tests and offline local development."""

    def __init__(self) -> None:
        self._collections: dict[str, dict[str, dict[str, Any]]] = defaultdict(dict)
        self._lock = asyncio.Lock()

    # -- internal helpers (no locking) --------------------------------------------------------
    def _read(self, path: str) -> dict[str, Any] | None:
        col, doc_id = split_path(path)
        doc = self._collections[col].get(doc_id)
        return copy.deepcopy(doc) if doc is not None else None

    def _apply(self, kind: str, path: str, data: dict[str, Any] | None, merge: bool) -> None:
        col, doc_id = split_path(path)
        docs = self._collections[col]
        if kind == "create":
            if doc_id in docs:
                raise Conflict("Document already exists", details={"path": path})
            docs[doc_id] = copy.deepcopy(data or {})
        elif kind == "set":
            if merge and doc_id in docs:
                merged = docs[doc_id]
                for k, v in (data or {}).items():
                    _set_field(merged, k, copy.deepcopy(v))
            else:
                docs[doc_id] = copy.deepcopy(data or {})
        elif kind == "update":
            if doc_id not in docs:
                raise NotFound("Document not found", details={"path": path})
            for k, v in (data or {}).items():
                _set_field(docs[doc_id], k, copy.deepcopy(v))
        elif kind == "delete":
            docs.pop(doc_id, None)

    # -- public API ---------------------------------------------------------------------------
    async def get(self, path: str) -> dict[str, Any] | None:
        return self._read(path)

    async def get_many(self, paths: Sequence[str]) -> list[dict[str, Any] | None]:
        return [self._read(p) for p in paths]

    async def set(self, path: str, data: dict[str, Any], *, merge: bool = False) -> None:
        async with self._lock:
            self._apply("set", path, to_doc(data), merge)

    async def create(self, path: str, data: dict[str, Any]) -> None:
        async with self._lock:
            self._apply("create", path, to_doc(data), False)

    async def update(self, path: str, data: dict[str, Any]) -> None:
        async with self._lock:
            self._apply("update", path, to_doc(data), False)

    async def delete(self, path: str) -> None:
        async with self._lock:
            self._apply("delete", path, None, False)

    async def query(
        self,
        collection: str,
        *,
        where: Iterable[Filter] = (),
        order_by: Iterable[OrderBy] = (),
        limit: int | None = None,
    ) -> list[dict[str, Any]]:
        filters = list(where)
        for _, op, _ in filters:
            if op not in SUPPORTED_OPS:
                raise ValueError(f"Unsupported operator {op}")
        docs = [
            d
            for d in self._collections[collection.strip("/")].values()
            if all(_matches(d, f) for f in filters)
        ]
        for field, direction in reversed(list(order_by)):
            docs.sort(key=lambda d, f=field: _sort_key(_get_field(d, f)), reverse=direction == "desc")
        if limit is not None:
            docs = docs[:limit]
        return copy.deepcopy(docs)

    async def run_transaction(self, fn: Callable[[Transaction], Awaitable[T]]) -> T:
        async with self._lock:
            txn = _MemoryTxn(self)
            result = await fn(txn)
            # Validate all writes before applying any (atomicity).
            snapshot = copy.deepcopy(self._collections)
            try:
                for kind, path, data, merge in txn._writes:
                    self._apply(kind, path, data, merge)
            except Exception:
                self._collections = snapshot
                raise
            return result

    # -- test helpers -------------------------------------------------------------------------
    def dump(self, collection: str) -> dict[str, dict[str, Any]]:
        return copy.deepcopy(self._collections[collection])
