---
name: Grill with Docs
description: Alignment session before building. Challenges plan against domain model, sharpens terminology, updates CONTEXT.md and ADRs.
triggers:
  - "grill this plan"
  - "challenge my approach"
  - "alignment session"
  - "/grill"
  - "use grill-with-docs"
---

# Grill with Docs — Pre-Mortem Alignment Session

## Purpose

Before writing code, align on what to build and how to talk about it. This is a questioning session that:

1. **Challenges assumptions** in the plan
2. **Sharpens project terminology** (jargon)
3. **Updates `CONTEXT.md`** with new language discovered
4. **Creates ADRs** for significant decisions

## When to Use

- Before starting a new feature
- When there's ambiguity about requirements
- When domain terminology is unclear
- After `oc ask bug-hunt` found issues — before fixing
- Any time you want to double-check understanding

## Session Flow

### Phase 1: Clarify the Goal (5 questions)

Ask the user:

1. **"What does success look like?"** — concrete outcome, not vague improvement
2. **"What's the simplest version that proves this works?"** — vertical slice
3. **"What could go wrong?"** — failure modes
4. **"What does this NOT solve?"** — scope boundaries
5. **"How will we know it's done?"** — acceptance criteria

### Phase 2: Map to Existing Code

```
- Does this contradict existing patterns in the codebase?
- Will this conflict with planned architecture?
- Are we using terms consistently with CONTEXT.md?
```

### Phase 3: Update Documentation

**If terminology discovered:**
- Update `CONTEXT.md` with new/clarified terms

**If decision made:**
- Create `docs/adr/NNN-short-description.md` with ADR format

**If scope changed:**
- Update `docs/TASKS.md`

### Phase 4: Summarize

End with:

```
UNDERSTOOD:
- Goal: <one line>
- Scope: <what's in, what's out>
- Next action: <first concrete step>

TERMINOLOGY:
- <term>: <definition from session>
```

## ADR Format

```markdown
# ADR NNN: <Title>

## Status
Accepted

## Context
What prompted this decision?

## Decision
What was decided?

## Consequences
What becomes easier? Harder?
```

## Example Session

```
YOU: I want to add user authentication.

AGENT:
1. What does success look like?
   - Users can sign up, login, logout
   - Sessions persist across browser closes
   - Admin can view user list

2. Simplest version?
   - Email/password only (no OAuth initially)
   - Session stored in HTTP-only cookie
   - No password reset (v2)

3. What could go wrong?
   - Users forget passwords
   - Session hijacking
   - Password storage security

4. What does this NOT solve?
   - OAuth (Google, GitHub logins)
   - Password reset flow
   - Email verification

5. How will we know it's done?
   - Unit tests for auth module
   - Integration test: signup → login → access protected route → logout

UNDERSTOOD:
- Goal: Email/password auth with sessions
- Scope: Signup/login/logout only, no OAuth
- Next action: Create auth module spec

TERMINOLOGY:
- materialization: when a user record becomes "real" in the system
```

## Integration with Docs-First

This skill complements Docs-First:
- Docs-First: Read existing docs to understand project
- Grill-with-Docs: Challenge and update those docs with new discoveries

Run `@architect` first to read docs, then this skill to challenge and refine.