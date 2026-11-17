# Architecture Decision Records

| # | Decision | Status |
|---|---|---|
| [0001](0001-monorepo-separate-deployables.md) | Monorepo with separately deployable apps | Accepted |
| [0002](0002-firestore-plus-postgres.md) | Firestore for real-time data, PostgreSQL for money | Accepted |
| [0003](0003-langgraph-separate-service.md) | LangGraph as an independent Cloud Run service | Accepted |
| [0004](0004-order-state-machine-in-backend.md) | Order state machine only in the API | Accepted |
| [0005](0005-integer-kobo-and-server-quotes.md) | Integer kobo and server-stored quotes | Accepted |
| [0006](0006-payment-provider-adapter.md) | Payment provider adapter; platform collects then settles | Accepted |
| [0007](0007-append-only-double-entry-ledger.md) | Append-only double-entry ledger | Accepted |
| [0008](0008-agent-tool-registry.md) | Typed, permissioned agent tool registry with approval | Accepted |
| [0009](0009-repository-ports-and-adapters.md) | Repository ports with Firestore and in-memory adapters | Accepted |
| [0010](0010-events-outbox-pubsub-tasks.md) | Transactional outbox → Pub/Sub; Cloud Tasks for timers | Accepted |
| [0011](0011-gemini-model-configuration.md) | Gemini model chosen by environment, pinned in production | Accepted |
| [0012](0012-multi-service-platform.md) | One order pipeline for Food, Beauty & Skin care and Package Delivery | Accepted |
| [0013](0013-wallet-and-cash.md) | Gud Meal wallet, pay on delivery, vendor cash-on-delivery, gateway failover | Accepted (legal review pending) |
| [0014](0014-google-maps-platform.md) | Google Maps Platform behind the API: places, routes, private live tracking | Accepted (key and billing approval pending) |
| [0015](0015-interstate-waybill.md) | Interstate waybill: hubs, rider legs, partner line haul, public tracking | Accepted (sample network) |
| [0016](0016-plus-rewards-group-orders.md) | Gud Meal Plus, Gud points and referrals, group orders with split bill | Accepted (defaults to confirm) |
| [0017](0017-gudy-on-whatsapp.md) | Gudy on WhatsApp: number linking, customer-only channel tokens, signed webhooks | Accepted (Meta account pending) |
| [0018](0018-groceries-pharmacy-market.md) | Groceries, Pharmacy and Market Shopping: three more shop services, products by the aisle, over-the-counter only | Accepted (defaults and legal review pending) |
| [0019](0019-receipt-printer.md) | Receipts: the receipt printer after payment, receipts kept under the customer's profile | Accepted |
