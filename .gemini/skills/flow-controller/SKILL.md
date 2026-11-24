---
name: flow-controller
description: >-
  Workflow state machine that reads project state, determines Tier, recommends
  or advances stages, and executes user-approved Stage AUTO Switch.
---

# Flow Controller

Read project state files, classify Tier, drive stage transitions, and escalate blockers to `WFN`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never enable Stage AUTO Switch on your own; execute it only when approved by the user via `WFB` (`ADR-0001`).
- Keep state handoffs file-driven (`Run ID` artifacts, `state.md`, `known-open.md`), never via chat memory.
- Halt and return structured blocker context to `WFN` whenever state is ambiguous or a Gate fails.
- Keep IP Skills external: invoke or recommend by reference, never copy them.
