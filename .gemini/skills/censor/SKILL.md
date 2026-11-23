---
name: censor
description: >-
  Tier 3 Generator-Critic Phase 2. Independently judges <id>-criticus-rN.md in a fresh
  context (or applies external verdict), outputs <id>-censo-rN.md, and updates <id>-*-ratio.md.
---

# Censor (Independent Judge)

Issue an evidence-backed verdict (`<id>-censo-r<N>.md`) on `<id>-criticus-r<N>.md` in a fresh context and reconcile remedies into `<id>-<summary>-ratio.md`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Judge only in a **fresh context** (`context=fresh`) or via external verdict (`--apply`).
- Reconcile 100% of attack finding IDs; never drop or renumber IDs.
- Only a human may write `ar_waiver`; agents never waive Round 2 or gates.
