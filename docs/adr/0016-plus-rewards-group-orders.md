# ADR-0016: GudMeals Plus, Gud points and referrals, group orders with split bill

- **Status:** Accepted (product defaults to be confirmed by the owner; legal review of subscription terms pending)
- **Date:** 2026-11-15
- **Context owner:** owner's product decisions of 2026-11-15 (see [ROADMAP](../ROADMAP.md)), phase 4

## Context

The owner wants three growth features:

- a **GudMeals Plus** membership
- **referral and loyalty rewards**
- **group orders with split bill**

All three touch money: fees, discounts, payments from several people, and refunds. They must keep the platform's
rules:

- integer kobo
- prices only from `pricing.py`
- status changes only through the order state machine
- an append-only, balanced ledger
- idempotency, and audit trails for staff actions
- no LLM authority over money

They must also avoid two regulatory traps:

- **Promotional cash in the wallet.** The wallet is closed-loop stored value that still needs a CBN review.
- **Person-to-person transfers.** Sending money between users is a licensed activity.

## Decision

### 1. GudMeals Plus (membership)

**Plan.** The plan lives in `PricingConfig.plus` and is edited through the existing versioned, audited pricing
endpoint. Defaults:

| Setting | Default |
|---|---|
| Price | ₦1,500 per 30 days, VAT included |
| Free delivery | Food and Beauty orders with a subtotal of ₦3,000 or more |
| Service fee | 50% off on Food and Beauty orders |
| Gud points | Double points on every completed order |

**Benefits are priced in `pricing.py`.**

- A member's quote waives the delivery fee and reduces the service fee before VAT. The breakdown adds
  `plus_savings_kobo`: the non-member total minus the member total, computed by the same function.
- Settlement does not change. Riders are still paid in full; a waived fee is not collected, so the ledger shows
  less `revenue:delivery` or more `expense:delivery_subsidy`.
- A delivery-fee voucher on a free-delivery order is refused.
- Membership is checked when the order is priced and again when the order is created (re-pricing), so a
  membership that lapses in between returns `price_changed`.

**Buying and renewing.**

- `POST /v1/plus/subscribe` with an `Idempotency-Key` pays by card (hosted checkout, `payment_records.purpose =
  'plus'`) or from the wallet (instant, under the wallet account lock).
- A verified payment posts Dr `cash:<provider>` or `liability:wallet:{uid}` / Cr `revenue:plus` (net) +
  `liability:vat`, then emits `plus.paid`.
- `MembershipService` activates the membership, or extends it from the current end date. Activation is idempotent
  per payment: one period per payment, recorded in `memberships/{uid}/periods/{n}`.
- **Auto-renew uses the wallet only.** GudMeals stores no card authorisations. A daily job,
  `/internal/jobs/renew-plus`, charges the wallet in the last 24 hours of a period, with the idempotency key
  `plus:{uid}:period:{n}`. When the balance is too low, the member gets one reminder and the membership lapses at
  the end of the period.
- **Paying again** is possible only in the last 7 days of a period, so a double tap cannot buy two months.
- **Cancelling** turns auto-renew off. Benefits last until the end of the paid period, and there are no partial
  refunds.

### 2. Gud points and referrals (no cash, only vouchers)

Rewards never create money. They become **personal vouchers**: `Voucher.customer_id` restricts a voucher to one
account. Vouchers are platform-funded discounts that `pricing.py` prices like any voucher and that settle through
`expense:promotions` when the order completes. Personal vouchers work on Food and Beauty orders. The quote service
reports an unknown code when someone else's personal voucher is used.

**Gud points.** Settings live in `platform_configuration/growth` (`GrowthConfig`).

- **Earning:** 1 point per ₦100 of a completed order's total, for every service except internal rider jobs. Plus
  members earn double.
- **Recording:** points are not money and are kept outside the ledger, in `loyalty_accounts/{uid}`, with an
  append-only `entries` subcollection. Deterministic entry ids (`order:{id}`) make earning idempotent.
- **Reversal:** a refund after completion removes points in proportion to the refund. The balance may go negative.
- **Redeeming:** 500 points become a ₦500 personal voucher, valid 90 days on orders of ₦2,000 or more. One
  Firestore transaction deducts the points and creates the voucher.

**Referrals.**

- Every customer gets a referral code, which maps to their account in `referral_codes/{code}`.
- A new customer can apply a friend's code once, before their first paid order, and not their own. They receive a
  ₦1,000 voucher at once, valid 30 days on orders of ₦3,000 or more.
- When their first order completes, the friend receives a ₦1,000 voucher, up to 10 such rewards per calendar month.
- Every reward is idempotent per referred customer.

### 3. Group orders with split bill

`group_orders/{id}` is a shared, server-side cart at one Food or Beauty store:

- the host and up to 9 members
- each member's own lines
- a 6-character join code, mapped in `group_codes/{code}`
- 3 hours to fill the cart

Who can do what:

- Only members can read the group.
- Members edit only their own lines, and only while the group is open.
- The host can lock or unlock the cart, remove members, check out and cancel.
- Joining is rate-limited per user to stop people guessing codes.

**Checkout.** The host checks out with one normal quote and order, built from everyone's lines with the host's
address and voucher, and the host's Plus benefits. The order carries `group_order_id`. The host picks one of two
payment modes:

- **The host pays.** The order is paid as usual. Shares are shown so friends know what they owe; no money moves
  between users.
- **Everyone pays their share.**
  - Each member pays their own share by card or wallet: `payment_records.purpose = 'group_share'`, with the payer
    as the record's customer.
  - Each share posts Dr `cash:<provider>` or `liability:wallet:{payer}` / Cr `liability:customer_funds`, exactly
    like an order payment.
  - The host can **pay the rest** (all unpaid shares) in one payment.
  - When the shares add up to the order total, the order moves `pending_payment → paid` (payment provider `group`)
    and continues to the merchant.
  - If the payment window (the normal unpaid-order expiry, 30 minutes) passes first, the order is cancelled and
    every paid share is refunded in full automatically.
  - A share paid twice, or paid after cancellation, is refunded automatically.
  - Group orders cannot be paid on delivery.

**Shares** come from `pricing.split_bill`. Each member pays for their own items. Delivery, service and small-order
fees, VAT and any discount are shared **in proportion to each member's items**. Largest-remainder rounding makes
the shares add up exactly to the order total, and every share is positive.

**Refunds of a paid group order** (merchant rejection, cancellation, support refunds):

- They are split across the share payments in proportion to what each person paid. Each part goes back to its
  payer, through the wallet or the original method under the normal refund rules.
- The order changes refund status only when the last of those refunds completes. All parts are recorded
  before any is paid out.
- When finance must approve the refund, each payer's part is a separate request.

### Gudy

Gudy gets three new read-only tools, and can open the Plus, Rewards and group order screens:

- `get_plus_membership`
- `get_rewards`: points, personal vouchers, referral code
- `get_group_orders`: my open groups, and my share and its status

No Gudy tool subscribes, redeems, joins or pays. Customers do those on the screen Gudy opens.

## Consequences

- **Migration `0003`:** `payment_records.purpose` accepts `plus` and `group_share`. There are no other new tables:
  points, memberships and groups live in Firestore, and money stays in the existing ledger with one new account,
  `revenue:plus`.
- **New Firestore collections**, all API-only:
  - `memberships/{uid}`
  - `loyalty_accounts/{uid}` with `entries`
  - `referral_codes/{code}`
  - `group_orders/{id}`
  - `group_codes/{code}`
  - `platform_configuration/growth`
- **Payments and orders:**
  - Several payments for one order are now normal for split bills, so the order-level refund allocates across
    them.
  - The duplicate-payment check, checkout and pay on delivery reject direct payment of split-bill orders.
- **Command Centre:** a Growth page with Plus members and revenue, points outstanding (a measure of future
  discounts), vouchers issued and redeemed, referrals, and the growth settings.

## Open items (before launch)

1. **The owner confirms the defaults:** Plus price and benefits, earn and redeem rates, referral amounts and caps,
   group size and payment window.
2. **Legal review:** subscription terms (auto-renewal consent, cancellation, no partial refunds, VAT-inclusive
   price under FCCPA), and loyalty and referral terms (expiry, abuse, tax treatment of rewards).
3. **Revenue recognition.** Plus fees are recognised when paid; deferring them over the 30 days is an accounting
   refinement. The outstanding-points liability is reported, not booked.
4. **Referral abuse controls** are basic: once per account, before the first paid order, a monthly cap, and a
   minimum order. Device and phone checks need verified phone numbers.
5. **Card auto-renewal** needs stored card authorisations (for example Paystack `authorization_code`) and a
   recurring-charge consent flow. Until then, card members renew by hand after a reminder.
