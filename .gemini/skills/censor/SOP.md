# Censor SOP — Independent Judicial Verdict

## Purpose
Evaluate every finding in `<id>-criticus-r<N>.md` against real source code and record remedies in `<id>-censo-r<N>.md` and `<id>-<summary>-ratio.md`.

## Steps

### 1. Verify Independence
1. Confirm this context did **not** author `<ratio-file>.md` (or run `--apply` on an external `<id>-censo-r<N>.md`).
2. If inherited and no fresh subagent is available, stop and ask the user to open a new window.
3. **Done when**: `context=fresh` (internal or external) is confirmed.

### 2. Judge Findings (Internal Mode) or Validate (`--apply` Mode)
- **Internal mode**:
  1. Read `<ratio-file>.md`, `<id>-criticus-r<N>.md`, and actual source files at every cited `path:line`.
  2. Classify each finding: `Accept (Blocker | Major | Minor)` or `Dismiss (Type a: false fact / Type b: out-of-scope / Type c: over-engineering)`.
  3. Steelman the ratio contract before accepting any Blocker or Major.
  4. If >= 6 findings and 0 dismissals, add `Weakest-3: <ID>, <ID>, <ID> - <reason>` in Section 1.
  5. Number accepted items `[Remedy N.k]` (no leading zeros, e.g., `1.1`, `1.10`).
  6. Save to `docs/specs/<feature>/<id>-censo-r<N>.md` with line 2: `Judge: model=<id> context=fresh via=internal`.
- **External `--apply` mode**:
  1. Verify `Judge:` header (`via=external`) and 100% ID match with `<id>-criticus-r<N>.md` (stop if mismatched; never edit the judge's text).
- **Done when**: `<id>-censo-r<N>.md` exists and passes `-Gate cite`.

### 3. Reconcile `<ratio-file>.md` & Commit
1. Back up `<ratio-file>.md` to `docs/specs/<feature>/<ratio-file>.r<N>-reviewed.md`.
2. Apply accepted remedies into `<ratio-file>.md` (Blocker -> Major -> Minor) and tag each with `(Remedy N.k)`.
3. Update `<ratio-file>.md` frontmatter: `status: ar-done`, `round: <N>`, `verdict: docs/specs/<feature>/<id>-censo-r<N>.md`, `open_accepted_items: <computed count>`.
4. Run `pwsh -NoProfile -File scripts/plan-lint.ps1 docs/specs/<feature>/<ratio-file>.md` until `0` `[state]`/`[verdict-cite]` errors.
5. Commit `docs/specs/<feature>/` (`docs(spec): AR round N verdict and remedies`).
6. If any **Blocker** was accepted or core `Interfaces` changed, route to `criticus` for **Round 2** (unless human adds `ar_waiver`).
7. **Done when**: Spec directory is committed and next step (`criticus` Round 2 or `sectio`) is stated.
