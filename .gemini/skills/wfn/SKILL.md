---
name: wfn
description: >-
  Runtime workflow navigator. Reads project state (git status, plan.md, state.md,
  known-open.md) and recommends the exact next skill, Tier, and Gate.
---

# WFN (Workflow Navigator)

Read project state and guide the user or main agent to the next workflow step.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Read-only: never edit production code, skills, or SOPs.
- Trust script Gate outputs (`plan-lint.ps1`, `ticket-gate.ps1`) over prose.
- Keep IP Skills external: recommend invoking them by name, never copy them.
