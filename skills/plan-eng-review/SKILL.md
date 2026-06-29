---
name: plan-eng-review
description: Engineering-manager mode plan review. Forces forcing questions on data flow, edge cases, test matrix, failure modes, and security before implementation. Adapted from garrytan/gstack for OpenCode.
---

# Plan Engineering Review

Review an execution plan thoroughly before any code changes. Lock in architecture, data flow, diagrams, edge cases, test coverage, performance, and security.

## When to invoke

- User asks to "review the architecture", "engineering review", or "lock in the plan"
- A design doc or plan exists and implementation is about to start
- A non-trivial feature or refactor needs sign-off before code

## Engineering preferences (defaults)

Apply these when forming recommendations:

- **DRY matters** — flag repetition aggressively.
- **Well-tested code is non-negotiable** — bias toward too many tests, not too few.
- **Engineered enough** — neither under-engineered (fragile, hacky) nor over-engineered (premature abstraction).
- **Bias toward more edge cases**, not fewer. Thoughtfulness > speed.
- **Explicit over clever**.
- **Right-sized diff** — smallest diff that cleanly expresses the change, but never compress a necessary rewrite into a minimal patch. If the foundation is broken, say so.

## Cognitive patterns — how experienced engineering leads think

These are instincts developed over years, not checklist items. Apply them throughout the review.

1. **State diagnosis** — Teams exist in four states: falling behind, treading water, repaying debt, innovating. Each demands a different intervention.
2. **Blast radius instinct** — Every decision evaluated through "what's the worst case and how many systems/people does it affect?"
3. **Boring by default** — Innovation tokens are finite. Everything else should be proven technology.
4. **Incremental over revolutionary** — Strangler fig, not big bang. Canary, not global rollout. Refactor, not rewrite.
5. **Systems over heroes** — Design for tired humans at 3am, not your best engineer on their best day.
6. **Reversibility preference** — Feature flags, A/B tests, incremental rollouts. Make the cost of being wrong low.
7. **Failure is information** — Blameless postmortems, error budgets, chaos engineering. Incidents are learning opportunities.

## Forcing questions (apply to the plan under review)

Walk through these. Each is a STOP if the plan does not answer it concretely.

### 1. Data flow

- Where does the data come from? Who/what writes it?
- Where does it go? Who/what reads it?
- What transformations happen in between? At each boundary, who validates the shape?
- What is the data's lifecycle? When is it deleted or archived?
- Diagram it (ASCII or mermaid) if not already in the plan.

### 2. State machine

- What are the legal states?
- What are the legal transitions?
- Who triggers each transition?
- What happens on illegal transitions? (Reject, log, alert, ignore?)

### 3. Edge cases

- Empty input (zero records, empty string, null).
- Boundary values (max int, empty list, single item).
- Concurrent access (two writers, reader during write).
- Partial failure (network drops mid-operation, disk full).
- Time-related (DST, leap second, clock skew, timezone-naive comparisons).
- Encoding/escaping (UTF-8 boundaries, percent-encoding, JSON unicode escapes).
- Adversarial input (oversized payload, malformed JSON, SQL/command injection patterns).

### 4. Test matrix

For each feature in the plan, list:

- Happy path test (1)
- Error path test per failure mode (N)
- Edge case test per edge case from #3 (M)
- Integration test if the feature crosses a process or trust boundary

A "lake" is a small handful of tests missing for a feature. An "ocean" is the entire test suite for a feature. Plan should fill the lakes explicitly.

### 5. Failure modes

- What happens when the dependency is down?
- What happens when the dependency is slow?
- What happens when the dependency returns malformed data?
- What happens when the local disk is full?
- What happens when the network partition lasts longer than the timeout?
- For each: graceful degradation, retry strategy, user-facing message.

### 6. Security

- Authentication: who is the caller? How is identity verified?
- Authorization: what is the caller allowed to do? How is the check enforced (not just declared)?
- Input validation: what input crosses a trust boundary? What is the validation?
- Secret handling: are secrets read from env, not hardcoded? Are they logged?
- Rate limits: at what rate does this endpoint/operation get abused?
- OWASP Top 10 cross-check for the change at hand.

### 7. Performance

- What is the expected QPS / data volume?
- What is the latency budget?
- What is the algorithmic complexity (Big-O)?
- Are there N+1 queries or hot loops in the critical path?
- What is the cache strategy? Cache key? Invalidation?
- What is the observability story (metrics, logs, traces)?

### 8. Rollout and rollback

- How is this deployed? (feature flag, canary, blue-green, all-at-once)
- How is it rolled back if it breaks production?
- What is the blast radius if the deploy goes wrong?
- What is the monitoring for the first 24h post-deploy?

## Output format

For each section above, write:

- **Status:** covered / partial / missing
- **Evidence:** file:line, doc reference, or "needs to be added"
- **Recommendation:** concrete next step

End with a single line:

```
PLAN_REVIEW_RESULT=approve|revise|block
```

Use `approve` only if every forcing question has a concrete answer. `revise` if some answers are missing or weak. `block` if the plan is fundamentally unready for implementation (e.g., missing data model, no test strategy, unverified assumptions).

## Iron Law

**No implementation starts until PLAN_REVIEW_RESULT=approve.**

A plan with "we'll figure it out as we go" is `block`, not `approve`.
