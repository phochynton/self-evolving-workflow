---
name: verify-controller
description: >-
  Execution verification and delivery controller running builds, tests, code
  lints, tool execution-log checks, and custos delivery with a retry circuit breaker.
---

# Verify Controller

Run execution checks (build, tests, code lint, `Execution Log`), enforce the retry circuit breaker, and gate `custos` delivery.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Keep engineering contract Gates (`plan-lint`, `ticket-gate`) in `rule-controller` (`ADR-0002`).
- Enforce a strict retry circuit breaker (see [SOP.md](SOP.md) for the exact limit and `WFN` escalation).
- Rely strictly on deterministic command exit codes and `Execution Log` evidence.
