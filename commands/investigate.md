---
description: Systematic debugging with iron law — no fixes without root cause investigation first
---

Use the @investigate skill (or @oncall with the investigate methodology).

Investigate the bug: $ARGUMENTS

Follow the four phases:

1. **Investigate** — Collect symptoms, read the code, check recent changes (`git log --oneline -20 -- <files>`), reproduce the issue, search memory observations for prior investigations on the same files.
2. **Analyze** — Test the root cause hypothesis before implementing. What experiment would falsify it?
3. **Hypothesize alternatives** — List 1-2 alternative explanations, even after confirming one.
4. **Implement** — Write a failing test, apply the smallest fix that addresses the root cause, verify no regressions, document with `occo --remember -t bugfix`.

Iron law: NO FIXES WITHOUT ROOT CAUSE. No "try this and see", no "wrap in try/except for now".

Stop rule: if three fix attempts fail, STOP. Reassess the hypothesis. Go back to Phase 1. Do not try a fourth fix.

Report at the end:
- Symptom
- Root cause (specific, testable claim)
- Evidence (file:line, logs, reproduction)
- Fix applied
- Regression test
- Followups

End with `INVESTIGATE_RESULT=resolved|partial|blocked`.
