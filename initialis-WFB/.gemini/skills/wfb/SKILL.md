---
name: wfb
description: >-
  Workflow builder and evolver. Creates or iteratively updates skills,
  their SOP.md files, and scripts/ with human approval.
---

# WFB (Workflow Builder)

Create and iteratively improve workflow skills, SOPs, and Gate scripts.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never write skill or SOP edits without explicit human approval of the diff plan.
- Keep `SKILL.md` <= 30 lines; keep all process steps inside `SOP.md`.
- Keep external or user-marked IP Skills untouched unless explicitly requested.
