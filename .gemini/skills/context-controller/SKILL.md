---
name: context-controller
description: >-
  Manages Context Window budgets, Progressive Disclosure, Handoff compression,
  cross-task preferences, and token-waste reporting for retro.
---

# Context Controller

Control Context Window budgets, compress Handoff bundles, expose preferences, and measure token waste for `retro`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Always produce a compressed Handoff bundle before `subagent-controller` dispatches a subagent.
- Keep cross-task preferences (including personal writing-style pointers) external to `SKILL.md` and `SOP.md`.
- Halt and return to `WFN` if required context cannot fit within budget without losing critical constraints.
