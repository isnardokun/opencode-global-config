#!/usr/bin/env bash
# Validate repo structure, JSON files, and shell scripts
# Usage: ./validate.sh [--installed]

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLED=0
errors=0

for _arg in "$@"; do
    case "$_arg" in
        --installed) INSTALLED=1 ;;
    esac
done

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅${NC} $1"; }
fail() { echo -e "${RED}❌${NC} $1"; errors=$((errors + 1)); }
warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }

check_file() {
    local base="${2:-$ROOT}"
    if [ -f "${base}/$1" ]; then
        pass "$1"
    else
        fail "Missing file: $1"
    fi
}

check_dir() {
    local base="${2:-$ROOT}"
    if [ -d "${base}/$1" ]; then
        pass "$1/"
    else
        fail "Missing directory: $1/"
    fi
}

echo "OpenCode Global Config — Validator"
echo "==================================="
echo ""

echo "Structure:"
check_file "opencode.json"
check_file "AGENTS.md"
check_file "CLAUDE.md"
check_file "install.sh"
check_file "validate.sh"
check_file "uninstall.sh"
check_file "oc"
check_dir  "agents"
check_dir  "skills"
check_dir  "plugins"
check_dir  "profiles"
check_dir  "commands"
check_dir  "hooks"
check_dir  "memory"
check_dir  "souls"
echo ""

echo "Required agents:"
for agent in architect builder builder-safe planner reviewer security-auditor docs-writer devops oncall migration-planner performance-profiler; do
    check_file "agents/${agent}.md"
done
echo ""

echo "Required commands:"
for cmd in analyze review secure feature bug-hunt docs devops oncall; do
    check_file "commands/${cmd}.md"
done
echo ""

echo "Required skills:"
for skill in project-map safe-implementation test-first precommit-review memory-retrieval docs-writer; do
    if [ -d "${ROOT}/skills/${skill}" ]; then
        pass "skills/${skill}/"
    else
        fail "Missing skill: skills/${skill}/"
    fi
done
echo ""

echo "JSON validation:"
if command -v jq >/dev/null 2>&1; then
    for jf in opencode.json opencode.strict.json profiles/*.json; do
        if jq empty "${ROOT}/${jf}" >/dev/null 2>&1; then
            pass "$jf"
        else
            fail "Invalid JSON: $jf"
        fi
    done
else
    warn "jq not installed — skipping JSON validation"
    warn "Install: apt install jq / brew install jq"
fi
echo ""

echo "Shell syntax:"
for sh in install.sh oc hooks/pre-commit hooks/pre-push; do
    if [ -f "${ROOT}/${sh}" ]; then
        if bash -n "${ROOT}/${sh}" 2>/dev/null; then
            pass "$sh"
        else
            fail "Bash syntax error: $sh"
        fi
    else
        warn "Not found (skipping): $sh"
    fi
done
echo ""

echo "OpenCode CLI compatibility:"
legacy_cli=$(grep -RIn "opencode -p\|opencode --profile" "${ROOT}/oc" "${ROOT}/hooks" 2>/dev/null || true)
if [ -z "$legacy_cli" ]; then
    pass "No legacy opencode -p/--profile calls"
else
    fail "Legacy OpenCode CLI usage found:"
    echo "$legacy_cli"
fi
echo ""

echo "Profile permission action check:"
if command -v python3 >/dev/null 2>&1; then
    if python3 - "${ROOT}/profiles" << 'PYEOF'
import json, pathlib, sys
allowed = {"ask", "allow", "deny"}
errors = []
for path in sorted(pathlib.Path(sys.argv[1]).glob("*.json")):
    data = json.loads(path.read_text())
    permissions = data.get("opencode", {}).get("permission", {})
    for tool, action in permissions.items():
        if isinstance(action, str) and action not in allowed:
            errors.append(f"{path.name}: {tool}={action}")
if errors:
    print("\n".join(errors))
    sys.exit(1)
PYEOF
    then
        pass "Profile permissions use ask/allow/deny"
    else
        fail "Invalid profile permission action"
    fi
else
    warn "python3 not installed — skipping profile permission action check"
fi
echo ""

echo "Agent model check (should be free — no hardcoded model):"
hardcoded=$(grep -l "^model:" "${ROOT}/agents/"*.md 2>/dev/null || true)
if [ -z "$hardcoded" ]; then
    pass "No hardcoded model in agents"
else
    fail "Hardcoded model found in: $hardcoded"
fi
echo ""

echo "Language artifact check:"
artifacts=$(grep -rn "No容忍\|基础设施\|средний\|密码\|報告ar\|发现问题" "${ROOT}/agents/" "${ROOT}/profiles/" "${ROOT}/souls/" "${ROOT}/plugins/" "${ROOT}/skills/" 2>/dev/null || true)
if [ -z "$artifacts" ]; then
    pass "No foreign-language LLM artifacts"
else
    fail "Foreign-language artifacts found:"
    echo "$artifacts"
fi
echo ""

echo "Line count sanity check:"
for f in install.sh oc validate.sh uninstall.sh Makefile; do
    if [ -f "${ROOT}/${f}" ]; then
        lines=$(wc -l < "${ROOT}/${f}" | tr -d ' ')
        if [ "$lines" -lt 5 ]; then
            fail "$f suspiciously short: $lines lines (possible minification)"
        else
            pass "$f: $lines lines"
        fi
    fi
done
echo ""

echo "Markdown frontmatter check:"
for md in "${ROOT}/agents/"*.md "${ROOT}/commands/"*.md; do
    [ -f "$md" ] || continue
    fname="${md#${ROOT}/}"
    first_line=$(head -n 1 "$md")
    fence_count=$(grep -c '^---$' "$md" 2>/dev/null || echo 0)
    if [ "$first_line" = "---" ] && [ "$fence_count" -ge 2 ]; then
        pass "$fname frontmatter"
    else
        fail "Invalid frontmatter: $fname"
    fi
done
echo ""

if [ "$INSTALLED" -eq 1 ]; then
    IDIR="${HOME}/.config/opencode"
    echo "Installed config check (~/.config/opencode):"
    check_file "opencode.json" "$IDIR"
    check_file "AGENTS.md"     "$IDIR"
    check_file "CLAUDE.md"     "$IDIR"
    check_dir  "agents"        "$IDIR"
    check_dir  "skills"        "$IDIR"
    check_dir  "plugins"       "$IDIR"
    check_dir  "commands"      "$IDIR"

    echo ""
    echo "oc command:"
    if command -v oc >/dev/null 2>&1; then
        pass "oc found: $(command -v oc)"
    else
        fail "oc not in PATH"
    fi
    echo ""
fi

echo "==================================="
if [ "$errors" -eq 0 ]; then
    echo -e "${GREEN}✅ Validation passed${NC}"
    exit 0
else
    echo -e "${RED}❌ Validation failed: $errors error(s)${NC}"
    exit 1
fi
