# GudMeals — System Architecture

> Status: living document. Decisions are recorded as ADRs in [`docs/adr`](../adr).

GudMeals is a set of separately deployable applications that share one identity system
(Firebase Authentication), one API (`gudmeal-api`), one real-time database (Cloud Firestore),
one money database (Cloud SQL PostgreSQL) and one AI service (`gudmeal-agents`).

## 1. System context

```mermaid
flowchart LR
  subgraph Clients
    CA["Customer app<br/>Flutter (Android/iOS)"]
    RA["Rider app<br/>Flutter (Android/iOS)"]
    WEB["Customer website<br/>Next.js"]
    PARTNER["GudMeals Partner<br/>Next.js"]
    ADMIN["Command Centre<br/>Next.js"]
  end

  subgraph Firebase
    AUTH["Firebase Auth"]
    FS[("Cloud Firestore<br/>real-time app data")]
    STG[("Cloud Storage<br/>images & documents")]
    FCM["Cloud Messaging"]
    AC["App Check"]
  end

  subgraph GCP["Google Cloud (per environment project)"]
    API["gudmeal-api<br/>FastAPI · Cloud Run"]
    AGENTS["gudmeal-agents<br/>LangGraph · Cloud Run"]
    SQL[("Cloud SQL PostgreSQL<br/>ledger · payments · idempotency<br/>audit · agent checkpoints")]
    PS["Pub/Sub<br/>domain events"]
    CT["Cloud Tasks<br/>timed / retryable jobs"]
    SCH["Cloud Scheduler"]
    SM["Secret Manager"]
  end

  GEM["Gemini API"]
  PAY["Paystack / Flutterwave"]
  MAPS["Google Maps Platform"]

  CA & RA & WEB & PARTNER & ADMIN -- "sign-in" --> AUTH
  CA & RA & WEB & PARTNER & ADMIN -- "ID token (HTTPS)" --> API
  CA & WEB & PARTNER & ADMIN -- "chat (ID token)" --> AGENTS
  CA & RA & WEB & PARTNER & ADMIN -- "read-only listeners<br/>(security rules)" --> FS
  AGENTS -- "tools call API on behalf of user" --> API
  AGENTS --> GEM
  AGENTS --> SQL
  API --> FS & SQL & STG & FCM & PS & CT
  PS -- "push" --> API
  CT -- "OIDC push" --> API
  SCH --> API
  API <--> PAY
  PAY -- "signed webhooks" --> API
  API --> MAPS
  API & AGENTS --> SM
```

### Key properties

| Concern | Decision |
|---|---|
| Who may change order state? | Only `gudmeal-api`, through the validated order state machine ([ADR-0004](../adr/0004-order-state-machine-in-backend.md)). Firestore rules deny all client writes to `orders`. |
| Who may touch money? | Only `gudmeal-api` payment and ledger services. Amounts are integer kobo computed by the deterministic pricing engine ([ADR-0005](../adr/0005-integer-kobo-and-server-quotes.md)). |
| What does the AI do? | Plans and orchestrates. Every action is a typed tool call executed by the API with the end user's identity, permissions and idempotency ([ADR-0003](../adr/0003-langgraph-separate-service.md), [ADR-0008](../adr/0008-agent-tool-registry.md)). |
| How do clients get live updates? | Firestore listeners on documents the user is allowed to read (order, assignment, tracking). |
| How are side effects made reliable? | Transactional outbox in Postgres → Pub/Sub → push handlers; Cloud Tasks for timers ([ADR-0010](../adr/0010-events-outbox-pubsub-tasks.md)). |

## 2. Repository layout

```
apps/web            Customer website (Next.js)
apps/partner        GudMeals Partner — restaurant dashboard (Next.js)
apps/admin          GudMeals Command Centre — super admin (Next.js)
packages/ui         Shared React component library + Tailwind theme
packages/api-client Typed TypeScript client for gudmeal-api
packages/tokens     Design tokens (single source → CSS, TS, Dart)
mobile/core         Shared Flutter package (models, API client, theme)
mobile/customer     GudMeals customer app (Flutter)
mobile/rider        GudMeals Rider app (Flutter)
services/api        gudmeal-api (FastAPI, Python)
services/agents     gudmeal-agents (LangGraph, Python)
firebase            Firestore/Storage rules, indexes, emulator config, rules tests
infra               Cloud Build, deployment & bootstrap scripts
docs                Architecture, ADRs, runbooks, reports
```

## 3. Order flow (happy path, delivery)

```mermaid
sequenceDiagram
  autonumber
  actor C as Customer
  participant API as gudmeal-api
  participant FS as Firestore
  participant PG as Postgres
  participant PSP as Paystack
  participant R as Restaurant
  participant D as Dispatch
  actor RD as Rider

  C->>API: POST /v1/quotes (items, address)
  API->>FS: read live menu, hours, zone config
  API-->>C: Quote (kobo amounts, expires in 10 min)
  C->>API: POST /v1/orders {quote_id} (Idempotency-Key)
  API->>FS: create order [draft]
  C->>API: POST /v1/orders/{id}/checkout (Idempotency-Key)
  API->>PG: payment_record [initialized]
  API->>PSP: initialize transaction (amount from quote)
  API->>FS: order [pending_payment]
  API-->>C: authorization_url
  C->>PSP: pays
  PSP-->>API: webhook charge.success (HMAC-SHA512 signed)
  API->>PSP: GET /transaction/verify/{ref} (never trust the client)
  API->>PG: tx: payment succeeded + ledger entries + outbox event
  API->>FS: order [paid → submitted_to_restaurant]
  FS-->>R: live order appears
  R->>API: accept (prep 20 min)
  API->>FS: order [restaurant_accepted]
  API->>D: rank eligible riders, create offer (Cloud Task timeout)
  RD->>API: accept offer
  API->>FS: order [rider_assigned]
  RD->>API: pickup → in transit → deliver (customer OTP)
  API->>FS: order [delivered → completed]
  API->>PG: settlement ledger entries (restaurant, rider, platform, VAT)
```

## 4. Environments

| Environment | GCP / Firebase project | Purpose |
|---|---|---|
| development | `gud-meal-dev` (+ local emulators) | Feature work, sandbox payment keys |
| staging | `gud-meal-staging` | Pre-release verification with sandbox payments |
| production | `gud-meal-prod` | Live traffic; deploys require explicit approval |

Each environment has its own Firebase project, Cloud SQL instance, service accounts and secrets.
Nothing is shared across environments except container images in Artifact Registry.

## 5. Further reading

- [Order lifecycle & state machine](order-lifecycle.md)
- [Data model (Firestore + PostgreSQL)](data-model.md)
- [Payments & ledger](payments-and-ledger.md)
- [AI multi-agent system](ai-agents.md)
- [Security model](security.md)
