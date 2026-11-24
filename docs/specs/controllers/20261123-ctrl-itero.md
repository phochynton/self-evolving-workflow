# 20261123-ctrl — Itero Retrospective & Evolution Proposals

- **Run ID**: `20261123-ctrl`
- **Commit**: `ca36f0a`
- **Metrics (`measure-tokens.ps1`)**: Unavailable in this remote devbox (`No transcript.jsonl found` under `$HOME/.gemini/antigravity/brain` or `$HOME/.gemini/jetski/brain/...`). Per `itero` Honest Boundary invariant, no token numbers are estimated.

## 1. Previous Action Items & Known-Open
- Previous retro action items: None (first `itero` run in this repo).
- `docs/specs/known-open.md`: Created in this run to track follow-up actions.

## 2. Retro Findings (Ordered by Severity)
1. **Automated checks — `ratio/SOP.md` missing `## 0. Requirement` (`plan-lint.ps1` failure)**:
   - `ratio/SOP.md` Step 3 lists sections `## 1`–`## 6`, omitting `Requirement`, causing `scripts/plan-lint.ps1` to fail with `ERROR [section] missing: requirement` on all 5 contracts until manually patched.
2. **Information access — `measure-tokens.ps1` in remote devbox**:
   - `itero/SOP.md` Step 1 assumes `transcript.jsonl` exists locally under `~/.gemini/antigravity/brain`, with no Honest Boundary branch when running in a remote devbox without local transcript logs.
3. **Navigation — Multi-repo skill discovery**:
   - Project-local `.gemini/skills/*` were invisible to `/` slash commands when CWD was `/home/antigravity` until manually symlinked to `~/.gemini/skills/`.

## 3. WFB Evolution Proposals (Pending User Approval)
1. **Target**: `.gemini/skills/ratio/SOP.md`
   - **Observed bug**: Step 3 omits `## 0. Requirement`, which `scripts/plan-lint.ps1` enforces as an `ERROR`.
   - **Proposed fix**: Add `## 0. Requirement` to `ratio/SOP.md` Step 3 section list.
2. **Target**: `.gemini/skills/itero/SOP.md` & `.gemini/skills/context-controller/SOP.md`
   - **Observed bug**: `measure-tokens.ps1` fails when `transcript.jsonl` is absent in remote devbox environments.
   - **Proposed fix**: Document an explicit `Honest Boundary` fallback when `transcript.jsonl` is unavailable (record `unavailable` instead of failing or estimating).
3. **Stage AUTO Switch Proposal**: None proposed this run (keep `WFB` diff-plan and `ADR-0001` human-approval gates active).
