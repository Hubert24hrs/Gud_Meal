# ADR-0011: Gemini model chosen by environment, pinned in production

**Status:** Accepted · **Date:** 2026-11-14

## Context
Gemini model ids change frequently (previews, aliases, retirements). The official models page could not
be fetched automatically when this was implemented, so no specific id is hard-coded.

## Decision
`GEMINI_MODEL` and `GEMINI_FALLBACK_MODEL` are environment variables. Development defaults to the
`gemini-flash-latest` alias. Staging and production must pin an explicit **stable** Flash model id,
verified with `services/agents/scripts/check_gemini_models.py` (lists models available to the project's
API key). Token prices used for cost tracking are configuration too.

## Consequences
- (+) Model upgrades are configuration changes backed by an evaluation run, not code changes.
- (−) Requires an evaluation step before changing the pinned model.
