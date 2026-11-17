# Local development

## 1. Install

| Tool | Version used | Notes |
|---|---|---|
| Python | 3.13 | via `uv` (0.12) |
| Node.js | 22.12+ | npm workspaces |
| Flutter | 3.47 (Dart 3.13) | Android SDK for device builds |
| Firebase CLI | 14.x | Auth emulator works without Java |
| Java | 21 (optional) | required only for the Firestore/Storage emulators and rules tests |
| PostgreSQL | 16 (optional) | SQLite is used by default for the money DB locally |

```bash
cd services/api && uv sync
```

```bash
cd services/agents && uv sync
```

```bash
npm install
```

## 2. Run the stack

| Process | Command | URL |
|---|---|---|
| Auth emulator | `node scripts/dev.mjs auth` | http://127.0.0.1:9099 (UI :4000) |
| API (memory data, sandbox payments) | `node scripts/dev.mjs api` | http://localhost:8000/docs |
| Agents (needs `GOOGLE_API_KEY` for real answers) | `node scripts/dev.mjs agents` | http://localhost:8100/docs |
| Customer web | `npm run dev:web` | http://localhost:3000 |
| Partner dashboard | `npm run dev:partner` | http://localhost:3001 |
| Command Centre | `npm run dev:admin` | http://localhost:3002 |
| Flutter customer app | `cd mobile/customer && flutter run` | Android emulator reaches the API at 10.0.2.2 |

Copy each `apps/*/.env.example` to `.env.local` (emulator mode is the default).

Demo users (emulator only):

```bash
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 uv run --directory services/api python scripts/seed_auth_emulator.py
```

The password comes from `DEMO_USER_PASSWORD` (the script has an emulator-only default). Accounts:
`customer@gudmeal.test`, `friend@gudmeal.test` (a second customer, for group orders and referrals),
`owner@gudmeal.test` (Jollof Junction), `kitchen@gudmeal.test`, `rider@gudmeal.test` (demo-rider-1),
`support@`, `finance@`, `hub@` (interstate hubs), `admin@gudmeal.test` (super admin).

## 3. Payments locally

Without provider keys the API enables the **local payment sandbox** (only when `ENVIRONMENT` is `local`/`test`):
checkout redirects to `http://localhost:8000/v1/dev/sandbox-checkout/<reference>`; “Approve” sends an
HMAC-signed webhook through the same verification → ledger → order pipeline Paystack uses.
To test real Paystack test mode, set `PAYSTACK_SECRET_KEY=sk_test_…` in `services/api/.env` and expose the
webhook URL (`/v1/webhooks/paystack`) with a tunnel.

## 3a. Gudy on WhatsApp locally

`node scripts/dev.mjs api` switches WhatsApp on with the **sandbox sender**, so no Meta account is needed. Run the
agents service too (`node scripts/dev.mjs agents`; without `GOOGLE_API_KEY`, Gudy runs in offline mode).

1. Open the **WhatsApp simulator** at http://localhost:8000/v1/dev/whatsapp (local and test only) and pick a
   phone number. Messages you send there are signed like Meta's webhooks and go through the real pipeline:
   signature check, de-duplication, task, linking, Gudy, reply.
2. Sign in on the website as `customer@gudmeal.test`, open Account → **Connect WhatsApp** and send the
   `LINK 123456` message it shows from the simulator.
3. Chat: "What do you offer?", share a location, "I have ₦10,000, find me food for 2 people", "plan 1", then tap
   **Yes, go ahead** and pay on the sandbox payment page. `STOP` disconnects.

To try Meta's real Cloud API, set `WHATSAPP_PROVIDER=cloud`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_APP_SECRET`,
`WHATSAPP_VERIFY_TOKEN` and `WHATSAPP_PHONE_NUMBER_ID` in `services/api/.env` (git-ignored, never committed) and
expose `/v1/webhooks/whatsapp` with a tunnel.

## 4. Using real Firestore / PostgreSQL locally

- Firestore emulator: install Java 21, run `firebase emulators:start --only auth,firestore`, then start the API
  with `DATA_BACKEND=firestore FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 SEED_DEMO_DATA=false` and seed with
  the API container (`gudmeal_api.seed.seed`).
- PostgreSQL: `DATABASE_URL=postgresql+asyncpg://…` then `uv run alembic upgrade head` in `services/api`.

## 5. Tests

See the table in the root README. Rules tests: `npm run test:rules` (starts the Firestore + Storage emulators).

**End-to-end check of a running stack** (auth, api and agents started as above): every journey over HTTP with
real emulator accounts, from browsing to food, beauty, pickup, wallet, pay on delivery, bike packages, interstate
waybills, group orders, Plus, rewards, support, partner tools, sign-up approvals, payouts, the Command Centre,
access control and Gudy. It prints PASS/FAIL per step:

```bash
services/api/.venv/Scripts/python services/api/scripts/e2e_local.py            # Windows (bin/python elsewhere)
services/api/.venv/Scripts/python services/api/scripts/e2e_local.py parcel_bike_delivery   # one journey
```

Shops keep their real opening hours (Lagos time), so at night the check opens its test shops all day and puts
the real hours back when it finishes.

## 6. Test on your phone (Android)

Your phone and this computer must be on the same Wi-Fi. Use this only on a network you trust (home or office):
while it runs, anyone on that Wi-Fi can reach the test servers.

1. Start the stack in **LAN mode**, each in its own terminal (Windows may ask to let Python/Node through the
   firewall: allow it):
   ```bash
   node scripts/dev.mjs auth --lan
   node scripts/dev.mjs api --lan
   node scripts/dev.mjs agents --lan
   ```
   Then seed the demo accounts (section 2), or run the end-to-end check once: it seeds them too.
2. Build the test APKs (needs the Android SDK; set `LAN_IP` to choose the address):
   `node scripts/build-test-apk.mjs` (or `... customer` / `... rider`). They go to `mobile/dist` (git-ignored).
3. Serve them: `node scripts/dev.mjs downloads --lan`, then open `http://<this computer's address>:8090` on the
   phone (or scan a QR code of that address), install, and sign in with a demo account.

Test builds talk plain http to this computer and use the Auth emulator and the payment sandbox, so never publish
them; rebuild if the computer's address changes. After **Approve** on the sandbox payment page, the page says
"Return to the Gud Meal app": go back to the app, which confirms the payment.
