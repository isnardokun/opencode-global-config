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

## Detailed Checklist — Pass 1 (CRITICAL)

Run these categories first. Highest severity. Apply regardless of language/framework.

### SQL & Data Safety

- String interpolation in SQL (even with `.to_i`/`.to_f` cast). Use parameterized queries / prepared statements.
- TOCTOU races: check-then-set patterns that should be atomic (`WHERE` + `update_all`).
- Bypassing model validations for direct DB writes (raw `update_column`, `QuerySet.update()`, Prisma raw queries).
- N+1 queries: missing eager loading (`.includes()`, `joinedload()`, `include`) for associations used in loops/views.

### Race Conditions & Concurrency

- Read-check-write without uniqueness constraint or duplicate-key catch + retry.
- find-or-create without unique DB index — concurrent calls can create duplicates.
- Status transitions that don't use atomic `WHERE old_status = ? UPDATE SET new_status`.
- Unsafe HTML rendering on user-controlled data (XSS): `.html_safe`, `raw`, `dangerouslySetInnerHTML`, `v-html`, `mark_safe`.

### LLM Output Trust Boundary

- LLM-generated values (emails, URLs, names) written to DB or passed to mailers without format validation. Add lightweight guards (`EMAIL_REGEXP`, `URI.parse`, `.strip`) before persisting.
- Structured tool output (arrays, hashes) accepted without type/shape checks before database writes.
- LLM-generated URLs fetched without allowlist — SSRF risk if URL points to internal network.
- LLM output stored in knowledge bases or vector DBs without sanitization — stored prompt injection risk.

### Shell Injection

- `subprocess.run()` / `subprocess.call()` / `subprocess.Popen()` with `shell=True` AND f-string/`.format()` interpolation in the command string — use argument arrays instead.
- `os.system()` with variable interpolation — replace with `subprocess.run()` using argument arrays.
- `eval()` / `exec()` on LLM-generated code without sandboxing.
- `child_process.exec()` with interpolated strings — use `execFile()` / `spawn()` with argument arrays.

### Enum & Value Completeness

When the diff introduces a new enum value, status string, tier name, or type constant:

- **Trace it through every consumer.** Read (not just grep) each file that switches on, filters by, or displays that value. If any consumer does not handle the new value, flag it. Common miss: adding a value to the frontend dropdown but the backend model/compute method does not persist it.
- **Check allowlists / filter arrays.** Search for arrays or `%w[]` lists containing sibling values.
- **Check `case` / `if-elsif` chains.** If existing code branches on the enum, does the new value fall through to a wrong default?

## Detailed Checklist — Pass 2 (INFORMATIONAL)

Lower severity but still actioned. Run after Pass 1 passes.

### Async/Sync Mixing

- Synchronous `subprocess.run()`, `open()`, `requests.get()` inside `async def` endpoints — blocks the event loop. Use `asyncio.to_thread()`, `aiofiles`, or `httpx.AsyncClient`.
- `time.sleep()` inside async functions — use `asyncio.sleep()`.
- Sync DB calls in async context without `run_in_executor()` wrapping.

### Column/Field Name Safety

- Verify column names in ORM queries (`.select()`, `.eq()`, `.gte()`, `.order()`) against actual DB schema — wrong column names silently return empty results.
- Cross-reference with schema documentation when available.

### LLM Prompt Issues

- 0-indexed lists in prompts (LLMs reliably return 1-indexed).
- Prompt text listing available tools/capabilities that do not match what is actually wired up.
- Word/token limits stated in multiple places that could drift.

### Completeness Gaps

- Shortcut implementations where the complete version would cost <30 minutes to add.
- Features implemented at 80-90% when 100% is achievable with modest additional code.
- Test coverage gaps where adding the missing tests is a "lake" not an "ocean".

### Time Window Safety

- Date-key lookups that assume "today" covers 24h — report at 8am only sees midnight→8am under today's key.
- Mismatched time windows between related features.

### Type Coercion at Boundaries

- Values crossing Ruby→JSON→JS boundaries where type could change (numeric vs string).
- Hash/digest inputs that do not normalize types before serialization.

### Distribution & CI/CD

- CI/CD workflow changes: verify build tool versions match project requirements, artifact names/paths are correct, secrets use `${{ secrets.X }}` not hardcoded values.
- New artifact types: verify a publish/release workflow exists and targets correct platforms.
- Version tag format consistency: `v1.2.3` vs `1.2.3` — must match across VERSION file, git tags, and publish scripts.

## Fix-First Heuristic

- **AUTO-FIX (mechanical, no judgment):** dead code, unused variables, N+1 with obvious eager loading, stale comments, magic numbers → named constants, version/path mismatches.
- **ASK (judgment required):** security, race conditions, design decisions, large fixes (>20 lines), enum completeness, removing functionality, anything changing user-visible behavior.

Rule of thumb: if a senior engineer would apply the fix without discussion, it is AUTO-FIX. If reasonable engineers could disagree, it is ASK.

Critical findings default toward ASK. Informational findings default toward AUTO-FIX.
