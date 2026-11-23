---
name: wfn
description: >-
  Runtime workflow navigator. Reads project state (git status, specs, .gemini/skills/)
  and recommends the exact next skill and Gate.
---

# WFN (Workflow Navigator)

Read project state and installed skills, then guide the user to the next step.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Read-only: never edit production code, skills, or SOPs.
- Trust script Gate outputs (`plan-lint.ps1`, `ticket-gate.ps1`) over prose.
- Route only to skills present in `.gemini/skills/` or added by the user.
