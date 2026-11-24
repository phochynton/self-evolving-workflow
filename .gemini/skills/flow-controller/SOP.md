# Flow Controller SOP — Workflow State Machine

## Purpose
Read file-based project state, determine Flow Tier (`Tier 1–4`), recommend next stages and controllers to `WFN`, and execute user-approved Stage AUTO Switch from `state.md`.

## Steps

### 1. Inspect File-Driven State
1. Run `git status --short` to check working-tree cleanliness.
2. Read active feature artifacts sharing `Run ID` (`<id>`):
   - `docs/specs/<feature>/<id>-*-ratio.md` (`run_id`, `status`, `round`, `verdict`, `open_accepted_items`, `ar_waiver`)
   - `docs/specs/<feature>/<id>-criticus-r*.md` and `<id>-censo-r*.md`
   - `.scratch/<feature>/issues/*`, `.scratch/<feature>/<id>-faber-state.md`, `.scratch/<feature>/evidence/*`
   - `docs/specs/known-open.md` and `state.md` (including `auto_switch:` block if present)
3. **Done when**: `<id>`, active feature, current stage, and blockers are identified from files.

### 2. Classify Tier & Recommend Next Stage
1. If Tier is unassigned or scope changed, dispatch `libra` to assign `Run ID` (`<id>`) and `Tier 1–4`.
2. If `Tier 4`, stop coding and recommend IP Skill `wayfinder` to `WFN` to split into Tier 2/3 plans.
3. Map current state to the recommended next stage and `WFN` target:

| Current State | Recommended Next Stage | Suggested WFN Target |
| :--- | :--- | :--- |
| `Tier 1` (single-line fix) | Single-line `tdd` (IP) + Gate + commit | `code-controller` |
| Needs contract (`Tier 2` / `Tier 3`) | Contract planning (`ratio`) | `rule-controller` |
| `status: draft` (`Tier 3`) | Generator-Critic (`criticus` / `censor`) | `rule-controller` |
| `status: ar-done` / `approved`, no Tickets | Ticket slicing (`sectio`) | `rule-controller` |
| Tickets ready / coding in progress | Implementation (`faber` / `implement-spec` IP) | `code-controller` |
| Build / test / tool-log / delivery (`custos`) | Execution & delivery verification | `verify-controller` |
| Human-facing PR or guide needed | Reader-oriented documentation | `manuscript-controller` |
| Delivered (`status: delivered`) | Retrospective & token audit | `itero` |

4. **Done when**: Target Tier, recommended stage, and suggested `WFN` target are determined.

### 3. Advance Stage or Return Recommendation to `WFN`
1. Check the `auto_switch:` block in `state.md` for an explicit user-approved entry matching this transition.
2. If approved in `state.md`, record the transition and advance automatically.
3. Otherwise, return the stage recommendation and suggested target to `WFN` for user confirmation.
4. **Done when**: Transition is either executed (if `auto_switch:` approved) or handed to `WFN`.

### 4. Escalate Blockers (Honest Boundary)
1. If state files conflict, required artifacts are missing, or a downstream controller trips a circuit breaker, stop advancing.
2. Write a structured blocker summary (`Stage`, `Run ID`, `Blocker`, `Required User Decision`) and return control to `WFN`.
3. **Done when**: Blocker context is handed back to `WFN` without silent bypass.
