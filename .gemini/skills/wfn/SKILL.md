---
name: wfn
description: >-
  User-facing runtime launcher and UI above the 8 controllers. Communicates with
  the user, invokes flow-controller for state, and decides when to trigger controllers.
---

# WFN (Workflow Launcher & UI)

Act as the user-facing launcher above the 8 `*-controller` skills: align intent, launch controllers, and surface blockers.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Read-only UI/launcher: keep production code, skills, and SOPs untouched.
- Delegate state-machine and Tier calculation to `flow-controller` (`ADR-0001`).
- Keep IP Skills external: recommend by reference only.
