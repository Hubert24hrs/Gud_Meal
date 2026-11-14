# ADR-0002: Firestore for real-time data, PostgreSQL for money

**Status:** Accepted · **Date:** 2026-11-14

## Context
Clients need live order and rider updates with offline support (Firestore's strength). Finance needs
ACID multi-row transactions, constraints, append-only guarantees and SQL reporting (PostgreSQL's strength).

## Decision
Firestore is the primary application database. Cloud SQL PostgreSQL is authoritative for payments, the
double-entry ledger, settlements, idempotency, audit events and LangGraph checkpoints. Cross-store
consistency uses the transactional outbox (ADR-0010): PostgreSQL commits first, Firestore is updated by
idempotent event handlers.

## Consequences
- (+) Each store used for its strength; finance auditable with SQL.
- (−) Two stores to operate; a reconciliation job compares order totals with payment records.
