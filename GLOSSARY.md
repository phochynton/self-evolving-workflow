# Self-Evolving Workflow

A human-in-the-loop workflow system that guides next steps, enforces gates, and evolves its own skills and SOPs over time.

## Language

**WFN**:
The user-facing runtime launcher and UI above the 8 controllers that communicates with the user and decides when to trigger each controller.
_Avoid_: Router, orchestrator, WFB, flow-controller

**WFB**:
The workflow builder that creates and iteratively updates non-IP workflow skills, SOPs, Gate scripts, and Stage AUTO Switch proposals from `retro`.
_Avoid_: WFN, skill editor, rule-controller

**SOP**:
The step-by-step control document (`SOP.md`) inside a skill folder that defines flow steps, gates, and completion criteria.
_Avoid_: Prompt, guideline

**Controller**:
A top-level coordinator skill (`.gemini/skills/<name>-controller/`) that routes, runs pre-checks, dispatches underlying Latin skills or IP Skills, and verifies output Gates.
_Avoid_: Orchestrator, manager, wrapper

**IP Skill**:
An external or pre-existing intellectual-property skill (such as `grill-with-docs`, `to-spec`, `to-tickets`, `implement-spec`, `tdd`, `code-review`, `retro`, `pr`, `diagnosing-bugs`, `codebase-design`, `wayfinder`) that is invoked by reference and never copied or modified.
_Avoid_: Custom skill, wrapped skill

## Controllers

**flow-controller**:
The workflow state machine that reads project state (`git`, `plan.md`, `state.md`, `known-open.md`), determines the Tier, recommends or advances stages, and executes user-approved Stage AUTO Switch.
_Avoid_: WFN, router

**subagent-controller**:
The multi-agent coordinator that enforces subagent dispatch permissions, selects execution modes, and accepts task handoffs.
_Avoid_: Context packer, WFN

**rule-controller**:
The governance controller that manages `AGENTS.md`, safety/permission guardrails, Honest Boundary, self-evolution rule proposals, and engineering contract artifacts (Spec, Tickets, ADR, Glossary, `plan-lint.ps1`, `ticket-gate.ps1`).
_Avoid_: WFB, manuscript-controller, verify-controller

**context-controller**:
The context and memory controller that manages Context Window budgets, Progressive Disclosure, Handoff compression, cross-task preferences, and token-waste measurement for `retro`.
_Avoid_: Subagent dispatcher

**tool-controller**:
The external integration controller that checks execution environment and credential readiness for CLI, API, and MCP tools and emits structured execution logs.
_Avoid_: Verify-controller

**verify-controller**:
The execution verification controller that runs builds, tests, code lints, and tool execution-log checks, enforcing a 3-attempt retry circuit breaker before returning blockers to `WFN`.
_Avoid_: Rule-controller, code-controller

**code-controller**:
The engineering quality controller that governs module design depth, TDD, code review, and debugging strategy by dispatching corresponding IP Skills or Latin skills.
_Avoid_: Verify-controller, implementer

**manuscript-controller**:
The human-facing documentation controller that produces reader-oriented documents (such as PR descriptions and user guides) with pluggable personal writing style profiles.
_Avoid_: Rule-controller, contract gate

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

**Ticket**:
A bounded vertical unit of work (at most 3 production files and 150 lines) with its own tests and doc sync.
_Avoid_: Slice, subtask

**Remedy**:
A numbered fix item (`[Remedy N.k]`) from `<id>-censo-r<N>.md` that must be traced into `<id>-<summary>-ratio.md`.
_Avoid_: Action item, review comment

**Disposition**:
A required row in `<id>-custos-r<N>.md` recording whether each finding is `fixed`, `deferred`, or `rejected` with evidence.
_Avoid_: Review summary

**Known-Open**:
The shared cross-feature list (`docs/specs/known-open.md`) tracking deferred findings and retro action items.
_Avoid_: Tech debt list, backlog

**Execution Log**:
A structured record emitted by `tool-controller` (`Run ID`, tool, command/endpoint, exit code, summary, timestamp) for `verify-controller` verification.
_Avoid_: Console output, raw trace

**Honest Boundary**:
The mandatory stop-and-report rule requiring any controller to halt and escalate to `WFN` when permissions, facts, or retries are exhausted.
_Avoid_: Silent fallback, best-effort guess

**Stage AUTO Switch**:
A user-approved flag in `state.md` (`auto_switch:`), proposed by `WFB` from `retro` evidence, allowing `flow-controller` to advance a proven stage transition automatically.
_Avoid_: Unattended auto-run
