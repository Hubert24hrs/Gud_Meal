# ADR-0013: Yummy Chops wallet, pay on delivery and vendor cash-on-delivery

- **Status:** Accepted (product), legal review pending before launch
- **Date:** 2026-11-15
- **Context owner:** owner's product decisions of 2026-11-15 (see [ROADMAP](../ROADMAP.md)), phase 2

## Context

The owner chose four payment methods: Paystack (card/transfer/USSD), a **Yummy Chops wallet**, **pay on delivery**
and Flutterwave as a backup, plus **cash-on-delivery collection for vendors** sending packages. Nigerian
customers often prefer cash; small online sellers depend on COD; instant refunds build trust. All of this touches
money, so it must keep the platform's rules: integer kobo, prices only from `pricing.py`, append-only balanced
ledger, idempotency, no trust in clients, no LLM authority over amounts, and audit trails.

## Decision

### One ledger, three new kinds of account

| Account | Type | Meaning |
|---|---|---|
| `liability:wallet:{uid}` | liability | A customer's stored value (closed loop) |
| `liability:vendor:{uid}` | liability | COD money collected for a seller, not yet paid out |
| `receivable:rider_cash:{uid}` | asset | Cash a rider collected at the door and still has to hand in |

`financial_accounts.owner_type/owner_id` record the owner (`wallet`, `vendor`, `rider_cash`). Balances are always
computed from ledger entries; `RiderProfile.cash_held_kobo` is only a copy used by dispatch.

### Wallet (closed-loop stored value)

- **Top-up** = a normal gateway checkout with `payment_records.purpose = 'wallet_topup'` (no order). After the same
  server-side verification as order payments: Dr `cash:<provider>` / Cr `liability:wallet:{uid}`.
- **Pay** (`provider = "wallet"`): in one database transaction the wallet account row is locked
  (`SELECT … FOR UPDATE`), the balance checked, a succeeded `payment_records` row written and
  Dr `liability:wallet:{uid}` / Cr `liability:customer_funds` posted; then the usual `payment.succeeded` event
  moves the order on. A PostgreSQL race test proves two simultaneous payments cannot overspend.
- **Refunds** go into the wallet instantly (no gateway) for wallet and cash payments, and for card payments when
  the customer opts in (`refund_to_wallet`). `refund_records.destination` records where a refund went.
- **No withdrawals** to bank or cash. Limits (settings): top-up ₦500–₦100,000, balance ≤ ₦300,000.
- Yummy can read the wallet but has **no tool that moves wallet money**.

### Pay on delivery

- Eligibility (server-side, `CashService`): feature flag `pay_on_delivery` and setting on; delivery (not pickup,
  not packages); total ≤ ₦25,000; a phone number; at least one completed order; no other active cash order; not
  blocked by support (audited endpoint). Refusals leave the order payable online.
- The order goes `pending_payment → submitted_to_restaurant` without payment (new SYSTEM-only transition, applied
  only to cash orders) with a `pending` cash `payment_records` row and no ledger posting.
- While unpaid, the order is **cancelled, never refunded** (customer before acceptance, merchant rejection,
  merchant timeout, staff). A central money guard in `OrderService.build_transition` enforces both directions:
  paid orders can only go to `refund_pending`; unpaid cash orders can only be cancelled.
- At the door the rider must confirm the cash; the server then posts Dr `receivable:rider_cash:{rider}` /
  Cr `liability:customer_funds` (amount from the server's record, never from the rider) **before** the order
  becomes `delivered`. Settlement then runs as for any paid order, and settlement refuses any order without a
  captured payment.
- Riders hand cash in: finance records a bank transfer / cash deposit (Dr `cash:bank`) or deducts it from earnings
  (Dr `liability:rider:{uid}`), both Cr `receivable:rider_cash:{uid}`. Withdrawable earnings are net of cash held.
  Dispatch does not offer cash jobs to riders who would exceed ₦50,000 of cash.

### Vendor cash-on-delivery (packages)

- The sender enters the COD amount (≤ ₦100,000); `pricing.py` adds a collection fee (1.5%, minimum ₦100, rounded
  to ₦10) plus VAT to the booking. At completion the fee is credited to `revenue:cod_fee`.
- At drop-off the rider confirms the cash: Dr `receivable:rider_cash:{rider}` / Cr `liability:vendor:{sender}`.
- The seller can move the money into their wallet instantly (Dr vendor / Cr wallet) or request a bank payout
  (`vendor_payouts`), which finance pays manually and records with the bank reference (Dr vendor / Cr `cash:bank`).

### Gateway failover

Checkout tries the default gateway, then `PAYMENT_FAILOVER_PROVIDER` when the first one cannot start a checkout.
A small circuit breaker tries a gateway last after three consecutive failures for two minutes. A customer who
picked a gateway explicitly gets its error. A second successful payment for one order (another gateway, the
wallet, or after switching to cash) is refunded automatically (`payment.orphaned`).

## Consequences

- No new money pathways outside the ledger; every movement is a balanced, idempotent, audited transaction.
- Migration `0002` (payment purpose, nullable `order_id` for top-ups, refund destination, `vendor_payouts`).
- Cash creates operational work: hand-ins, refused deliveries and lost cash need procedures (see below).

## Open items (must be closed before launch)

1. **Legal/regulatory review** of the wallet as closed-loop stored value under CBN rules (limits, KYC tiers,
   whether a licensed partner must hold the funds), consumer-protection terms, and NDPA notices for bank details.
2. Failed cash deliveries: support can cancel and block pay on delivery, but compensating the merchant and the rider
   is a manual finance step; return trips for refused COD packages are not automated.
3. Seller payouts and rider hand-ins are recorded manually; automated transfers (e.g. Paystack Transfers) need
   keys, compliance checks and a reconciliation job.
4. Limits (top-up, balance, pay-on-delivery amount, rider cash) are product defaults to be confirmed by the owner.
