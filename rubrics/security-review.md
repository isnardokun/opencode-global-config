# Security Review Rubric

Use this rubric for `@security-auditor`, pre-push review, and release readiness checks.

## Blocking Criteria

- Secrets: API keys, tokens, private keys, credentials, or `.env` values committed or exposed in logs.
- Command execution: user-controlled input reaches shell execution without validation or quoting.
- Filesystem risk: broad deletes, writes outside expected directories, weak permissions, or unsafe symlinks.
- Network exposure: unsafe CORS, open admin ports, unauthenticated sensitive endpoints, or insecure defaults.
- Dependency risk: known critical vulnerabilities or unpinned installer/runtime dependencies in release paths.

## Required Evidence

- Cite `file:line` for each finding.
- Include severity: `critical`, `high`, `medium`, or `low`.
- Distinguish exploitable issues from hardening recommendations.
- Do not report speculative issues as confirmed findings.

## Output Shape

- Critical/high blockers.
- Medium/low findings.
- Remediation recommendations.
- Residual security risks.
