# ADR-0015: Interstate waybill through hubs, rider legs and partner line haul

- **Status:** Accepted (product); the network is **sample data** until real carriers and hubs are signed
- **Date:** 2026-11-15
- **Context owner:** owner's product decisions of 2026-11-15 (see [ROADMAP](../ROADMAP.md)), phase 3

## Context

Package Delivery must also send packages **between cities** (Lagos ↔ Enugu ↔ other states) through partner
logistics companies and hubs. Yummy Chops has riders only inside its launch cities (Lagos, Enugu). The trip between
cities is done by a line-haul carrier (an inter-city bus or truck company) on fixed departures. There are no real
carrier contracts or hub addresses yet, so the feature ships with an original **sample network** that is labelled
“(sample)” everywhere. Waybills move money, so the platform rules still apply:

- integer kobo, with prices only from `pricing.py`
- status changes only through the order state machine
- an append-only, balanced ledger
- idempotency and audit trails
- no LLM authority over money

Customers and recipients also expect a tracking number that works without signing in, and that number must not
expose anybody's personal data.

## Decision

### A waybill is an order

A waybill is an ordinary `orders` document:

- `vertical = "waybill"` and `restaurant_id = "gm-waybill"`
- a `waybill` object with the tracking number, lane, carrier, hubs, sender and recipient, size and weight,
  category, declared value, COD amount, expected dates, `stage`, `milestones`, rider-job ids and trip reference

It reuses the existing pipeline:

- the server-stored quote → order flow with an `Idempotency-Key`
- checkout by card/transfer/USSD or the wallet; **pay on delivery is not offered**, because packages are paid at
  booking
- refunds, disputes, order lists, totals and notifications

The coarse status stays in the 17-state machine: `paid → in_transit` (the origin hub has the package) →
`delivered` → `completed`. The detail lives in `waybill.stage`:

`awaiting_dropoff | pickup_scheduled | picked_up | at_origin_hub | departed | at_destination_hub |
out_for_delivery | ready_for_collection | delivered | cancelled`

Every scan appends a milestone. The customer sees five steps: Booked, At the hub, On the way, Arrived, Delivered.

### Rider legs are internal package jobs

Home pickup (the **first mile**: sender → origin hub) and door delivery (the **last mile**: destination hub →
recipient) are ordinary same-city package orders:

- `leg_of = <waybill id>`, `leg_kind = first_mile | last_mile`, with deterministic ids `{waybill}-fm` and
  `{waybill}-lm`, so creating them is idempotent
- `payment.provider = "internal"`: they hold no customer money and **cannot be checked out**
- created `draft → ready_for_pickup` by the system (a transition allowed only for legs), so normal dispatch
  offers them to riders

How each leg ends:

- **First mile.** Hub staff scan the package in, which completes the job. Riders cannot mark it delivered.
- **Last mile.** The job starts automatically when the package arrives at a destination hub with door service.
  The rider needs the recipient's delivery code (copied from the waybill) and confirms any cash on delivery as
  for packages. Its delivery marks the waybill delivered (`in_transit → delivered`, system).

Legs are hidden from customer order lists, admin analytics and customer notifications.

### Network configuration

The network lives in `platform_configuration/logistics`:

| Element | Fields |
|---|---|
| Cities | Door service yes/no |
| Hubs | Yummy Chops hubs and partner terminals; drop-off and collection flags; address and hours; `is_sample` |
| Carriers | Name and id |
| Lanes | Carrier; transit days; departure weekdays; cut-off hour; base price by size; included kg; price per extra kg; carrier share |
| Global | Booking fee; maximum weight by size |

Admins edit it with `GET/PUT /v1/admin/config/logistics` (versioned and audited). The default is the sample network:

| Lane | Carrier | Transit | Small / medium / large |
|---|---|---|---|
| Lagos ↔ Enugu | Sample Carrier East | 1–2 days | ₦4,500 / ₦6,500 / ₦9,500 |
| Lagos → Abuja | Sample Carrier North | 1–2 days | ₦5,000 / ₦7,000 / ₦10,000 |
| Lagos → Port Harcourt | Sample Carrier South | 2–3 days | ₦5,000 / ₦7,500 / ₦10,500 |
| Enugu → Abuja | Sample Carrier North | 1–2 days | ₦4,500 / ₦6,500 / ₦9,500 |
| Enugu → Port Harcourt | Sample Carrier South | 1 day | ₦3,500 / ₦5,000 / ₦7,500 |

Every lane departs Monday to Saturday with a 15:00 cut-off. The price includes 2, 5 or 10 kg by size, then
₦300 per extra kg. The carrier receives 60% of the line haul.

Hubs:

- **Yummy Chops hubs:** Lagos (Ikeja, Lekki) and Enugu (Independence Layout). They take drop-offs and hand
  packages over to recipients.
- **Partner terminals:** Abuja (Utako) and Port Harcourt (GRA Phase 2). They offer collection only, because Yummy
  Chops has no riders there yet. Door pickup and delivery exist only where Yummy Chops has riders.

### Pricing and dates (deterministic, `pricing.py` / `logistics.py`)

The price is the sum of:

- **line haul:** the lane base for the size, plus each started extra kg × the per-kg price
- **pickup fee:** the normal package fee for the distance from the sender to the origin hub
- **door delivery fee:** the normal package fee for the distance from the destination hub to the recipient
- **booking fee:** ₦200
- **COD collection fee:** as for packages
- **VAT** on all of the above

Weight limits are 5, 10 or 20 kg by size, and never more than 50 kg. The carrier's cost (60% of the line haul) is
stored in the order's settlement terms. Booking re-prices the quote: a changed price returns `price_changed`.

Expected dates come from the next departure after the cut-off (Lagos time) plus the lane's transit days. Home
pickup adds three hours. Door delivery adds a day.

### Hub operations

Hub operations happen in the Command Centre's **Hubs** console. They need the `hub_agent` role or
`operations_manager`, through the permission `hubs:operate`.

| Scan | Rule |
|---|---|
| Receive | Only at the booked origin hub. It completes the first-mile job, or cancels it when the sender walked in. Waybill `paid → in_transit`. |
| Depart | A batch of tracking numbers with one trip reference. Packages that are not at that hub are skipped with a reason. |
| Arrive | At the destination hub. Door delivery starts the last-mile rider job; otherwise the package is ready for collection. |
| Hand over | The recipient's 4-digit collection code, using the normal code check (attempts lock the code). Waybill → `delivered`. |

Every scan is a transactional compare-and-set on `status` and `stage`, so repeating a scan changes nothing. Scans
are recorded as order events.

### Tracking without personal data

The tracking number is `GMW` followed by 8 characters from an alphabet without look-alike characters. A lookup
document `waybill_tracking/{code}` maps it to the order. Collisions are retried at booking.

`GET /v1/track/{code}` is public and returns route, step, labels, places, expected dates and the collection point.
It never returns names, phone numbers or addresses. It is rate-limited per client address: 30 requests, then one
every two seconds.

The website has `/track` (no-index), the order screens show the history, and Yummy can track by number.

### Money

| Event | Debit | Credit |
|---|---|---|
| Payment (card / wallet) | as for any order | `liability:customer_funds` |
| Rider leg completed | `expense:waybill_riders` | `liability:rider:{rider}` |
| Last-mile rider confirms COD cash | `receivable:rider_cash:{rider}` | `liability:vendor:{sender}` |
| Waybill completed | `liability:customer_funds` (total) | `liability:vat`, `revenue:cod_fee`, `revenue:waybill` (rest) |
| ↳ same transaction | `expense:linehaul` (carrier cost) | `liability:carrier:{carrier}` |
| Carrier paid by finance (bank reference, ≤ amount owed, idempotent, audited) | `liability:carrier:{carrier}` | `cash:bank` |

Leg postings are recorded against the waybill's order id. Waybills produce no merchant commission record.

Cancellation:

- The customer can cancel with a full automatic refund until the package is with a rider or at a hub (stages
  `awaiting_dropoff` or `pickup_scheduled`, and the first-mile job not yet picked up). The first-mile job is then
  called off.
- After that, support handles it as a dispute.

### Yummy

Yummy has two read-only tools:

- `get_waybill_options`: routes from the customer's city, from-prices, transit days, and door delivery or
  collection points
- `track_waybill`: by tracking number, or the customer's latest waybill

Booking happens in the app or on the website, so Yummy needs no booking tool and no new approval.

## Consequences

- **No new tables or migrations.** Waybills reuse `orders`; ledger accounts are created on first use;
  `waybill_quotes` and `waybill_tracking` are API-only Firestore collections. There is one new composite index:
  `orders (vertical, status)`, for the hub boards.
- **New state-machine edges:**
  - `paid → in_transit` (system/staff): waybills only, enforced by `_flow_guard`
  - `draft → ready_for_pickup` (system): legs only, enforced by `_flow_guard`
  - system `in_transit → delivered`: waybills only, enforced by `_flow_guard`
  - system cancellation from `ready_for_pickup` / `rider_assigned`: only orders holding no customer money (legs)
    pass the money guard
- **Unchanged rules:** packages and waybills can never take the pay-on-delivery `→ submitted_to_restaurant` step,
  and legs cannot be paid, cancelled or disputed by customers.
- **Customer screens:** the website, the customer app and Yummy all book or track waybills from the same API.
- **Rider app:** it shows legs as “Interstate · to/from the hub”, with a hand-over card instead of the code form
  on first-mile jobs.

## Open items (before real launch)

1. **Real carriers, hubs and rates.** Contracts with line-haul partners, real hub addresses and opening hours,
   lane prices, the carrier share and departure times. Until then the network is the sample above.
2. **Carrier settlement.** Payouts are recorded by hand by finance. There is no carrier portal, manifest exchange
   or automated transfer yet; a trip is a free-text reference.
3. **Exceptions.** Failed door deliveries, unclaimed packages (storage time, return to sender), refused COD
   packages, and lost or damaged packages are manual support processes. The declared value is recorded, but there
   is no insurance or claims flow.
4. **Legal.** Prohibited and restricted items policy, ID checks at collection, liability limits and carrier terms
   need review.
5. **Hub scoping.** Hub agents may scan at any hub. Assigning staff to specific hubs is a later refinement.
