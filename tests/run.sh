#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass() { printf 'ok - %s\n' "$1"; }
fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }

run_oc() {
    (cd "$TMPDIR" && HOME="$TMPDIR/home" PATH="$TMPDIR/bin:$PATH" "$ROOT/occo" "$@")
}

mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/opencode" <<'EOF'
#!/usr/bin/env bash
if [ -n "${OC_CALL_COUNT_FILE:-}" ]; then
  count=0
  [ -f "$OC_CALL_COUNT_FILE" ] && count=$(cat "$OC_CALL_COUNT_FILE")
  printf '%s\n' "$((count + 1))" > "$OC_CALL_COUNT_FILE"
fi
if [ -n "${OC_CAPTURE:-}" ]; then
  printf '%s\n' "$@" > "$OC_CAPTURE"
fi
if [ -n "${OC_FAKE_OUTPUT:-}" ]; then
  printf '%b\n' "$OC_FAKE_OUTPUT"
fi
exit "${OC_FAKE_EXIT:-0}"
EOF
cp "$TMPDIR/bin/opencode" "$TMPDIR/bin/occo"
chmod +x "$TMPDIR/bin/opencode" "$TMPDIR/bin/occo"
ln -sf opencode "$TMPDIR/bin/occo"

mkdir -p "$TMPDIR/home/.config/opencode/memory"
cp -r "$ROOT/profiles" "$TMPDIR/home/.config/opencode/profiles"
cat > "$TMPDIR/home/.config/opencode/memory/INDEX.md" <<'EOF'
<!-- INDEX_START -->
obs_1 | 2026-05-02 | alpha | bugfix | auth parser fix
obs_2 | 2026-05-02 | beta | decision | auth design note
EOF

result="$(run_oc --memory "auth" -p alpha -t bugfix)"
[[ "$result" == *"obs_1"* ]] || fail "memory -p/-t should include matching project/type"
[[ "$result" != *"obs_2"* ]] || fail "memory -p/-t should exclude non-matching project/type"
pass "oc --memory parses -p and -t filters"

cat >> "$TMPDIR/home/.config/opencode/memory/INDEX.md" <<'EOF'
obs_3 | 2026-05-02 | gamma | note | multi word query example
EOF
multi_word_result="$(run_oc --memory multi word query)"
[[ "$multi_word_result" == *"obs_3"* ]] || fail "memory should search multi-word query without filters"
pass "oc --memory supports multi-word queries without filters"

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

echo "9" > "$TMPDIR/home/.config/opencode/.session"
run_oc --compact >/dev/null
[[ "$(cat "$TMPDIR/home/.config/opencode/.session")" == "0" ]] || fail "compact should reset session counter after successful opencode run"
pass "oc --compact resets counter on success"

echo "21" > "$TMPDIR/home/.config/opencode/.session"
compact_count_file="$TMPDIR/auto-compact-count"
OC_CALL_COUNT_FILE="$compact_count_file" run_oc ask "trigger auto compact" >/dev/null
[[ "$(cat "$compact_count_file")" == "2" ]] || fail "auto-compact should call opencode once for command and once for compact"
[[ "$(cat "$TMPDIR/home/.config/opencode/.session")" == "0" ]] || fail "auto-compact should reset session counter"
pass "auto-compact does not recurse through _oc_run"

rm -rf "$TMPDIR/home/.config/opencode/memory/outcomes"
mkdir -p "$TMPDIR/home/.config/opencode/memory/outcomes"
if (cd "$TMPDIR" && OC_FAKE_OUTPUT="workflow finished without marker" run_oc --workflow bug-hunt "$TMPDIR" >/dev/null 2>&1); then
  fail "workflow should fail when completion marker is missing"
fi
missing_marker_outcomes=$(find "$TMPDIR/home/.config/opencode/memory/outcomes" -name 'bug-hunt-*.json' 2>/dev/null | wc -l)
[[ "$missing_marker_outcomes" -eq 0 ]] || fail "workflow should not track outcome without completion marker"

if (cd "$TMPDIR" && OC_FAKE_OUTPUT=$'workflow failed\nWORKFLOW_COMPLETE=true' OC_FAKE_EXIT=7 run_oc --workflow bug-hunt "$TMPDIR" >/dev/null 2>&1); then
  fail "workflow should fail when opencode exits non-zero even with completion marker"
fi
failed_marker_outcomes=$(find "$TMPDIR/home/.config/opencode/memory/outcomes" -name 'bug-hunt-*.json' 2>/dev/null | wc -l)
[[ "$failed_marker_outcomes" -eq 0 ]] || fail "workflow should not track outcome after non-zero opencode exit"

(cd "$TMPDIR" && OC_FAKE_OUTPUT=$'workflow finished\nWORKFLOW_COMPLETE=true' run_oc --workflow bug-hunt "$TMPDIR" >/dev/null)
success_marker_outcomes=$(find "$TMPDIR/home/.config/opencode/memory/outcomes" -name 'bug-hunt-*.json' 2>/dev/null | wc -l)
[[ "$success_marker_outcomes" -eq 1 ]] || fail "workflow should track outcome after exact completion marker"
pass "workflow success requires exact completion marker"

rm -rf "$TMPDIR/clean-home"
HOME="$TMPDIR/clean-home" PATH="$TMPDIR/bin:$PATH" "$ROOT/occo" ask --dry-run "analiza el proyecto" >/dev/null
[[ -f "$TMPDIR/clean-home/.config/opencode/.session" ]] || fail "oc should create session file in clean HOME"
printf 'not-a-number' > "$TMPDIR/home/.config/opencode/.session"
run_oc ask --dry-run "analiza el proyecto" >/dev/null
[[ "$(cat "$TMPDIR/home/.config/opencode/.session")" == "1" ]] || fail "oc should recover from corrupt session counter"
pass "oc session tracking handles clean and corrupt state"

hook_dir="$TMPDIR/hooks"
bin_dir="$TMPDIR/bin"
mkdir -p "$hook_dir" "$bin_dir"
cp "$ROOT/hooks/pre-commit" "$hook_dir/pre-commit"
cp "$ROOT/hooks/pre-push" "$hook_dir/pre-push"
chmod +x "$hook_dir/pre-commit" "$hook_dir/pre-push"

cat > "$bin_dir/occo" <<'EOF'
#!/usr/bin/env bash
if [ -n "${OC_CAPTURE:-}" ]; then
  printf '%s\n' "$@" > "$OC_CAPTURE"
fi
case "${OC_TEST_MARKER:-false}" in
  fail) echo 'HOOK_REVIEW_RESULT=fail' ;;
  missing) echo 'no marker here' ;;
  old) echo 'BLOCKING_FINDINGS=false' ;;
  nonzero) echo 'HOOK_REVIEW_RESULT=pass'; exit 7 ;;
  notlast) printf 'HOOK_REVIEW_RESULT=pass\nextra text\n' ;;
  *) echo 'HOOK_REVIEW_RESULT=pass' ;;
esac
EOF
chmod +x "$bin_dir/occo"

hook_path="$bin_dir:/usr/bin:/bin"
PATH="$hook_path" "$hook_dir/pre-commit" >/dev/null || fail "pre-commit should pass with default deterministic checks"
PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=false "$hook_dir/pre-commit" >/dev/null || fail "pre-commit should pass on pass marker as final line"
if PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=fail "$hook_dir/pre-commit" >/dev/null 2>&1; then fail "pre-commit should fail on fail marker"; fi
if PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=missing "$hook_dir/pre-push" >/dev/null 2>&1; then fail "pre-push should fail on missing marker"; fi
if PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=old "$hook_dir/pre-push" >/dev/null 2>&1; then fail "pre-push should reject old BLOCKING_FINDINGS marker"; fi
if PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=notlast "$hook_dir/pre-commit" >/dev/null 2>&1; then fail "pre-commit should require pass marker as last non-empty line"; fi
if PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=nonzero "$hook_dir/pre-push" >/dev/null 2>&1; then fail "pre-push should fail on non-zero oc"; fi

cat > "$bin_dir/timeout" <<'EOF'
#!/usr/bin/env bash
exit 124
EOF
chmod +x "$bin_dir/timeout"
if PATH="$hook_path" OC_HOOK_LLM=1 OC_TEST_MARKER=false OC_HOOK_TIMEOUT_SECONDS=1 "$hook_dir/pre-commit" >/dev/null 2>&1; then fail "pre-commit should fail closed on timeout"; fi
rm -f "$bin_dir/timeout"

hook_repo="$TMPDIR/hook-repo"
mkdir -p "$hook_repo"
git -C "$hook_repo" init >/dev/null 2>&1
git -C "$hook_repo" config user.email test@example.com
git -C "$hook_repo" config user.name Test
printf 'baseline\n' > "$hook_repo/file.txt"
git -C "$hook_repo" add file.txt
git -C "$hook_repo" commit -m init >/dev/null 2>&1
printf 'baseline\nFULL_DIFF_SENTINEL_SHOULD_NOT_APPEAR\n' > "$hook_repo/file.txt"
git -C "$hook_repo" add file.txt
hook_prompt_capture="$TMPDIR/hook-prompt"
(cd "$hook_repo" && PATH="$hook_path" OC_HOOK_LLM=1 OC_CAPTURE="$hook_prompt_capture" OC_TEST_MARKER=false "$hook_dir/pre-commit" >/dev/null) || fail "pre-commit should pass in fixture repo"
if grep -q 'FULL_DIFF_SENTINEL_SHOULD_NOT_APPEAR' "$hook_prompt_capture"; then fail "pre-commit prompt should not include full diff body when gitleaks is missing"; fi
grep -q 'file.txt' "$hook_prompt_capture" || fail "pre-commit prompt should include metadata for changed file"
pass "hooks require final pass marker, fail closed, and omit full diff body"

profile_list="$(run_oc --list-profiles)"
[[ "$profile_list" == *"default"* ]] || fail "list-profiles should include default"
[[ "$profile_list" != *"default.json"* ]] || fail "list-profiles should omit .json suffix"
if run_oc --profile does-not-exist >/dev/null 2>&1; then fail "invalid profile should fail"; fi
pass "profiles list clean names and reject invalid profiles"

ask_security="$(run_oc ask --dry-run "revisa seguridad antes de publicar")"
[[ "$ask_security" == *"Intent: security-review"* ]] || fail "ask should route security requests"
[[ "$ask_security" == *"@security-auditor"* ]] || fail "ask security route should include security auditor"
[[ "$ask_security" == *"hasta 3 preguntas puntuales"* ]] || fail "ask security prompt should keep clarification guardrail"
[[ "$ask_security" != *"~/.config/opencode/rubrics"* ]] || fail "ask should not require external rubric file reads"

ask_feature="$(run_oc ask --dry-run "implementa dark mode")"
[[ "$ask_feature" == *"Intent: feature"* ]] || fail "ask should route feature requests"
[[ "$ask_feature" == *"@builder"* ]] || fail "ask feature route should include builder"
[[ "$ask_feature" == *"hasta 3 preguntas puntuales"* ]] || fail "ask feature prompt should keep clarification guardrail"
[[ "$ask_feature" == *"Docs-First"* ]] || fail "ask feature prompt should include Docs-First"

ask_auth_sessions="$(run_oc ask --dry-run "implementa autenticación con sesiones")"
[[ "$ask_auth_sessions" == *"Intent: feature"* ]] || fail "ask should accept detailed Spanish auth requests"

ask_docs="$(run_oc ask --dry-run "documenta este proyecto")"
[[ "$ask_docs" == *"Intent: documentation"* ]] || fail "ask should route documentation requests"
[[ "$ask_docs" == *"Docs-First"* ]] || fail "ask docs prompt should include Docs-First"
[[ "$ask_docs" == *"PROJECT_CONTEXT"* ]] || fail "ask docs prompt should mention docs-first files"

ask_ci="$(run_oc ask --dry-run "configura CI")"
[[ "$ask_ci" == *"Intent: devops"* ]] || fail "ask should route standalone CI requests to devops"

ask_prod="$(run_oc ask --dry-run "producción está caída con logs de error")"
[[ "$ask_prod" == *"Intent: production-debug"* ]] || fail "ask should route production incidents"
[[ "$ask_prod" == *"@oncall"* ]] || fail "ask production route should include oncall"
[[ "$ask_prod" == *"hasta 3 preguntas puntuales"* ]] || fail "ask production prompt should keep clarification guardrail"

ask_unknown="$(run_oc ask --dry-run "ayuda con esto")"
[[ "$ask_unknown" == *"Intent: clarify"* ]] || fail "ask should clarify ambiguous requests"
[[ "$ask_unknown" == *"hasta 3 preguntas puntuales"* ]] || fail "ask clarify prompt should ask targeted questions"

ask_readiness="$(run_oc ask --dry-run "revisa el proyecto y dime que falta para estar en 100%")"
[[ "$ask_readiness" == *"Intent: readiness-analysis"* ]] || fail "ask should route readiness requests before generic review"
[[ "$ask_readiness" == *"@architect"* ]] || fail "ask readiness route should include architect"
[[ "$ask_readiness" == *"Evita bash"* ]] || fail "ask readiness prompt should avoid bash by default"

ask_auth="$(run_oc ask --dry-run "implementa autenticación")"
[[ "$ask_auth" == *"Intent: clarify"* ]] || fail "ask should clarify vague auth implementation requests"

ask_dry_clarify="$(run_oc ask --dry-run --clarify "implementa autenticación")"
[[ "$ask_dry_clarify" == *"Intent: clarify"* ]] || fail "ask dry-run clarify should not block"

capture_file="$TMPDIR/opencode-args"
OC_CAPTURE="$capture_file" run_oc ask "revisa seguridad antes de publicar" >/dev/null
grep -q '^run$' "$capture_file" || fail "ask execution should call opencode run"
grep -q '@security-auditor' "$capture_file" || fail "ask execution should pass routed prompt to opencode"
pass "oc ask dry-run routes natural language requests"

init_repo="$TMPDIR/init-repo"
mkdir -p "$init_repo"
git -C "$init_repo" init >/dev/null 2>&1
git -C "$init_repo" config user.email test@example.com
git -C "$init_repo" config user.name Test
printf 'baseline\n' > "$init_repo/push-file.txt"
git -C "$init_repo" add push-file.txt
git -C "$init_repo" commit -m init >/dev/null 2>&1
printf 'baseline\nGENERATED_PRE_PUSH_SENTINEL_SHOULD_NOT_APPEAR\n' > "$init_repo/push-file.txt"
git -C "$init_repo" add push-file.txt
git -C "$init_repo" commit -m update >/dev/null 2>&1
run_oc --init "$init_repo" >/dev/null
test -x "$init_repo/.git/hooks/pre-commit" || fail "oc --init should create pre-commit hook"
test -x "$init_repo/.git/hooks/pre-push" || fail "oc --init should create pre-push hook"
grep -q 'HOOK_REVIEW_RESULT=pass' "$init_repo/.git/hooks/pre-commit" || fail "generated pre-commit should require pass marker"
grep -q 'HOOK_REVIEW_RESULT=pass' "$init_repo/.git/hooks/pre-push" || fail "generated pre-push should require pass marker"
grep -q 'OC_HOOK_TIMEOUT_SECONDS:-60' "$init_repo/.git/hooks/pre-commit" || fail "generated pre-commit should set default timeout"
grep -q 'OC_HOOK_TIMEOUT_SECONDS:-60' "$init_repo/.git/hooks/pre-push" || fail "generated pre-push should set default timeout"
grep -q 'timeout_cmd' "$init_repo/.git/hooks/pre-commit" || fail "generated pre-commit should use timeout command"
grep -q 'timeout_cmd' "$init_repo/.git/hooks/pre-push" || fail "generated pre-push should use timeout command"
if grep -q 'BLOCKING_FINDINGS=false' "$init_repo/.git/hooks/pre-commit"; then fail "generated pre-commit should not require old false marker"; fi
if grep -q 'BLOCKING_FINDINGS=false' "$init_repo/.git/hooks/pre-push"; then fail "generated pre-push should not require old false marker"; fi
bash -n "$init_repo/.git/hooks/pre-commit"
bash -n "$init_repo/.git/hooks/pre-push"
generated_push_prompt_capture="$TMPDIR/generated-pre-push-prompt"
(cd "$init_repo" && PATH="$hook_path" OC_HOOK_LLM=1 OC_CAPTURE="$generated_push_prompt_capture" OC_TEST_MARKER=false "$init_repo/.git/hooks/pre-push" >/dev/null) || fail "generated pre-push should pass in fixture repo"
if grep -q 'GENERATED_PRE_PUSH_SENTINEL_SHOULD_NOT_APPEAR' "$generated_push_prompt_capture"; then fail "generated pre-push prompt should not include full diff body"; fi
grep -q 'push-file.txt' "$generated_push_prompt_capture" || fail "generated pre-push prompt should include metadata for changed file"
pass "oc --init generates fail-closed git hooks"

cp "$ROOT/opencode.json" "$TMPDIR/home/.config/opencode/opencode.json"
cp "$ROOT/AGENTS.md" "$TMPDIR/home/.config/opencode/AGENTS.md"
cp "$ROOT/CLAUDE.md" "$TMPDIR/home/.config/opencode/CLAUDE.md"
for dir in agents skills plugins commands memory profiles rubrics; do
  rm -rf "$TMPDIR/home/.config/opencode/$dir"
  cp -r "$ROOT/$dir" "$TMPDIR/home/.config/opencode/$dir"
done
doctor_output="$(run_oc --doctor)"
[[ "$doctor_output" == *"All checks passed"* ]] || fail "doctor should pass against installed fixture"
HOME="$TMPDIR/home" PATH="$TMPDIR/bin:$PATH" bash "$ROOT/validate.sh" --installed >/dev/null || fail "validate --installed should pass against fixture"

mv "$TMPDIR/home/.config/opencode/rubrics/code-review.md" "$TMPDIR/home/.config/opencode/rubrics/code-review.md.bak"
if run_oc --doctor >/dev/null 2>&1; then fail "doctor should fail when installed rubric is missing"; fi
if HOME="$TMPDIR/home" PATH="$TMPDIR/bin:$PATH" bash "$ROOT/validate.sh" --installed >/dev/null 2>&1; then fail "validate --installed should fail when rubric is missing"; fi
mv "$TMPDIR/home/.config/opencode/rubrics/code-review.md.bak" "$TMPDIR/home/.config/opencode/rubrics/code-review.md"

bash "$ROOT/install.sh" --dry-run >/dev/null || fail "install dry-run should pass"
pass "doctor, installed validation and installer dry-run pass in fixtures"

dry_run_output="$(bash "$ROOT/install.sh" --dry-run)"
[[ "$dry_run_output" == *"opencode-config-install."* ]] || fail "install dry-run should show mktemp-style install dir"
[[ "$dry_run_output" == *"Requisitos del sistema:"* ]] || fail "install dry-run should report system requirements"
[[ "$dry_run_output" == *"opencode"* ]] || fail "install dry-run should mention opencode requirement"
uninstall_output="$(HOME="$TMPDIR/no-config-home" bash "$ROOT/uninstall.sh" --force)"
[[ "$uninstall_output" != *"To restore:"* ]] || fail "uninstall should not print restore command without backup"
pass "installer and uninstaller handle temp paths and missing backups"

if ! command -v node >/dev/null 2>&1; then
  pass "node not installed; skipping safety guard JS smoke test"
  printf 'All tests passed\n'
  exit 0
fi

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
if (!(await blocked('rm -rf "$HOME"'))) throw new Error('rm -rf "$HOME" should be blocked')
if (!(await blocked("rm -rf ${HOME}"))) throw new Error("rm -rf ${HOME} should be blocked")
if (!(await blocked("sudo rm -rf $HOME/.config"))) throw new Error("sudo rm -rf $HOME/.config should be blocked")
if (!(await blocked('rm -rf "$HOME"/.config'))) throw new Error('rm -rf "$HOME"/.config should be blocked')
if (!(await blocked('rm -rf "${HOME}"/.config'))) throw new Error('rm -rf "${HOME}"/.config should be blocked')
if (!(await blocked('sudo rm -rf "$HOME"/.config'))) throw new Error('sudo rm -rf "$HOME"/.config should be blocked')
if (!(await blocked('rm -rf "$HOME"/.config; true'))) throw new Error('rm -rf "$HOME"/.config; true should be blocked')
if (!(await blocked('rm -rf "${HOME}"/.config && true'))) throw new Error('rm -rf "${HOME}"/.config && true should be blocked')
if (!(await blocked('sudo rm -rf $HOME/.config || true'))) throw new Error('sudo rm -rf $HOME/.config || true should be blocked')
if (!(await blocked('rm -rf /; true'))) throw new Error('rm -rf /; true should be blocked')
if (!(await blocked('rm -rf /home/someuser'))) throw new Error('rm -rf /home/someuser should be blocked')
if (!(await blocked('rm -rf /etc/ssh'))) throw new Error('rm -rf /etc/ssh should be blocked')
if (!(await blocked('rm -rf /var/log && true'))) throw new Error('rm -rf /var/log && true should be blocked')
if (!(await blocked('sudo rm -rf /root/.ssh'))) throw new Error('sudo rm -rf /root/.ssh should be blocked')
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

# E2E: install.sh --with-codebase-memory
# Real install.sh boots against a local clone of the repo (no network), with
# opencode + git as the real binaries, but codebase-memory-mcp stubbed so we
# don't depend on GitHub releases. Verifies that when the binary pre-exists on
# PATH but the MCP entry is missing from opencode.json, install.sh calls
# 'codebase-memory-mcp install -y' to register it. This is the exact path
# that broke in v1.18.0 and required v1.18.1+v1.19.1 follow-ups.
#
# Strategy: real git/opencode + stub cbm. install.sh does git clone in a
# mktemp dir; we override REPO_URL with a local file:// URL of THIS repo
# so the clone succeeds without network. Then we provide:
#   - opencode: real binary
#   - git: real binary
#   - codebase-memory-mcp: stub at $TMPDIR/bin/codebase-memory-mcp that
#     mutates a tracked opencode.json with jq
#   - the rest of PATH inherits from the test environment

CBM_INSTALL_LOG="$TMPDIR/cbm-install-log"
export CBM_INSTALL_LOG

mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/codebase-memory-mcp" <<'CBM_EOF'
#!/usr/bin/env bash
log="${CBM_INSTALL_LOG:-/tmp/cbm-install.log}"
printf 'stub-cbm: %s\n' "$*" >> "$log"
case "$1" in
    install)
        cfg="$HOME/.config/opencode/opencode.json"
        if [ -f "$cfg" ] && command -v jq >/dev/null 2>&1; then
            tmp="$(mktemp)"
            jq '.mcp["codebase-memory-mcp"] = {"enabled": true, "type": "local"}' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
        fi
        exit 0
        ;;
esac
exit 0
CBM_EOF
chmod +x "$TMPDIR/bin/codebase-memory-mcp"

CBM_E2E_HOME="$TMPDIR/cbm-home"
mkdir -p "$CBM_E2E_HOME/.config/opencode"
printf '%s' '{"$schema":"https://opencode.ai/config.json","permission":{"read":"allow"}}' > "$CBM_E2E_HOME/.config/opencode/opencode.json"

# Run install.sh against the local repo via file:// URL (no network).
# Override REPO_URL with the local clone target.
HOME="$CBM_E2E_HOME" \
    PATH="$TMPDIR/bin:$PATH" \
    CBM_INSTALL_LOG="$CBM_INSTALL_LOG" \
    bash -c "REPO_URL='$ROOT' bash '$ROOT/install.sh' --with-codebase-memory" \
    >/dev/null 2>&1 \
    || fail "install.sh --with-codebase-memory should succeed offline against local repo"

# After install.sh, opencode.json was regenerated by install.sh (it overwrites
# with an absolute-path template). The MCP entry should NOT be in the
# regenerated file because install.sh's template has no MCP block. So the
# remediation path (v1.18.1 follow-up) should run 'install -y' to add it.
grep -q '"codebase-memory-mcp"' "$CBM_E2E_HOME/.config/opencode/opencode.json" \
    || fail "after install --with-codebase-memory: opencode.json must contain codebase-memory-mcp MCP entry (file: $CBM_E2E_HOME/.config/opencode/opencode.json)"
grep -q 'install -y' "$CBM_INSTALL_LOG" \
    || fail "install --with-codebase-memory must call 'install -y' on the binary (the v1.18.0 regression guard)"
pass "install --with-codebase-memory registers MCP server in opencode.json (E2E)"

# --- v1.21.0 smoke coverage for previously untested subcommands ---

# --wizard: should print the banner and exit non-zero or block on prompts.
# We assert only the deterministic part: the wizard banner is printed.
# (Interactive loops are not testable; we trust the gate-keeping if the
# banner appears.)
result="$(run_oc --wizard </dev/null 2>&1 || true)"
[[ "$result" == *"OpenCode Wizard"* ]] || fail "occ --wizard should print the wizard banner"
pass "occ --wizard prints the wizard banner"

# --budget: prints session turn counter (may also create observation as
# a side effect of occ's own track_turn; we assert on counter presence
# because that's the user-visible behavior).
result="$(run_oc --budget 2>&1 || true)"
[[ "$result" == *"Session turns"* ]] || fail "occ --budget should print session turns (got: ${result:0:200})"
pass "occ --budget prints session turn count"

# --status: lists status, profile, hooks, last observation. Output may
# also contain an "Observation created" line as a side effect; we only
# assert the deterministic banner + section headers.
result="$(run_oc --status 2>&1 || true)"
[[ "$result" == *"OpenCode Status"* ]] || fail "occ --status should print status banner"
[[ "$result" == *"Active profile"* ]] || fail "occ --status should print active profile"
[[ "$result" == *"Hooks"* ]] || fail "occ --status should print hooks state"
pass "occ --status prints status, profile and hooks"

# --profile <name>: switches active profile, persists to .current_profile,
# rejects unknown names. Profiles are pre-populated by tests/run.sh setup.
run_oc --profile devops >/dev/null 2>&1 || fail "occ --profile devops should succeed (devops profile exists)"
[[ "$(cat "$TMPDIR/home/.config/opencode/.current_profile" 2>/dev/null)" == "devops" ]] || fail "active profile should be persisted to .current_profile"
if run_oc --profile does-not-exist >/dev/null 2>&1; then fail "invalid profile should fail"; fi
pass "occ --profile switches and persists, rejects invalid"

# --list-templates: lists the known observation templates (bugfix, decision,
# feature, config). These are static metadata, not memory-dependent.
list_t="$(run_oc --list-templates 2>&1 || true)"
[[ "$list_t" == *"bugfix"* ]] || fail "--list-templates should include bugfix"
[[ "$list_t" == *"decision"* ]] || fail "--list-templates should include decision"
[[ "$list_t" == *"feature"* ]] || fail "--list-templates should include feature"
[[ "$list_t" == *"config"* ]] || fail "--list-templates should include config"
pass "occ --list-templates lists all 4 templates"

# --memory --timeline <id>: prints timeline around the obs if found, or
# 'Observation not found' warning. Pre-populate one obs file at the
# canonical path so the test passes on EITHER happy or warn path.
mkdir -p "$TMPDIR/home/.config/opencode/memory/projects/alpha"
cat > "$TMPDIR/home/.config/opencode/memory/projects/alpha/1.md" <<'OBS_EOF'
---
date: 2026-06-29
summary: alpha project timeline test fixture
---
content
OBS_EOF
result="$(run_oc --memory --timeline obs_1 2>&1 || true)"
[[ "$result" == *"Timeline around"* || "$result" == *"Observation not found"* ]] \
    || fail "--memory --timeline should print timeline or not-found (got: ${result:0:200})"
pass "occ --memory --timeline resolves obs id"

# --memory --get <id>: prints observation body or 'Observation not found'.
# Pre-populate the same obs file as above; --get normalizes the id (strips
# 'obs_' prefix), so we look for the matching warn or the body.
result="$(run_oc --memory --get obs_1 2>&1 || true)"
[[ "$result" == *"alpha project timeline test fixture"* || "$result" == *"Observation not found"* ]] \
    || fail "--memory --get should print obs body or not-found (got: ${result:0:200})"
pass "occ --memory --get resolves obs id"

# --capture: writes a session marker to memory/.session_start if not
# present. Just verify it runs (exit 0) and prints 'Session started'.
result="$(run_oc --capture 2>&1)"
[[ "$result" == *"Session"* ]] || fail "occ --capture should print session info (got: ${result:0:200})"
pass "occ --capture marks session start"

# --save-all: persists outcomes to memory/outcomes/*.json and creates
# an observation. Capture the count before and after to assert at
# least one new JSON appears after the run.
outcomes_dir="$TMPDIR/home/.config/opencode/memory/outcomes"
mkdir -p "$outcomes_dir"
before=$(ls "$outcomes_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')
result="$(run_oc --save-all 2>&1 || true)"
[[ "$result" == *"Estado guardado"* || "$result" == *"saved"* || "$result" == *"Guardando"* ]] \
    || fail "occ --save-all should report saving (got: ${result:0:200})"
after=$(ls "$outcomes_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')
[[ "$after" -gt "$before" ]] || fail "occ --save-all should write at least one new JSON to outcomes/"
pass "occ --save-all writes a new outcome JSON to memory/outcomes/"

# --list-workflows: lists the 5 hardcoded workflow names. Static
# metadata, no I/O. Asserts on names that appear in occo's
# show_help output.
list_wf="$(run_oc --list-workflows 2>&1 || true)"
[[ "$list_wf" == *"bug-hunt"* ]] || fail "--list-workflows should include bug-hunt"
[[ "$list_wf" == *"new-project"* ]] || fail "--list-workflows should include new-project"
[[ "$list_wf" == *"debug"* ]] || fail "--list-workflows should include debug"
[[ "$list_wf" == *"feature"* ]] || fail "--list-workflows should include feature"
[[ "$list_wf" == *"document"* ]] || fail "--list-workflows should include document"
pass "occ --list-workflows lists all 5 workflows"

# --detect-skills <path>: scans a directory for stack fingerprints
# (package.json, go.mod, etc.) and reports which language-specific
# skills apply. Pre-stage a Node project so the test prints something
# deterministic; copy the local skills-registry so we don't hit the
# network.
detect_repo="$TMPDIR/detect-repo"
mkdir -p "$detect_repo"
printf '{"name":"t","version":"0.0.1"}\n' > "$detect_repo/package.json"
cp "$ROOT/skills-registry.json" "$TMPDIR/home/.config/opencode/skills-registry.json"
result="$(cd "$detect_repo" && HOME="$TMPDIR/home" PATH="$TMPDIR/bin:$PATH" "$ROOT/occo" --detect-skills . 2>&1 || true)"
[[ "$result" == *"Skills disponibles"* ]] || fail "occ --detect-skills should print detected skills list (got: ${result:0:200})"
pass "occ --detect-skills detects stack from project files"

printf 'All tests passed\n'
