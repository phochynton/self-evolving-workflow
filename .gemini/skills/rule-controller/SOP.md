# Rule Controller SOP — Governance & Contract Gates

## Purpose
Manage `AGENTS.md`, safety/permission guardrails, Honest Boundary, self-evolution rule proposals, and deterministic engineering contract Gates (`ADR-0002`).

## Steps

### 1. Enforce Guardrails & Honest Boundary
1. Check `AGENTS.md` and `ProtectedPaths` in `scripts/plan-lint.config.psd1` (if configured in the target repo) before any write or external action.
2. If required facts, permissions, or inputs are missing, stop immediately (`Honest Boundary`) and return a structured blocker to `WFN`.
3. **Done when**: Guardrail compliance is confirmed or a blocker is returned to `WFN`.

### 2. Dispatch Contract Creation & Run Contract Gates
1. Route engineering contract tasks to the matching skill without copying IP Skill prose:
   - Specs / Tickets -> `to-spec` (IP), `to-tickets` (IP), `ratio`, `sectio`
   - Terminology / ADRs -> `domain-modeling` (IP) against `GLOSSARY.md` and `docs/adr/`
2. Run deterministic contract Gates:
   - `pwsh -NoProfile -File scripts/plan-lint.ps1 <contract.md>`
   - `pwsh -NoProfile -File scripts/ticket-gate.ps1 <slice>`
3. **Done when**: Contract artifacts exist and all deterministic contract Gates return `PASS`.

### 3. Propose Rule Evolution
1. When recurring guardrail gaps or `AGENTS.md` ambiguities appear, draft a concise rule-evolution proposal (with rationale and diff).
2. Present the proposal to the user via `WFN` for explicit approval before editing `AGENTS.md`.
3. **Done when**: Rule proposal is approved or logged in `docs/specs/known-open.md`.
