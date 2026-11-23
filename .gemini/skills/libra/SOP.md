# Libra SOP — Scope & Risk Triage

## Purpose
Assign `Tier 1`, `Tier 2`, `Tier 3`, or `Tier 4` based on blast radius, risk, and clarity.

## Steps

### 1. Gather Facts & Assign Run ID
1. Generate a shared `Run ID` (`<id>`, e.g., `YYYYMMDD-<hash4>`) for this feature run.
2. Read the user request and check `scripts/plan-lint.config.psd1` (`Tier3When`, `MaxTicketFiles`, `MaxTicketLines`).
3. Run a quick `codegraph` or `grep` check to estimate affected production files and modules.
4. **Done when**: `<id>`, affected file count, P0 risk match, and requirement clarity are known.

### 2. Classify Flow Tier
Apply the highest matching Tier:

| Condition | Assigned Tier | Next Step |
| :--- | :--- | :--- |
| Crosses >1 subsystem, >9 prod files, or architecture is unclear | **Tier 4** | **Reject coding.** Invoke IP Skill `wayfinder` to map decisions and split into Tier 2/3 plans. |
| Touches `Tier3When` (auth, schema, concurrency, security, core routes) OR >3 prod files | **Tier 3** | Invoke `ratio` (with `criticus` + `censor` + `sectio`) using `<id>`. |
| Medium multi-file change (`<= 3` prod files or `<= 3` small slices), no `Tier3When` | **Tier 2** | Invoke `ratio` (light contract) -> `faber` -> single-pass `code-review` (IP). |
| Single file, single bug, clear fix, no `Tier3When` | **Tier 1** | Invoke `faber` directly (single-line `tdd` IP + Gate + commit). |

**Done when**: One Tier (`Tier 1–4`) and `<id>` are recorded in `.scratch/<feature>/<id>-libra.md` (if needed).

### 3. Route Clarifications (Optional)
1. If requirements are unclear in `Tier 2` or `Tier 3`, invoke IP Skill `grill-with-docs` (existing repo) or `grill-me` (new repo) before `ratio`.
2. If debugging an unclear failure, invoke IP Skill `diagnosing-bugs` first.
3. **Done when**: The next skill (`wayfinder`, `grill-with-docs`, `ratio`, or `faber`) is output clearly.

### 4. External Planning Bundle (Optional: `--external-plan`)
1. When the user wants an external model to draft or pre-design the plan, collect the relevant file paths from Step 1.
2. Invoke `codex` with `-Name "<id>-libra"` to package those files into `.scratch/<feature>/<id>-libra.Related-Code_Full_Dump.MD`.
3. **Done when**: The `codex` bundle link is returned ready for external planning.
