# WFN SOP — Starter Runtime Navigation

## Purpose
Inspect repository state and installed skills, then recommend the next action and Gate.

## Steps

### 1. Inspect State & Installed Skills
1. Run `git status --short`.
2. List available skills in `.gemini/skills/`.
3. Check active specs under `docs/specs/<feature>/` and `.scratch/<feature>/`.
4. **Done when**: Current state and available skills are known.

### 2. Recommend Next Step
1. If no workflow skills are installed beyond `wfn`, `wfb`, and `codex`, recommend `wfb` to add your skills.
2. Otherwise, match the current artifact state to the user's installed skills and `scripts/` Gates.
3. **Done when**: A 4-line status block (`Stage`, `Blockers`, `Next Skill`, `Next Gate`) is output.
