# Code Controller SOP — Design, TDD, Review & Debugging

## Purpose
Route engineering quality tasks to the right IP Skill or Latin skill without duplicating their instructions, and hand execution verification to `verify-controller`.

## Steps

### 1. Select Engineering Strategy
Route by current need (zero-duplication dispatch):

| Engineering Need | Dispatched Skill(s) |
| :--- | :--- |
| Module interface / deepening / seam design | `codebase-design` (IP) |
| Test-first implementation | `tdd` (IP) or `faber` (with `implement-spec` IP) |
| Bug diagnosis / performance regression | `diagnosing-bugs` (IP) |
| Code quality & spec-compliance review | `code-review` (IP) |

**Done when**: Target skill is selected and dispatched with the active `Run ID` Ticket/contract.

### 2. Hand Off Execution Checks to `verify-controller`
1. After code or test edits, hand build, test, and code-lint verification to `verify-controller`.
2. If `verify-controller` returns a failure (attempts `< 3`), apply targeted diagnosis (`diagnosing-bugs` IP if needed) and fix.
3. If `verify-controller` trips the 3-attempt circuit breaker, stop and escalate via `WFN`.
4. **Done when**: `verify-controller` reports `PASS` (or `WFN` receives the circuit-breaker escalation).
