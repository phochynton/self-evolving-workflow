# WFB SOP — Iterative Skill, SOP & AUTO Switch Evolution

## Purpose
Safely create or update non-IP workflow skills (`wfn`, `wfb`, the 8 `*-controller` skills, `codex`, and Latin skills), their `SOP.md` files, `scripts/`, and `retro`-gated Stage AUTO Switch settings in `state.md`.

## Steps

### 1. Gather Evolution Input
1. Read the change source: user request, `itero` (`retro` + `context-controller` token audit) proposal, `rule-controller` rule proposal, or `docs/specs/known-open.md`.
2. Read `GLOSSARY.md` and the target skill's `SKILL.md` and `SOP.md`.
3. Verify the target is **not** an IP Skill. If it is an IP Skill, stop and reject the edit.
4. **Done when**: Target files, problem statement, and non-IP status are confirmed.

### 2. Propose Diff Plan (or AUTO Switch) & Wait for Approval
1. Draft a concise change plan listing:
   - Target files (`SKILL.md`, `SOP.md`, `scripts/*`, or `state.md`)
   - Exact problem or flow bug being fixed
   - Before/After summary of the change
2. If `retro` confirms a flow ran smoothly and qualifies for Stage AUTO Switch (`ADR-0001`), include an explicit **Stage AUTO Switch Proposal** citing `retro` and `context-controller` token evidence.
3. **Stop and ask the human for explicit approval.**
4. **Done when**: The human approves the change plan (and any Stage AUTO Switch proposal).

### 3. Apply Edit & Run Quality Gates
1. Edit the approved files using native file tools; record approved Stage AUTO Switch entries under `auto_switch:` in `state.md`.
2. Verify all 4 quality checks pass:
   - **IP boundary**: Zero IP Skills copied, wrapped, or modified.
   - **Lean `SKILL.md`**: `SKILL.md` is <= 30 lines and points to `SOP.md`.
   - **Simple English & Glossary**: Plain, positive instructions; terms match `GLOSSARY.md`; every step has a **Done when** criterion.
   - **Single source of truth**: No duplicated rules across `SKILL.md` and `SOP.md`.
3. **Done when**: All 4 checks pass.

### 4. Isolate Commit
1. Stage only the modified skill/SOP/script paths (`git add <explicit paths>`).
2. Commit with message `chore(workflow): <short summary>`. Never mix workflow edits with product code.
3. **Done when**: Clean `git status` and isolated commit recorded.
