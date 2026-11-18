# Payments & Financial Ledger

## Principles

1. **Never trust the client.** A payment is successful only after the API verifies it with the provider's
   verify endpoint and the amount, currency and reference match the server-side payment record.
2. **Money is integer kobo** (`₦1 = 100 kobo`). No floats anywhere in the money path.
3. **Amounts come from the pricing engine**, never from a request body or an LLM.
4. **Idempotency everywhere**: order creation, checkout, refunds and webhook processing.
5. **Append-only double-entry ledger** in PostgreSQL. Corrections are reversing transactions.
6. **Provider-agnostic**: `PaymentProvider` adapter with Paystack (primary) and Flutterwave implementations.
   We do **not** assume marketplace split settlement is available on the merchant account — the platform
   collects, then settles restaurants and riders from the ledger (see ADR-0006).

## Payment flow

| Step | Component | Detail |
|---|---|---|
| Initialize | `PaymentService.initiate` | Creates `payment_records` row (status `initialized`) keyed by idempotency key, calls provider `initialize` with the order total, stores `authorization_url`. |
| Customer pays | Provider checkout | Card / bank transfer / USSD as enabled on the merchant account. |
| Webhook | `POST /v1/webhooks/paystack` | Raw body HMAC-SHA512 with the secret key, compared in constant time with `x-paystack-signature`. Optional source-IP allow-list. |
| Webhook | `POST /v1/webhooks/flutterwave` | `verif-hash` header compared in constant time with the configured secret hash. |
| Dedupe | `payment_events` | Unique `(provider, dedupe_key)`; duplicates return `200` without re-processing. |
| Verify | provider verify API | Re-queried server-side; amount, currency and reference must match. |
| Commit | one Postgres transaction | payment → `succeeded`, ledger entries, outbox event `payment.succeeded`. |
| Fulfil | outbox → Pub/Sub → API | order `pending_payment → paid → submitted_to_restaurant` (idempotent). |
| Client return | `POST /v1/payments/verify` | Same verification path; safe to call any number of times. |

Delayed or missing webhooks are covered by the client-triggered verify call and by the scheduled
reconciliation job (`/internal/jobs/reconcile-payments`) that re-verifies stale `initialized` payments.

## Ledger

Tables: `financial_accounts`, `financial_transactions`, `ledger_entries` (see [data-model](data-model.md)).

- Each `financial_transaction` has ≥ 2 entries; Σ debits = Σ credits (checked in code **and** by a
  deferred constraint trigger in PostgreSQL).
- `ledger_entries` and `financial_transactions` reject `UPDATE`/`DELETE` via triggers.
- Every transaction carries `kind`, `order_id`/`reference`, `idempotency_key` (unique) and actor.

### Chart of accounts

| Code | Type | Meaning |
|---|---|---|
| `cash:paystack`, `cash:flutterwave` | asset | Funds held at the payment provider |
| `cash:bank` | asset | Settlement bank account |
| `liability:customer_funds` | liability | Paid by customers for orders not yet completed |
| `liability:restaurant:{id}` | liability | Owed to a restaurant |
| `liability:rider:{id}` | liability | Owed to a rider |
| `liability:vat` | liability | VAT collected on platform fees |
| `revenue:commission` | revenue | Commission on food subtotal |
| `revenue:service_fee` | revenue | Service + small-order fees |
| `revenue:delivery` | revenue | Delivery fee minus rider pay |
| `expense:promotions` | expense | Platform-funded discounts |
| `expense:delivery_subsidy` | expense | Rider pay exceeding the delivery fee |
| `expense:refunds` | expense | Refunds absorbed by the platform |
| `expense:provider_fees` | expense | Payment processing fees |
| `liability:wallet:{uid}` | liability | A customer's GudMeals wallet (closed-loop stored value) |
| `liability:vendor:{uid}` | liability | Cash-on-delivery money collected for a seller, not yet paid out |
| `receivable:rider_cash:{uid}` | asset | Cash a rider collected at the door and has not handed in |
| `revenue:cod_fee` | revenue | Cash-on-delivery collection fees on packages |
| `liability:carrier:{id}` | liability | Owed to a line-haul carrier for interstate waybills |
| `revenue:waybill` | revenue | Waybill line haul, pickup, door delivery and booking fees (net of VAT and the COD fee) |
| `expense:linehaul` | expense | Carriers' share of waybill line haul |
| `expense:waybill_riders` | expense | Rider pay for waybill pickups and door deliveries |
| `revenue:plus` | revenue | GudMeals Plus membership fees (net of VAT) |

### Postings

**Payment captured** (total `T`): Dr `cash:<provider>` T / Cr `liability:customer_funds` T.

**Order completed** — with subtotal `S`, commission `K`, restaurant-funded discount `Dr`, platform-funded
discount `Dp`, delivery fee `F`, rider pay `P`, service + small-order fees `V`, VAT `X`:

| Account | Debit | Credit |
|---|---|---|
| `liability:customer_funds` | T | |
| `expense:promotions` | Dp | |
| `liability:restaurant:{id}` | | S − K − Dr |
| `liability:rider:{id}` | | P |
| `liability:vat` | | X |
| `revenue:commission` | | K |
| `revenue:service_fee` | | V |
| `revenue:delivery` / `expense:delivery_subsidy` | (P − F if P > F) | F − P if F ≥ P |

Balanced because `T = S + F + V + X − Dr − Dp`.

**Refund before completion**: Dr `liability:customer_funds` / Cr `cash:<provider>`.
**Refund after completion**: Dr `liability:restaurant:{id}` (restaurant at fault) or `expense:refunds`
(platform absorbs) / Cr `cash:<provider>`.
**Payout**: Dr `liability:restaurant:{id}`, `liability:rider:{id}`, `liability:vendor:{id}` or
`liability:carrier:{id}` / Cr `cash:bank`.

### Wallet, pay on delivery and vendor COD (phase 2, [ADR-0013](../adr/0013-wallet-and-cash.md))

| Event | Debit | Credit |
|---|---|---|
| Wallet top-up verified (`payment_records.purpose = wallet_topup`) | `cash:<provider>` | `liability:wallet:{uid}` |
| Order paid from the wallet (account row locked, balance checked) | `liability:wallet:{uid}` | `liability:customer_funds` |
| Refund into the wallet (before / after completion) | `liability:customer_funds` / restaurant / `expense:refunds` | `liability:wallet:{uid}` |
| Pay on delivery: rider confirms the cash (before `delivered`) | `receivable:rider_cash:{rider}` | `liability:customer_funds` |
| Vendor COD: rider confirms the cash at drop-off | `receivable:rider_cash:{rider}` | `liability:vendor:{sender}` |
| Rider hands cash in (bank transfer / cash deposit) | `cash:bank` | `receivable:rider_cash:{rider}` |
| Rider cash deducted from earnings | `liability:rider:{rider}` | `receivable:rider_cash:{rider}` |
| Seller moves COD money to their wallet | `liability:vendor:{uid}` | `liability:wallet:{uid}` |
| Seller bank payout marked paid by finance | `liability:vendor:{uid}` | `cash:bank` |

Wallet and cash payments are `payment_records` with `provider = wallet | cash`; they are never sent to a gateway,
webhooks for them are refused, and reconciliation skips them. Pay-on-delivery records stay `pending` (no ledger
entry) until the rider confirms the cash; if the order is called off first they become `abandoned`. Settlement
refuses any order without a succeeded payment record. Refunds record their `destination` (`original` or
`wallet`); wallet and cash payments are always refunded into the wallet.

### Interstate waybill (phase 3, [ADR-0015](../adr/0015-interstate-waybill.md))

| Event | Debit | Credit |
|---|---|---|
| Waybill paid (card or wallet; pay on delivery is not offered) | as for any order | `liability:customer_funds` |
| A waybill rider job (pickup or door delivery) completed | `expense:waybill_riders` | `liability:rider:{rider}` |
| Last-mile rider confirms cash on delivery | `receivable:rider_cash:{rider}` | `liability:vendor:{sender}` |
| Waybill completed: total `T`, VAT `X`, COD fee `C` | `liability:customer_funds` T | `liability:vat` X, `revenue:cod_fee` C, `revenue:waybill` T − X − C |
| ↳ in the same transaction: carrier cost `L` (lane share of the line haul, fixed at quote time) | `expense:linehaul` L | `liability:carrier:{carrier}` L |
| Carrier paid by bank transfer (finance, bank reference, at most the balance owed) | `liability:carrier:{carrier}` | `cash:bank` |

All waybill postings are recorded against the waybill's order id. Rider jobs are internal orders with
`payment.provider = "internal"`: they hold no customer money and are never sent to a gateway. A customer
cancellation before the package reaches a rider or a hub is refunded in full like any paid order.

### GudMeals Plus, rewards and split bills (phase 4, [ADR-0016](../adr/0016-plus-rewards-group-orders.md))

| Event | Debit | Credit |
|---|---|---|
| Plus paid by card (`payment_records.purpose = plus`, verified) | `cash:<provider>` (price) | `revenue:plus` (price − VAT), `liability:vat` |
| Plus paid or renewed from the wallet (account row locked) | `liability:wallet:{uid}` | `revenue:plus`, `liability:vat` |
| A member's share of a group order (`purpose = group_share`), card | `cash:<provider>` | `liability:customer_funds` |
| A member's share paid from their own wallet | `liability:wallet:{member}` | `liability:customer_funds` |
| Paid group order completed | as for any order (the shares add up to the total) | |
| Reward voucher used on an order | `expense:promotions` (platform-funded discount at completion) | |

Plus details:

- **Price and VAT.** The Plus price includes VAT; `pricing.vat_inclusive_split` takes the VAT part out.
- **Member benefits** are fees that are not charged (free delivery, cheaper service fee), so a member's order
  books less `revenue:delivery` / `revenue:service_fee`, or more `expense:delivery_subsidy`. Riders are paid in
  full.
- **Refunds.** There is no automatic refund of Plus fees.

Points and vouchers:

- **Points are not money.** They are kept in Firestore (`loyalty_accounts`). The Command Centre reports the
  outstanding value, the discounts customers can still claim.
- **Vouchers.** Redeemed points, referral gifts and referral thank-yous become personal vouchers, priced like any
  platform voucher.

Split bills:

- **Payments.** A split-bill order has one succeeded payment per share (several per order). The order moves to
  `paid` (payment provider `group`) when they cover the total.
- **Unpaid expiry.** If the payment window ends first, the order is cancelled and every share is refunded in full.
  A late or duplicate share payment is refunded automatically.
- **Refunds after payment** are split across the share payments in proportion to what each person still has paid
  in. Each part goes to its payer (wallet or original method), and the order changes status with the last part.

### Gateway failover

Checkout without an explicit provider tries the default gateway, then `PAYMENT_FAILOVER_PROVIDER` (if configured)
when the first cannot start the checkout; the response carries `failover_from`. After three consecutive failures a
gateway is tried last for two minutes. A second successful payment for the same order is refunded automatically.

## Refund & payout approval

- Customers and the Payment/Support agents can only **request** a refund review.
- Refunds above the configured auto-approve threshold, and all payouts, require approval by a
  `finance_manager` or `super_admin`. Approval actions are audited.
