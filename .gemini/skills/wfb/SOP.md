# WFB SOP — Iterative Skill & SOP Evolution

## Purpose
Safely create or update non-IP workflow skills (`wfn`, `wfb`, `codex`, `libra`, `ratio`, `criticus`, `censor`, `sectio`, `faber`, `custos`, `itero`), their `SOP.md` files, and `scripts/`.

## Steps

### 1. Gather Evolution Input
1. Read the change source: user request, `itero` proposal, or `docs/specs/known-open.md`.
2. Read [GLOSSARY.md](../../../GLOSSARY.md) and the target skill's `SKILL.md` and `SOP.md`.
3. Verify the target is **not** an IP Skill. If it is an IP Skill, stop and reject the edit.
4. **Done when**: Target files, problem statement, and non-IP status are confirmed.

### 2. Propose Diff Plan & Wait for Approval
1. Draft a concise change plan listing:
   - Target files (`SKILL.md`, `SOP.md`, or `scripts/*`)
   - Exact problem or flow bug being fixed
   - Before/After summary of the change
2. **Stop and ask the human for explicit approval.**
3. **Done when**: The human approves the change plan.

### 3. Apply Edit & Run Quality Gates
1. Edit the approved files using native file tools.
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
