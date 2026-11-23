# WFN SOP — Runtime Workflow Navigation

## Purpose
Determine the current workflow state and output the single clearest next action, skill, and Gate.

## Steps

### 1. Inspect Project State
1. Run `git status --short` to check for uncommitted work.
2. Check for active feature artifacts (sharing `Run ID` `<id>`):
   - `docs/specs/<feature>/<id>-*-ratio.md` (check `run_id`, `status`, `round`, `verdict`, `open_accepted_items`, `ar_waiver`)
   - `docs/specs/<feature>/<id>-criticus-r*.md` and `<id>-censo-r*.md`
   - `.scratch/<feature>/issues/<id>-sectio-*.md`, `.scratch/<feature>/<id>-faber-state.md`, `.scratch/<feature>/evidence/*`
   - `docs/specs/known-open.md`
3. **Done when**: Current stage, `<id>`, and active feature (or "new task") are identified.

### 2. Route by State & Tier
Follow this decision table:

| Current State | Recommended Skill | Action |
| :--- | :--- | :--- |
| New task / unclear Tier | `libra` | Assign `Run ID` `<id>` and `Tier 1–4` (or `codex` for external plan). |
| `Tier 4` (oversized/unclear) | IP Skill: `wayfinder` | Stop coding; map decisions and split into Tier 2/3 plans. |
| `Tier 1` (single-line) | `faber` | Run single-line `tdd` (IP) + Gate + commit. |
| `Tier 2` / `Tier 3` without `<id>-*-ratio.md` | `ratio` | Create contract `<id>-<summary>-ratio.md` (`Interfaces` & `plan-lint`). |
| `<id>-*-ratio.md` `status: draft` (Tier 3) | `criticus` | Run `plan-lint.ps1`, dispatch `criticus-Alpha/Beta/Gamma` (plus `codex` if external). |
| `<id>-criticus-r<N>.md` exists, no `<id>-censo-r<N>.md` | `censor` | Open fresh context (or external) for `<id>-censo-r<N>.md`. |
| `<id>-censo-r<N>.md` has `open_accepted_items > 0` or Blocker needs R2 | `ratio` / `criticus` | Apply `(Remedy N.k)` in `<id>-*-ratio.md`; run Round 2 if Blocker accepted. |
| `<id>-*-ratio.md` `status: ar-done` or `approved`, no Slices | `sectio` | Run `plan-lint.ps1 -Gate map`, then slice via `to-tickets` (IP). |
| Slices exist, incomplete in `<id>-faber-state.md` | `faber` | Execute via `implement-spec` (IP) + `ticket-gate.ps1`. |
| All Slices done, not delivered | `custos` | Run mechanical Gate, review loop (`code-review` IP -> `<id>-custos-r<N>.md`), and `-Gate post -Deliver`. |
| `status: delivered` | `itero` | Collect `<id>-itero-metrics.json`, run `retro` (IP), write `<id>-itero.md`. |
| Evolution proposals ready | `wfb` | Review and apply approved skill/SOP updates. |

**Done when**: Exact next skill, target file (`@<path>`), and required Gate command are output.

### 3. Output Format
Print a concise 4-line status block:
- **Stage**: `<current stage & Tier>`
- **Blockers**: `<dirty tree / open_accepted_items / failing Gate / none>`
- **Next Skill**: `<skill name>` (plus `@<artifact>` if applicable)
- **Next Gate**: `<exact command or none>`

**Done when**: The 4-line status block is delivered without modifying any files.
