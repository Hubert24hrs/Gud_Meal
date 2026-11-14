# Gud Meal — status report (2026-11-15)

**Bottom line:** the core marketplace, payments/ledger, dispatch, AI agents, three web apps and two Flutter
apps are implemented and tested locally. **Nothing is deployed**, and the product is **not production-ready**:
cloud resources, real payment test-mode, a Gemini key and the items in
[PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) are still required.

## What has been built

| Area | Contents |
|---|---|
| Architecture | System/data/security/AI docs, 11 ADRs, roadmap |
| `services/api` | Catalog & search, deterministic pricing (fees, VAT, vouchers, ₦50 fee rounding), quotes, orders with a 17-state machine, Paystack/Flutterwave/sandbox payments, signed webhooks, refunds with finance approval, double-entry append-only ledger, settlements, rider payouts, dispatch scoring with offer timeouts and manual dispatch, OTP delivery & pickup codes, reviews, support tickets, onboarding approvals that set Firebase custom claims, admin analytics/forecast, audit log, outbox, Alembic migration, 98 HTTP paths |
| `services/agents` | LangGraph graph (guard → router → specialist ⇄ tools), 8 agents, 30 typed tools, `interrupt()` approvals, Postgres/SQLite/memory checkpointers, thread ownership, tool audit, token/cost accounting, Gemini via env-pinned model |
| Web | Customer site (SEO pages, JSON-LD, sitemap, checkout, payment callback, tracking, AI chat with approvals + voice), Partner dashboard (live board with alerts, menu editor, insights, settlements, hours), Command Centre (overview, order intervention, verification, refunds, payments, finance, support, AI monitoring, pricing config, flags, audit) |
| Mobile | `gud_meal_core` (Freezed models, Dio clients, auth port, theme from tokens), customer app (discovery, menu & options, cart, checkout, tracking, AI concierge), rider app (online/GPS, offers with countdown, pickup/transit/OTP delivery, navigation, earnings, SOS) |
| Firebase | Deny-by-default Firestore & Storage rules, composite indexes, quote TTL, emulator config, rules tests |
| Delivery | Dockerfiles, CI workflow, manual deploy workflow, Cloud Build config, GCP bootstrap & deploy scripts |

## What works (verified)

- Full order lifecycle through the HTTP API: quote → order → checkout → signed webhook → server verification →
  ledger → restaurant accept → dispatch → rider pickup → live tracking → OTP delivery → completion → settlement.
- The same lifecycle **in a browser** against the running stack (Firebase Auth emulator + API + Next.js):
  sign-in, menu customisation, voucher, server quote (₦13,499.38 with exact VAT), sandbox payment, callback
  verification, tracking with delivery code, completion, review; Command Centre showed matching GMV, a balanced
  trial balance and a generated settlement (₦9,775 net to the restaurant).
- The vision request (“₦10,000, best meal for two before 8pm, order it”) through the agents service against the
  real API: plans within budget, a draft order, an approval screen with the exact API total, then a payment link;
  declining never charges.
- **Gud Meal Partner in a browser** (restaurant owner account, Auth emulator + API, sandbox-paid orders): live
  board with a “(n) New orders” title alert; reject with a reason → automatic full refund (₦18,031.88); accept with
  a custom prep time → start preparing → mark ready; pickup handover (a wrong code shows “Incorrect code”, the
  right code completes the order); sold-out toggle, item edit (₦1,650.50 + description) and a new item, all
  reflected in the public menu API; insights (gross ₦1,500, earnings ₦1,275 after ₦225 commission, 67%
  acceptance); payouts empty state; pause/resume reflected in the public listing; opening hours including
  past-midnight trading (Saturday 10:00–02:00). The ledger trial balance stayed equal (₦102,035.02 each side).
  Partner and Command Centre layouts checked at 375 px, 768 px and 1280 px: no horizontal page scroll.
- Flutter customer app (web build) rendering live restaurants and menus from the API.

## What has been tested — results

| Suite | Result |
|---|---|
| API unit + HTTP integration (SQLite) | **402 passed**, 2 skipped (PostgreSQL-only) |
| API integration on PostgreSQL 16 (embedded) incl. append-only and unbalanced-transaction triggers | **40 passed** |
| Alembic upgrade / `alembic check` / downgrade / upgrade | passed |
| Agents (routing, permissions, approvals, isolation, injection, redaction, failure recovery, cost, Gemini schema) | **28 passed**, 1 skipped (live Gemini needs a key) |
| TypeScript (api-client 6, web 7) + 3 Next.js production builds with type-check | **13 passed**, builds OK |
| Flutter core / customer / rider | **11 / 7 / 5 passed**, analyzer clean |
| Firestore & Storage rules tests (Firebase emulators) | **passed in CI** ([run](https://github.com/Hubert24hrs/Gud_Meal/actions/runs/43651031712)); not runnable locally without Java |
| Firestore DocumentStore contract tests against the emulator | **8 passed in CI** (memory + Firestore backends) |
| Docker images build + API container smoke test | **passed in CI**; not runnable locally without Docker |
| Full CI (6 jobs) on GitHub Actions | **all green** on the first push ([run](https://github.com/Hubert24hrs/Gud_Meal/actions/runs/43651031712)) |

## What has been deployed

Nothing. No GCP or Firebase project was created or modified, no paid service was enabled.

## What has not been deployed

All services, web apps, rules and indexes; Cloud SQL, Pub/Sub, Tasks, Scheduler, Secret Manager, Artifact
Registry; mobile store builds.

## Firebase configuration status

Rules, indexes and emulator config are in `firebase/`. The `.firebaserc` aliases point to
`gud-meal-dev|staging|prod`, which do not exist yet. Apps run against the Auth emulator with demo config.

## GCP configuration status

Not configured. `infra/scripts/bootstrap-gcp.sh` creates everything per environment (Cloud SQL only with an
explicit flag and confirmation). Region default: `europe-west1`.

## LangGraph agent status

Implemented and tested with a scripted model and the real API. Without `GOOGLE_API_KEY` the service runs in a
safe degraded mode (keyword routing + “try the app” reply). The Gemini model id is not pinned because the official
models page could not be fetched; pin a stable Flash id per ADR-0011.

## Payment integration status

Paystack and Flutterwave adapters are implemented to their documented contracts and tested with mocked HTTP;
the full pipeline is exercised with the local sandbox provider. **No real provider call has been made** (no keys).

## Security status

Implemented: token verification, RBAC, data isolation, deny-by-default rules, webhook signatures, idempotency,
append-only ledger/audit, rate limits, AI guardrails. Outstanding: App Check enforcement, penetration test,
dependency scanning, distributed rate limiting, NDPA documentation.

## Outstanding issues

1. Emulator-based tests run only in CI (this machine has no Java); they pass there.
2. Real payments (Paystack test mode) and real Gemini calls are unverified.
3. Restaurant artwork uses branded placeholders until restaurants upload photos; no live map yet.
4. Order tracking polls the API every 5 s (Firestore listeners are the production upgrade).
5. Rate limiting is per Cloud Run instance; refunds via Flutterwave need the transaction id.
6. The rider Flutter app is covered by widget/unit tests and the analyzer only; it has not been run on a device
   or emulator (it has no web build, and its GPS flows need a phone).

## Required user actions

1. Create `gud-meal-dev|staging|prod` GCP projects, add Firebase, enable billing and budgets.
2. Provide Paystack **test** keys (and Flutterwave if wanted) for sandbox verification.
3. Provide a Gemini API key; choose and pin a stable Flash model.
4. Install Java 21 locally if you want to run emulator rules tests (`winget install EclipseAdoptium.Temurin.21.JDK`).
5. Legal: NDPA review, privacy policy/terms, fund-holding (collect-then-settle) review with Paystack and counsel.
6. Apple/Google developer accounts and signing keys for store releases.

## Estimated monthly infrastructure cost

About **$420–790/month for production** at launch scale (300 orders/day, 2,000 AI turns/day), $65–125 staging,
$0–75 dev — excluding payment fees and SMS. Details and assumptions: [COST_ESTIMATE.md](COST_ESTIMATE.md).

## Recommended next steps

1. Bootstrap `gud-meal-dev`, deploy via the manual workflow, and run the Paystack test-mode flow end-to-end.
2. Add a Gemini key, pin the model, run `pytest -m live_gemini` and build a small evaluation set.
3. Switch customer tracking to Firestore listeners and add Google Maps to the tracking screens.
4. Restaurant photo uploads (Storage rules already allow it) and partner staff management.
5. Monitoring dashboards/alerts, load test, security review, then a closed beta in Lekki/VI.
