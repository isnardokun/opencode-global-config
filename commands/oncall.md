---
description: Production incident response — diagnose, classify, mitigate
---

Use @oncall.

Diagnose the current production issue: $ARGUMENTS

Follow the Reversibility-Weighted Risk protocol:

1. **Collect information** — recent logs, metrics, error patterns, recent deployments
2. **Classify severity** — P1 (full outage) / P2 (degraded) / P3 (warning)
3. **Identify root cause** — or state what additional info is needed
4. **Propose mitigations** ordered by reversibility:
   - Reversible + low impact → can execute directly
   - Reversible + high impact → notify team first
   - Irreversible → do NOT execute, escalate
5. **Document** every action with expected and actual result
6. **Rollback plan** for any change made

Do NOT delete data. Do NOT run irreversible commands without explicit confirmation.
