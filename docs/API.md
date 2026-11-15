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

Parcel orders are ordinary orders with `vertical: "parcel"` and a `parcel` object (pickup/drop-off contacts,
size, contents); they skip the merchant (`paid → ready_for_pickup`) and are cancellable with a full refund until a
rider is assigned. `GET /v1/config/public` also returns `cities` and `support` contacts (`placeholders: true` until
real contacts are configured).
