# ADR-0003: LangGraph as an independent Cloud Run service

**Status:** Accepted · **Date:** 2026-11-14

## Context
AI behaviour changes frequently; it must not require app-store releases or share a blast radius with
payments. LLMs must never directly modify business data.

## Decision
`services/agents` is a separate FastAPI + LangGraph service. Clients call it with their Firebase ID
token. Tools call `gudmeal-api` forwarding that token (on-behalf-of), so the API remains the single policy
enforcement point. The agents service has no Firestore write access and its own database for
checkpoints and agent telemetry only.

## Consequences
- (+) Agents upgradeable independently; defence in depth (two authentication checks).
- (−) Extra network hop per tool call (mitigated by deploying both services in the same region).
