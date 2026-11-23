# WFB SOP — Starter Skill & SOP Builder

## Purpose
Safely add new skills or iteratively update existing skills in `.gemini/skills/` and `scripts/`.

## Steps

### 1. Gather Input
1. Read the user request (new skill to add, or SOP/Gate improvement).
2. Read `GLOSSARY.md` and any target `SKILL.md` / `SOP.md`.
3. **Done when**: Target skill name, purpose, and inputs/outputs are clear.

### 2. Propose Plan & Wait for Approval
1. Draft a concise plan listing target files, steps, and Gate checks.
2. **Stop and ask the human for explicit approval.**
3. **Done when**: The human approves the plan.

### 3. Write & Validate
1. Create or update `.gemini/skills/<name>/SKILL.md` (<= 30 lines) and `SOP.md` (Simple English, numbered steps, **Done when** criteria).
2. Update `GLOSSARY.md` if new domain terms are introduced.
3. **Done when**: All files pass length, Simple English, and glossary checks.

### 4. Isolate Commit
1. Stage only the modified skill/SOP/script paths (`git add <explicit paths>`).
2. Commit with `chore(workflow): <short summary>`.
3. **Done when**: Clean `git status` and isolated commit recorded.
