# Verify Controller SOP — Execution Verification, Delivery & Circuit Breaker

## Purpose
Verify code builds, unit/E2E tests, code lints, structured `Execution Log` outputs from `tool-controller`, and final `custos` delivery Gates, enforcing a 3-attempt retry circuit breaker.

## Steps

### 1. Run Execution Checks
1. Execute the target build, unit/integration/E2E tests, and code linters for the active Ticket.
2. When `tool-controller` executed an external CLI/API/MCP action, verify its structured `Execution Log` against expected exit codes and post-conditions.
3. **Done when**: Verbatim command outputs, exit codes, and log checks are captured.

### 2. Track Retry Loop & Trip Circuit Breaker
1. Track consecutive failures for the current check in `.scratch/<feature>/<id>-verify-state.md` (or active state file).
2. If checks fail and attempts `< 3`:
   - Return structured failure evidence to `code-controller` (for code/test fixes) or `tool-controller` (for tool/env fixes) to retry.
3. If checks fail on attempt `3` (or higher):
   - **Trip Circuit Breaker**: stop all retries immediately.
   - Write a structured blocker (`Stage`, `Run ID`, `Failed Check`, `Attempt: 3/3`, `Verbatim Error`) and return control to `WFN`.
4. **Done when**: Checks pass, or control is halted and handed back to `WFN`.

### 3. Gate Delivery (`custos`)
1. Once all Tickets pass execution checks, dispatch `custos` for final delivery Gate verification and `Disposition` closure.
2. Hand PR body drafting to `manuscript-controller` (`ADR-0002`).
3. **Done when**: `custos` passes and delivery is ready for `manuscript-controller` / `itero`.
