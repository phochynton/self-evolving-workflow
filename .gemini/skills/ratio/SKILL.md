---
name: ratio
description: >-
  Contract planning skill mixing to-spec, Interfaces (Consumes/Produces),
  enh.plan (Blast Radius, on-demand MCP grounding, invariants), and plan-lint.
  Outputs <id>-<summary>-ratio.md using the shared Run ID.
---

# Ratio (Contract Planning)

Turn requirements into a verifiable, lint-clean contract (`<id>-<summary>-ratio.md`) with explicit `Interfaces`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Read-only on production code: write only under `docs/specs/<feature>/`.
- Include `Interfaces` (`Consumes`/`Produces`) so isolated slice agents never guess signatures.
- Run `scripts/plan-lint.ps1` and paste its verbatim result before finishing.
