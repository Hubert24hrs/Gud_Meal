# API reference

- Interactive docs (local): http://localhost:8000/docs (FastAPI / OpenAPI 3.1). Disabled in production.
- Machine-readable spec: [`packages/api-client/openapi.json`](../packages/api-client/openapi.json)
  (regenerate with `uv run python scripts/export_openapi.py ../../packages/api-client/openapi.json` in `services/api`).
- Agents service: http://localhost:8100/docs — `POST /v1/chat`, `POST /v1/chat/{thread_id}/approval`,
  `GET /v1/threads`, `GET /v1/threads/{id}/messages`, `DELETE /v1/threads/{id}`, `GET /v1/admin/metrics`.

## Conventions

| Topic | Rule |
|---|---|
| Auth | `Authorization: Bearer <Firebase ID token>`; optional `X-Firebase-AppCheck` (required when enforced) |
| Money | integer kobo, fields end in `_kobo` |
| Idempotency | `Idempotency-Key` header (8–200 chars) required on `POST /v1/orders`, `POST /v1/orders/{id}/checkout`, `POST /v1/rider/payouts`; replays return the stored response with `Idempotent-Replayed: true` |
| Errors | `{"error": {"code", "message", "details", "request_id"}}` with stable codes (`price_changed`, `quote_expired`, `invalid_transition`, `voucher_invalid`, `out_of_delivery_area`, `rate_limited`, …) |
| Webhooks | `POST /v1/webhooks/paystack` (`x-paystack-signature`), `POST /v1/webhooks/flutterwave` (`verif-hash`) |
| Internal | `/internal/*` accepts only Google OIDC tokens from allowed service accounts (shared secret locally) |

## Route groups

`/v1` public catalog · `/v1/me`, `/v1/quotes`, `/v1/orders`, `/v1/payments`, `/v1/meal-plans`, `/v1/support`,
`/v1/applications` (customers) · `/v1/partner/restaurants/{id}/…` (restaurant roles) · `/v1/rider/…` (riders) ·
`/v1/admin/…` (staff permissions) · `/internal/tasks|events|jobs` (Cloud Tasks, Pub/Sub, Scheduler).

## Multi-service endpoints (2026-11-15)

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/services?city=` | public | Food, Beauty & Skin care, Package Delivery: availability, partner counts, coming-soon options |
| `GET /v1/services/{food\|beauty}/categories?city=` | public | Browse categories with merchant counts (Promotions, Local food, Skincare…) |
| `GET /v1/restaurants?vertical=food\|beauty\|all&city=&category=&pickup=` | public | Merchants for a service; cards carry `vertical`, `city`, `promotions` |
| `GET /v1/search?q=&vertical=&city=` | public | Dishes/products and stores; each hit carries its `vertical` |
| `GET /v1/cities` · `GET /v1/places/areas?city=` · `GET /v1/places/resolve?q=` | public | Launch cities and neighbourhood centres for addresses without a map pin |
| `POST /v1/parcels/quotes` · `GET /v1/parcels/quotes/{id}` | customer | Price a package delivery (same city, size, contents, optional `scheduled_for`) |
| `POST /v1/parcels` (Idempotency-Key) | customer | Create the parcel order from a quote; pay with `POST /v1/orders/{id}/checkout` |
| `GET /v1/me/order-summary` | customer | Paid orders, total spent (net of refunds), per service, this month, favourite store |

## Wallet, pay on delivery and cash on delivery (phase 2)

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/wallet` · `GET /v1/wallet/transactions` | customer | Balance, limits, refund setting, statement, seller COD summary |
| `POST /v1/wallet/topups` (Idempotency-Key) | customer | Start a gateway checkout that credits the wallet once verified |
| `PUT /v1/wallet/settings` | customer | `refund_to_wallet`: card refunds go instantly to the wallet |
| `GET /v1/orders/{id}/payment-options` | customer | Card / wallet / pay on delivery, each with `available` and a `reason` |
| `POST /v1/orders/{id}/checkout` `{"provider": "wallet" \| "cash"}` | customer | Pay from the wallet (instant) or choose pay on delivery (server checks eligibility) |
| `GET /v1/seller/balance` | customer | Cash-on-delivery money collected for you, payouts, statement |
| `POST /v1/seller/payouts` · `POST /v1/seller/move-to-wallet` (Idempotency-Key) | customer | Withdraw COD money to a bank account (finance pays) or move it to the wallet |
| `POST /v1/rider/deliveries/{id}/deliver` `{"code", "cash_collected"}` | rider | `cash_collected: true` is required when the order has cash to collect |
| `GET /v1/admin/cash` | finance | Cash held per rider, wallet and seller balances |
| `POST /v1/admin/riders/{uid}/cash-remittances` (Idempotency-Key) | finance | Record a hand-in (bank transfer, cash deposit) or deduct from earnings |
| `GET /v1/admin/seller-payouts` · `POST /v1/admin/seller-payouts/{id}/decision` | finance | Review seller withdrawals; paid needs the bank reference |
| `PUT /v1/admin/customers/{uid}/pay-on-delivery` | support | Turn pay on delivery off/on for a customer (audited) |

Parcel quotes accept `cod_amount_kobo`; the breakdown then includes `cod_fee_kobo`. Rider order views include
`payment_method` (`cash` | `prepaid`) and `collect_cash_kobo`. `GET /v1/config/public` adds `wallet`,
`pay_on_delivery` and `cash_on_delivery` limits.

Parcel orders are ordinary orders with `vertical: "parcel"` and a `parcel` object (pickup/drop-off contacts,
size, contents); they skip the merchant (`paid → ready_for_pickup`) and are cancellable with a full refund until a
rider is assigned. `GET /v1/config/public` also returns `cities` and `support` contacts (`placeholders: true` until
real contacts are configured).

## Maps and location (Google Maps Platform, see [GOOGLE_MAPS.md](GOOGLE_MAPS.md))

All Google calls happen inside the API with a server key; without a key the same endpoints answer from the
neighbourhood table and straight-line estimates. Responses say which: `provider` / `source` is `google`, `local`
or `estimate`, and `precision` is `rooftop`, `street`, `area` or `approximate`.

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/places/autocomplete?q=&session=&lat=&lng=&city=` | signed in | Address suggestions in Nigeria, biased to the user; `session` groups one search for billing |
| `GET /v1/places/details?place_id=&session=` | signed in | The chosen place: address, pin, area, city, plus `serviceable` and `zone` |
| `GET /v1/places/reverse?lat=&lng=` | signed in | "Use my location": the device's own fix with the nearest address or neighbourhood |
| `GET /v1/delivery/estimates?restaurant_ids=&lat=&lng=` | signed in | Up to 10 kitchens: road distance, travel and arrival minutes, delivery fee, `delivers`, `source` |
| `GET` · `PUT /v1/partner/restaurants/{id}/location` | restaurant owner/manager | The kitchen's pin and address; checked against the address (422 with `suggested_location`, or `confirm_pin: true`); moves over 2 km and radius changes are staff-only; audited |
| `GET /v1/admin/riders/live` | dispatch | Online riders for the operations map; idle riders only have an area-level position |
| `GET /v1/admin/maps/status` | config readers | Provider, routes mode, traffic-aware, requests today and the daily cap |

`GET /v1/orders/{id}/tracking` now returns `rider_location`, `eta_minutes`, `eta_source` and `route_polyline`
(current leg, Google encoded polyline) only while a rider is on that delivery, plus `pickup_location` and
`dropoff_location`. `POST /v1/rider/location` is refused with `invalid_transition` (409) while the rider is
offline. Quotes and parcel quotes include `road_distance_km` and `route_source`; delivery fees use the measured
road distance when Google answered. The places endpoints share the `places` rate limit (40 burst, 0.5/s per user).
