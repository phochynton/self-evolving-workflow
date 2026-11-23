---
name: custos
description: >-
  Verification and delivery guardian. Runs mechanical Gates, review loop
  (code-review IP or external), enforces Disposition and Known-Open, and calls pr.
---

# Custos (Verification & Delivery)

Guard final quality with mechanical Gates, dual-axis code review, and traceable dispositions.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Run `ticket-gate.ps1 -Mode green` before every review round.
- Record every finding in `## Disposition` (`Hard`/`Missing`/`Scope` are never `deferred`).
- Only `plan-lint.ps1 -Gate post -Deliver` may set `status: delivered`.
