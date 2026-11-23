---
name: codex
description: >-
  Packages a list of source files verbatim into {Name}.Related-Code_Full_Dump.MD
  via scripts/dump_related_code.ps1 for external planning (libra) or external review (criticus).
---

# Codex (Full-Code Bundle)

Bundle full source files into one Markdown file for external models without reading the output in this window.

Read and follow [SOP.md](SOP.md) in this directory.

## Invariants
- Never open, view, paste, or summarize the generated `.Related-Code_Full_Dump.MD` file.
- Use `scripts/dump_related_code.ps1` only; never paste source files manually.
- On script failure, fix the file list or path and re-run.
