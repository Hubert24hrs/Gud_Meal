# Production readiness checklist

Legend: ✅ done and verified · 🟡 implemented, needs cloud/credentials to verify · ⬜ not started · 👤 needs you

## Core platform
- ✅ Deterministic pricing (kobo), quotes with TTL, re-validation at order time (price/availability/hours)
- ✅ Order state machine (17 states) with actor rules, reasons, guards; exhaustive unit tests
- ✅ Idempotency keys for order creation, checkout and payouts
- ✅ Double-entry ledger, DB-enforced append-only + balance trigger (verified on PostgreSQL 16)
- ✅ Alembic migration verified: upgrade → `alembic check` (no drift) → downgrade → upgrade
- ✅ Transactional outbox, idempotent event handlers, sweeper job for lost events
- ✅ Firestore adapter (contract tests pass against the Firestore emulator in CI)
- 🟡 Pub/Sub event bus, Cloud Tasks timers, FCM notifications (code paths exist; need a GCP project)
- ⬜ Load testing (target: 50 orders/min, p95 < 500 ms on quote/checkout)

## Payments
- ✅ Paystack + Flutterwave adapters tested against documented request/response formats (mocked HTTP)
- ✅ Webhook signature verification (HMAC-SHA512 / verif-hash), duplicate suppression, server-side verify
- ✅ Amount/currency mismatch → payment flagged, never fulfilled; orphaned payments auto-refunded
- 👤 Run Paystack **test-mode** end-to-end (needs your `sk_test` key and a public webhook URL)
- 👤 Confirm merchant settlement terms, refund API access and fund-holding compliance with Paystack / counsel
- ⬜ Provider fee reconciliation from settlement reports

## Security
- ✅ Firebase ID token verification (revocation check), RBAC with 10 roles, restaurant/rider data isolation
- ✅ Deny-by-default Firestore & Storage rules (emulator tests pass in CI)
- ✅ Rate limits, input validation, audit log, security headers, CORS allow-list, internal OIDC auth
- ✅ AI safety: tool allow-lists per agent and role, approval interrupts, prompt-injection guard, card redaction,
  tokens never checkpointed, thread isolation (tested)
- ✅ WhatsApp channel: signed webhooks, number linking by one-time code, customer-only channel tokens, an
  App Check exemption limited to the agents service account (which cannot call `/internal/*`)
- 👤 Enable App Check enforcement in production (`APP_CHECK_ENFORCED=true`) after registering apps
- ⬜ External penetration test / OWASP ASVS L2 review; dependency scanning (Dependabot) and SAST in CI
- ⬜ Distributed rate limiting (current limiter is per instance)

## AI
- ✅ LangGraph orchestrator, 8 agents, 43 tools, approvals, Postgres/SQLite checkpointers, cost tracking
- ✅ Tool schemas convert to Gemini function declarations (offline test)
- 👤 Provide `GOOGLE_API_KEY`; pin a stable Gemini Flash model id; run the live test (`pytest -m live_gemini`)
- 👤 Gudy on WhatsApp: Meta account, number, keys and templates, and approval of Meta's messaging charges
  ([DEPLOYMENT.md](DEPLOYMENT.md) section 4a)
- ⬜ Evaluation set (routing accuracy, tool-call accuracy, refusal quality) before each model change
- ⬜ LangSmith tracing in staging

## Apps
- ✅ Customer web, partner dashboard, command centre: production builds + type checks; customer flow, partner
  dashboard (order board incl. reject/refund and pickup handover, menu editor, hours, insights, pause) and admin
  finance verified manually in a browser against the local stack; partner and command centre layouts checked at
  phone, tablet and desktop widths
- ✅ Flutter customer & rider apps: analyze clean, widget/unit tests; customer web build verified against the API
  (the rider app has not been run on a device yet)
- 👤 Firebase app registration (`flutterfire configure` or dart-defines), Android signing keystore, iOS signing
- ⬜ Real food photography (restaurant uploads), Google Maps live map on tracking screens, push notification
  handling in the apps, offline caching in the apps
- ⬜ Accessibility audit (screen readers, contrast in dark mode) and device testing on low-end Android

## Maps

- [x] Google Places (New), Geocoding and Routes called only by the API with a server key; keyless fallback is
  labelled as estimates ([ADR-0014](adr/0014-google-maps-platform.md))
- [x] Delivery fees on measured road distance, stored on the quote (orders re-price the same)
- [x] Rider location privacy enforced by the API (offline refused, idle ~1 km, precise only on a delivery)
- [x] Cost controls: field masks, session tokens, caches, daily cap, traffic-aware switch, live ETA refresh
- [ ] Server key in Secret Manager, APIs enabled, quotas and a billing budget with alerts (owner)
- [ ] Restricted Android/iOS/browser keys if map tiles are wanted; test on a device with release signing
- [ ] Smoke test with a real key in dev (billable, needs approval) and compare quoted fees with real trips
- [ ] Legal review of the Google Maps Platform terms (caching, attribution)

## Operations & compliance
- ✅ Dockerfiles, CI, manual deploy workflow, bootstrap & deploy scripts, rollback procedure documented
- 👤 Create GCP projects, billing, budgets; run bootstrap; add secrets; first deploy
- ⬜ Monitoring dashboards & alerts (5xx rate, webhook failures, stuck orders, outbox backlog, AI cost/day)
- ⬜ Backup restore drill; incident runbooks; on-call rota
- 👤 NDPA: privacy notice (including what Meta processes for WhatsApp chats), DPIA, DPO, data-processing agreements, cookie policy; legal review of terms
