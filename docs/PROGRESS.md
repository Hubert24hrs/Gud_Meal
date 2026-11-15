# Gud Meal — status report (2026-11-15)

**Bottom line:** the core marketplace, payments/ledger, dispatch, AI agents, three web apps and two Flutter
apps are implemented and tested locally. On 2026-11-15 the owner chose a multi-service direction (see
[ROADMAP.md](ROADMAP.md#multi-service-expansion-owner-decisions-of-2026-11-15)); **phase 1 of it is done**: a
Glovo-style redesign of the customer app and website in Gud Meal orange, **Beauty & Skin care**, **Package
Delivery** (instant and scheduled), **Lagos and Enugu**, and **Gudy**, the AI assistant (five languages, offline
mode). **Phase 2 is done too**: the **Gud Meal wallet** (top-up, one-tap pay, instant refunds), **pay on delivery**
with rider cash tracking and hand-ins, **cash on delivery for sellers** with payouts, and **Flutterwave failover**
([ADR-0013](adr/0013-wallet-and-cash.md); the wallet still needs a legal review). **Phase 3 is done**: the **interstate waybill** between Lagos, Enugu, Abuja and Port Harcourt. It covers home
pickup or hub drop-off, line haul by partner carriers, door delivery or hub collection, public tracking
numbers and a hub console ([ADR-0015](adr/0015-interstate-waybill.md)). Its hubs and carriers are **sample
data** until real partners sign. Phases 4–5 (Plus/referrals/group orders, WhatsApp) are not started. **Nothing is deployed**, and the product is **not production-ready**: cloud resources, real payment
test-mode, a Gemini key and the items in [PRODUCTION_READINESS.md](PRODUCTION_READINESS.md) are still required.

## What has been built

| Area | Contents |
|---|---|
| Architecture | System/data/security/AI docs, 14 ADRs (ADR-0012: one order pipeline for food, beauty and parcels; ADR-0013: wallet, pay on delivery, vendor COD, failover; ADR-0015: interstate waybill), roadmap with the owner's product decisions |
| `services/api` | Catalog & search, deterministic pricing (fees, VAT, vouchers, ₦50 fee rounding), quotes, orders with a 17-state machine, Paystack/Flutterwave/sandbox payments, signed webhooks, refunds with finance approval, double-entry append-only ledger, settlements, rider payouts, dispatch scoring with offer timeouts and manual dispatch, OTP delivery & pickup codes, reviews, support tickets, onboarding approvals that set Firebase custom claims, admin analytics/forecast, audit log, outbox, Alembic migration; **multi-service**: merchant verticals (food, beauty) and cities (Lagos, Enugu), browse categories and promotions, Package Delivery (parcel quotes and orders, scheduled pickups released by a task, cancel-until-rider refunds, no-merchant settlement), customer order totals, Lagos/Enugu neighbourhood lookup, support contacts; **money (phase 2)**: closed-loop wallet (top-ups, one-tap pay under an account row lock, instant refunds), pay on delivery (eligibility, cash confirmed at the door, rider cash receivables, hand-ins, dispatch cash limit, support block), vendor COD on packages (fee in pricing, seller balance, payouts, move to wallet), gateway failover with a circuit breaker, automatic refund of duplicate payments, money guard on order status, migration 0002; **logistics (phase 3)**: interstate waybill (network of cities, hubs, carriers and lanes in configuration; deterministic line-haul pricing and expected dates; quotes and bookings; first- and last-mile rider jobs dispatched like packages; hub receive/depart/arrive/hand-over with compare-and-set milestones; public tracking numbers without personal data; carrier balances and payouts in the ledger; full refund until the package is with a rider or at a hub); 135 HTTP paths |
| `services/agents` | **Gudy**: LangGraph graph (guard → router → specialist ⇄ tools), 8 agents, 40 typed tools (services, totals, navigation buttons, support contacts, parcel quote and booking, read-only wallet and payment options, waybill routes and tracking added), replies in English, Pidgin, Igbo, Yoruba or Hausa, rule-based **offline mode** without a Gemini key, `interrupt()` approvals, Postgres/SQLite/memory checkpointers, thread ownership, tool audit, token/cost accounting, Gemini via env-pinned model |
| Web | Customer site, **redesigned Glovo-style in Gud Meal orange** (animated draggable service bubbles, /food, /beauty, /send, /discover, /support, Profile-style account, mobile bottom bar, floating Gudy, wallet page, card/wallet/pay-on-delivery choice at checkout, cash-on-delivery for packages, **interstate waybill** booking with expected dates, a public `/track` page and a printable label) plus SEO pages, JSON-LD, sitemap, checkout, payment callback, tracking, Gudy chat with approvals + voice; Partner dashboard (live board with alerts, menu editor, insights, settlements, hours), Command Centre (overview, order intervention, verification, refunds, payments, finance, **cash & wallets** (rider cash hand-ins, seller withdrawals, pay-on-delivery block, carrier payouts), **hubs** (scan in, depart with a trip reference, arrive, hand over against the collection code), support, AI monitoring, pricing config, flags, audit) |
| Mobile | `gud_meal_core` (Freezed models, Dio clients, auth port, theme from tokens), customer app **redesigned Glovo-style** (home with animated, finger-draggable bubbles drawn as original illustrations; Food and Beauty pages; Package Delivery with cash on delivery; Discover; Orders with spending; Support; Profile; **wallet**; card/wallet/pay-on-delivery choice; **interstate waybill** booking, tracking history and collection code; draggable Gudy robot and chat), rider app (online/GPS, offers with countdown, pickup/transit/OTP delivery, **cash collection confirmation**, package jobs with sender/recipient call buttons, waybill pickup and door-delivery jobs with a hub hand-over card, navigation, earnings with cash held, SOS) |
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
- **Phase 2 (money) on the running local stack** (Auth emulator + API + agents, demo accounts):
  - *Website*: a ₦10,000 wallet top-up started on the wallet page, approved on the sandbox checkout page and
    credited (statement shows “Wallet top-up”).
  - *API as the apps call it* (signed in with emulator tokens): payment options for a ₦6,655.63 order showed card ✓,
    wallet ✓ and pay on delivery ✗ “unlocks after your first order”; paying from the wallet sent the order to the
    restaurant and left ₦3,344.37; cancelling refunded ₦6,655.63 into the wallet at once; a package with ₦25,000
    cash on delivery priced at ₦1,900 + ₦100 + ₦380 collection fee + ₦178.50 VAT = ₦2,558.50; the Command Centre
    cash view showed ₦10,000 in customer wallets and refused the customer (403); Gudy read the wallet and its
    history and explained pay on delivery in Pidgin.
  - The visual pass of the new screens in the browser pane was limited because the pane was hidden during this
    session; the screens are covered by widget/component tests and the production builds.

- **Phase 3 (interstate waybill) on the running local stack.** The setup was the Auth emulator, the API and the
  agents with the demo accounts, signed in with emulator tokens as the apps are.
  - *Routes.* Lagos sends to Enugu (from ₦5,052.50, 1–2 days, door delivery). It also sends to Abuja and Port
    Harcourt (from ₦5,590, collection at a partner terminal).
  - *Door to door.* Lekki to Independence Layout (Enugu), 3.2 kg, with ₦25,000 cash on delivery:

    | Line haul | Pickup | Delivery | Booking | COD fee | VAT | Total |
    |---|---|---|---|---|---|---|
    | ₦5,100 | ₦1,300 | ₦1,100 | ₦200 | ₦380 | ₦606 | **₦8,686** |

    It was expected Tue 17 to Thu 19 Nov.
  - *Drop-off and collection.* Lagos (Lekki hub) to Abuja (Utako terminal), 1.5 kg of documents, **₦5,590**,
    booked and paid from the wallet.
    - The Lekki board listed the package, and the customer was refused access to the board (403).
    - A scan at the wrong hub was refused.
    - Receive, depart (trip LAG-ABJ-0907) and arrive followed.
    - A wrong collection code was refused; the right code completed and settled the order.
  - *Tracking and money.*
    - Public tracking showed six milestones and no names or phone numbers.
    - Gudy tracked the package by number.
    - Finance saw ₦3,000 owed to Sample Carrier North and recorded the payout. Paying more than was owed (422) and
      a hub agent recording a payout (403) were refused.
  - *Bugs found and fixed during this check:*
    - Pay on delivery was offered on door-to-door waybills.
    - An internal rider job could be sent to checkout.
    - Gudy's tracking reply kept the expected date after delivery and did not label the collection point.
  - *Not checked in a browser.* The browser pane was hidden, so the new screens were not checked visually: the
    website booking form, tracking page and label, the hub console, and the app screens. Component and widget
    tests and the production builds cover them.

## What has been tested — results

| Suite | Result |
|---|---|
| API unit + HTTP integration (SQLite) | **536 passed**, 3 skipped (PostgreSQL-only); 31 new for phase 3: line-haul pricing and weight limits, departures around the cut-off and Sundays, expected dates, stage labels, waybill postings always balance (15 random cases), state rules and flow guard, catalogue, quote validation, door to door with two rider jobs, hubs, COD and ledger, drop-off and hub collection paid from the wallet, cancellations, hub permissions and network configuration, no pay on delivery or rider-job checkout; 47 for phase 2: postings always balance, COD fee, state rules and money guard, wallet top-up/pay/instant refund, card refunds to the wallet, duplicate payment refund, pay on delivery end to end with rider cash and hand-ins (bank and earnings offset), cancellations without refunds, eligibility rules, dispatch cash limit, vendor COD with payouts and move to wallet, gateway failover and circuit breaker |
| API integration on PostgreSQL 16 (embedded) incl. append-only and unbalanced-transaction triggers, and a race test proving two simultaneous wallet payments cannot overspend (it fails when the account lock is removed) | **94 passed** |
| Alembic upgrade / `alembic check` / downgrade / upgrade (with migration 0002; phase 3 needs no migration) on PostgreSQL 16 | passed |
| Agents (routing, permissions, approvals, isolation, injection, redaction, failure recovery, cost, Gemini schema, Gudy offline mode in 5 languages, parcel booking via tools, wallet and cash questions, waybill routes and tracking) | **42 passed**, 1 skipped (live Gemini needs a key) |
| TypeScript (api-client 6, web 17) + 3 Next.js production builds with type-check | **23 passed**, builds OK |
| Flutter core / customer / rider | **12 / 30 / 8 passed** (bubble drag-and-spring-back, Food page, Gudy button, Orders spending, parcel form, cash on delivery for packages, payment choice, wallet, Discover, interstate waybill booking, rider package job, rider cash confirmation, rider hub hand-over), analyzer clean |
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
The Gud Meal wallet, pay on delivery and vendor cash on delivery run inside Gud Meal's ledger; gateway failover
is tested with a simulated outage. Seller payouts, rider hand-ins and carrier payouts are recorded manually by finance.

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
9. Gud Meal Plus, referrals/loyalty, group orders and WhatsApp ordering are designed into the roadmap but
   **not built** (phases 4–5).
10. Support WhatsApp/phone/email are placeholders (flagged in the apps) until real contacts are provided.
11. Store artwork is generated (gradient + illustration) until partners upload photos; field names still say
    `restaurant_*` for all merchants (rename deferred, see ADR-0012).
12. The wallet is closed-loop stored value with product-default limits (top-up ₦500–₦100,000, balance ≤ ₦300,000);
    it needs a **legal/CBN review** before launch (ADR-0013).
13. Refused or failed cash deliveries: support can cancel the order and switch pay on delivery off for the
    customer, but compensating the merchant/rider is a manual finance step, and return trips for refused COD
    packages are not automated.
14. Seller payouts and rider cash hand-ins are recorded by finance by hand (no automated bank transfers yet).
15. Local dev uses a new SQLite file (`gudmeal_local_v2.db`) because local dev creates tables directly; the old
    `gudmeal_local.db` was left untouched.
16. The interstate waybill runs on a **sample network**: Gud Meal hubs in Lagos (Ikeja, Lekki) and Enugu,
    partner terminals in Abuja and Port Harcourt, three sample carriers and sample prices. Real carriers, hub
    addresses, hours and rates are needed ([ADR-0015](adr/0015-interstate-waybill.md)).
17. Carrier payouts are recorded by finance by hand. There is no carrier portal or manifest exchange; a trip is
    a free-text reference.
18. Waybill exceptions are manual support processes: failed door deliveries, unclaimed packages, returns,
    refused cash-on-delivery packages, and lost or damaged packages. The declared value is recorded but not
    insured.
19. Hub agents can scan at any hub; there is no per-hub staff assignment yet.

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
10. Legal/CBN review of the Gud Meal wallet (closed-loop stored value, limits, KYC, who holds the funds) and
    confirmation of the money limits: wallet top-up/balance, pay on delivery ₦25,000, rider cash ₦50,000, COD
    ₦100,000 and the 1.5% (min ₦100) collection fee.
11. Real line-haul partners and hubs for the interstate waybill: carrier contracts, hub and terminal
    addresses and hours, lane prices and departure times, and the carrier share. Also a legal review of the
    waybill terms: prohibited items, liability limits and ID checks at collection.

## Estimated monthly infrastructure cost

About **$420–790/month for production** at launch scale (300 orders/day, 2,000 AI turns/day), $65–125 staging,
$0–75 dev — excluding payment fees and SMS. Details and assumptions: [COST_ESTIMATE.md](COST_ESTIMATE.md).

## Recommended next steps

1. Bootstrap `gud-meal-dev`, deploy via the manual workflow, and run the Paystack test-mode flow end-to-end.
2. Add a Gemini key, pin the model, run `pytest -m live_gemini` and build an evaluation set for Gudy in all five
   languages (Pidgin, Igbo, Yoruba and Hausa reviewed by native speakers).
3. Multi-service phases 4–5 in order: Gud Meal Plus, referrals/loyalty and group orders; Gudy on WhatsApp
   (after the Meta account is ready). Replace the sample waybill network with real carriers and hubs.
4. Switch customer tracking to Firestore listeners and add Google Maps (address search, pins, live map).
5. Partner photo uploads (Storage rules already allow it), partner staff management, shop wording for beauty
   partners in the dashboard.
6. Monitoring dashboards/alerts, load test, security review, then closed betas in Lekki/VI and Independence
   Layout (Enugu).
