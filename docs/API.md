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
