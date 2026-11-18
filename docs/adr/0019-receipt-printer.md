# ADR-0019: Receipts and the receipt printer

- **Status:** Accepted (built and tested locally)
- **Date:** 2026-11-17
- **Context owner:** owner's request of 2026-11-17: after checkout and payment, show the customer a receipt
  printer; the red PRINT button prints the receipt of what was just paid for and stores it "where the receipts
  are meant to be stored"; in the app and on the website

## Context

A customer who had paid saw the order's tracking page and nothing that read as proof of payment. The owner
supplied a React component to build from: a thermal printer seen from above (designed and built by Aakash
Mehra) with a red PRINT button, a paper strip that feeds out, can be stopped, continued and torn off, and
sounds synthesised in the browser.

Three things the request needed that the component did not have:

- **The real receipt.** The component printed sample items in yen. A GudMeals receipt must repeat exactly what
  the order was charged, for every service (shops, packages, interstate waybills).
- **A place to keep receipts.** Nothing stored receipts; the order was the only record.
- **A phone version.** The customer app is Flutter, not React.

Rules that had to keep holding: money is integer kobo and priced only by `pricing.py`; ledger tables are
append-only; a customer sees only their own data.

## Decision

### 1. A receipt is the paid order, repeated; printing keeps it

- `domain/receipts.py` builds a `Receipt` from an `Order` alone:
  - the shop (or "GudMeals" for packages), the receipt number (`GM-` plus the order's short code), the lines
    with their choices, the charges, the total, how it was paid and the payment reference;
  - for packages and waybills, a short summary (route, size, recipient, tracking number) in place of lines.
- **Nothing is priced.** Charges are the fields of the order's stored price breakdown. If they would not add up
  to the total charged, the rows are left out and the total stands alone.
- A receipt exists once money has been taken (`paid`, `partially_refunded`, `refunded`). A later refund is
  shown on the receipt; it does not remove it.
- **Storage:** `customer_profiles/{uid}/receipts/{order_id}`. One receipt per order, under the customer's own
  profile, written the first time they press PRINT. Further presses count the copy (`print_count`).
- **Endpoints** (customer only; anyone else gets 404):

| Endpoint | What it does |
|---|---|
| `GET /v1/orders/{id}/receipt` | The receipt to show; `saved` says whether it is kept. `409 order_not_paid` before payment |
| `POST /v1/orders/{id}/receipt` | PRINT was pressed: keep the receipt and count the copy |
| `GET /v1/receipts` | My receipts, newest first |

- No money moves, so the ledger is not involved.

### 2. The printer

- **Website:** `apps/web/src/components/ui/receipt-printer.tsx`, the supplied component adapted:
  - the maker's mark reads **GudMeals**;
  - the hint under the printer is a large dark pill: "Press the red PRINT button to print your receipt";
  - the paper prints the real receipt in naira;
  - it needs the `motion` package (the component's own dependency), added to `apps/web`.
- **Customer app:** `mobile/customer/lib/features/receipts/receipt_printer.dart`, the same printer rebuilt in
  Flutter with the same measurements and behaviour: feed, stop, another copy joined on, pull to tear off.
  - Flutter has no sound synthesiser without adding an audio plugin, so the motor is felt as small vibrations
    and the button clicks. The round button mutes both.
- Both follow the device's reduced-motion setting: the receipt then appears at once.

### 3. Where customers meet it

- **Right after paying:**
  - website: the payment return page opens `/orders/{id}/receipt` once the payment is verified; a wallet
    payment goes there directly;
  - app: the order screen opens the printer once when it sees the order paid after a checkout (card or
    wallet), including a payment finished later from the order screen.
- **Pay on delivery:** nothing is paid at checkout, so no printer then. The receipt is offered on the order
  once the cash is recorded.
- **Later:** "Print my receipt" on every paid order; "My receipts" in the profile (app) and on the account page
  (website, `/receipts`). "Read receipt" shows a long receipt in full.
- If saving fails, the hint says so and PRINT can be pressed again.

## Not built, and why

- **Printing on paper or saving a PDF to the phone.** The request was for the on-screen printer and stored
  receipts. A real print needs a print layout on the website and a PDF plugin in the app.
- **Receipts for wallet top-ups, GudMeals Plus and a friend's share of a group order.** These are payments
  without an order of the payer's own. The host of a group order gets the order's receipt.
- **A tax invoice** (seller's tax number, VAT breakdown per line). To decide with the accountant.

## Consequences

- One new dependency on the website (`motion`).
- Receipts are personal data. They sit under the customer's profile; there is no account-deletion flow yet, and
  when one is built it must remove this subcollection too.
- The receipt wording (charge names, "Paid with") lives on the server, so the app and the website always agree.

## Tests

- API: `tests/integration/test_receipts.py`.
- Website: `src/components/receipt-screen.test.tsx`, `src/app/checkout/callback/callback.test.tsx`.
- App: `test/receipt_test.dart`, `test/order_pay_test.dart`.
- Live stack: `scripts/e2e_local.py food_one_payment_covers_everything` reads, prints and lists the receipt.
