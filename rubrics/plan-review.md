# Plan Review Rubric

Use this rubric for `@planner`, design review, and implementation planning gates.

## Required Criteria

- Scope is explicit: what will change and what will not change.
- Assumptions are listed, especially around compatibility, persisted data, and external consumers.
- Phases are small, reversible, and independently verifiable.
- Each phase includes success criteria and concrete verification commands or checks.
- Risks, tradeoffs, and simpler alternatives are called out before implementation.

## Blocking Criteria

- The plan changes public behavior without migration or approval.
- The plan lacks objective verification for risky changes.
- The plan touches unrelated areas without a clear reason.
- The plan depends on unavailable tools, secrets, services, or manual-only validation.

## Output Shape

- Assumptions.
- Phased plan with verification per phase.
- Risks and tradeoffs.
- Open questions or approval gates.
