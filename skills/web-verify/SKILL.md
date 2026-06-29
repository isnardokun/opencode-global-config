---
name: web-verify
description: Runtime-agnostic web verification. Detects available tools (curl, wget, lynx, playwright) and uses the best one. Degraded mode: text-only HTTP checks. Full mode: browser automation with screenshots and console capture.
---

# Web Verify

Verify a URL works correctly using whatever tools are available on the host. Adapts from text-only HTTP checks to full browser automation depending on what's installed.

## When to invoke

- Before declaring a deploy successful
- After making a frontend change, to confirm it still renders
- To check if a URL is reachable, what status it returns, what content it serves
- To capture a screenshot of a running app
- To check console errors, network failures, accessibility tree

## Tool detection

Run this once at the start of a verification session:

```bash
echo "TOOL_CURL=$(command -v curl >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_WGET=$(command -v wget >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_LYNX=$(command -v lynx >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_PLAYWRIGHT=$(command -v playwright >/dev/null 2>&1 && echo yes || echo no)"
echo "TOOL_PW_CLI=$(npx --no-install playwright --version 2>/dev/null | head -1)"
```

Tier the verification by what is available:

| Tools | Tier | What you can do |
|-------|------|-----------------|
| curl + wget | 1 (HTTP only) | Status, headers, HTML body, broken links |
| + lynx | 2 (Text rendering) | Above + text-only render, link traversal |
| + playwright | 3 (Browser) | Above + click, fill, screenshot, console, accessibility tree |
| All four | 4 (Full QA) | Above + multi-step interaction, network capture, responsive viewport |

If nothing is available, install instructions: see "Optional install" below.

## Tier 1 — HTTP only (curl + wget)

### Status and headers

```bash
curl -sI URL                              # HEAD request, status + headers
curl -s -o /dev/null -w "%{http_code}\n" URL  # status code only
curl -sL URL | head -50                   # follow redirects, first 50 lines
```

### Check the response body

```bash
curl -sL URL | grep -E "title|<h1|<h2"    # extract structural headings
curl -sL URL | grep -c "404\|500"          # count error indicators
```

### Find broken links in a page

```bash
# Extract all hrefs, filter to internal, HEAD-check each
curl -sL URL \
  | grep -oE 'href="[^"]+"' \
  | sed 's/href="//;s/"$//' \
  | grep -E "^/" \
  | sort -u \
  | while read -r path; do
      code=$(curl -s -o /dev/null -w "%{http_code}" "URL$path")
      [ "$code" != "200" ] && echo "BROKEN ($code): URL$path"
    done
```

### Verify content presence

```bash
# Check that a specific string is in the response (e.g., expected headline)
curl -sL URL | grep -q "Expected Headline Text" && echo "OK" || echo "MISSING"

# Check that error page is NOT shown
curl -sL URL | grep -qi "stack trace\|null pointer" && echo "ERROR PAGE LEAKED" || echo "OK"
```

## Tier 2 — Text rendering (lynx)

```bash
# Dump the page as plain text (great for verifying copy, link text, structure)
lynx -dump URL

# List all links on the page
lynx -listonly -dump URL

# Save rendered text to a file for diff
lynx -dump URL > /tmp/page.txt
```

Use this when the agent needs to verify that:

- Copy renders correctly (no mojibake, no HTML entities leaking)
- Headings form a logical document outline
- All links are present and labeled
- The page is not blank or shows a fallback

## Tier 3 — Browser automation (playwright)

If Playwright is installed (via `install.sh --with-playwright` or `npx playwright install chromium`):

```bash
# Capture the accessibility tree (what screen readers see)
# Use a small Node script — see below
```

A minimal Node script for full automation:

```javascript
// save as /tmp/verify.mjs and run with: node /tmp/verify.mjs
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage();
const consoleErrors = [];
page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
page.on('pageerror', err => consoleErrors.push(String(err)));
page.on('response', res => { if (res.status() >= 400) console.log(`HTTP ${res.status()}: ${res.url()}`); });

await page.goto(process.argv[2]);
await page.screenshot({ path: '/tmp/screenshot.png', fullPage: true });
const title = await page.title();
const h1 = await page.locator('h1').first().textContent().catch(() => null);

console.log(JSON.stringify({ title, h1, consoleErrors }, null, 2));
await browser.close();
```

```bash
node /tmp/verify.mjs URL
```

## Tier 4 — Full multi-step interaction

For QA workflows that require clicking, filling forms, navigating, and verifying state across pages, use the Playwright script approach above with explicit step sequences. See `skills/qa-web/SKILL.md` for the methodology.

## What you cannot do without a browser

Without Playwright/Chromium installed, you cannot verify:

- JavaScript execution (client-side rendering, hydration)
- Visual layout (CSS, responsive design, fonts)
- Interactive elements (click handlers, form submission in single-page apps)
- Console errors and runtime exceptions
- Network panel (failed fetches, CORS, mixed content)

For these, fall back to producing a manual checklist for the user to run:

```
## Manual verification checklist for URL

1. Open URL in a browser.
2. Confirm the page renders without a blank screen.
3. Open DevTools console. Report any red errors.
4. Click the primary CTA. Confirm the expected next page.
5. Resize to 375px wide. Confirm no horizontal scroll.
6. Resize to 1440px wide. Confirm layout adapts.
7. Open DevTools Network tab. Refresh. Report any 4xx/5xx.
```

## Optional install (Playwright)

If the user wants browser automation:

```bash
# One-time: install Playwright + Chromium
npm install -g playwright
npx playwright install chromium
# Note: adds ~170 MB download for Chromium
```

Or via the opencode-global-config installer:

```bash
bash install.sh --with-playwright
```

The flag is **optional** and **non-default**. The base install remains zero-deps. Playwright is detected at runtime via `command -v playwright` and used if present, ignored if absent.

## Anti-patterns

- **Pretending a tier-1 check verifies JavaScript rendering.** It does not. Curl returns HTML; the page may be a hydration shell that shows nothing.
- **Confusing 200 status with "the page works".** A 200 can be served with a client-side error overlay.
- **Screenshots without baseline comparison.** A screenshot proves rendering, not correctness.
- **Skipping the degraded tier.** If Playwright fails mid-run, fall back to tier 1/2 — do not abort.

## Output

Always end a verification session with:

```
WEB_VERIFY_RESULT=ok|degraded|failed
```

- `ok` — full verification with browser, all checks pass.
- `degraded` — only tier 1/2 checks ran (no browser); note which categories could not be verified.
- `failed` — URL unreachable, status code indicates failure, or critical content missing.
