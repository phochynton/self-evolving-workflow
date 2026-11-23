# Custos SOP — Verification, Review Loop & Delivery

## Purpose
Verify code changes (`Tier 2` single-pass; `Tier 3` review loop), track every finding, and pass the final delivery Gate.

## Steps

### 1. Mechanical Pre-Review Gate
1. Run `pwsh -NoProfile -File scripts/ticket-gate.ps1 -Mode green -Ticket review-r<N> -Feature <slug> -Cmd "<test_cmd>" -BuildCmd "<build_cmd>" -Static <checks>`.
2. Fix any failures before starting review.
3. **Done when**: Mechanical Gate passes on `HEAD`.

### 2. Review Execution (`Tier 2` vs `Tier 3`)
- **Tier 2**: Invoke IP Skill `code-review` once against `HEAD_AT_START...HEAD`; fix Hard/Missing/Scope items and re-run Step 1.
- **Tier 3**: Run review loop (fixed point `HEAD_AT_MAP_START` in Round 1; fix diff only in Round 2+):
  1. Check `reviewer_mode` (`auto`: external if any Tier 3 Slice, else internal).
  2. Internal: invoke IP Skill `code-review` (with mechanical results, without developer prose). External: generate `.scratch/<feature>/<id>-custos-prompt-r<N>.md` and apply reply via `--apply-review`.
  3. Verify citations (`-Gate cite`) and write `docs/specs/<feature>/<id>-custos-r<N>.md` with `## Disposition` (`[Finding N.k] | Level | fixed/deferred/rejected | Ref`).
     - `Hard`, `Missing`, `Scope` must be `fixed` or `rejected` (with verified `path:line`).
     - `deferred` items must be added to `docs/specs/known-open.md` as `K-<n>`.
  4. If any item is `fixed`: fix via `faber` (`[review-rN]` commit), `grep` for the same pattern (**sweep**), and loop to Step 1 (up to `max_iterations`).

**Done when**: Latest review round has `0` `fixed` items and all findings have valid dispositions.

### 3. Final Delivery Gate
1. Run `pwsh -NoProfile -File scripts/ticket-gate.ps1 -Mode green -Ticket final ...`.
2. Generate `docs/specs/<feature>/<id>-custos-retro-input.md` (previous actions, open items, metrics stub) and commit.
3. Invoke IP Skill `pr` to draft the PR description.
4. Run `pwsh -NoProfile -File scripts/plan-lint.ps1 docs/specs/<feature>/<ratio-file>.md -Gate post -Base <HEAD_AT_MAP_START> -Deliver`.
5. **Done when**: `plan-lint.ps1 -Gate post -Deliver` passes and sets `status: delivered`.
