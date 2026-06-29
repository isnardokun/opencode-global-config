---
description: Engineering-manager mode plan review — lock in architecture, data flow, edge cases, test matrix before implementation
---

Use the @plan-eng-review skill (or @planner with the plan-eng-review methodology).

Review the plan or design doc: $ARGUMENTS

Apply the forcing questions in order. Each is a STOP until the plan answers it concretely:

1. **Data flow** — Where does data come from, where does it go, what transformations, who validates at each boundary, what is the lifecycle?
2. **State machine** — Legal states, legal transitions, who triggers each, what happens on illegal transitions?
3. **Edge cases** — Empty input, boundary values, concurrent access, partial failure, time-related (DST, leap second, clock skew), encoding/escaping, adversarial input.
4. **Test matrix** — Happy path, error path per failure mode, edge case per edge case, integration if cross-trust-boundary.
5. **Failure modes** — Dependency down/slow/malformed, disk full, network partition longer than timeout. For each: graceful degradation, retry strategy, user message.
6. **Security** — Authn (who + verify), authz (what + enforce not just declare), input validation, secret handling, rate limits, OWASP Top 10 cross-check.
7. **Performance** — Expected QPS, latency budget, Big-O, N+1 / hot loops, cache strategy, observability.
8. **Rollout and rollback** — Deploy strategy, rollback procedure, blast radius, first-24h monitoring.

For each section output:
- **Status:** covered / partial / missing
- **Evidence:** file:line or "needs to be added"
- **Recommendation:** concrete next step

Engineering preferences: DRY matters, well-tested is non-negotiable, engineered enough (not under/over), bias toward more edge cases, explicit over clever, right-sized diff.

Iron law: NO implementation starts until the final line is `PLAN_REVIEW_RESULT=approve`. Use `revise` if some answers are weak. Use `block` if the plan is fundamentally unready.

Do NOT modify any files. This is a review, not an implementation.
