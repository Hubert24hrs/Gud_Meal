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

## 4. Using real Firestore / PostgreSQL locally

- Firestore emulator: install Java 21, run `firebase emulators:start --only auth,firestore`, then start the API
  with `DATA_BACKEND=firestore FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 SEED_DEMO_DATA=false` and seed with
  the API container (`gudmeal_api.seed.seed`).
- PostgreSQL: `DATABASE_URL=postgresql+asyncpg://…` then `uv run alembic upgrade head` in `services/api`.

## 5. Tests

See the table in the root README. Rules tests: `npm run test:rules` (starts the Firestore + Storage emulators).
