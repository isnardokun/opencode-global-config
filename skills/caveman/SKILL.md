---
name: Caveman (Light)
description: Compressed communication mode. Reduces filler while keeping full technical accuracy. ~30% token savings.
triggers:
  - "use caveman mode"
  - "compress your communication"
  - "be more concise"
  - "less verbose"
  - "/caveman"
---

# Caveman (Light) — Compressed Communication Mode

## Purpose

Communicate more efficiently without losing technical precision. Light compression removes filler words and uses project jargon, saving ~30% tokens while staying readable.

## When to Use

- When responses are getting too long
- When repeating information already known
- Memory entries that should be concise
- Handoff documents
- Status updates

## Light Compression Rules

### DO: Remove Filler, Keep Structure

| Instead of | Use |
|------------|-----|
| "So, what we need to do here is..." | "Goal:" |
| "I think that maybe we should..." | "Option:" |
| "Let me check if I understand correctly..." | "Checking:" |
| "This is interesting because..." | (delete) |
| "As you can see from the code above..." | "Code shows:" |
| "The issue here is that..." | "Issue:" |
| "In order to fix this we need to..." | "Fix:" |
| "It seems like the problem might be..." | "Possible:" |

### DO: Use Project Terminology

- Replace verbose descriptions with established jargon from `CONTEXT.md`
- If `CONTEXT.md` defines "materialization cascade", use that instead of "when a lesson in a section becomes real"
- Use variable/function names from the codebase directly

### DO: Keep Essential Structure

```
ISSUE: <one line>
CAUSE: <one line>
FIX: <one line>
```

### DON'T: Over-Compress

- Don't remove "not", "no", negations — they change meaning
- Don't remove error messages, stack traces, or code
- Don't compress in debugging sessions (need full context)
- Don't compress when asking for clarification
- Technical terms stay — they're precise

## Examples

### Verbose (Before)
```
So, as we were discussing, the issue here seems to be that when we try to authenticate the user with the new OAuth flow, the token refresh mechanism doesn't properly handle the case where the refresh token has expired. I think we should probably look at the auth service first to understand what's happening there.

As you can see from the error above, it's failing at line 42 in the token refresh logic where we're trying to parse the new access token. Let me know what you think about this approach.
```

### Compressed (After)
```
ISSUE: OAuth token refresh fails when refresh token expired.
CAUSE: Auth service line 42 — new access token parsing error.
CHECK: auth service token refresh logic.
```

## Implementation

When this skill is active, the agent should:

1. **Scan response for filler** before sending
2. **Replace verbose phrases** with concise versions
3. **Use jargon** if `CONTEXT.md` or domain model defines it
4. **Keep technical precision** — accuracy over compression
5. **Preserve error messages and code** — never compress actual data

## Token Savings

Light mode target: **~30% reduction** while maintaining full comprehension.

If response feels too compressed: err on side of clarity. This is "efficient" not "cavernícola."