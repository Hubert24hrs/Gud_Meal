# Production readiness checklist

Legend: ✅ done and verified · 🟡 implemented, needs cloud/credentials to verify · ⬜ not started · 👤 needs you

## Core platform
- ✅ Deterministic pricing (kobo), quotes with TTL, re-validation at order time (price/availability/hours)
- ✅ Order state machine (17 states) with actor rules, reasons, guards; exhaustive unit tests
- ✅ Idempotency keys for order creation, checkout and payouts
- ✅ Double-entry ledger, DB-enforced append-only + balance trigger (verified on PostgreSQL 16)
- ✅ Alembic migration verified: upgrade → `alembic check` (no drift) → downgrade → upgrade
- ✅ Transactional outbox, idempotent event handlers, sweeper job for lost events
- 🟡 Firestore adapter (contract tests run against the emulator in CI; not run on this machine — no Java)
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
- ✅ Deny-by-default Firestore & Storage rules (tests written; run in CI emulator job)
- ✅ Rate limits, input validation, audit log, security headers, CORS allow-list, internal OIDC auth
- ✅ AI safety: tool allow-lists per agent and role, approval interrupts, prompt-injection guard, card redaction,
  tokens never checkpointed, thread isolation (tested)
- 👤 Enable App Check enforcement in production (`APP_CHECK_ENFORCED=true`) after registering apps
- ⬜ External penetration test / OWASP ASVS L2 review; dependency scanning (Dependabot) and SAST in CI
- ⬜ Distributed rate limiting (current limiter is per instance)

## AI
- ✅ LangGraph orchestrator, 8 agents, 30 tools, approvals, Postgres/SQLite checkpointers, cost tracking
- ✅ Tool schemas convert to Gemini function declarations (offline test)
- 👤 Provide `GOOGLE_API_KEY`; pin a stable Gemini Flash model id; run the live test (`pytest -m live_gemini`)
- ⬜ Evaluation set (routing accuracy, tool-call accuracy, refusal quality) before each model change
- ⬜ LangSmith tracing in staging

## Apps
- ✅ Customer web, partner dashboard, command centre: production builds + type checks; customer flow and admin
  finance verified manually in a browser against the local stack
- ✅ Flutter customer & rider apps: analyze clean, widget/unit tests; customer web build verified against the API
- 👤 Firebase app registration (`flutterfire configure` or dart-defines), Android signing keystore, iOS signing
- ⬜ Real food photography (restaurant uploads), Google Maps live map on tracking screens, push notification
  handling in the apps, offline caching in the apps
- ⬜ Accessibility audit (screen readers, contrast in dark mode) and device testing on low-end Android

## Operations & compliance
- ✅ Dockerfiles, CI, manual deploy workflow, bootstrap & deploy scripts, rollback procedure documented
- 👤 Create GCP projects, billing, budgets; run bootstrap; add secrets; first deploy
- ⬜ Monitoring dashboards & alerts (5xx rate, webhook failures, stuck orders, outbox backlog, AI cost/day)
- ⬜ Backup restore drill; incident runbooks; on-call rota
- 👤 NDPA: privacy notice, DPIA, DPO, data-processing agreements, cookie policy; legal review of terms
