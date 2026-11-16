# API reference

- Interactive docs (local): http://localhost:8000/docs (FastAPI / OpenAPI 3.1). Disabled in production.
- Machine-readable spec: [`packages/api-client/openapi.json`](../packages/api-client/openapi.json)
  (regenerate with `uv run python scripts/export_openapi.py ../../packages/api-client/openapi.json` in `services/api`).
- Agents service: http://localhost:8100/docs — `POST /v1/chat`, `POST /v1/chat/{thread_id}/approval`,
  `GET /v1/threads`, `GET /v1/threads/{id}/messages`, `DELETE /v1/threads/{id}`, `GET /v1/admin/metrics`.
  `POST /v1/chat` takes `channel` (`app`, `web`, `partner`, `admin` or `whatsapp`) and, from the
  WhatsApp channel, an optional `delivery_address` (a location the customer shared).

## Conventions

| Topic | Rule |
|---|---|
| Auth | `Authorization: Bearer <Firebase ID token>`; optional `X-Firebase-AppCheck` (required when enforced). Gudy's WhatsApp chats use a channel token (`gmc1.…`, customer role only, 10 minutes) that the API issues itself |
| Service calls | Gud Meal's agents service sends `X-Service-Authorization: Bearer <Google OIDC token>` (shared `X-Internal-Token` locally) and is then exempt from App Check; the user's own token is still required |
| Money | integer kobo, fields end in `_kobo` |
| Idempotency | `Idempotency-Key` header (8–200 chars) required on `POST /v1/orders`, `POST /v1/orders/{id}/checkout`, `POST /v1/rider/payouts`; replays return the stored response with `Idempotent-Replayed: true` |
| Errors | `{"error": {"code", "message", "details", "request_id"}}` with stable codes (`price_changed`, `quote_expired`, `invalid_transition`, `voucher_invalid`, `out_of_delivery_area`, `rate_limited`, …) |
| Webhooks | `POST /v1/webhooks/paystack` (`x-paystack-signature`), `POST /v1/webhooks/flutterwave` (`verif-hash`), `POST /v1/webhooks/whatsapp` (`X-Hub-Signature-256`) |
| Internal | `/internal/*` accepts only Google OIDC tokens from allowed service accounts (shared secret locally) |

## Route groups

`/v1` public catalog · `/v1/me`, `/v1/quotes`, `/v1/orders`, `/v1/payments`, `/v1/meal-plans`, `/v1/support`,
`/v1/applications` (customers) · `/v1/partner/restaurants/{id}/…` (restaurant roles) · `/v1/rider/…` (riders) ·
`/v1/admin/…` (staff permissions) · `/internal/tasks|events|jobs` (Cloud Tasks, Pub/Sub, Scheduler).

## Multi-service endpoints (2026-11-15)

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/services?city=` | public | Food, Beauty & Skin care, Package Delivery: availability, partner counts, coming-soon options |
| `GET /v1/services/{food\|beauty}/categories?city=` | public | Browse categories with merchant counts (Promotions, Local food, Skincare…) |
| `GET /v1/restaurants?vertical=food\|beauty\|all&city=&category=&pickup=` | public | Merchants for a service; cards carry `vertical`, `city`, `promotions` |
| `GET /v1/search?q=&vertical=&city=` | public | Dishes/products and stores; each hit carries its `vertical` |
| `GET /v1/cities` · `GET /v1/places/areas?city=` · `GET /v1/places/resolve?q=` | public | Launch cities and neighbourhood centres for addresses without a map pin |
| `POST /v1/parcels/quotes` · `GET /v1/parcels/quotes/{id}` | customer | Price a package delivery (same city, size, contents, optional `scheduled_for`) |
| `POST /v1/parcels` (Idempotency-Key) | customer | Create the parcel order from a quote; pay with `POST /v1/orders/{id}/checkout` |
| `GET /v1/me/order-summary` | customer | Paid orders, total spent (net of refunds), per service, this month, favourite store |

## Wallet, pay on delivery and cash on delivery (phase 2)

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/wallet` · `GET /v1/wallet/transactions` | customer | Balance, limits, refund setting, statement, seller COD summary |
| `POST /v1/wallet/topups` (Idempotency-Key) | customer | Start a gateway checkout that credits the wallet once verified |
| `PUT /v1/wallet/settings` | customer | `refund_to_wallet`: card refunds go instantly to the wallet |
| `GET /v1/orders/{id}/payment-options` | customer | Card / wallet / pay on delivery, each with `available` and a `reason` |
| `POST /v1/orders/{id}/checkout` `{"provider": "wallet" \| "cash"}` | customer | Pay from the wallet (instant) or choose pay on delivery (server checks eligibility) |
| `GET /v1/seller/balance` | customer | Cash-on-delivery money collected for you, payouts, statement |
| `POST /v1/seller/payouts` · `POST /v1/seller/move-to-wallet` (Idempotency-Key) | customer | Withdraw COD money to a bank account (finance pays) or move it to the wallet |
| `POST /v1/rider/deliveries/{id}/deliver` `{"code", "cash_collected"}` | rider | `cash_collected: true` is required when the order has cash to collect |
| `GET /v1/admin/cash` | finance | Cash held per rider, wallet and seller balances |
| `POST /v1/admin/riders/{uid}/cash-remittances` (Idempotency-Key) | finance | Record a hand-in (bank transfer, cash deposit) or deduct from earnings |
| `GET /v1/admin/seller-payouts` · `POST /v1/admin/seller-payouts/{id}/decision` | finance | Review seller withdrawals; paid needs the bank reference |
| `PUT /v1/admin/customers/{uid}/pay-on-delivery` | support | Turn pay on delivery off/on for a customer (audited) |

Parcel quotes accept `cod_amount_kobo`; the breakdown then includes `cod_fee_kobo`. Rider order views include
`payment_method` (`cash` | `prepaid`) and `collect_cash_kobo`. `GET /v1/config/public` adds `wallet`,
`pay_on_delivery` and `cash_on_delivery` limits.

Parcel orders are ordinary orders with `vertical: "parcel"` and a `parcel` object (pickup/drop-off contacts,
size, contents); they skip the merchant (`paid → ready_for_pickup`) and are cancellable with a full refund until a
rider is assigned. `GET /v1/config/public` also returns `cities` and `support` contacts (`placeholders: true` until
real contacts are configured).

## Interstate waybill (phase 3, [ADR-0015](adr/0015-interstate-waybill.md))

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/waybill/origins` | public | Cities you can send from: home pickup yes/no, drop-off hubs |
| `GET /v1/waybill/destinations?origin=` | public | Where a city sends to: from-price, transit days, door delivery or collection hubs, carrier |
| `POST /v1/waybills/quotes` · `GET /v1/waybills/quotes/{id}` | customer | Price a waybill and get the expected dates. Inputs: route, pickup or drop-off, door or collection, sender, recipient, size, weight, category, declared value, cash on delivery |
| `POST /v1/waybills` (Idempotency-Key) | customer | Book from a quote (re-priced; `price_changed` if it moved). Returns the order with `waybill.tracking_code`. Pay with `POST /v1/orders/{id}/checkout`, by card or wallet only |
| `GET /v1/track/{code}` | public, rate-limited per client address | Route, step, milestones, places, expected dates, collection point; **no names, phones or addresses** |
| `GET /v1/admin/hubs` · `GET /v1/admin/hubs/{hub_id}/board` | `hubs:operate` (hub agents, operations) | Hubs; the board lists packages expected, in the hub, departed and arriving |
| `POST /v1/admin/waybills/receive` · `…/depart` · `…/arrive` · `…/collect` | `hubs:operate` | Scan in at the origin hub, send a batch with a trip reference, mark arrival, hand over against the recipient's collection code |
| `GET` · `PUT /v1/admin/config/logistics` | `config:read` / `config:write` | The network (cities, hubs, carriers, lanes and their prices); versioned and audited |
| `POST /v1/admin/carriers/{carrier_id}/payouts` (Idempotency-Key) | finance (`payouts:approve`) | Record a bank payment to a carrier (at most what is owed) |

Waybill fields in other responses:

- Orders with `vertical: "waybill"` carry a `waybill` object (tracking number, hubs, parties, stage, milestones,
  expected dates) and `progress.steps`, the five step labels.
- The breakdown adds `linehaul_fee_kobo` and `pickup_fee_kobo`.
- Rider views of waybill jobs carry `leg_kind` (`first_mile` | `last_mile`) and `hub_handover` (first-mile jobs end
  with hub staff, not with a code).
- `GET /v1/admin/cash` adds `carriers` and `totals.carrier_balances_kobo`.
- Customer order lists never include rider jobs. Rider jobs cannot be checked out, cancelled or disputed.

## Plus, rewards and group orders (phase 4, [ADR-0016](adr/0016-plus-rewards-group-orders.md))

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/plus` | customer | The plan (price, benefits) and my membership (until when, auto-renew, savings, `can_renew`) |
| `POST /v1/plus/subscribe` (Idempotency-Key) `{"provider", "auto_renew"}` | customer | Join or renew. `provider: "wallet"` is instant; otherwise it returns a hosted checkout. Paying again works only in the last 7 days of a period |
| `PUT /v1/plus/auto-renew` `{"auto_renew"}` | customer | Renew from the wallet each period, or cancel at the end of it |
| `GET /v1/rewards` · `GET /v1/rewards/vouchers` | customer | Gud points, redeem steps, personal vouchers, referral code, history |
| `POST /v1/rewards/redeem` (Idempotency-Key) `{"points"}` | customer | Turn points into a personal voucher (in steps, e.g. 500 points = ₦500) |
| `POST /v1/rewards/referral` `{"code"}` | customer | Apply a friend's code (new customers, once): a welcome voucher at once |
| `GET /v1/group-orders` · `POST /v1/group-orders` | customer | My group orders · start one at a Food or Beauty store (delivery address, `split_mode` `each` or `host`) |
| `POST /v1/group-orders/join` `{"code"}` | customer (rate-limited) | Join with the 6-character code |
| `GET /v1/group-orders/{id}` | members | Members, everyone's items (live prices), shares, my share, what is still unpaid, pay-by time |
| `PUT /v1/group-orders/{id}/lines` · `…/ready` · `…/settings` | members (settings: host) | Replace my items · I'm done · who pays |
| `POST /v1/group-orders/{id}/lock` · `…/unlock` · `…/cancel` · `DELETE …/members/{uid}` | host (leave: the member) | Manage the cart; cancelling after ordering refunds every paid share |
| `POST /v1/group-orders/{id}/checkout` (Idempotency-Key) | host | One quote and one order for everyone (host's address, voucher, Plus); shares from `split_bill` |
| `POST /v1/group-orders/{id}/pay` (Idempotency-Key) `{"provider", "cover_rest"}` | members | Pay my share by card or wallet, or (host) pay everything still unpaid |
| `GET /v1/admin/growth` | analytics (finance, operations, marketing, admin) | Plus members and revenue, points outstanding, referrals, reward vouchers |
| `GET` · `PUT /v1/admin/config/growth` | `config:read` / `config:write` | Points, referral and group-order settings (versioned, audited); the Plus plan is part of `/v1/admin/config/pricing` |
| `POST /internal/jobs/renew-plus` | Cloud Scheduler | Daily wallet renewals and low-balance reminders |

Related fields in other responses:

- Quotes and orders carry `breakdown.plus_savings_kobo`.
- Orders placed from a group carry `group_order_id`.
- `GET /v1/config/public` adds `plus`.
- Split-bill orders refuse `POST /v1/orders/{id}/checkout` and pay on delivery: each member pays through
  `/group-orders/{id}/pay`.

## Gudy on WhatsApp (phase 5, [ADR-0017](adr/0017-gudy-on-whatsapp.md))

| Method & path | Who | Purpose |
|---|---|---|
| `GET /v1/me/whatsapp` | customer | Whether WhatsApp ordering is on, the business number, and my linked number (masked, e.g. `+234 801 ••• 1111`) |
| `POST /v1/me/whatsapp/link-code` | customer (5 an hour) | A 6-digit code (single use, 10 minutes) and a `wa.me` link that pre-fills `LINK 123456` |
| `DELETE /v1/me/whatsapp` | customer | Disconnect my number (sending `STOP` on WhatsApp does the same) |
| `GET /v1/webhooks/whatsapp?hub.mode=&hub.verify_token=&hub.challenge=` | Meta | Webhook verification: echoes the challenge when the verify token matches; 404 while WhatsApp is off |
| `POST /v1/webhooks/whatsapp` | Meta | Incoming messages. `X-Hub-Signature-256` must match (HMAC-SHA256 of the raw body with the app secret), else 401. De-duplicated by message id and queued |
| `POST /internal/tasks/whatsapp-message` | Cloud Tasks | Handles one message: link codes, `STOP`, `HELP`, shared locations, and the chat with Gudy |
| `GET /v1/dev/whatsapp` · `POST /v1/dev/whatsapp/{number}/send` · `GET /v1/dev/whatsapp/{number}/messages` | local and test only | WhatsApp simulator: sends signed fake webhooks (text, button taps, locations) and shows the sandbox replies |

Related fields in other responses:

- Orders and support tickets that Gudy creates in a WhatsApp chat carry `channel: "whatsapp"`. Gudy in the app and
  on the website still uses `ai_agent`. `POST /v1/orders`, `POST /v1/parcels`, `POST /v1/waybills` and
  `POST /v1/support/tickets` accept the new value.
