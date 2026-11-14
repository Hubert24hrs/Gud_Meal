# Gud Meal — notes for AI coding sessions

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

## Gotchas
- `packages/ui/src/components.tsx` is a `"use client"` module: pure helpers that server components call
  (like `cn`) live in `packages/ui/src/utils.ts`.
- On Windows, write files from Python with `encoding="utf-8"` (default cp1252 breaks on ₦).
- The Firestore emulator needs Java 21; without it, API tests use the in-memory DocumentStore (same contract).
- Postgres-only tests run when `TEST_DATABASE_URL` points to PostgreSQL (CI does this).
