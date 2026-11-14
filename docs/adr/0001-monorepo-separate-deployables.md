# ADR-0001: Monorepo with separately deployable apps

**Status:** Accepted · **Date:** 2026-11-14

## Context
Five client applications, an API and an AI service must share contracts (order states, money rules,
design tokens) yet be released independently (e.g. upgrade agents without a mobile release).

## Decision
One Git repository with independent build units: npm workspaces for the three Next.js apps and shared
TypeScript packages, `uv` projects for the two Python services, and Flutter packages (`mobile/core`
shared by the customer and rider apps). Each deployable has its own build target and CI job.

## Consequences
- (+) Atomic changes across API contract and clients; one CI; shared design tokens.
- (−) Larger checkout; CI uses path filters to stay fast.
