---
name: sectio
description: >-
  Tier 3 architecture slicing. Runs plan-lint -Gate map, invokes IP Skill
  to-tickets, and adds ## MAP contracts with strict Slice size limits.
---

# Sectio (Architecture Slicing)

Break an approved `plan.md` into bounded vertical Slices before any coding starts.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Require `plan-lint.ps1 -Gate map` `PASS` (`fast-track=eligible`) before slicing.
- Invoke IP Skill `to-tickets`; keep each Slice <= 3 production files and <= 150 lines.
- Every Slice owns its tests and doc sync (no test-only or doc-only Slices).
