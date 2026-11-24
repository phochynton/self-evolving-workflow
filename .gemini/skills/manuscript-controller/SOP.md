# Manuscript Controller SOP — Human-Facing Docs & Style Profiles

## Purpose
Draft reader-oriented documents (PR descriptions, user guides, READMEs) while dynamically applying an external personal writing-style profile (`ADR-0002`).

## Steps

### 1. Load External Writing-Style Profile
1. Request the user's external writing-style profile or preference pointer from `context-controller` (if configured).
2. If no external style profile exists, use clear, concise project defaults without inventing hidden rules.
3. **Done when**: Active style profile (or default) is loaded outside `SKILL.md`/`SOP.md`.

### 2. Draft Human-Facing Document
1. For Pull Request bodies, dispatch IP Skill `pr` by reference and apply the loaded style profile.
2. For user guides, release notes, or READMEs, draft concise reader-oriented prose grounded in verified repo facts.
3. Confirm no engineering contract Gates (`plan-lint`, `ticket-gate`, `GLOSSARY.md`, `docs/adr/`) are bypassed or altered here (`rule-controller`).
4. **Done when**: Document is drafted, styled, and ready for user review.
