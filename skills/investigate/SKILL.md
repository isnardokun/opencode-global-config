---
name: investigate
description: Systematic debugging with the iron law: no fixes without root cause investigation first. Four phases: investigate, analyze, hypothesize, implement. Stop after three failed fixes. Adapted from garrytan/gstack for OpenCode.
---

# Investigate

Systematic debugging. The iron law is non-negotiable: **no fixes without root cause investigation first**. Fixing symptoms creates whack-a-mole debugging. Every fix that does not address the root cause makes the next bug harder to find.

## When to invoke

- User reports an error, 500, stack trace, or unexpected behavior
- User asks "why is this broken?", "debug this", "fix this bug", "investigate this error"
- A regression is suspected: "it was working yesterday"
- The diagnosis is unclear and the obvious fix has already been tried

## The four phases

### Phase 1 — Investigate

Gather context before forming any hypothesis.

1. **Collect symptoms.** Read the error message, stack trace, and reproduction steps. If context is missing, ask one question at a time.
2. **Read the code.** Trace the code path from the symptom back to potential causes. Use Grep to find all references, Read to understand the logic.
3. **Check recent changes:**
   ```bash
   git log --oneline -20 -- <affected-files>
   ```
   Was this working before? A regression means the root cause is in the diff.
4. **Reproduce.** Can the bug be triggered deterministically? If not, gather more evidence before forming a hypothesis.
5. **Check investigation history.** Search prior memory observations for the same files. Recurring bugs in the same area are an architectural smell.

Output: a **root cause hypothesis** — a specific, testable claim about what is wrong and why.

### Phase 2 — Analyze

Test the hypothesis before implementing any fix.

- What evidence supports it? What evidence contradicts it?
- What is the smallest experiment that would falsify it?
- If the hypothesis requires assuming the bug is in component X, run the experiment to confirm X is involved before fixing X.

Output: **confirmed root cause** (or revised hypothesis).

### Phase 3 — Hypothesize alternatives

Even after confirming one root cause, list 1-2 alternative explanations. Why?

- The confirmed hypothesis may be a proximate cause; the deeper cause is elsewhere.
- A second hypothesis may share the same fix and shorten the implementation.
- A second hypothesis may need a different fix and prove the first was wrong.

Output: ranked list of hypotheses with the chosen one at the top and the reason.

### Phase 4 — Implement

Only after the root cause is confirmed and the fix is scoped:

1. Write a failing test that reproduces the bug.
2. Apply the smallest fix that addresses the root cause (not the symptom).
3. Verify the test passes.
4. Verify no other tests regressed.
5. Document the root cause and fix in a memory observation (`occo --remember -t bugfix -p <project>`).

## Iron Law

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

This means:

- No "let me just try changing this and see if it works".
- No "I'll add a try/except around it for now".
- No "we'll investigate properly after the demo".

If the user pushes for a quick fix without investigation, say:

> "The iron law says no fixes without root cause. If I patch the symptom now, the next bug will be harder to find. Two paths: (1) I investigate properly first, or (2) you take ownership of the symptom-patch and its consequences. Which?"

## Stop after three failed fixes

If three fix attempts in a row fail to resolve the issue:

1. **STOP.** Do not try a fourth fix.
2. **Reassess the root cause hypothesis.** A failing fix usually means the hypothesis is wrong or incomplete.
3. **Go back to Phase 1.** Gather more context. Read more code. Check different log sources.
4. **Escalate if needed.** Surface the pattern: "Three fix attempts have failed, all variants of hypothesis X. Hypothesis X is likely wrong. Need fresh context or a second pair of eyes."

Three failed fixes on the same wrong hypothesis is a strong signal the diagnosis is incorrect, not that the fix is "almost there".

## Output format

When completing an investigation, report:

- **Symptom:** what the user observed.
- **Root cause:** the specific, testable claim.
- **Evidence:** file:line, log entries, reproduction steps.
- **Fix:** the minimal change applied.
- **Test:** the regression test that now passes.
- **Followups:** anything left open (related bugs, hardening, documentation gaps).

End with one of:

```
INVESTIGATE_RESULT=resolved|partial|blocked
```

- `resolved` — root cause confirmed, fix applied, test passing.
- `partial` — root cause confirmed, fix applied, but the underlying structural issue remains.
- `blocked` — three failed fixes, hypothesis likely wrong, needs fresh context.

## Anti-patterns

- **Cargo-cult debugging** — copying a fix from a similar but unrelated bug.
- **Cargo-cult fixes from Stack Overflow** — applying a fix without understanding the root cause.
- **Symptom patching** — wrapping an error in a try/except, logging it, moving on.
- **Drive-by refactors** — "while I'm here, let me also fix X" without explicit scope.
- **Skipping the regression test** — "I'll add the test later" (you will not).
