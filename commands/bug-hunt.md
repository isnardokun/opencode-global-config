---
description: Multi-agent bug hunt — architect + security + planner + builder + reviewer
---

Use the bug-hunt workflow on the current project.

Execute in order:

**Phase 1 — @architect with project-map:**
Map the project. Identify high-risk areas, complex modules, untested code. List most likely bug locations.

**Phase 2 — @security-auditor:**
Look for security-related bugs: injection, auth bypass, race conditions, resource leaks. Do not fix yet.

**Phase 3 — @planner:**
Create a prioritized fix plan. Order bugs by severity. Define success criteria for each fix.

**Phase 4 — @builder with safe-implementation:**
Fix bugs according to the plan. One bug at a time. Write or update tests for each fix.

**Phase 5 — @reviewer:**
Review all fixes. Verify tests pass. Confirm no regressions introduced. Final approval.
