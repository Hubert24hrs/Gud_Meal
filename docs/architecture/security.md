# Security Model

## Identity & roles

- Firebase Authentication for every user type (phone OTP, email/password, Google where enabled).
- Roles are Firebase **custom claims** set only by the API's admin endpoints:
  `roles: [..]`, `restaurant_roles: {restaurantId: "owner"|"manager"|"staff"}`.
- Roles: `customer`, `restaurant_owner`, `restaurant_manager`, `restaurant_staff`, `rider`,
  `support_agent`, `operations_manager`, `finance_manager`, `marketing_manager`, `hub_agent`, `super_admin`.
- The API verifies ID tokens with the Firebase Admin SDK (`check_revoked=True` for privileged routes)
  and maps roles to fine-grained permissions in `security/rbac.py` (deny by default).
- **WhatsApp channel tokens** ([ADR-0017](../adr/0017-gudy-on-whatsapp.md)). A WhatsApp message has no ID
  token, so for a linked number the API mints a short-lived token for Gudy:
  - HMAC-SHA256 signed with `CHANNEL_TOKEN_SECRET`, valid 10 minutes, with a unique id
  - **customer role only**, whatever roles the account has, so staff, merchant and rider powers never act over
    WhatsApp
  - accepted by the API and the agents service next to Firebase ID tokens, and kept only in contextvars and request
    headers (never in graph state, logs or the database)

## Data isolation

| Boundary | Enforcement |
|---|---|
| Customer ↔ customer | API ownership checks; Firestore rules `resource.data.customer_id == request.auth.uid` |
| Restaurant ↔ restaurant | `restaurant_roles` claim must contain the order's `restaurant_id` (API + rules) |
| Rider ↔ rider | `order.rider_id == uid`; riders see only the drop-off details needed for the active delivery |
| Staff | permission-based; every privileged mutation writes an `audit_events` row |
| AI threads | thread ownership table checked on every call; memory never shared across users |
| Group orders | only members can read a group (others get 404); members change only their own items; the host alone locks, checks out, cancels or removes people; joining by code is rate-limited per user and groups expire |
| Personal vouchers | a reward voucher carries `customer_id`; anyone else's quote reports an unknown code |
| Waybill tracking | public `GET /v1/track/{code}` returns progress, places and dates only (no names, phones or addresses), rate-limited per client address; hub scans need `hubs:operate` and are accepted only at the package's booked hub for each step |
| WhatsApp numbers | a number reaches an account only after the signed-in customer creates a one-time code and sends it from that number (single use, 10 minutes, 5 an hour). One number per account and one account per number. Unlinked numbers get instructions only, never Gudy. Numbers are masked in responses and audit events |

## Platform controls

- **Firestore rules**: deny-by-default; clients can only write `carts/{uid}` (schema-validated) and
  nothing else. All other writes go through the API (Admin SDK).
- **Storage rules**: size and content-type limits; restaurant documents readable only by the owner and staff.
- **App Check**: enforced on Firestore/Storage; the API verifies App Check tokens (`X-Firebase-AppCheck`)
  when `APP_CHECK_ENFORCED=true`. Gud Meal's own agents service proves itself instead with a Google-signed OIDC
  token (`X-Service-Authorization`, audience and service account checked; the shared internal secret locally),
  and still needs the user's own token on every call.
- **Secrets**: Secret Manager only; `.env` files are git-ignored; the repo is public.
- **IAM**: one service account per service with least-privilege roles (see `infra/scripts/bootstrap-gcp.sh`).
- **Internal endpoints** (`/internal/*`): Google-signed OIDC tokens from Pub/Sub / Cloud Tasks / Scheduler,
  audience and service-account email verified.
- **Webhooks**: signature verification (constant time), optional source IP allow-list, idempotent processing.
  WhatsApp webhooks are checked with `X-Hub-Signature-256` (HMAC-SHA256 of the raw body with the Meta app
  secret) and de-duplicated by message id.
- **Rate limiting**: per-principal token buckets on sensitive routes (OTP, location updates, AI chat).
- **Input validation**: Pydantic models with strict bounds on every request body.
- **Headers**: HSTS, no-sniff, frame-deny on web apps; CORS restricted to known origins.

## Compliance notes (Nigeria)

- Nigeria Data Protection Act 2023 (NDPA) and NDPC guidance: lawful basis & consent records for marketing and
  personalisation, data subject access / deletion procedure (`/v1/me/data-export`, `/v1/me` delete request),
  breach notification runbook, Data Protection Impact Assessment before launch, local DPO designation.
- Location data: precise rider location retained 30 days by default, customer addresses only while saved. A
  location shared on WhatsApp is kept on the number's link and deleted when the customer disconnects.
- WhatsApp: Meta processes the chat. The privacy notice must say so and explain how to disconnect (`STOP` or the
  app). Message ids used for de-duplication expire after 7 days.
- Payment data: card data never touches Gud Meal systems (provider-hosted checkout) — PCI DSS scope stays SAQ-A.
- These are engineering notes, not legal advice; a Nigerian data-protection counsel review is a launch gate.
