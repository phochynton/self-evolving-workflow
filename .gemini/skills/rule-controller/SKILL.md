---
name: rule-controller
description: >-
  Governance controller managing AGENTS.md, guardrails, Honest Boundary,
  rule evolution proposals, and contract Gates (Spec, Tickets, ADR, Glossary).
---

# Rule Controller

Enforce `AGENTS.md` guardrails, Honest Boundary, and engineering contract Gates (`plan-lint`, `ticket-gate`, Glossary/ADR).

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never modify `WFB`-owned Skill/SOP files directly; hand skill/SOP changes to `WFB`.
- Keep human-facing prose (PRs, user guides) out of scope (`manuscript-controller`, `ADR-0002`).
- Halt and return structured blocker context to `WFN` whenever Honest Boundary or a contract Gate fails.
- Keep IP Skills external: dispatch `to-spec`, `to-tickets`, and `domain-modeling` by reference, never copy them.
