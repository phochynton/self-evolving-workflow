# Tool Controller SOP — External Tool & Environment Readiness

## Purpose
Ensure CLI, API, and MCP dependencies and credentials are ready before external calls, and produce structured `Execution Log` records for `verify-controller`.

## Steps

### 1. Pre-Flight Environment & Credential Check
1. Identify required CLI binaries, API endpoints, or MCP servers for the task.
2. Verify availability and non-expired credentials without printing or leaking secrets.
3. If a required tool or credential is missing, halt immediately (Honest Boundary) and return structured blocker context to `WFN`.
4. **Done when**: Environment and credentials are confirmed ready, or blocker is returned to `WFN`.

### 2. Execute & Emit Structured Execution Log
1. Run the CLI/API/MCP action via sanctioned interfaces.
2. Record a structured `Execution Log` entry (`Run ID`, `Tool`, `Command/Endpoint`, `Exit Code`, `Key Output Summary`, `Timestamp`) in `.scratch/<feature>/<id>-tool-log.md`.
3. **Done when**: The invocation finishes and the `Execution Log` entry is written.

### 3. Hand Off to `verify-controller`
1. Pass the `Execution Log` pointer to `verify-controller` for post-condition verification and retry tracking (max 3 attempts).
2. **Done when**: `verify-controller` accepts or trips the circuit breaker back to `WFN`.
