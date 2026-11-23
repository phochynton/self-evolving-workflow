# initialis-WFB

A clean, public starter kit for a self-evolving, SOP-driven agent workflow.
It contains **no IP Skills** and **no repo-specific tools**. Use `wfb` to add and evolve your own skills.

## Included

- `.gemini/skills/wfn/` — Runtime workflow navigator (reads state and recommends next step)
- `.gemini/skills/wfb/` — Workflow builder (creates and iteratively updates skills and `SOP.md`)
- `.gemini/skills/codex/` — Full-code bundler (`scripts/dump_related_code.ps1`) for external planning or review
- `scripts/` — Generic PowerShell 7 Gate scripts (`plan-lint.ps1`, `ticket-gate.ps1`, `measure-tokens.ps1`, `dump_related_code.ps1`) and config templates
- `GLOSSARY.md` — Starter domain glossary in Simple English

## Quick Start

1. Copy `.gemini/`, `scripts/`, and `GLOSSARY.md` into your repository root.
2. Copy `scripts/agent.yaml.example` to `agent.yaml` and `scripts/plan-lint.config.psd1.example` to `scripts/plan-lint.config.psd1`, then customize for your project.
3. Invoke `wfb` to create your own skills (with `SKILL.md` <= 30 lines + `SOP.md`) or wire in external skills you already own.
4. Invoke `wfn` anytime to check project state and get the next recommended skill and Gate.
