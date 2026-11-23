# Criticus SOP — Adversarial Review Phase 1

## Purpose
Find hidden bugs, spec gaps, missing permissions, and interface flaws in `docs/specs/<feature>/<id>-<summary>-ratio.md` (`Tier 3`).

## Steps

### 1. Pre-Attack Lint Gate
1. Run `pwsh -NoProfile -File scripts/plan-lint.ps1 docs/specs/<feature>/<ratio-file>.md` and paste output verbatim.
2. If `FAIL`, stop immediately and return to `ratio` to fix the ratio contract.
3. Read `run_id` (`<id>`) from the ratio frontmatter and check `docs/specs/known-open.md`.
4. **Done when**: `plan-lint.ps1` returns `PASS`, `<id>` is known, and working tree is clean.

### 2. Dispatch `criticus` Subagents
Read `agent.yaml` (`attackers_model`, `attackers_reasoning`):
- **Tier 1 / 2** (if invoked manually): 1 subagent (`criticus-Alpha`).
- **Tier 3**: 3 parallel `criticus` subagents (`invoke_subagent`, roles `criticus-Alpha`, `criticus-Beta`, `criticus-Gamma`) with strict role isolation:
  - **`criticus-Alpha`**: Rules, `AGENTS.md`, `GLOSSARY.md`, and `Docs Sync` audit.
  - **`criticus-Beta`**: Call chains, `Interfaces` (`Consumes`/`Produces`), and module depth (check permission matrix & existing data migration).
  - **`criticus-Gamma`**: Boundaries, concurrency, client-supplied fields, security, and real-data test paths.
- Cap each `criticus` at **10 findings** (0 is valid) and require `Omitted: <count> (highest severity omitted: <level>)`.
- **Done when**: All `criticus` reports are collected without modifying the repo.

### 3. Verify Citations, Write `<id>-criticus-r<N>.md`, & External Review Bundle
1. Write merged findings to `docs/specs/<feature>/<id>-criticus-r<N>.md` with unique IDs (`Alpha-1`, `Beta-1`, `Gamma-1`, etc.).
2. Run `pwsh -NoProfile -File scripts/plan-lint.ps1 docs/specs/<feature>/<ratio-file>.md -Gate cite -Attack docs/specs/<feature>/<id>-criticus-r<N>.md`.
3. Mark any invalid `path:line` as `Citation Check: FAIL` (do not delete; let `censor` dismiss).
4. For **External Review (`--external-judge`)**:
   - Build `.scratch/<feature>/<id>-criticus-prompt-r<N>.md` (within `external_max_chars`) with rules, format, ratio contract, and `<id>-criticus-r<N>.md`.
   - Invoke **`codex`** (`-FromDoc` on `<id>-criticus-r<N>.md` or `-ListFile`) with `-Name "<id>-criticus-r<N>"` to package full source files.
5. **Done when**: `<id>-criticus-r<N>.md` is saved, `-Gate cite` has run, and next step (`censor` in a fresh context or external app) is stated.
