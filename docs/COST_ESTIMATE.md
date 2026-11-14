# Monthly infrastructure cost estimate

**Status: planning estimate, not a quote.** Cloud and model prices change; confirm every line with the
[Google Cloud pricing calculator](https://cloud.google.com/products/calculator) and the current Gemini price
list before production rollout. Figures are USD per month.

## Assumptions (launch phase, Lagos)

- 300 orders/day (~9,000/month), 3,000 daily active customers, 60 riders, 40 restaurants.
- Riders ping location every ~25 m of movement while online (rate-limited server-side).
- AI concierge: 2,000 assistant turns/day, ~5,000 input + ~400 output tokens per turn (Flash-class model;
  rates in `services/agents/.env.example` — update them to the current price list).
- Region `europe-west1`; one Cloud SQL instance per environment.

## Estimate

| Service | Dev | Staging | Production | Notes |
|---|---|---|---|---|
| Cloud Run (api + agents) | 0–5 | 5–15 | 40–90 | prod keeps 1 warm API instance; agents scale to zero |
| Cloud SQL PostgreSQL 16 | 0–50* | 50–60 | 200–260 | prod HA `db-custom-2-7680` + backups/PITR; *dev can stay on SQLite |
| Firestore | 0–5 | 0–5 | 10–40 | reads dominated by order/tracking listeners |
| Pub/Sub, Cloud Tasks, Scheduler | 0 | 0–2 | 2–8 | |
| Artifact Registry + Cloud Build | 0–3 | 2–5 | 5–10 | |
| Secret Manager, Logging, Monitoring | 0–2 | 2–5 | 10–30 | keep log levels at INFO, exclude health checks |
| Gemini API (assistant) | 0–10 | 5–20 | ~150 | 60k turns × (5k in + 400 out) tokens at the configured rates |
| Google Maps Platform | 0 | 0–10 | 0–200 | not called server-side yet; autocomplete/geocoding/routes when enabled |
| **Total (infra)** | **~0–75** | **~65–125** | **~420–790** | |

## Not included (variable business costs)

- **Payment fees** — Paystack's published local card pricing is a percentage plus a flat fee with a cap
  (verify on paystack.com). Fees are booked to `expense:provider_fees` when settlement reports are reconciled.
- **SMS for phone sign-in** — Firebase/Identity Platform bills phone verification per SMS by destination
  country; Nigeria rates must be checked. Encourage silent verification / longer sessions to limit SMS.
- Apple Developer ($99/yr) and Google Play ($25 one-off) accounts.

## Cost controls already in the design

Scale-to-zero for agents and non-prod; budget alerts in the bootstrap script; per-user rate limits on AI chat,
location pings and quotes; Gemini model chosen by environment variable; token and cost tracking per AI turn
visible in the Command Centre (AI agents page).
