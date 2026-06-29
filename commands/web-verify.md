---
description: Verify a URL works — runtime-agnostic (curl/wget/lynx/playwright)
---

Use the @web-verify skill.

Verify: $ARGUMENTS

Detect available tools and tier the verification:
- curl + wget only → status, headers, HTML body, broken links
- + lynx → text rendering, link traversal, document outline
- + playwright → screenshots, console errors, accessibility tree, click/fill
- all four → full multi-step interaction

Tier 1 commands (always work):
- `curl -sI URL` — status + headers
- `curl -sL URL | grep ...` — body checks
- broken link extraction with parallel HEAD checks

Tier 2 (if lynx):
- `lynx -dump URL` — text rendering
- `lynx -listonly -dump URL` — link list

Tier 3 (if playwright):
- `npx playwright screenshot URL /tmp/shot.png --full-page`
- Node script for full automation (see SKILL.md)

End with `WEB_VERIFY_RESULT=ok|degraded|failed`.

If Playwright is not installed, do NOT install it silently. Note that tier 3+ checks are unavailable and produce a degraded result. Offer to install via `bash install.sh --with-playwright` if the user wants full browser automation.
