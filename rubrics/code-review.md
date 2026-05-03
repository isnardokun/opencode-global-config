# Code Review Rubric

Use this rubric for `@reviewer`, pre-commit review, and final delivery review.

## Blocking Criteria

- Runtime errors: broken imports, undefined names, syntax errors, missing files, or invalid config.
- Behavioral regressions: changed public behavior without explicit requirement or migration path.
- Data loss risk: destructive operations, unsafe migrations, or irreversible state changes without rollback.
- Security regressions: exposed secrets, unsafe command execution, injection paths, or weakened permissions.
- Test failure: existing required tests, lint, validation, or build commands fail.

## Required Evidence

- Cite findings with `file:line` whenever possible.
- Explain impact and a minimal remediation path.
- Separate verified findings from assumptions.
- If no blockers exist, state residual risks and untested areas.

## Output Shape

- Blocking findings.
- Important recommendations.
- Optional improvements.
- Final recommendation: approved or not approved.
