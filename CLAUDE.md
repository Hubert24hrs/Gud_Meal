# GudMeals — notes for AI coding sessions

## Non-negotiables
- The GitHub repo is **public**: never commit secrets, `.env*` (except `*.example`), service-account JSON,
  `google-services.json`, keystores. Local env files are `.env.local` / `.env` (git-ignored).
- Money is integer **kobo** everywhere (`*_kobo`). Prices come only from `services/api/.../domain/pricing.py`.
- Order status changes only via `OrderService.transition` (state machine in `domain/order_state.py`).
- Ledger tables are append-only; corrections are reversing transactions. Postings must balance.
- AI tools (`services/agents/src/gudmeal_agents/tools`) never take identity/amount arguments; sensitive
  tools set `requires_approval=True`. Tokens are bound via contextvars and must never enter graph state.

## Commands
- API: `cd services/api && uv run pytest` · lint `uv run ruff check src tests && uv run ruff format --check src tests`
- Agents: `cd services/agents && uv run pytest`
- Web: `npx vitest run --root apps/web` · build `npm run build` (from repo root)
- Flutter: `flutter analyze && flutter test` in `mobile/core|customer|rider`; models use Freezed → `dart run build_runner build` in `mobile/core`
- Tokens: edit `packages/tokens/tokens.json`, then `node packages/tokens/build.mjs` (regenerates CSS/TS/Dart)
- Local stack: `node scripts/dev.mjs auth|api|agents` and `npm run dev:web|dev:partner|dev:admin`
- End-to-end check of the running stack (every journey over HTTP): `services/api/.venv/Scripts/python services/api/scripts/e2e_local.py [journey ...]`
- Phone test: `node scripts/dev.mjs auth api agents downloads --lan --seed` (preview server `phone-test`: sign-in emulator, API, Gudy, download page and demo accounts in one), then `node scripts/build-test-apk.mjs` (docs/LOCAL_DEVELOPMENT.md §6); the test apps find this computer on the phone's Wi-Fi by themselves, so its address may change without a rebuild (ADR-0020). `dev.mjs api` turns on local-testing settings (shops always open, 40 km rider search, quick re-offers; with `--lan` demo shops accept orders by themselves)
- Brand files: `python scripts/make-brand-assets.py` (needs Pillow) makes the logo cut-outs, app icons, launch screens and favicons from `assets/brand/gudmeals-logo.webp` (ADR-0022). The platform is called **GudMeals**; colours come from the logo via `packages/tokens/tokens.json`

## Gotchas
- `packages/ui/src/components.tsx` is a `"use client"` module: pure helpers that server components call
  (like `cn`) live in `packages/ui/src/utils.ts`.
- On Windows, write files from Python with `encoding="utf-8"` (default cp1252 breaks on ₦).
- The Firestore emulator needs Java 21; without it, API tests use the in-memory DocumentStore (same contract).
- Postgres-only tests run when `TEST_DATABASE_URL` points to PostgreSQL (CI does this).
- Servers that keep running (the local stack, the phone test) start as preview servers from `.claude/launch.json`
  (the app allows five at once, so `phone-test` is four services in one), never in a background shell: a shell
  that never exits keeps a `/goal` waiting, and each check-in costs the owner usage.
