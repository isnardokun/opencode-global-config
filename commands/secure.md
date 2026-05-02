---
description: Security audit — find vulnerabilities without modifying code
---

Use @security-auditor.

Audit the current project for security vulnerabilities.

Check for:
- SQL injection and NoSQL injection
- XSS and CSRF vulnerabilities
- Hardcoded secrets, API keys, tokens
- Authentication and authorization flaws
- Insecure session management
- Missing input validation / sanitization
- Exposed sensitive data in logs or errors
- Dependency vulnerabilities (check package.json / requirements.txt / go.mod)
- Insecure HTTP endpoints (missing HTTPS, CORS misconfiguration)
- Privilege escalation paths

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW

Do NOT modify any files.
Do NOT execute commands other than read operations.
