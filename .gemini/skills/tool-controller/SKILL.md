---
name: tool-controller
description: >-
  External integration controller checking CLI, API, and MCP environment and
  credential readiness, and emitting structured execution logs for verification.
---

# Tool Controller

Verify CLI, API, and MCP environment readiness before invocation and emit structured `Execution Log` records for `verify-controller`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Always run pre-flight environment and credential checks before calling external tools.
- Halt and return to `WFN` on missing tools, expired auth, or failed checks (`Honest Boundary`).
- Emit structured `Execution Log` output for every invocation so `verify-controller` can verify post-conditions.
