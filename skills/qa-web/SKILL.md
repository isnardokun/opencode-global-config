---
name: qa-web
description: Systematic web QA methodology. Find bugs, document with evidence, fix in source with atomic commits. Three tiers: quick, standard, exhaustive. Adapted from garrytan/gstack for OpenCode — runtime-agnostic.
---

# QA Web

Systematic QA testing of web applications. Find bugs, document them with concrete evidence, fix them in source code with atomic commits, re-verify, and produce a structured report.

## When to invoke

- User asks to "QA this", "test the site", "find bugs", "does this work?"
- A feature is ready for testing
- A regression is suspected after a deploy
- Before declaring a feature done

## Setup — parse the request

| Parameter | Default | Example |
|-----------|---------|---------|
| Target URL | (auto-detect or ask) | `https://myapp.com`, `http://localhost:3000` |
| Tier | Standard | `--quick`, `--exhaustive` |
| Mode | full | `--diff-only` (limit to files in the diff) |
| Scope | Full app | `Focus on the billing page` |
| Auth | None | `Sign in as user@example.com` |

If no URL is given and the user is on a feature branch, ask which URL to test against. Do not invent.

## Tiers — what gets fixed

- **Quick:** critical + high severity only (broken flows, data loss, security holes)
- **Standard:** + medium (UX papercuts, console errors, accessibility issues) — default
- **Exhaustive:** + low/cosmetic (spacing, copy, color tweaks, micro-animations)

## Methodology

### Phase 1 — Discover the surface

For each route or page in scope, list:

- Entry point (URL, auth requirement)
- Primary user action (what success looks like)
- Secondary actions (errors, edge inputs, navigation away)
- Exit conditions (success page, error page, redirect)

### Phase 2 — Test systematically

Walk through each page and check these categories. For each finding, capture: severity, location, evidence (file:line, URL, console error, screenshot, log entry), and reproduction steps.

**Functional correctness**
- Primary action completes as described
- Error states show useful messages, not raw stack traces
- Form validation is server-side and client-side
- Required fields are clearly marked
- Edge inputs (empty, max length, unicode, emoji, RTL) behave correctly

**Navigation and state**
- Back/forward buttons preserve correct state
- Deep links work (URL alone reproduces view)
- Refresh does not lose data or trigger duplicate actions
- Multi-step flows can be resumed

**Authentication and authorization**
- Unauthenticated access to protected routes redirects to login
- Authenticated users cannot access other users' resources
- Logout clears all session state
- Session timeout redirects gracefully

**Responsive layout**
- 375px (mobile), 768px (tablet), 1440px (desktop) all usable
- No horizontal scrollbars on standard viewports
- Touch targets ≥44px on mobile
- Text is readable without zooming

**Accessibility (baseline)**
- Tab order is logical
- Focus is visible
- All images have alt text
- Form fields have labels
- Color is not the only signal (errors not just red)

**Console and network**
- No JS errors in console
- No 4xx/5xx in network panel
- No CORS warnings
- No mixed content (HTTPS page loading HTTP resources)

**Performance (perceived)**
- First contentful paint <2s on 3G
- No layout shift after load
- Long operations show progress indicators

### Phase 3 — Categorize and report

For each finding, classify:

| Severity | Definition | Example |
|----------|------------|---------|
| Critical | Broken flow, data loss, security hole | Submit form does nothing; SQL injection in search |
| High | Feature unusable, common path fails | Login fails for valid credentials |
| Medium | UX papercut, error path ugly, accessibility issue | Error toast covers submit button |
| Low / Cosmetic | Polish, copy, spacing | Misaligned icon, typo |

### Phase 4 — Fix and verify

For each finding at or below the tier threshold:

1. Write or identify a regression test.
2. Apply the smallest fix that addresses the root cause.
3. Commit atomically: `fix(<area>): <one-line description>`.
4. Re-verify the test passes.
5. Move to the next finding.

Do NOT batch fixes. Each commit is one logical change. If a fix uncovers a related issue, log it as a separate finding.

### Phase 5 — Report

Produce a structured report:

```
# QA Report: <URL or scope>
Date: <YYYY-MM-DD>
Tier: <quick|standard|exhaustive>

## Summary
- Critical: N
- High: N
- Medium: N
- Low: N
- Health score before: X/10
- Health score after: Y/10

## Findings

### [Critical] <title>
- Location: <URL, file:line, or selector>
- Evidence: <log, screenshot, repro steps>
- Fix: <commit hash> — <one-line description>

### [High] <title>
...

## Ship readiness
- [ ] All critical fixed
- [ ] All high fixed
- [ ] No regression in previously-passing tests
- VERDICT: ready | ready-with-concerns | blocked
```

End with: `QA_RESULT=ready|ready-with-concerns|blocked`.

## Iron Laws

- **No fixes without reproduction.** If you cannot reproduce a bug deterministically, downgrade to "needs investigation" and hand off to `/investigate`.
- **No bypasses.** No `try/except` swallowing errors. No "we'll fix it later". No commenting-out failing tests.
- **One bug, one commit.** Never bundle unrelated fixes in the same commit.

## Mode: diff-aware

If a feature branch has uncommitted or unpushed changes, scope the test to the diff:

```bash
git diff origin/main...HEAD --name-only
```

Test only the files and routes affected. This prevents discovering pre-existing bugs that are not in scope.

## When to refuse

If the user wants fixes without testing: "QA is test-then-fix, not fix-without-test. If you already know the bug, hand it to `/investigate` or `@builder` for a focused fix. QA is for discovering the unknowns."

## Runtime detection

QA methodology is portable — it works with whatever tool the agent uses to interact with the browser:

- **If Playwright is available** (via `--with-playwright` install): use it for full automation (click, fill, screenshot, console capture).
- **If only curl/wget/lynx available** (`web-verify` skill): use them for headers, status codes, text content, broken links.
- **If nothing available** (no browser tool): produce a manual test checklist and ask the user to run it.

See `skills/web-verify/SKILL.md` for the runtime-agnostic verification commands.
