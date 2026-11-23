---
name: itero
description: >-
  Retrospective and evolution bridge. Runs measure-tokens.ps1, invokes IP Skill
  retro, updates known-open.md, and outputs structured proposals for wfb.
---

# Itero (Retro & Evolution Bridge)

Measure session metrics, run `retro` (IP Skill), and feed concrete workflow fixes to `wfb`.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Cite script numbers from `metrics.json` verbatim; never estimate token math.
- Track previous retro action items and `Known-Open` status explicitly.
- Route skill/SOP improvements to `wfb`; never edit IP Skills.
