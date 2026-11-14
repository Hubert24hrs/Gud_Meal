# ADR-0005: Integer kobo and server-stored quotes

**Status:** Accepted · **Date:** 2026-11-14

## Decision
All money is an `int` number of kobo (₦1 = 100 kobo). The pricing engine computes subtotal, fees,
discounts and VAT with integer arithmetic and explicit half-up rounding. A quote is persisted server-side
with a 10-minute TTL; orders are created from a `quote_id` and re-validated (availability, opening hours,
unchanged prices). Clients and the AI never submit amounts.

## Consequences
- (+) No floating-point errors; tamper-proof totals; identical numbers in UI, AI and ledger.
- (−) Quotes must be refreshed when they expire (handled transparently by the clients).
