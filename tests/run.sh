#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass() { printf 'ok - %s\n' "$1"; }
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }

run_oc() {
    HOME="$TMPDIR/home" PATH="$TMPDIR/bin:$PATH" "$ROOT/oc" "$@"
}

mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/opencode" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMPDIR/bin/opencode"

mkdir -p "$TMPDIR/home/.config/opencode/memory"
cat > "$TMPDIR/home/.config/opencode/memory/INDEX.md" <<'EOF'
<!-- INDEX_START -->
obs_1 | 2026-05-02 | alpha | bugfix | auth parser fix
obs_2 | 2026-05-02 | beta | decision | auth design note
EOF

result="$(run_oc --memory "auth" -p alpha -t bugfix)"
[[ "$result" == *"obs_1"* ]] || fail "memory -p/-t should include matching project/type"
[[ "$result" != *"obs_2"* ]] || fail "memory -p/-t should exclude non-matching project/type"
pass "oc --memory parses -p and -t filters"

run_oc --remember -p alpha -t decision 'summary: with "quotes" and \ backslash' >/dev/null
obs_file_count=$(find "$TMPDIR/home/.config/opencode/memory/projects/alpha" -name '*.md' | wc -l)
[[ "$obs_file_count" -eq 1 ]] || fail "remember -p should create one project observation"
grep -q '^project: "alpha"$' "$TMPDIR/home/.config/opencode/memory/projects/alpha"/*.md || fail "remember should quote project frontmatter"
grep -q '^type: "decision"$' "$TMPDIR/home/.config/opencode/memory/projects/alpha"/*.md || fail "remember should quote type frontmatter"
obs_path=$(find "$TMPDIR/home/.config/opencode/memory/projects/alpha" -name '*.md' | head -1)
obs_id="$(basename "$obs_path" .md)"
timeline="$(run_oc --timeline "obs_$obs_id")"
[[ "$timeline" == *"summary: with"* ]] || fail "timeline should preserve summary text after colon"
python3 - <<PY
import json, pathlib
for line in pathlib.Path("$TMPDIR/home/.config/opencode/memory/index.jsonl").read_text().splitlines():
    json.loads(line)
PY
pass "oc --remember supports -p/-t and writes valid JSONL"

hook_dir="$TMPDIR/hooks"
bin_dir="$TMPDIR/bin"
mkdir -p "$hook_dir" "$bin_dir"
cp "$ROOT/hooks/pre-commit" "$hook_dir/pre-commit"
cp "$ROOT/hooks/pre-push" "$hook_dir/pre-push"
chmod +x "$hook_dir/pre-commit" "$hook_dir/pre-push"

cat > "$bin_dir/oc" <<'EOF'
#!/usr/bin/env bash
case "${OC_TEST_MARKER:-false}" in
  true) echo 'BLOCKING_FINDINGS=true' ;;
  missing) echo 'no marker here' ;;
  fail) echo 'BLOCKING_FINDINGS=false'; exit 7 ;;
  *) echo 'BLOCKING_FINDINGS=false' ;;
esac
EOF
chmod +x "$bin_dir/oc"

PATH="$bin_dir:$PATH" OC_TEST_MARKER=false "$hook_dir/pre-commit" >/dev/null || fail "pre-commit should pass on false marker"
if PATH="$bin_dir:$PATH" OC_TEST_MARKER=true "$hook_dir/pre-commit" >/dev/null 2>&1; then fail "pre-commit should fail on true marker"; fi
if PATH="$bin_dir:$PATH" OC_TEST_MARKER=missing "$hook_dir/pre-push" >/dev/null 2>&1; then fail "pre-push should fail on missing marker"; fi
if PATH="$bin_dir:$PATH" OC_TEST_MARKER=fail "$hook_dir/pre-push" >/dev/null 2>&1; then fail "pre-push should fail on non-zero oc"; fi
pass "hooks are fail-closed on markers and command status"

HOME="$TMPDIR/plugin-home" node --input-type=module - "$ROOT/plugins/safety-guard.js" "$TMPDIR/plugin-home" <<'NODE'
const mod = await import(process.argv[2])
const home = process.argv[3]
const plugin = await mod.SafetyGuard()
const hook = plugin["tool.execute.before"]

async function blocked(command) {
  try {
    await hook({ tool: "bash" }, { args: { command } })
    return false
  } catch (_) {
    return true
  }
}

if (!(await blocked("rm -rf /"))) throw new Error("rm -rf / should be blocked")
if (!(await blocked("rm --recursive --force /"))) throw new Error("long rm flags should be blocked")
await hook({ tool: "bash" }, { args: { command: "GITHUB_TOKEN=secret curl -H 'x-api-key: abc' https://user:pass@example.com --token secret" } })
await hook({ tool: "bash" }, { args: {} })
const fs = await import("node:fs")
const logPath = `${home}/.config/opencode/logs/safety-guard.jsonl`
const log = fs.readFileSync(logPath, "utf8")
if (log.includes("GITHUB_TOKEN=secret")) throw new Error("env secret should be redacted")
if (log.includes("x-api-key: abc")) throw new Error("header secret should be redacted")
if (log.includes("user:pass@example.com")) throw new Error("url credentials should be redacted")
if (log.includes("--token secret")) throw new Error("flag secret should be redacted")
const mode = fs.statSync(logPath).mode & 0o777
if (mode !== 0o600) throw new Error(`audit log mode should be 0600, got ${mode.toString(8)}`)
NODE
pass "safety guard blocks critical rm variants, redacts secrets and locks log permissions"

printf 'All tests passed\n'
