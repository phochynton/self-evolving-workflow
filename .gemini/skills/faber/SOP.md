# Faber SOP — Tiered Coding Execution

## Purpose
Execute coding according to the assigned `Tier` (`Tier 1`, `Tier 2`, or `Tier 3`).

## Steps

### 1. Record Baseline (Tier 2 & Tier 3)
1. Run `pwsh -NoProfile -File scripts/ticket-gate.ps1 -Mode baseline -Feature <slug> -Cmd "<test_cmd>" -BuildCmd "<build_cmd>"`.
2. **Done when**: Baseline failures and build warning count are saved in `.scratch/<feature>/evidence/`.

### 2. Execute by Flow Tier
- **Tier 1 (Single-Line Flow)**:
  1. Write a 3-line brief (`.scratch/<feature>/<id>-faber-brief.md`: goal, target file, acceptance check).
  2. Read target code first, invoke IP Skill `tdd` (red -> minimal green), run test + build Gate, and commit.
- **Tier 2 (Gated Standard Flow)**:
  1. Read `<ratio-file>.md` (`Interfaces` + `Touches`), invoke IP Skill `tdd` with `ticket-gate.ps1` (`-Mode red` then `-Mode green`), update `Docs sync`, and commit.
  2. Hand off to `custos` for single-pass `code-review` (IP).
- **Tier 3 (Isolated Slice Flow via `implement-spec`)**:
  1. Invoke IP Skill **`implement-spec`** against `<ratio-file>.md` and the `sectio` tickets (`to-tickets` output), passing `GLOSSARY.md` and `ticket-gate.ps1` rules.
  2. Each `implement-spec` worker subagent runs in a fresh context: **Read first** (`read: path:line`) -> **Red** (`ticket-gate.ps1 -Mode red`, failing on `Red test` behavior) -> **Green** (`tdd` IP, minimal implementation) -> **Docs & Claims** -> **Gate** (`ticket-gate.ps1 -Mode green -Plan <ratio-file> -Lint scripts/plan-lint.ps1 -BuildCmd <build_cmd> -Static <checks>`) -> **Commit** (`<type>(<scope>): <msg> [NN]` via explicit `git add <paths>`).
  3. **Failure Ladder**: On `ESCALATE [attempts]` (2nd fail), spawn a fresh subagent one reasoning level higher with the failure log. On `STOP [attempts]` (3rd fail), halt for human `-ResetAttempts`.
  4. **Main-agent verification**: Check `git show --stat` and logs (never trust prose alone); append `- NN | <SHA> | tests=<count> | read: <path:line,...> | tests-changed: <list|none> | <note>` to `.scratch/<feature>/<id>-faber-state.md`.

**Done when**: All target code, tests, docs, and `[NN]` commits pass `ticket-gate.ps1 -Mode green`.
