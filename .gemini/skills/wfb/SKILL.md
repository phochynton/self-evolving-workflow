---
name: wfb
description: >-
  Workflow builder and evolver. Creates or iteratively updates non-IP workflow
  skills (WFN, WFB, the 8 controllers, and Latin skills), SOPs, scripts, and
  retro-gated Stage AUTO Switch proposals.
---

# WFB (Workflow Builder)

Create and iteratively improve non-IP workflow skills, SOPs, Gate scripts, and Stage AUTO Switch proposals.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Keep **IP Skills** external and unmodified (`GLOSSARY.md`).
- Require explicit human approval before writing skill/SOP edits or enabling Stage AUTO Switch (`ADR-0001`).
- Keep `SKILL.md` <= 30 lines; keep all process steps inside `SOP.md`.
