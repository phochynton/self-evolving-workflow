# Context Controller SOP — Budget, Handoff & Token Audit

## Purpose
Keep Context Window usage lean through Progressive Disclosure, compressed Handoff bundles, externalized cross-task preferences, and token-waste reporting for `retro`.

## Steps

### 1. Enforce Budget & Progressive Disclosure
1. Check current Context Window load and target task scope.
2. Load only minimal entry pointers first (`GLOSSARY.md`, active `<id>-*-ratio.md`, relevant ADR), deferring deep file reads until needed.
3. **Done when**: A lean load plan is set without exceeding budget.

### 2. Compress Handoff & Expose Preferences
1. Before `subagent-controller` dispatches a subagent (or across session handoffs), compress state into a concise Handoff bundle (`Run ID`, goal, file pointers, constraints, `Done when`).
2. When `manuscript-controller` or another controller requests user preferences (such as personal writing style), provide the external preference file/pointer without embedding it into skill SOPs.
3. **Done when**: Compressed Handoff bundle or preference pointer is ready.

### 3. Measure Token Waste for `retro`
1. Run `pwsh -NoProfile -File scripts/measure-tokens.ps1` at delivery/retro time; if `transcript.jsonl` is unavailable (e.g., remote devbox), record `unavailable` (`Honest Boundary`) without estimating numbers.
2. Identify high-waste steps (repeated reads, oversized dumps, retry loops) and write `<id>-token-audit.md` for `itero` (`retro`).
3. **Done when**: Token-waste report (or `unavailable` record) is handed to `itero` / `retro`.
