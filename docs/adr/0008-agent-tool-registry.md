# ADR-0008: Typed, permissioned agent tool registry with approval

**Status:** Accepted · **Date:** 2026-11-14

## Decision
Tools are registered centrally with a Pydantic argument model, allowed roles, agent membership,
`requires_approval`, timeout and rate-limit settings, and an async handler that calls the API through a
client bound to the caller's token. A custom LangGraph node executes tool calls through this pipeline and
uses `interrupt()` for approvals. No tool accepts identity arguments or raw queries.

## Consequences
- (+) Uniform security, audit and testing for every AI action.
- (−) Each new capability needs an API endpoint first (intentional).
