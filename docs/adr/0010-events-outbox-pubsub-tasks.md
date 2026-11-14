# ADR-0010: Transactional outbox → Pub/Sub; Cloud Tasks for timers

**Status:** Accepted · **Date:** 2026-11-14

## Decision
Financial commits write an `outbox_events` row in the same PostgreSQL transaction. A relay publishes
events to Pub/Sub (`EVENT_BUS=pubsub`) or dispatches in-process (`EVENT_BUS=inprocess`, local and tests).
Push subscriptions deliver to `/internal/events` (OIDC-verified). Handlers are idempotent. Timed work
(rider offer expiry, unpaid order expiry) uses Cloud Tasks HTTP targets; Cloud Scheduler triggers
reconciliation jobs.

## Consequences
- (+) No lost side effects after a successful payment; retries are safe.
- (−) Eventual consistency (typically sub-second) between the ledger and order status.
