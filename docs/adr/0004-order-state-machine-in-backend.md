# ADR-0004: Order state machine only in the API

**Status:** Accepted · **Date:** 2026-11-14

## Decision
`domain/order_state.py` defines every legal transition, the actors allowed to perform it and its guards.
`OrderService.transition` performs a compare-and-set inside a Firestore transaction and appends an
`order_events` record. Firestore rules deny client writes to `orders`. The AI can only call API endpoints
that internally use the same service.

## Consequences
- (+) One place to reason about the lifecycle; exhaustively unit-tested.
- (−) Every status change is an API call (acceptable; it also centralises notifications and audit).
