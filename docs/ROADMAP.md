# Gud Meal — Implementation Roadmap

Staged delivery, as agreed: **core marketplace → delivery infrastructure → AI → administration → launch.**
Live status of each item is tracked in [PROGRESS.md](PROGRESS.md).

## Stage 0 — Discovery & architecture
- Environment inspection, architecture, ADRs, data model, security model.

## Stage 1 — Core marketplace
- API foundation: config, auth (Firebase ID tokens), RBAC, errors, logging, rate limits.
- Domain: money (kobo), opening hours, geo, pricing engine, vouchers, order state machine.
- Catalog: restaurants, menus, items, customisations, search, discovery filters.
- Quotes → orders → checkout with idempotency.
- Payments: Paystack + Flutterwave adapters, webhooks, verification, ledger postings.
- Customer website: discovery, restaurant pages, cart, checkout, tracking.
- Partner dashboard: incoming orders, accept/reject, menu & availability management.
- Customer mobile app: discovery, cart, checkout, tracking.

## Stage 2 — Delivery infrastructure
- Rider onboarding & verification, availability, location updates (geohash).
- Dispatch scoring, offers with Cloud Tasks timeouts, manual dispatch.
- Pickup / delivery with OTP, live tracking, notifications (FCM).
- Rider app: offers, active delivery, earnings, payouts.

## Stage 3 — AI multi-agent ecosystem
- LangGraph orchestrator, router, eight specialist agents, tool registry, approvals.
- Budget meal planner ("₦10,000 for two before 8pm"), Postgres checkpoints, memory isolation.
- Gemini integration, cost/latency tracking, LangSmith tracing, AI chat in web + mobile, voice input.

## Stage 4 — Administration
- Command Centre: overview, orders intervention, verification queues, refunds, payments,
  commission/fee configuration, feature flags, audit logs, AI monitoring, disputes, settlements.

## Stage 5 — Production launch
- GCP projects per environment, Cloud SQL, Secret Manager, Cloud Run, Pub/Sub, Tasks, Scheduler.
- Security review (OWASP ASVS L2), rules tests, load tests, payment sandbox → live verification.
- NDPA compliance review, privacy/cookie policies, Play Store / App Store submissions.
