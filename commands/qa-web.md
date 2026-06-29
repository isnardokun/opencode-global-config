---
description: Systematic web QA — test, find bugs, fix atomically, verify
---

Use the @qa-web skill (or @builder + @reviewer following the qa-web methodology).

Run QA on: $ARGUMENTS

Parse the request for: target URL, tier (quick/standard/exhaustive), scope, auth requirements.

Apply the four phases:
1. **Discover** — list routes, primary actions, edge states
2. **Test** — walk through each page checking: functional correctness, navigation, auth/authz, responsive (375/768/1440px), accessibility baseline, console errors, network failures, perceived performance
3. **Categorize** — critical / high / medium / low with evidence
4. **Fix and verify** — atomic commits, regression tests, re-verify

If browser automation is available (Playwright via `install.sh --with-playwright`), use it. Otherwise use the `web-verify` skill for runtime-agnostic checks (curl/wget/lynx).

Iron laws:
- No fixes without reproduction
- No bypasses (try/except swallowing, commenting tests)
- One bug, one commit

End with `QA_RESULT=ready|ready-with-concerns|blocked`.

Do NOT skip testing and go straight to fixes. Do NOT bundle unrelated fixes.
