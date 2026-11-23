# Self-Evolving Workflow (Starter)

A human-in-the-loop workflow starter kit with no pre-installed IP Skills.

## Language

**WFN**:
The runtime workflow navigator that reads project state and recommends the next skill or Gate.
_Avoid_: Router, orchestrator, WFB

**WFB**:
The workflow builder that creates and iteratively updates skills and their SOPs.
_Avoid_: WFN, skill editor

**SOP**:
The step-by-step control document (`SOP.md`) inside a skill folder that defines flow steps, Gates, and completion criteria.
_Avoid_: Prompt, guideline

**Gate**:
A deterministic script check that decides pass or fail without agent self-rating.
_Avoid_: Checklist, manual check

**Run ID**:
A shared short identifier (`<id>`, such as `YYYYMMDD-<hash4>`) generated once per feature run and prefixed to every skill's output file (`<id>-<skill>.md`).
_Avoid_: Session ID, random suffix

**Flow Tier**:
Risk and size classification (`Tier 1` single-line, `Tier 2` gated standard, `Tier 3` full review + slices, `Tier 4` reject and split).
_Avoid_: Complexity level
