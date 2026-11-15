# Gud Meal — status report (2026-11-15)

**Bottom line:** the core marketplace, payments/ledger, dispatch, AI agents, three web apps and two Flutter
apps are implemented and tested locally. On 2026-11-15 the owner chose a multi-service direction (see
[ROADMAP.md](ROADMAP.md#multi-service-expansion-owner-decisions-of-2026-11-15)); **phase 1 of it is done**: a
Glovo-style redesign of the customer app and website in Gud Meal orange, **Beauty & Skin care**, **Package
Delivery** (instant and scheduled), **Lagos and Enugu**, and **Gudy**, the AI assistant (five languages, offline
mode). Phases 2–5 (wallet and pay on delivery, interstate waybill, Plus/referrals/group orders, WhatsApp) are not
started. **Nothing is deployed**, and the product is **not production-ready**: cloud resources, real payment
test-mode, a Gemini key and the items in [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) are still required.

## What has been built

| Area | Contents |
|---|---|
| Architecture | System/data/security/AI docs, 12 ADRs (ADR-0012: one order pipeline for food, beauty and parcels), roadmap with the owner's product decisions |
| `services/api` | Catalog & search, deterministic pricing (fees, VAT, vouchers, ₦50 fee rounding), quotes, orders with a 17-state machine, Paystack/Flutterwave/sandbox payments, signed webhooks, refunds with finance approval, double-entry append-only ledger, settlements, rider payouts, dispatch scoring with offer timeouts and manual dispatch, OTP delivery & pickup codes, reviews, support tickets, onboarding approvals that set Firebase custom claims, admin analytics/forecast, audit log, outbox, Alembic migration; **multi-service**: merchant verticals (food, beauty) and cities (Lagos, Enugu), browse categories and promotions, Package Delivery (parcel quotes and orders, scheduled pickups released by a task, cancel-until-rider refunds, no-merchant settlement), customer order totals, Lagos/Enugu neighbourhood lookup, support contacts; 107 HTTP paths |
| `services/agents` | **Gudy**: LangGraph graph (guard → router → specialist ⇄ tools), 8 agents, 36 typed tools (services, totals, navigation buttons, support contacts, parcel quote and booking added), replies in English, Pidgin, Igbo, Yoruba or Hausa, rule-based **offline mode** without a Gemini key, `interrupt()` approvals, Postgres/SQLite/memory checkpointers, thread ownership, tool audit, token/cost accounting, Gemini via env-pinned model |
| Web | Customer site, **redesigned Glovo-style in Gud Meal orange** (animated draggable service bubbles, /food, /beauty, /send, /discover, /support, Profile-style account, mobile bottom bar, floating Gudy) plus SEO pages, JSON-LD, sitemap, checkout, payment callback, tracking, Gudy chat with approvals + voice; Partner dashboard (live board with alerts, menu editor, insights, settlements, hours), Command Centre (overview, order intervention, verification, refunds, payments, finance, support, AI monitoring, pricing config, flags, audit) |
| Mobile | `gud_meal_core` (Freezed models, Dio clients, auth port, theme from tokens), customer app **redesigned Glovo-style** (home with animated, finger-draggable bubbles drawn as original illustrations; Food and Beauty pages; Package Delivery; Discover; Orders with spending; Support; Profile; draggable Gudy robot and chat), rider app (online/GPS, offers with countdown, pickup/transit/OTP delivery, package jobs with sender/recipient call buttons, navigation, earnings, SOS) |
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
- **Multi-service phase 1 in a browser** (phone-size viewport, Auth emulator + API + agents in offline mode):
  - *Mobile app (Flutter web build)*: home bubbles pop in, follow a drag and spring back, and a tap opens the
    service; Food and Beauty pages with categories, filters, popular brands and store cards; Discover; Support;
    Profile signed in and out. Gudy answered “What do you offer?” with service chips and a Pidgin question about
    spending in Pidgin. **Package Delivery booked end to end**: Lekki → Ikota, 8.4 km, small parcel quoted at
    ₦2,700 + ₦100 booking fee + ₦210 VAT = **₦3,010**, booked, paid in the sandbox, then shown as “Finding a rider”
    with the recipient code and a pickup → drop-off card.
  - *Website*: the same home bubbles and Gudy button, bottom tab bar, Food page, Support, and a parcel quote from
    the real API (Lekki → Yaba, 13.1 km: ₦3,650 + ₦100 + ₦281.25 VAT = ₦4,031.25).
  - Bugs found and fixed while testing: sign-in screen not closing after a successful sign-in, section titles
    squeezed by a spacer, Gudy greeting pushing its button off-screen, a bubble's rest position outside the
    physics bounds (never settled), validation messages hidden below the fold, food wording on parcel orders,
    filter pills wrapping, and the partner editor rejecting the new “product” item kind.

## What has been tested — results

| Suite | Result |
|---|---|
| API unit + HTTP integration (SQLite) | **435 passed**, 2 skipped (PostgreSQL-only); 33 new for services, categories, beauty orders, parcels (pricing, validation, lifecycle with rider and ledger, scheduled release, cancellation), order totals and neighbourhoods |
| API integration on PostgreSQL 16 (embedded) incl. append-only and unbalanced-transaction triggers | **40 passed** |
| Alembic upgrade / `alembic check` / downgrade / upgrade | passed |
| Agents (routing, permissions, approvals, isolation, injection, redaction, failure recovery, cost, Gemini schema, Gudy offline mode in 5 languages, parcel booking via tools) | **39 passed**, 1 skipped (live Gemini needs a key) |
| TypeScript (api-client 6, web 11) + 3 Next.js production builds with type-check | **17 passed**, builds OK |
| Flutter core / customer / rider | **11 / 14 / 6 passed** (bubble drag-and-spring-back, Food page, Gudy button, Orders spending, parcel form, rider package job), analyzer clean |
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
7. Gudy without a Gemini key runs in offline mode: a fixed set of intents, full replies in English and Pidgin
   only (Igbo, Yoruba and Hausa get a greeting, then English). Natural conversation in all five languages needs
   the key.
8. Addresses without a map pin use neighbourhood centres (about 1 km accuracy) until Google Maps is configured;
   parcel prices are distance estimates from those centres.
9. Wallet, pay on delivery, vendor cash-on-delivery, interstate waybill, Gud Meal Plus, referrals/loyalty,
   group orders and WhatsApp ordering are designed into the roadmap but **not built** (phases 2–5); the apps show
   them as “coming soon”.
10. Support WhatsApp/phone/email are placeholders (flagged in the apps) until real contacts are provided.
11. Store artwork is generated (gradient + illustration) until partners upload photos; field names still say
    `restaurant_*` for all merchants (rename deferred, see ADR-0012).

## Required user actions

1. Create `gud-meal-dev|staging|prod` GCP projects, add Firebase, enable billing and budgets.
2. Provide Paystack **test** keys (and Flutterwave if wanted) for sandbox verification.
3. Provide a Gemini API key (turns Gudy's offline mode into the full multilingual assistant); choose and pin a
   stable Flash model.
4. Install Java 21 locally if you want to run emulator rules tests (`winget install EclipseAdoptium.Temurin.21.JDK`).
5. Legal: NDPA review, privacy policy/terms, fund-holding (collect-then-settle) review with Paystack and counsel.
6. Apple/Google developer accounts and signing keys for store releases.
7. Google Maps API key (address search, map pins in Lagos and Enugu, live rider map).
8. WhatsApp Business (Meta) account and number for WhatsApp support and ordering (phase 5).
9. Real support contacts (WhatsApp, phone, email) and real partner restaurants and beauty shops for both cities.

## Estimated monthly infrastructure cost

About **$420–790/month for production** at launch scale (300 orders/day, 2,000 AI turns/day), $65–125 staging,
$0–75 dev — excluding payment fees and SMS. Details and assumptions: [COST_ESTIMATE.md](COST_ESTIMATE.md).

## Recommended next steps

1. Bootstrap `gud-meal-dev`, deploy via the manual workflow, and run the Paystack test-mode flow end-to-end.
2. Add a Gemini key, pin the model, run `pytest -m live_gemini` and build an evaluation set for Gudy in all five
   languages (Pidgin, Igbo, Yoruba and Hausa reviewed by native speakers).
3. Multi-service phases 2–5 in order: wallet + pay on delivery + vendor COD; interstate waybill; Gud Meal Plus,
   referrals/loyalty and group orders; Gudy on WhatsApp (after the Meta account is ready).
4. Switch customer tracking to Firestore listeners and add Google Maps (address search, pins, live map).
5. Partner photo uploads (Storage rules already allow it), partner staff management, shop wording for beauty
   partners in the dashboard.
6. Monitoring dashboards/alerts, load test, security review, then closed betas in Lekki/VI and Independence
   Layout (Enugu).
