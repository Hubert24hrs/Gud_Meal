# ADR-0009: Repository ports with Firestore and in-memory adapters

**Status:** Accepted · **Date:** 2026-11-14

## Decision
Services depend on repository protocols. Production uses Firestore adapters (Admin SDK async client,
transactions for compare-and-set). Unit/API tests and offline local development use in-memory adapters
with the same semantics (locks emulate transactions). The Firestore adapters are exercised by contract
tests against the Firestore emulator in CI (`pytest -m firestore`).

## Consequences
- (+) Fast deterministic tests; the API runs locally even without the Java-based emulator.
- (−) Two implementations to keep aligned → shared contract test suite.
