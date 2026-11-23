# Self-Evolving Workflow

A human-in-the-loop workflow system that guides next steps, enforces gates, and evolves its own skills and SOPs over time.

## Language

**WFN**:
The runtime workflow navigator that reads project state and recommends the next skill or gate.
_Avoid_: Router, orchestrator, WFB

**WFB**:
The workflow builder that creates and iteratively updates non-IP workflow skills and their SOPs.
_Avoid_: WFN, skill editor

**SOP**:
The step-by-step control document (`SOP.md`) inside a skill folder that defines flow steps, gates, and completion criteria.
_Avoid_: Prompt, guideline

**IP Skill**:
An external or pre-existing intellectual-property skill (such as `grill-with-docs`, `to-spec`, `to-tickets`, `implement-spec`, `tdd`, `code-review`, `retro`, `pr`, `diagnosing-bugs`, `codebase-design`, `wayfinder`) that is invoked by reference and never copied or modified.
_Avoid_: Custom skill, wrapped skill

## Flow Tiers

**Tier 1**:
A single-line flow for small, single-file fixes with no subagents or adversarial review.
_Avoid_: Lite S, quick fix

**Tier 2**:
A gated standard flow for medium multi-file changes using mechanical gates and a single-pass `code-review`, without adversarial review.
_Avoid_: Lite M, standard flow

**Tier 3**:
A full Generator-Critic plus slice-coding flow for high-risk or P0 changes, using `criticus`, `censor`, `sectio`, `faber` (`implement-spec`), and a review loop.
_Avoid_: MAP, full flow

**Tier 4**:
An oversized or unclear scope that must be rejected before coding and split into smaller Tier 2 or Tier 3 plans.
_Avoid_: Mega feature, big bang

## Artifacts & Gates

**Run ID**:
A shared short identifier (`<id>`, such as `YYYYMMDD-<hash4>`) generated once per feature run and prefixed to every skill's output file (`<id>-<skill>.md`).
_Avoid_: Session ID, random suffix

**Gate**:
A deterministic script check that decides pass or fail without agent self-rating.
_Avoid_: Checklist, manual check

**Slice**:
A bounded vertical unit of work (at most 3 production files and 150 lines) with its own tests and doc sync.
_Avoid_: Ticket, subtask

**Remedy**:
A numbered fix item (`[Remedy N.k]`) from `<id>-censo-r<N>.md` that must be traced into `<id>-<summary>-ratio.md`.
_Avoid_: Action item, review comment

**Disposition**:
A required row in `<id>-custos-r<N>.md` recording whether each finding is `fixed`, `deferred`, or `rejected` with evidence.
_Avoid_: Review summary

**Known-Open**:
The shared cross-feature list (`docs/specs/known-open.md`) tracking deferred findings and retro action items.
_Avoid_: Tech debt list, backlog
