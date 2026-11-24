---
status: accepted
---

# WFN Above Controllers and Retro-Gated Stage AUTO Switch

`WFN` sits above the 8 `*-controller` skills as the user-facing runtime launcher and UI that communicates with the user and decides when to trigger each controller, while `flow-controller` handles the internal state machine, Tier determination, and stage transitions. Stage AUTO Switch is never enabled autonomously by `flow-controller`; instead, `WFB` proposes AUTO Switch for a proven flow based on `retro` evidence, and only the user can approve enabling it.

## Considered Options

- **Let `flow-controller` absorb `WFN` and auto-switch on any passing Gate**: Rejected because mixing user-facing UI/intent routing with internal state-machine execution blurs human-in-the-loop control, and unvetted auto-switching risks silent drift.
- **Keep `WFN` as the top-level user interface and gate AUTO Switch through `WFB` + `retro` + user approval**: Chosen so humans retain explicit authority over both controller invocation and automation expansion.

## Consequences

- Any controller hitting a 3-attempt retry limit, Gate failure, or Honest Boundary blocker must halt and return structured blocker context to `WFN` for user decision.
- Inter-controller state handoffs remain file-driven via Run ID artifacts (`<id>-<skill>.md`), `state.md`, and `known-open.md`, rather than conversational memory.
