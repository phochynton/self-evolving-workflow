---
name: criticus
description: >-
  Tier 3 Generator-Critic Phase 1. Runs plan-lint Gate, dispatches criticus
  subagents, verifies path:line citations via -Gate cite, outputs <id>-criticus-rN.md,
  and invokes codex for external review bundles.
---

# Criticus (Adversarial Attackers)

Stress-test `<id>-<summary>-ratio.md` before any code is written, grounded in verified `path:line` evidence.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never modify `plan.md` or production code during attack.
- Run `plan-lint.ps1` before dispatching attackers; abort on `FAIL`.
- Verify every `path:line` citation with `plan-lint.ps1 -Gate cite`.
