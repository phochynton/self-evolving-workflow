---
name: subagent-controller
description: >-
  Multi-agent coordinator enforcing subagent dispatch permissions, execution
  mode selection, and compressed task handoff acceptance.
---

# Subagent Controller

Verify dispatch permissions, launch subagents using compressed Handoff bundles, and validate returned results.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Require a compressed Handoff bundle from `context-controller` before every subagent dispatch.
- Enforce workspace and permission rules defined in [SOP.md](SOP.md).
- Halt and return structured blocker context to `WFN` if permissions or task scope are insufficient.
