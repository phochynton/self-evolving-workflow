---
name: code-controller
description: >-
  Engineering quality controller governing module design depth, TDD, code
  review, and debugging strategy by dispatching IP Skills and Latin skills.
---

# Code Controller

Coordinate module design, TDD, code review, and debugging strategy while delegating execution verification and retries to `verify-controller`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Keep IP Skills external: dispatch `codebase-design`, `tdd`, `code-review`, `diagnosing-bugs`, and `implement-spec` by reference, never copy them.
- Never run unlimited test-fix loops on your own; hand build/test/lint checks and the 3-attempt circuit breaker to `verify-controller`.
- Escalate unresolved architectural or blocker issues to `WFN`.
