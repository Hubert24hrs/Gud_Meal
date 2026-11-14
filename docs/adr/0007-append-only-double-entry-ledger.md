# ADR-0007: Append-only double-entry ledger

**Status:** Accepted · **Date:** 2026-11-14

## Decision
`financial_transactions` + `ledger_entries` in PostgreSQL. Entries are positive amounts with a
debit/credit direction. Balance is enforced in code and by a deferred constraint trigger; `UPDATE` and
`DELETE` are rejected by triggers. Corrections are reversing transactions. Each transaction has a unique
idempotency key so retried postings are no-ops.

## Consequences
- (+) Auditable, reconcilable, tamper-evident.
- (−) Balances are aggregates (add materialised snapshots when volume requires it).
