---
name: manuscript-controller
description: >-
  Human-facing documentation controller producing reader-oriented docs (PRs,
  user guides, READMEs) with pluggable external personal writing style profiles.
---

# Manuscript Controller

Produce human-facing documents (PR descriptions, user guides, READMEs) using external personal writing-style profiles.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never govern Specs, Tickets, ADRs, `GLOSSARY.md`, `plan-lint.ps1`, or `ticket-gate.ps1`; those belong to `rule-controller` (`ADR-0002`).
- Never hardcode personal writing-style rules inside `SKILL.md` or `SOP.md`; load them via external style profiles / `context-controller` preferences.
- Keep IP Skills external: dispatch `pr` by reference, never copy it.
