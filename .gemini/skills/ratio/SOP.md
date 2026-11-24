# Ratio SOP — Contract Planning

## Purpose
Produce a high-density contract `docs/specs/<feature>/<id>-<summary>-ratio.md` using the shared `Run ID` (`<id>`, e.g., `YYYYMMDD-<hash4>`), locking `Interfaces`, grounding APIs, and passing `plan-lint.ps1`.

## Steps

### 1. Align Spec & Architecture (Read-Only)
1. Reuse `<id>` from `libra` if present, or generate `<id>` (`YYYYMMDD-<hash4>`).
2. If requirements or domain terms are unsettled, invoke IP Skill `grill-with-docs` or `to-spec` first.
3. Query `codegraph` first, then `grep` to list every affected production, config, view, and test symbol (`path > Type > Method`). Mark new items `NEW`.
4. Check project architecture invariants (`AGENTS.md`, `docs/adr/`, `GLOSSARY.md`).
5. **Done when**: `<id>`, Blast Radius symbol list, and architecture constraints are collected.

### 2. On-Demand MCP Grounding
1. Check `agent.yaml` (`workflow.adversarial_review.mcp_grounding`: `off | on_demand | required`).
2. When `required` or (`on_demand` and external framework/SDK APIs change):
   - Query available doc MCPs (e.g., Microsoft Learn, Context7) up to 6 queries.
   - Record results in `docs/specs/<feature>/<id>-grounding.md` (`API | version | source | exists/differs/unverified | plan assumption`).
   - If MCP is unavailable, mark `unverified` and rely strictly on repo facts.
3. **Done when**: External APIs are grounded in `<id>-grounding.md` or skipped per config.

### 3. Draft Contract `<id>-<summary>-ratio.md`
Write `docs/specs/<feature>/<id>-<summary>-ratio.md` with YAML frontmatter (`run_id: <id>`, `feature`, `status: draft`, `round: 0`, `verdict: null`, `open_accepted_items: 0`) and these sections:
0. **`## 0. Requirement`**: Concise 1–2 sentence requirement statement (required by `plan-lint.ps1`).
1. **`## 1. Blast Radius Target`**: Exact symbol list from Step 1 (plus `Grounding: <id>-grounding.md` if created).
2. **`## 2. Out of Scope`**: Explicit exclusions for `censor` to dismiss out-of-scope attacks.
3. **`## 3. Interfaces (Consumes / Produces)`**: Exact method/API signatures, DTOs, and contracts so isolated `faber` agents never guess.
4. **`## 4. Test Seams & Review Focus`**:
   - Public test seams (what each seam catches and misses).
   - Top 3–5 implied failure modes pinned to concrete test names.
5. **`## 5. Step-by-Step Plan & Criteria`**: Ordered steps (for `Tier 2`, keep brief without full code transcripts; include Before/After diffs only for non-obvious changes).
6. **`## 6. Regression & Docs Sync`**: Required regression tests and doc paths matching `scripts/plan-lint.config.psd1`.

**Done when**: `<id>-<summary>-ratio.md` is saved and free of long background prose (move rationale to `<id>-rationale.md` if needed).

### 4. Run `plan-lint` Gate
1. Run `pwsh -NoProfile -File scripts/plan-lint.ps1 docs/specs/<feature>/<id>-<summary>-ratio.md`.
2. If `WARN [size]` appears, re-run with `-Slim`.
3. Fix all `ERROR` items from actual repo facts and re-run until `PASS`.
4. **Done when**: Verbatim `PASS` output from `plan-lint.ps1` is recorded.
