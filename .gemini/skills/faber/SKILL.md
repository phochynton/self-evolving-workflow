---
name: faber
description: >-
  Executes coding by Flow Tier (Tier 1 single-line, Tier 2 gated, Tier 3 via
  IP Skill implement-spec + isolated Slice gates), invoking tdd and ticket-gate.ps1.
---

# Faber (Tiered Coding Execution)

Implement changes cleanly using `tdd` / `implement-spec` (IP Skills) and deterministic `ticket-gate.ps1` evidence.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never skip red-before-green (`ticket-gate.ps1 -Mode red` then `-Mode green`).
- In `Tier 3`, invoke IP Skill `implement-spec` after `to-tickets` and record `state.md`.
- Keep original file encoding/BOM/line endings; stage explicit paths (`git add <paths>`).
