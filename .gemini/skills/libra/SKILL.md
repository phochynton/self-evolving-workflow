---
name: libra
description: >-
  Assesses task scope and risk to assign Flow Tier 1, 2, 3, or 4.
  Rejects Tier 4 (oversized) tasks and routes them to wayfinder for splitting.
---

# Libra (Scope & Risk Triage)

Weigh the task size and risk to choose the right Flow Tier before planning or coding.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never start coding during triage.
- Reject `Tier 4` tasks and route them to IP Skill `wayfinder` for splitting.
- Never downgrade below `Tier3When` rules in `scripts/plan-lint.config.psd1`.
