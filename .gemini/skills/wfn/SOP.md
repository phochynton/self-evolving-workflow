# WFN SOP — User-Facing Launcher & UI

## Purpose
Serve as the single human-in-the-loop entry point above the 8 `*-controller` skills, `WFB`, and `itero`: communicate with the user, consult `flow-controller` for state, decide when to launch targets, and surface blockers.

## Steps

### 1. Align User Intent & Consult `flow-controller`
1. Read the user's request.
2. Invoke `flow-controller` to inspect file-driven state (`Run ID`, Tier, recommended stage, blockers).
3. **Done when**: User intent and `flow-controller` recommendation are known.

### 2. Launch Appropriate Target
Based on user intent and `flow-controller` recommendation, launch the matching target:

| Intent / Stage | Target to Launch |
| :--- | :--- |
| Multi-agent dispatch, permissions, handoff | `subagent-controller` |
| `AGENTS.md`, guardrails, Spec/Tickets/ADR/Glossary, `plan-lint`/`ticket-gate` | `rule-controller` |
| Context budget, Handoff compression, preferences, token report | `context-controller` |
| CLI / API / MCP readiness check and invocation | `tool-controller` |
| Build, test, code lint, log check, 3-retry circuit breaker, `custos` delivery | `verify-controller` |
| Module design, TDD, code review, debugging strategy | `code-controller` |
| Human-facing PRs, user guides, writing-style profile docs | `manuscript-controller` |
| Post-delivery retrospective (`retro` IP) | `itero` |
| Skill/SOP evolution & `retro`-gated Stage AUTO Switch proposals | `WFB` |

**Done when**: The target is launched (or confirmed with the user when human approval is required).

### 3. Handle Escalated Blockers & Output Status
1. Present any escalated blocker (3-attempt circuit breaker, Gate failure, or Honest Boundary) clearly and ask the user how to proceed.
2. Output a concise 4-line status block:
   - **Stage**: `<current stage & Tier>`
   - **Blockers**: `<dirty tree / circuit breaker / failing Gate / none>`
   - **Next Target**: `<controller, WFB, or itero>` (plus `@<artifact>` if applicable)
   - **Next Gate**: `<exact command or user decision required>`
3. **Done when**: The user has clear visibility and control over the next launch or blocker resolution.
