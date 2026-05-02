---
description: Review current git diff before commit
---

Use @reviewer with precommit-review skill.

Review the current staged and unstaged changes:

!`git status --short`
!`git diff --stat`
!`git diff`

Classify all findings as:

- **Blocker** — must fix before merge
- **High** — strongly recommended to fix
- **Medium** — should fix
- **Low** — optional improvement

Report:
- Files modified
- Tests present or missing
- Security concerns (secrets, injection, auth)
- Final recommendation: Approve / Fix required

Do NOT modify any files.
