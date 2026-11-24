---
status: accepted
---

# Split Engineering Contracts (rule-controller) from Human-Facing Docs (manuscript-controller)

Engineering contract and governance artifacts (Specs, Tickets, ADRs, `GLOSSARY.md`, `plan-lint.ps1`, `ticket-gate.ps1`, and terminology/ADR trigger checks) are owned by `rule-controller`, whereas human-facing documents (PR descriptions, user guides, and READMEs) with pluggable external writing-style profiles are owned by `manuscript-controller`.

## Considered Options

- **Group all text/Markdown artifacts under `manuscript-controller`**: Rejected because Specs, Tickets, ADRs, and `GLOSSARY.md` function as enforceable engineering contracts and deterministic Gates (as in `WorkpackageReportingSystem`), not prose deliverables.
- **Split by governance contract vs. human-facing prose**: Chosen so `rule-controller` enforces contract Gates while `manuscript-controller` applies external personal style profiles without hardcoding preferences into `SKILL.md` or `SOP.md`.

## Consequences

- `verify-controller` remains scoped to execution verification (builds, unit/E2E tests, code lints, and `tool-controller` execution logs), leaving contract and terminology Gates to `rule-controller`.
- Personal writing-style profiles live outside `manuscript-controller` (e.g., via `context-controller` cross-task preferences or an external style file).
