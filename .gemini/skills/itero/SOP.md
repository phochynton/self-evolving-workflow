# Itero SOP — Retrospective & Evolution Bridge

## Purpose
Close the feedback loop after delivery by measuring token/cache facts, running `retro` (IP), and preparing evolution proposals for `wfb`.

## Steps

### 1. Measure Token & Cache Metrics
1. Run `pwsh -NoProfile -File scripts/measure-tokens.ps1 -Output docs/specs/<feature>/<id>-itero-metrics.json` (pass `-SubagentPaths` and `-Segment` when available).
2. Read `<id>-itero-metrics.json` and `docs/specs/<feature>/<id>-custos-retro-input.md`.
3. **Done when**: `<id>-itero-metrics.json` is generated and committed in `docs/specs/<feature>/`.

### 2. Run IP Skill `retro`
1. Invoke IP Skill `retro` with `<id>-custos-retro-input.md` and `<id>-itero-metrics.json`.
2. Report:
   - Status of previous retro action items (`done` / `open` / `dropped`)
   - Unresolved `Known-Open` items (`docs/specs/known-open.md`)
   - Exact cache hit rate, cache multiplier, warm input/turn, and cold-cache loss from `<id>-itero-metrics.json`
3. Record new follow-up actions in `docs/specs/known-open.md` (`action` type) and save summary to `docs/specs/<feature>/<id>-itero.md`.
4. **Done when**: `<id>-itero.md` is complete and `known-open.md` is updated.

### 3. Emit `wfb` Evolution Proposals
1. For any workflow or SOP bug discovered during the cycle, write a concise proposal:
   - **Target skill/SOP** (`wfn`, `wfb`, or one of the 8 Latin skills)
   - **Observed bug** (with evidence)
   - **Proposed SOP/Gate fix**
2. Hand off proposals to `wfb` for human-approved iteration.
3. **Done when**: Actionable `wfb` proposals (or "none") are delivered.
