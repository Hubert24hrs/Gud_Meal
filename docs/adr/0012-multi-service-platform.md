# ADR-0012: One order pipeline for Food, Beauty & Skin care and Package Delivery

**Status:** Accepted · **Date:** 2026-11-15

## Context
The owner decided (2026-11-15) that Yummy Chops offers three services in Lagos and Enugu: Food (restaurants),
Beauty & Skin care (products from partner shops) and Package Delivery (bike courier; scheduled pickups now,
cash-on-delivery for vendors and interstate waybill later), with a Glovo-style customer experience and an AI
assistant, Yummy, that speaks English, Nigerian Pidgin, Igbo, Yoruba and Hausa.

The existing pipeline (server quote → order → verified payment → merchant → dispatch → rider OTP → settlement in
an append-only ledger) is the most valuable and most tested part of the system.

## Decision
- **Merchants carry a `vertical`** (`food` | `beauty`) and a `city` (`lagos` | `enugu`). Beauty shops are
  ordinary merchants with `kind=product` items (optional `unit_label`, e.g. "30 ml"); they reuse quotes, the
  state machine, partner dashboard, dispatch and settlement unchanged. Delivery zones belong to a city.
- **Parcels are orders with `vertical=parcel`** and no merchant: the pickup point takes the merchant's place
  (`restaurant_location/address`), so dispatch, the rider app, tracking, OTP delivery and the ledger work
  unchanged. Prices come only from `compute_parcel_price` in `domain/pricing.py` (size + road km, ₦50 rounding,
  booking fee, VAT on fees). Settlement posts no merchant liability and no commission.
- **One new state transition**, `paid → ready_for_pickup` (system only, parcels only, enforced in
  `OrderService`), released immediately or 30 minutes before a scheduled pickup by a Cloud Task. Customers may
  cancel a parcel with a full automatic refund until a rider is assigned.
- **Browse categories** (Promotions, Local food, International… / Skincare, Hair care…) are a mapping over
  merchant cuisines in `domain/catalog_groups.py`; promotions are merchant-specific vouchers.
- **Neighbourhood gazetteer** (`domain/places.py`) places addresses without a map pin until Google Maps is
  configured; every listed area is tested to fall inside a delivery zone of its own city.
- **Yummy offline mode**: without a Gemini key a deterministic, rule-based model drives the same LangGraph graph,
  so every action still goes through tool validation, permissions, rate limits, audit and approval screens.

## Consequences
- (+) Beauty and parcels inherited payments, refunds, dispatch, tracking, ledger and audit with ~1 new transition.
- (+) Customer totals (`/v1/me/order-summary`) and the assistant work across services from day one.
- (−) Field names still say `restaurant_*`; a rename to `merchant_*` would touch every client and is deferred.
- (−) Interstate waybill needs hub/partner states that do not fit this model; it gets its own design (Phase 3).
- (−) Offline Yummy understands a fixed set of intents and replies fully only in English and Pidgin.
