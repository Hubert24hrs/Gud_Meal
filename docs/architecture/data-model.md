# Data Model

Two stores, each with a clear job (ADR-0002):

- **Cloud Firestore** — real-time application data that clients read through listeners.
- **Cloud SQL PostgreSQL** — money, idempotency, audit and AI checkpoints. Authoritative for finance.

All timestamps are UTC (`SERVER_TIMESTAMP` in Firestore, `timestamptz` in Postgres). Business logic
that depends on local time (opening hours, "deliver before 8pm") uses `Africa/Lagos`.
All money fields are integers in **kobo** and end with `_kobo`.

## Firestore collections

| Collection | Key | Written by | Readable by | Notes |
|---|---|---|---|---|
| `users/{uid}` | uid | API | owner, staff | roles mirror of custom claims, display info |
| `customer_profiles/{uid}` | uid | API | owner | dietary prefs, allergies, personalisation consent |
| `customer_profiles/{uid}/addresses/{id}` | auto | API | owner | saved delivery addresses |
| `restaurant_profiles/{rid}` | rid | API | public (if `status == active`) | name, cuisine, rating, hours, geo, zone |
| `restaurant_locations/{rid}` | rid | API | public | geohash + lat/lng for proximity queries |
| `restaurant_menus/{rid}` | rid | API | public | ordered category list (small, bounded) |
| `food_items/{itemId}` | auto | API | public (active restaurants) | price_kobo, category, tags, availability |
| `food_customisations/{groupId}` | auto | API | public | option groups referenced by items |
| `food_categories/{id}` | slug | API | public | platform-wide categories for discovery |
| `carts/{uid}` | uid | **owner** (validated) | owner | convenience only — never used for pricing |
| `quotes/{quoteId}` | auto | API | owner | server price quote; TTL 10 min |
| `orders/{orderId}` | auto | API only | customer, restaurant staff, assigned rider, staff | status machine, totals snapshot |
| `orders/{id}/customer_private/codes` | fixed | API | customer only | delivery / pickup codes |
| `order_events/{eventId}` | auto | API | same as order | append-only status history |
| `rider_profiles/{uid}` | uid | API | owner, staff | verification, vehicle, rating, status |
| `rider_locations/{uid}` | uid | API (rider via API) | staff, dispatch | last known location, geohash, TTL |
| `delivery_assignments/{id}` | auto | API | assigned rider, staff | offer → accepted/declined/expired |
| `delivery_tracking/{orderId}` | orderId | API | customer, staff | coarse rider position while in transit |
| `reviews/{id}` | auto | API | public | one per order |
| `promotions/{id}`, `vouchers/{code}` | — | API | staff (vouchers resolved via API) | |
| `loyalty_accounts/{uid}` | uid | API | owner | points balance mirror |
| `support_tickets/{id}` | auto | API | owner, support staff | |
| `notifications/{id}` | auto | API | recipient | in-app inbox |
| `agent_conversations/{threadId}` | thread | agents service | owner | titles & summaries only |
| `agent_activity_logs/{id}` | auto | agents service | staff | tool invocations (redacted) |
| `platform_configuration/{doc}` | fixed | API (admin) | staff; selected public fields | fees, commission, zones |
| `feature_flags/{flag}` | flag | API (admin) | public (non-sensitive) | |
| `applications/{id}` | auto | API | owner, staff | restaurant / rider onboarding |
| `waybill_quotes/{id}` | auto | API | owner (via API) | interstate waybill quote (price, route, expected dates) |
| `waybill_tracking/{code}` | tracking number | API | API only | maps a public tracking number to its order |
| `memberships/{uid}` (+ `periods/{payment_id}`) | uid | API | owner (via API) | GudMeals Plus: paid-through date, auto-renew, one period per payment |
| `loyalty_accounts/{uid}` (+ `entries/{id}`) | uid | API | owner (via API) | Gud points balance, referral state; append-only entries |
| `referral_codes/{code}` | code | API | API only | referral code → customer |
| `group_orders/{id}` · `group_codes/{code}` | auto · code | API | members (via API) | shared cart, members, items, shares; join code → group |
| `whatsapp_links/{wa_id}` | WhatsApp number | API | API only | the linked account, Gudy thread, pending approval and shared location ([ADR-0017](../adr/0017-gudy-on-whatsapp.md)) |
| `whatsapp_accounts/{uid}` | uid | API | owner (via API, masked) | the number linked to an account (one number per account, one account per number) |
| `whatsapp_link_codes/{code}` | 6-digit code | API | API only | one-time link codes: single use, 10 minutes (TTL on `expire_at`) |
| `whatsapp_messages/{id}` | WhatsApp message id | API | API only | de-duplication of Meta's retries, no message content (TTL 7 days on `expire_at`) |

Orders carry a `channel`: `app`, `web`, `ai_agent` (Gudy in the app or on the website), `whatsapp` (Gudy on
WhatsApp) or `admin`. Support tickets use the same values, with `phone` in place of `admin`.

Interstate waybills are `orders` with `vertical = "waybill"` and a `waybill` object (tracking number, hubs,
parties, stage, milestones). Their rider jobs are `orders` with `leg_of` / `leg_kind`. The network (cities, hubs,
carriers, lanes) is `platform_configuration/logistics` ([ADR-0015](../adr/0015-interstate-waybill.md)).

Bounded documents: menus are split into item documents; order line items are capped (50); event
history lives in `order_events`, not arrays on the order.

## PostgreSQL tables (`services/api/migrations`)

| Table | Purpose | Mutability |
|---|---|---|
| `financial_accounts` | chart of accounts (code, type, owner) | insert-only (deactivate flag) |
| `financial_transactions` | one business event (payment, settlement, refund, payout) | **append-only** (trigger) |
| `ledger_entries` | debit/credit lines | **append-only** (trigger) + balance constraint trigger |
| `payment_records` | provider payments, status | status updates only, history in `payment_events` |
| `payment_events` | webhook & verification history, dedupe | append-only |
| `refund_records` | refund requests & approvals | status updates, audited |
| `restaurant_settlements` | settlement statements | status updates, audited |
| `rider_payouts` | withdrawal requests | status updates, audited |
| `commission_records` | commission per order | append-only |
| `idempotency_records` | request dedupe (scope, key) | expires (TTL job) |
| `outbox_events` | transactional outbox → Pub/Sub | publish status |
| `audit_events` | who did what, when | **append-only** (trigger) |

The agents service owns a separate database (`gudmeal_agents`) with LangGraph checkpoint tables,
`agent_threads`, `agent_tool_invocations` and `agent_usage`.

## Indexes

Firestore composite indexes are declared in [`firebase/firestore.indexes.json`](../../firebase/firestore.indexes.json)
(orders by restaurant + status + created time, by customer + created time, by rider + status; food items by
restaurant + category; restaurants by zone + status + rating). Postgres indexes are part of the Alembic migration.
