# Subagent Controller SOP — Dispatch Permissions & Handoff

## Purpose
Coordinate multi-agent execution by checking permissions, requiring `context-controller` Handoff compression, and verifying returned deliverables.

## Steps

### 1. Pre-Check Permissions & Handoff Bundle
1. Confirm the task requires a subagent and verify allowed roles/tools (read-only `research` vs write-capable `self`/specialized).
2. Request a compressed Handoff bundle from `context-controller` (`Run ID`, objective, file pointers, constraints, `Done when`).
3. If permissions are missing or scope is unclear, halt (Honest Boundary) and return to `WFN`.
4. **Done when**: Permissions are verified and the compressed Handoff bundle is attached.

### 2. Dispatch & Monitor
1. Select execution mode (`inherit` workspace, matching model tier) and invoke the subagent with the compressed Handoff bundle.
2. Wait reactively for completion without polling loops.
3. **Done when**: Subagent completes and returns its output artifact or message.

### 3. Accept Handoff
1. Verify the subagent output satisfies the Handoff `Done when` criteria and did not violate `ProtectedPaths` or scope.
2. If output is incomplete or errored, return structured blocker context to `WFN` (or trigger `verify-controller` if executable checks apply).
3. **Done when**: Deliverable is accepted into Run ID artifacts or escalated to `WFN`.
