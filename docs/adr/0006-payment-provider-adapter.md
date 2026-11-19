# ADR-0006: Payment provider adapter; platform collects then settles

**Status:** Accepted · **Date:** 2026-11-14

## Context
Paystack and Flutterwave both serve Nigeria. Split / sub-account settlement availability depends on the
merchant account configuration and compliance status, which cannot be assumed.

## Decision
A `PaymentProvider` protocol (`initialize`, `verify`, `refund`, `verify_webhook`, `parse_webhook`) with
Paystack (primary) and Flutterwave adapters. Yummy Chops collects the full amount, records it in the ledger
and settles restaurants and riders on a configurable schedule from ledger balances. Split settlement can
be added later as a provider capability without changing the ledger model.

## Consequences
- (+) Works with any merchant account; one reconciliation model.
- (−) The platform holds funds temporarily — requires settlement operations and a legal review of
  fund-holding rules before launch.
