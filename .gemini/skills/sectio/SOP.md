# Sectio SOP — Architecture Slicing

## Purpose
Prepare bounded, self-contained vertical Slices in `.scratch/<feature>/issues/NN-slug.md` for `faber`.

## Steps

### 1. Entry Gate
1. Record `HEAD_AT_MAP_START` (`git rev-parse HEAD`).
2. Run `pwsh -NoProfile -File scripts/plan-lint.ps1 docs/specs/<feature>/<ratio-file>.md -Gate map` and paste output verbatim.
3. If `fast-track=blocked`, stop and report errors (do not bypass without human `ar_waiver`).
4. **Done when**: `plan-lint.ps1 -Gate map` outputs `fast-track=eligible` and working tree is clean.

### 2. Slice via IP Skill `to-tickets`
1. Invoke IP Skill `to-tickets` against `docs/specs/<feature>/<ratio-file>.md` to create `.scratch/<feature>/issues/<id>-sectio-NN-<slug>.md`.
2. Use `expand-contract` for wide refactors so every Slice stays <= 3 production files and <= 150 lines (only a human may add `Size-waiver: <reason>`).
3. **Done when**: Ordered vertical Slice files exist.

### 3. Add `## MAP` Contract Fields
Append a `## MAP` section to every Slice file with:
- `Tier`: `1 | 2 | 3`
- `Touches`: allowed production path prefixes (tests and docs excluded)
- `Red test`: specific test name expected to fail first (or `n/a - <reason>` for pure config/docs)
- `Tests-may-change`: optional list of existing tests allowed to change + why
- `Integration test`: required for `Tier 3` (real data source, no mock)
- `Attack case`: required for `Tier 3` (client-supplied protected field test, or `n/a - <reason>`)
- `Remedies`: `[Remedy N.k]` IDs claimed by this Slice
- `Docs sync`: doc paths to update in the same commit
- `Claims`: `doc path | claimed behavior | test name or path:line` (completed by `faber`)

Verify every `[Remedy N.k]` in the latest `<id>-censo-r<N>.md` is claimed by at least one Slice.
**Done when**: All Slices have complete `## MAP` fields, all Remedies are covered, and the task graph is ready for `faber` (`/implement-spec`).
