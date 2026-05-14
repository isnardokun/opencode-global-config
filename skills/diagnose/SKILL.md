---
name: Diagnose
description: Disciplined debugging loop: reproduce → minimise → hypothesise → instrument → fix → regression test.
triggers:
  - "diagnose this"
  - "debug this issue"
  - "find the bug"
  - "investigate this"
  - "/diagnose"
---

# Diagnose — Disciplined Debugging Loop

## Purpose

Systematic debugging that avoids common pitfalls:
- Jumping to conclusions
- Fixing symptoms, not root cause
- Missing reproduction steps
- Regressions from incomplete fixes

## The Loop

Follow this sequence strictly. Don't skip ahead.

### Step 1: Reproduce

**Goal:** Confirm bug exists and understand when it happens.

Ask:
- "Can you show me the exact error?"
- "What inputs trigger this?"
- "Does it happen consistently or intermittently?"

**Output:**
```
REPRO:
- Command/input: <exact>
- Expected: <what should happen>
- Actual: <what happens instead>
- Frequency: <always/sometimes/once>
```

### Step 2: Minimise

**Goal:** Reduce to smallest reproducible case.

- Remove unrelated code
- Find minimal reproduction
- Strip external dependencies
- Isolate the failure point

**Output:**
```
MINIMISED CASE:
- File:line: <exact location>
- Relevant code: <3-5 lines max>
- Dependencies: <only what's needed>
```

### Step 3: Hypothesise

**Goal:** Form testable hypothesis about cause.

NOT "it's probably X" — instead:
- "If Y is true, then Z should also be true"
- "Removing Y should fix the issue"

**Output:**
```
HYPOTHESIS: <one sentence>
PREDICTION: <if hypothesis is correct, then...>
TEST: <how to verify>
```

### Step 4: Instrument

**Goal:** Add logging/breakpoints to test hypothesis.

- Add targeted logging at failure point
- Use print statements or debugger
- Never add logging everywhere — be surgical

**Output:**
```
INSTRUMENTED:
- Added: <what logging added>
- Expected output: <what should appear>
```

### Step 5: Fix

**Goal:** Apply minimal fix for root cause.

- Fix the cause, not the symptom
- One fix at a time
- If fix requires larger refactor, flag it but don't do it yet

**Output:**
```
FIX APPLIED:
- File:line: <where>
- Change: <what changed>
- Rationale: <why this fixes the root cause>
```

### Step 6: Regression Test

**Goal:** Confirm fix works and nothing else broke.

- Run same reproduction case — should pass now
- Run existing tests
- Check related functionality

**Output:**
```
REGRESSION:
- Original case: PASS/FAIL
- Existing tests: <X passed, Y failed>
- Related functionality: <status>
```

## Debugging Anti-Patterns

### DON'T

- Don't assume the fix is obvious — prove it
- Don't add logging everywhere — be surgical
- Don't fix multiple things at once
- Don't skip regression testing
- Don't ignore related failure modes

### DO

- Keep minimal reproduction case
- Write down what you tried and what happened
- Take breaks when stuck — fresh eyes help
- Use binary search for bisecting issues

## Integration with Docs-First

If `docs/` exists:
1. Check `docs/RISKS.md` for known issues
2. Check `docs/CHANGELOG.md` for recent changes that might have caused it
3. Update `docs/RISKS.md` with new findings if discovered

## Example Session

```
AGENT: Let me walk through the diagnose loop.

STEP 1 - REPRO:
You: POST /api/users returns 500 only when email contains +
Expected: 201 Created
Actual: 500 Internal Server Error
Frequency: Always

STEP 2 - MINIMISED:
- File: src/api/users.js:45
- Line: email.split('@')[0] — fails on "user+tag@gmail.com"

STEP 3 - HYPOTHESIS:
Hypothesis: Email with + is valid but our split assumes no + in local part.
Prediction: If we URL-decode before split, it should work.
Test: Check if req.body.email is URL-encoded

STEP 4 - INSTRUMENTED:
Added: console.log('email:', req.body.email)
Output: email: user+tag@gmail.com (not URL-encoded)

STEP 5 - FIX:
Change: Use email.split('@')[0].split('+')[0] instead of simple split
Rationale: Handles +tag portion before @

STEP 6 - REGRESSION:
- Original case: PASS
- Existing tests: 12/12 passed
- Related: signup form with test+user@domain.com works

ROOT CAUSE: Email parsing didn't handle plus-addressing format.
```

## When to Stop

If after 3 iterations no clear hypothesis:
1. Write up what you've tried in `docs/RISKS.md`
2. Ask for help or take a break
3. Document the known unknowns