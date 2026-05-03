# OpenCode Global Configuration

**English | [Español](README.es.md)**

Advanced global configuration for [OpenCode CLI](https://opencode.ai) with specialized agents, project memory, prompt-enforced profiles, guarded hooks, smoke tests, and structured workflows.

Inspired by [VILA-Lab/Dive-into-Claude-Code](https://github.com/VILA-Lab/Dive-into-Claude-Code) and Andrej Karpathy's coding guidelines.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Natural Language Mode](#natural-language-mode)
- [Optional `oc ask` Router](#optional-oc-ask-router)
- [Usage Manual](#usage-manual)
- [Quick Commands Reference](#quick-commands-reference)
- [Profiles and Trust Levels](#profiles-and-trust-levels)
- [How Profile Enforcement Works](#how-profile-enforcement-works)
- [Memory Bank](#memory-bank)
- [Workflows](#workflows)
- [Context Compaction](#context-compaction)
- [Security Plugin](#security-plugin)
- [Git Hooks](#git-hooks)
- [Validation and Tests](#validation-and-tests)
- [Souls / Personas](#souls--personas)
- [Project Structure](#project-structure)
- [Inspiration](#inspiration)
- [Changelog](#changelog)

---

## Features

**v1.9.4 + reusable review rubrics, natural routing, and release-readiness hardening**

- **11 specialized agents** — no hardcoded model; use whichever model you select in OpenCode's UI
- **8 official slash commands** — `/analyze`, `/review`, `/secure`, `/feature`, `/bug-hunt`, `/docs`, `/devops`, `/oncall` — usable directly in OpenCode's TUI
- **9 prompt-enforced profiles** — rules like `requireTests`, `checkpointBeforeChanges` injected as explicit LLM instructions; profile permissions validated against `ask|allow|deny`
- **6 skills** for analysis, implementation, validation, memory, and documentation
- **3 review rubrics** for code review, security review, and plan/design gates
- **1 security plugin** with regex hardening, ESM metadata, redacted audit log, and restrictive log permissions
- **Optional `oc ask` router** — natural-language intent routing with `--dry-run`, `--explain`, and `--clarify`
- **3-layer Memory Bank** (search / timeline / full detail) + JSONL index + project/type filters
- **5 single-pass workflows** (bug-hunt, new-project, debug, document, feature)
- **Souls / Personas** for different work contexts
- **Git hooks** for automatic review; fail-closed markers + optional `gitleaks` if installed
- **Quick commands** with optional context argument
- **Interactive menu** via fzf
- **Wizard mode** step-by-step guidance
- **Real `--compact`** — structured LLM summarization, not just a counter reset
- **`oc --doctor`** — diagnoses installation health
- **`validate.sh`** — validates repo integrity, docs consistency, counts, plugin syntax, and installed config via `--installed`
- **`tests/run.sh`** — functional smoke tests for memory, hooks, profiles, init, compact, doctor, install dry-run, and safety guard
- **`VERSION`** — simple version source validated against docs/scripts
- **`uninstall.sh`** — safe removal with automatic backup
- **`install.sh --dry-run`** — simulate installation
- **Stack detection** in `oc --init` — auto-detects Node.js/Python/Rust/Go/Java/Docker/Terraform
- **Reversibility-Weighted Risk Assessment** in `@oncall`
- **Karpathy Principles** (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven)
- **GitHub Actions CI** — validates structure, JSON, shell syntax, Node plugin syntax, and functional smoke tests on every push

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

The installer: backs up existing config, sets up PATH in bash/zsh/fish, works on Linux and macOS.

**Requirements:** `opencode` and `git` (required), `fzf` (only for `oc --interactive`)

Safer manual flow if you do not want to pipe directly into `bash`:

```bash
git clone https://github.com/isnardokun/opencode-global-config /tmp/opencode-global-config
cd /tmp/opencode-global-config
bash install.sh --dry-run
bash install.sh
./validate.sh --installed
oc --doctor
```

See [INSTALL.md](INSTALL.md) for manual installation and troubleshooting.

---

## Natural Language Mode

Inside an `opencode` interactive session, describe what you need — the system detects intent and activates the right agent:

```bash
opencode   # open interactive session
```

Then type naturally inside the session:

```
# Analysis → activates @architect
analyze the project
what stack does this use?
understand the structure

# Implementation → activates @builder
implement authentication with JWT
create a users endpoint
add input validation

# Review → activates @reviewer
review my code
check the changes

# Security → activates @security-auditor
look for security issues
audit the project

# Documentation → activates @docs-writer
generate documentation
create README for the project

# Production → activates @oncall
why is the build failing?
diagnose the error
```

Full intent mapping is in `AGENTS.md`.

Optional wrapper mode:

```bash
oc ask "arregla el bug de login"
oc ask --dry-run "revisa seguridad antes de publicar"
oc ask --clarify "implementa autenticación"
```

`oc ask` keeps all explicit commands available, but adds a natural-language router that chooses the likely agent/workflow and asks targeted clarification questions when the request is ambiguous.

---

## Optional `oc ask` Router

Use `oc ask` when you want one command that interprets what you mean and selects the best existing agent/workflow. It is an optional UX layer; all explicit commands remain available and unchanged.

```bash
oc ask "analyze this repo and list release risks"
oc ask "fix the login bug"
oc ask "review security before publishing"
oc ask "document this project"
```

Routing preview without calling OpenCode:

```bash
oc ask --dry-run "review security before publishing"
```

Example output:

```text
Intent: security-review
Route: @security-auditor + rubrics/security-review.md
Prompt:
Usa @security-auditor ...
```

Ask local clarification questions first:

```bash
oc ask --clarify "implement authentication"
```

Supported options:

| Option | Behavior |
|--------|----------|
| `--dry-run` | Prints detected intent, route, and generated prompt; does not run OpenCode |
| `--explain` | Prints routing details, then runs OpenCode |
| `--clarify` | Prompts locally for objective, context, and success criteria before routing |

Current routing examples:

| User request contains | Intent | Route |
|-----------------------|--------|-------|
| `analyze`, `stack`, `architecture` | `architecture-analysis` | `@architect + project-map` |
| `100%`, `readiness`, `what is missing` | `readiness-analysis` | `@architect + project-map -> @planner` |
| `implement`, `add`, `feature` | `feature` | `@architect -> @planner -> @builder -> @reviewer` |
| vague auth request like `implement auth` | `clarify` | interpreter asks targeted questions |
| `bug`, `fix`, `error`, `broken` | `bugfix` | `@architect -> @planner -> @builder -> @reviewer` |
| `review`, `diff`, `pre-commit` | `code-review` | `@reviewer + precommit-review + code-review rubric` |
| `security`, `audit`, `token`, `xss`, `sql` | `security-review` | `@security-auditor + security-review rubric` |
| `docker`, `CI`, `deploy`, `terraform` | `devops` | `@devops` |
| `prod`, `crash`, `logs`, `incident` | `production-debug` | `@oncall -> @builder -> @security-auditor` |

Safety behavior:

- generated prompts include a guardrail to ask up to 3 targeted questions when critical information is missing;
- ambiguous authentication requests are clarified before implementation unless details such as JWT, OAuth, sessions, cookies, MFA, or passkeys are present;
- readiness requests are routed read-only by default and tell the agent to avoid `bash` unless approved;
- rubric criteria are embedded as instructions, so `oc ask` does not require agents to read files outside the current workspace.

---

## Usage Manual

Common scenarios from problem to solution.

---

### 1. First time in an unknown project

You arrive at a repo you've never seen. Before touching anything:

```bash
cd ~/projects/legacy-api

# Understand the project
oc analyze .

# Expected @architect output:
# - Stack: Node.js 16, Express, MongoDB, Redis
# - Entry points: src/index.js, src/api/routes/
# - Critical files: src/auth/middleware.js, src/db/connection.js
# - Risks: outdated deps, no tests in /api/payments
# - Suggested plan: 3 phases
```

No files were modified — `@architect` is read-only.

---

### 2. Implement a new feature

Full flow: understand → plan → implement → review.

```bash
# Option A: automatic workflow (all phases in one session)
oc --workflow feature "add OAuth2 authentication with Google" ~/my-api

# Option B: manual step-by-step
oc analyze ~/my-api                          # Understand structure first
oc plan "add OAuth2 with Google"             # Review plan before executing
oc build "implement OAuth2 with Google"      # Execute with test-first
oc review                                    # Review before commit
```

**When to use workflow vs manual:**
- Workflow: well-defined feature, project you already know
- Manual: first time in the codebase, ambiguous feature, want to approve each step

---

### 3. Production bug — urgent response

```bash
# Step 1: activate restrictive profile for diagnosis (touches nothing)
oc --profile review

# Step 2: diagnose
oc oncall
# @oncall classifies P1/P2/P3, identifies root cause,
# lists mitigations by reversibility

# Step 3: activate fix profile
oc --profile trusted

# Step 4: implement fix with test
oc build "fix: JWT token validation rejecting valid tokens after DST change"

# Step 5: verify
oc review

# Step 6: save to memory for future reference
oc --remember -p api -t bugfix "JWT fails on DST change — use UTC in token generation, not local time"
```

**Automated alternative:**
```bash
oc --workflow debug "JWT token validation failing after DST change in ~/api"
```

---

### 4. Security audit before deploy

```bash
# Maximum restrictive profile (zero modifications possible)
oc --profile deny

# Audit
oc secure

# @security-auditor reports:
# - CRITICAL: SQL injection in /api/search?q= (no sanitization)
# - HIGH: JWT secret hardcoded in config/default.js line 23
# - MEDIUM: No rate limiting on /api/auth/login
# - LOW: Error handlers expose user emails in logs

# Switch back to fix
oc --profile default
oc build "fix: sanitize inputs, move JWT secret to env var, add rate limiting"
```

---

### 5. Generate documentation for an existing project

```bash
oc --workflow document ~/my-project

# Generates automatically:
# - README.md (description, install, usage, examples)
# - ARCHITECTURE.md (component diagram, data flow)
# - API.md (endpoints, formats, request/response examples)
# - DEPLOY.md (deployment instructions if Docker/CI detected)
```

For a specific subdirectory:
```bash
cd src/api && oc docs
```

---

### 6. Start a new project from scratch

```bash
oc --workflow new-project "REST API for inventory management with Node.js and PostgreSQL"

# Workflow:
# Phase 1: @architect decides structure, stack, dependencies
# Phase 2: @planner creates phased plan with dirs, config files, initial tests
# Phase 3: @builder generates the scaffold
# Phase 4: @docs-writer creates README, ARCHITECTURE, CONTRIBUTING

# After the workflow, init local OpenCode config
oc --init .
# Creates .opencode/opencode.json plus pre-commit and pre-push git hooks
```

---

### 7. Code review before committing

```bash
# You have staged changes and want to review them before commit
oc review

# @reviewer reports:
# - Files modified
# - Critical findings (blockers)
# - Medium findings (warnings)
# - Tests present or missing
# - Recommendation: approve / fix

# If critical issues found:
oc build "fix: <critical finding description>"
oc review   # review again
```

The git hook installed by `oc --init` does this automatically on every `git commit`.

---

### 8. Working with Memory Bank

```bash
# Save a technical decision
oc --remember -p my-api -t decision "Chose CQRS over generic repository because reporting queries need independent optimization"

oc --remember -p my-api -t config "Redis in production: db=1 sessions, db=2 cache, db=3 rate limiting — do not mix"

oc --remember -p my-api -t bugfix "Email worker hangs on UTF-8 subjects with > 3-byte chars — sanitize before queuing"

# Retrieve context before starting work
oc --memory "auth"
oc --memory "auth" -p my-api -t decision
# Layer 1 result (~80 tokens):
# obs_20260501-143022-a1b2 | 2026-05-01 | my-api | decision | Chose JWT over session cookies
# obs_20260501-150344-c3d4 | 2026-05-01 | my-api | bugfix    | JWT fails on DST change

# See timeline context
oc --memory --timeline 20260501-143022-a1b2

# See full detail
oc --memory --get 20260501-143022-a1b2
```

---

### 9. Controlled refactor

```bash
# Phase 1: understand what the code touches
oc analyze src/services/

# Phase 2: plan with explicit success criteria
oc plan "refactor UserService to separate auth logic from profile logic — tests must pass before and after"

# Phase 3: implement with conservative profile
oc --profile default   # edit=ask — confirms each change
oc build "refactor UserService: extract AuthService and ProfileService"

# Phase 4: full diff review
oc review
```

---

### 10. DevOps — infrastructure and deploys

```bash
# Activate devops profile (requireSecurityReview + requireCheckpoint enforced)
oc --profile devops

oc devops "create multi-stage Dockerfile for the API, optimized for production"
oc devops "configure GitHub Actions CI/CD with tests, build, and staging deploy"
oc devops "add health check endpoint and configure liveness/readiness probes for Kubernetes"

# Production diagnostics
oc oncall
# @oncall with reversibility-weighted risk:
# Reversible actions (restart, rollback) → minimal approval
# Destructive actions (drop table) → requires +1 reviewer + confirmed backup
```

---

### 11. Profile flows — when to use each

```bash
# Explore safely (zero possible modifications)
oc --profile deny
oc "what does this code do?"

# Planning — technical meeting, estimation, design
oc --profile plan
oc plan "migrate from MongoDB to PostgreSQL"

# Code review of someone else's PR
oc --profile review
oc "review changes in src/api/ and report problems"

# Day-to-day development
oc --profile default   # asks confirmation before each change

# Full trust — own project, well known
oc --profile trusted
oc build "implement pagination on all listing endpoints"

# Infrastructure and automation scripts
oc --profile devops
oc devops "create automated backup script for PostgreSQL"
```

---

### 12. Long session — context management

```bash
# Check how many turns you've used
oc --budget
# Session turns: 34
# Consider running: oc --compact

# Summarize the session (real LLM summarization)
oc --compact
# OpenCode generates structured summary:
#   Goal / Findings / Changes Made / Decisions / Current State / Remaining Work
# Turn counter resets after.

# Save the summary
oc --remember "Session summary: implementing OAuth2, phases 1-3 complete, frontend integration pending"

# Continue with clean context
oc --memory "OAuth2"
oc build "integrate OAuth2 with React frontend"
```

---

### 13. Interactive mode — explore without knowing what you need

```bash
oc --interactive   # requires fzf

# Menu:
# a  @architect    - Analyze architecture and risks
# b  @builder      - Implement changes
# r  @reviewer     - Review code
# ...

# Navigate with arrows, Enter to select
# Agents that need input (p, b, v) prompt for description before executing
```

---

### 14. Wizard mode — guided step by step

```bash
oc --wizard

# Menu:
# 1) Analyze project
# 2) Plan complex task
# 3) Implement new feature
# 4) Review existing code
# 5) Security audit
# 6) DevOps

# Select option, enter description
# Wizard confirms before moving to each next phase
# Cancel at any point by responding 'n'
```

---

### Agent Reference

| Agent | Permissions | When to use |
|-------|-------------|-------------|
| `@architect` | read-only | Understand before modifying |
| `@planner` | read-only | Design a plan with verifiable phases |
| `@builder` | edit + bash(ask) | Implement code |
| `@builder-safe` | edit(ask) + bash(ask) | Implement with confirmation before every edit — first-time projects or critical paths |
| `@reviewer` | read-only | Review diff before commit |
| `@security-auditor` | read-only | Find vulnerabilities |
| `@docs-writer` | edit | Generate / update documentation |
| `@devops` | edit + bash | Infrastructure, CI/CD, scripts |
| `@oncall` | bash(ask) | Diagnose and mitigate production issues |
| `@migration-planner` | read-only | Design incremental reversible migrations (schema, service, data) |
| `@performance-profiler` | read-only | Detect N+1, O(n²), blocking I/O, missing indexes |

---

## Quick Commands Reference

```bash
# Natural router (optional)
oc ask "fix the login bug"        # Routes to the likely agent/workflow
oc ask --dry-run "audit release"  # Preview route without running OpenCode
oc ask --clarify "add auth"       # Ask local clarification questions first

# Analysis
oc analyze ~/project      # @architect + project-map
oc plan "complex task"    # @planner
oc build "new feature"    # @builder + test-first
oc review                 # @reviewer + precommit-review

# Specialized (all accept optional context path)
oc secure [path]          # @security-auditor
oc docs [path]            # @docs-writer
oc devops "dockerfile"    # @devops
oc oncall [description]   # @oncall

# Profiles (persists for all following commands)
oc --profile deny         # Maximum restrictive
oc --profile plan         # Planning only
oc --profile trusted      # Direct edits allowed
oc --profile devops       # Infrastructure
oc --list-profiles        # List all available

# Memory
oc --memory "query"                  # Search (Layer 1: fast)
oc --memory "query" -p project -t decision  # Filter by project/type
oc --memory --timeline <obs_id>      # Timeline context (Layer 2)
oc --memory --get <obs_id>           # Full detail (Layer 3)
oc --remember "note"                 # Save to global memory
oc --remember -t bugfix "note"       # Save with type
oc --remember -p project "note"      # Save to project memory
oc --remember -p project -t decision "note"  # Save with project and type

# Session
oc --budget               # Show session turns
oc --compact              # Summarize + reset counter

# Workflows
oc --workflow bug-hunt ~/project              # 5 phases
oc --workflow new-project "my-api"            # 4 phases
oc --workflow debug "error description"       # 3 phases
oc --workflow document ~/project              # 3 phases
oc --workflow feature "add auth" ~/api        # 4 phases

# Direct
oc "any task"             # Sends directly to OpenCode

# Validation
make check                 # Syntax + JSON checks
make test                  # Functional smoke tests
./validate.sh              # Full repo validation
bash install.sh --dry-run  # Safe installation simulation
```

---

## Profiles and Trust Levels

9 profiles with Deny-First gradient. The active profile applies to **all** following `oc` non-interactive commands until changed.

| Profile | Description | Files/iter | Edit | Bash |
|---------|-------------|------------|------|------|
| `deny` | Read-only analysis, zero modifications | 5 | ❌ | ❌ |
| `plan` | Plan and analyze only, no changes | 10 | ❌ | ❌ |
| `review` | Read and report | 15 | ❌ | ask |
| `default` | General development, confirm each change | 3 | ask | ask |
| `work` | Professional work, conservative defaults | 3 | ask | ask |
| `research` | Research and exploration | 10 | ask | ask |
| `auto` | Assisted mode with decision tracking | 5 | ask | ask |
| `trusted` | Advanced developer, direct edits | 10 | ✅ | ✅ |
| `devops` | Infrastructure with mandatory checkpoint | 20 | ✅ | ✅ |

---

## How Profile Enforcement Works

OpenCode does not read these custom profile files as native profiles. The `oc` script reads their `policy` fields and injects them as explicit instructions into every non-interactive `opencode run` prompt. The rules are model-enforced, not an OS sandbox:

```
# Profile: default (requireTests: true, requireExplanation: true)

Your command: oc build "implement pagination"

What the LLM actually receives:
"Use @builder with safe-implementation and test-first. Implement: pagination

[Active profile rules — follow these strictly:]
- Before any change, explain exactly what you will do and why.
- Write or update tests before implementing any change."
```

**Rules enforced via prompt injection:**

| JSON rule | Instruction injected to LLM |
|-----------|------------------------------|
| `reportOnly: true` | Do NOT make file edits or run commands. Report only. |
| `requireExplanation: true` | Before any change, explain what you'll do and why. |
| `requireTests: true` | Write or update tests before implementing any change. |
| `requireDiffReview: true` | Show a summary/diff of all changes before applying. |
| `checkpointBeforeChanges: true` | Summarize current state before making changes. |
| `requireCheckpoint: true` | Create a state checkpoint before any change. |
| `requireRollback: true` | Always provide a rollback plan before any change. |
| `requireSecurityReview: true` | Include security review for every change. |
| `trackDecisions: true` | Document every technical decision with reasoning. |
| `documentAllChanges: true` | Document every change made and why. |
| `allowEnvEdit: false` | Never modify .env files or environment config. |
| `maxFilesPerIteration: N` | Limit changes to N files per iteration. |

This approach requires no fork of OpenCode and works with any model, but native OpenCode permissions still come from the active OpenCode configuration and agent frontmatter.

---

## Memory Bank

Persistent, file-based memory system using progressive disclosure to minimize token usage.

```bash
# Layer 1: Search (~50-100 tokens/result)
oc --memory "docker"
oc --memory "auth" -t decision
oc --memory "auth" -p my-project -t decision

# Layer 2: Timeline (~200 tokens)
oc --memory --timeline 20260501-143022-a1b2c3d4

# Layer 3: Full detail (~500-1000 tokens)
oc --memory --get 20260501-143022-a1b2c3d4

# Create observations
oc --remember "General note"
oc --remember -t bugfix "Fixed JWT expiration bug"
oc --remember -t decision "Chose Redis for sessions"
oc --remember -p my-project -t config "Redis db=1 for sessions"
```

**Observation types:** `note`, `bugfix`, `feature`, `decision`, `config`, `refactor`, `review`, `investigation`

**Observation format:**
```markdown
---
id: obs_20260501-143022-a1b2c3d4
date: 2026-05-01 14:30:22
project: "my-api"
type: "bugfix"
summary: "Fix JWT expiration bug"
tokens_est: 200
---

Full content here...
```

---

## Slash Commands (OpenCode TUI)

Native OpenCode commands usable inside the interactive session (`opencode`). No need for the `oc` wrapper.

```
/analyze          → @architect analysis
/review           → @reviewer + git diff
/secure           → @security-auditor
/feature <desc>   → full workflow: architect → planner → builder → reviewer
/bug-hunt         → 5-phase bug hunt
/docs             → @docs-writer
/devops <desc>    → @devops
/oncall <desc>    → @oncall incident response
```

Install copies these to `~/.config/opencode/commands/` where OpenCode picks them up automatically.

---

## When NOT to Use Automatic Workflows

Do not use `oc --workflow feature` or `/feature` for:

- **First time in the repo** — run `oc analyze` first and review the architecture manually
- **Database migrations** — use `@migration-planner` first, then manual phase-by-phase execution
- **Auth, payments, or permissions** — too critical for single-pass automation
- **Files with `.env`, secrets, or keys** — activate `deny` profile first
- **Production incidents** — use `oc oncall` (interactive) not a workflow
- **Ambiguous requirements** — the workflow will make assumptions; clarify first
- **No tests exist** — add tests before running automated implementation

In those cases: `oc analyze → oc plan → review → oc build`

---

## Workflows

Multi-agent pipelines that execute **all phases in a single OpenCode session**. The model maintains full context between phases — no timeout between calls.

```bash
oc --workflow bug-hunt ~/project              # 5 phases
oc --workflow new-project "my-api"            # 4 phases
oc --workflow debug "error description"       # 3 phases
oc --workflow document ~/project              # 3 phases
oc --workflow feature "add OAuth2" ~/api      # 4 phases (description + path)
```

| Workflow | Phases | Agent chain |
|----------|--------|-------------|
| `bug-hunt` | 5 | architect → security-auditor → planner → builder → reviewer |
| `new-project` | 4 | architect → planner → builder → docs-writer |
| `debug` | 3 | oncall → builder → security-auditor |
| `document` | 3 | architect → docs-writer → reviewer |
| `feature` | 4 | architect → planner → builder → reviewer |

**`feature` workflow takes two arguments:**
```bash
oc --workflow feature "add OAuth2 login" ~/myapi
#                      ↑ description      ↑ path
```

---

## Context Compaction

```bash
oc --budget    # Show current session turns
oc --compact   # Summarize session + reset counter
```

Warning fires automatically when turns > 20.

`--compact` invokes OpenCode with a structured summarization prompt that produces:

- **Goal** — what was the session objective?
- **Findings** — what was analyzed or discovered?
- **Changes Made** — every file modified and why
- **Decisions** — technical decisions with reasoning
- **Current State** — state of the project/task now
- **Remaining Work** — what hasn't been done yet

After `--compact`, save the summary: `oc --remember "session summary: ..."`.

For project-specific continuity:

```bash
oc --remember -p my-project -t note "session summary: ..."
```

---

## Reversibility-Weighted Risk

`@oncall` evaluates actions by reversibility:

| Action | Reversible? | Approval |
|--------|-------------|----------|
| Restart service | ✅ | Minimal |
| Clear cache | ✅ | Minimal |
| Rollback deployment | ✅ | Medium |
| Scale up/down | ✅ | Minimal |
| Edit config (runtime) | ⚠️ | Confirm |
| Delete data | ❌ | +1 reviewer + backup |
| Drop table | ❌ | Emergency protocol |

---

## Security Plugin

`safety-guard.js` blocks destructive commands before execution. It normalizes whitespace before pattern evaluation to prevent trivial bypasses, redacts common secret formats before audit logging, and writes audit logs with restrictive permissions.

The plugin is loaded as ESM via `plugins/package.json` (`type: module`), avoiding Node's `MODULE_TYPELESS_PACKAGE_JSON` warning during validation/tests.

**Blocked patterns:**
- `rm -rf` on critical paths (`/`, `~`, `$HOME`, `${HOME}`, `/home`, `/root`, `/etc`, `/usr`, `/var`, `/bin`) and their subpaths
- quoted/split path variants such as `"$HOME"/.config` and dangerous targets followed by shell separators such as `;`, `&&`, `||`, or `|`
- `mkfs` (filesystem format)
- `dd if=` (direct disk write)
- Fork bomb `:(){ :|:& };:`
- Direct block device writes (`> /dev/sda`)
- Critical file truncation (`> /etc/passwd`, `> /etc/shadow`, `> /etc/sudoers`)
- World-writable recursive `chmod` on system paths

**Audit behavior:**
- logs bash commands to `~/.config/opencode/logs/safety-guard.jsonl`;
- redacts common env tokens, bearer tokens, API key headers, credentialed URLs, and `--token` / `--password` style flags;
- creates the log directory as `0700` and log file as `0600`.

This is a best-effort guardrail, not a sandbox. Native OpenCode permissions, user review, and deterministic scanners still matter.

Recent hardening added smoke coverage for common bypass attempts, including `$HOME` expansion forms, absolute critical subpaths such as `/etc/ssh`, and chained shell commands after a destructive target.

---

## Git Hooks

```bash
# Install hooks for a project
oc --init ~/my-project
# Creates .opencode/opencode.json + .git/hooks/pre-commit + .git/hooks/pre-push

# Or install globally
cp hooks/pre-commit ~/.config/opencode/hooks/
cp hooks/pre-push   ~/.config/opencode/hooks/
```

`pre-commit` runs `@reviewer` with `precommit-review` before every commit. It passes the staged diff explicitly and blocks unless the output contains the exact line `BLOCKING_FINDINGS=false`.

`pre-push` runs `@security-auditor` before push. It passes a diff against upstream when available and blocks unless the output contains `BLOCKING_FINDINGS=false`.

If `gitleaks` is installed, both hooks run it before the LLM-assisted review. If it is not installed, hooks continue with the fail-closed LLM gate.

---

## Validation and Tests

```bash
make check
make test
./validate.sh
bash install.sh --dry-run
git diff --check
```

`./validate.sh` covers:

- required files/directories, agents, commands, skills;
- JSON syntax, including `plugins/package.json`;
- shell syntax for `oc`, installer, uninstaller, validator, and hooks;
- plugin JavaScript syntax with Node when available;
- legacy OpenCode CLI calls (`opencode -p`, `opencode --profile`);
- profile permission actions (`ask|allow|deny`);
- model-free agents and language-artifact scan;
- documentation consistency against `VERSION`, 9 profiles, 11 agents, 6 skills;

Functional smoke tests are run separately with `make test` and in CI. They cover:

- memory search, including project/type filters and multi-word queries;
- `--remember`, timeline lookup, and valid JSONL memory index writes;
- session tracking, including clean-home startup and corrupt `.session` recovery;
- hooks fail-closed marker behavior;
- profiles list/switch validation;
- `oc ask` natural-language routing and prompt generation;
- `oc --init`, `--compact`, `--doctor`, and installed fixture validation;
- installer dry-run and uninstaller missing-backup behavior;
- safety guard destructive-command blocking, secret redaction, and log permissions.

---

## Souls / Personas

Predefined personas in `souls/souls.md`:

- `senior-developer` — 15+ years, clean and tested code, no hacky solutions
- `security-auditor` — CISSP/CEH, zero-trust mindset
- `devops-sre` — Infrastructure as Code, SLOs, blameless post-mortems
- `code-reviewer` — strict standards, specific actionable comments
- `tech-lead` — team of 5-20, architecture, risk communication

---

## Project Structure

```
opencode-global-config/
├── oc                       # Main script — profile enforcement, workflows, memory
├── VERSION                  # Version source checked by validate.sh
├── agents/
│   ├── architect.md         # Read-only, risk analysis, tradeoff declarations
│   ├── planner.md           # Success criteria, verifiable phases
│   ├── builder.md           # Karpathy principles (4 rules)
│   ├── builder-safe.md      # Conservative builder with confirmation
│   ├── reviewer.md
│   ├── security-auditor.md
│   ├── docs-writer.md
│   ├── devops.md
│   ├── oncall.md            # Reversibility-weighted risk, P1/P2/P3 classification
│   ├── migration-planner.md # Incremental reversible migration plans
│   └── performance-profiler.md # N+1, O(n²), blocking I/O, missing indexes
├── skills/
│   ├── project-map/         # Project structure analysis
│   ├── safe-implementation/ # Minimal, verifiable changes
│   ├── test-first/          # Goal-Driven Execution
│   ├── precommit-review/    # Diff review before commit
│   ├── memory-retrieval/    # 3-layer progressive disclosure
│   └── docs-writer/         # Technical documentation
├── rubrics/
│   ├── code-review.md       # Blocking criteria and evidence for reviews
│   ├── security-review.md   # Security severities and remediation gate
│   └── plan-review.md       # Verifiable planning and design criteria
├── plugins/
│   ├── safety-guard.js      # Regex hardening, redacted audit log
│   └── package.json         # ESM metadata for plugin loading/tests
├── memory/
│   ├── INDEX.md
│   ├── ARCHITECTURE.md
│   ├── projects/
│   ├── decisions/
│   └── patterns/
├── profiles/                # 9 deny-first profiles
│   ├── deny.json
│   ├── plan.json
│   ├── review.json
│   ├── default.json
│   ├── auto.json
│   ├── trusted.json
│   ├── devops.json
│   ├── research.json
│   └── work.json
├── souls/
│   └── souls.md
├── hooks/
│   ├── pre-commit
│   └── pre-push
├── tests/
│   └── run.sh               # Functional smoke tests
├── CLAUDE.md                # Compact system context (40 lines)
├── AGENTS.md                # Intent mapping + 4 Karpathy principles
├── README.md                # English documentation (this file)
├── README.es.md             # Spanish documentation
├── INSTALL.md
├── CHANGELOG.md
├── CONTEXTO_PROYECTO.md     # Living project context / change log
└── LICENSE
```

---

## Inspiration

### Claude Code Architecture Analysis
- [VILA-Lab/Dive-into-Claude-Code](https://github.com/VILA-Lab/Dive-into-Claude-Code) — "98.4% infrastructure, 1.6% AI"
- [Piebald-AI/claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts)

### Karpathy Guidelines
- [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)

### Memory Systems
- [kunickiaj/codemem](https://github.com/kunickiaj/codemem)
- [swarmclawai/swarmvault](https://github.com/swarmclawai/swarmvault)

### Skills & Plugins
- [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills)

---

## Changelog

### Unreleased Bug-Hunt Hardening

#### Safety and Reliability Fixes

- **`plugins/safety-guard.js`**: blocks additional destructive `rm -rf` variants using `$HOME`, `${HOME}`, quoted HOME paths, critical absolute subpaths (`/home/*`, `/etc/*`, `/var/*`, `/root/*`), and chained shell separators after dangerous targets.
- **`oc`**: `track_turn` now creates the config directory when needed and recovers from corrupt `.session` values instead of failing arithmetic expansion.
- **`oc --memory`**: multi-word searches without flags now use the full query instead of accidentally treating later words as project/type positional arguments.
- **`install.sh`**: uses `mktemp -d` for clone workspace creation and colon-delimited PATH matching to avoid substring false positives.
- **`uninstall.sh`**: prints restore instructions only when a backup was actually created.
- **`tests/run.sh`**: adds regression coverage for all fixes above.

---

### v1.9.4 (2026-05-02)

#### Release Readiness

- **`tests/run.sh`**: expanded functional smoke tests for memory project/type filters, `--remember`, timeline, profiles, fail-closed hooks, `oc --init`, `--compact`, `--doctor`, `validate.sh --installed`, installer dry-run, and safety guard.
- **`VERSION`**: added a simple version source checked by `validate.sh`.
- **`validate.sh`**: documentation consistency checks for version, 9 profiles, 11 agents, 6 skills, and memory project flag support.
- **`rubrics/`**: added code review, security review, and plan review gates; validator checks required rubric files.
- **`plugins/package.json`**: declares plugin JavaScript as ESM and removes Node's typeless-module warning.
- **Hooks**: pass explicit diffs, require `BLOCKING_FINDINGS=false`, and run optional `gitleaks` when available.
- **`oc --init`**: generates both `pre-commit` and `pre-push` fail-closed hooks.

#### Release Notes

- Adds reusable code/security/plan review rubrics inspired by `dsifry/metaswarm` without adding multi-CLI orchestration complexity.
- Strengthens installed-config validation so missing rubrics fail `validate.sh --installed` and `oc --doctor`.
- Keeps release gates green through expanded smoke tests, shell validation, plugin syntax checks, and CI.

---

### v1.9.3 (2026-05-01)

#### OpenCode 1.14 Compatibility

- **`oc`: migrate `_oc_run()` to `opencode run`** — `opencode -p` was removed in OpenCode 1.14; all internal calls and hooks now use `opencode run "<prompt>"`. Without this fix, all profile enforcement and hooks were silently broken.
- **`oc`: remove `opencode --profile` flag** — not supported by OpenCode; profiles are enforced exclusively via prompt injection in `_oc_run()`
- **`hooks/pre-commit`, `hooks/pre-push`**: migrated to `opencode run`

#### Fixes

- **`profiles/auto.json`**: `edit: auto, bash: auto` → `edit: ask, bash: ask` — `auto` is not a valid permission value (`ask|allow|deny` only)
- **`install.sh --dry-run`**: now exits immediately after printing the plan — previously ran requirement checks first, violating the dry-run contract
- **`install.sh`**: banner updated to v1.9.3

#### Validation Hardening

- **`validate.sh`**: detects legacy `opencode -p` / `opencode --profile` calls — CI catches regressions to the old API
- **`validate.sh`**: profile permission validator (Python) — checks all `profiles/*.json` for invalid action values
- **`validate.sh`**: `opencode.strict.json` added to JSON validation loop
- **`.github/workflows/validate.yml`**: shellcheck on `validate.sh`; artifact scan extended to `skills/`
- **`README.md`, `README.es.md`, `INSTALL.md`**: corrected version counts, obsolete CLI commands, install snippets

---

### v1.9.2 (2026-05-01)

#### validate.sh Hardening

- **Line count sanity check** — fails if `install.sh`, `oc`, `validate.sh`, `uninstall.sh`, or `Makefile` have fewer than 5 lines (detects accidental minification)
- **Markdown frontmatter validation** — verifies all `agents/*.md` and `commands/*.md` have valid multi-line YAML frontmatter (`---` on first line + closing fence)
- **Language artifact scan extended** — covers `skills/` directory; adds `发现问题` to pattern list

#### Makefile

- **`format` target** — `shfmt` on all shell scripts + `jq` pretty-print on all JSON configs; graceful if `shfmt` not installed
- **`check` target** — adds `jq empty opencode.strict.json`

---

### v1.9.1 (2026-05-01)

- **`.editorconfig`** — UTF-8, LF, 2-space indent, final newline, no trailing whitespace
- **`Makefile`** — targets: `validate`, `check`, `install`, `dry-run`, `uninstall`, `doctor`
- **`opencode.strict.json`** — paranoid profile: `webfetch: deny`, `websearch: deny`, `external_directory: deny`
- **`@builder-safe`** — new conservative agent with `edit: ask, bash: ask`; same logic as `@builder` but confirms before every edit

---

### v1.9 (2026-05-01)

#### Native OpenCode Config

- **`opencode.json` hardened** — `read/list/glob/grep: allow`, `edit/bash/webfetch/websearch: ask`; `autoupdate: false`; `watcher.ignore` list for common build artifacts; now also loads `CLAUDE.md` as instruction
- **Profiles restructured** — each profile now has declarative `opencode.permission` metadata validated by this repo + `policy` rules injected via prompt. Native OpenCode enforcement still comes from OpenCode config and agent frontmatter
- **`get_profile_rules()` reads `policy` key** — backwards-compatible (falls back to `rules` if `policy` absent)

#### Official Slash Commands (`commands/`)

8 slash commands usable directly in OpenCode's TUI (`/analyze`, `/review`, `/secure`, `/feature`, `/bug-hunt`, `/docs`, `/devops`, `/oncall`). These are native OpenCode commands — work without `oc`, inside the interactive session.

#### New Agents

- **`@migration-planner`** — designs incremental, reversible migration plans (schema, service, data); read-only
- **`@performance-profiler`** — detects N+1 queries, O(n²) algorithms, blocking I/O, missing indexes; read-only

#### Quality & Safety

- **`validate.sh`** — validates full repo structure: files, dirs, agents, commands, skills, JSON, bash syntax, model-free agents, no foreign-language artifacts. Run: `./validate.sh` or `./validate.sh --installed`
- **`uninstall.sh`** — safe uninstaller that backs up config before removal. Run: `bash uninstall.sh`
- **`install.sh --dry-run`** — simulate installation without touching files: `bash install.sh --dry-run`
- **`safety-guard.js` audit log** — bash commands logged to `~/.config/opencode/logs/safety-guard.jsonl` with redaction and restrictive file permissions
- **`oc --doctor`** — diagnoses installation health: checks opencode, oc, config files, dirs, JSON validity, fzf, active profile, audit log
- **GitHub Actions CI** — `.github/workflows/validate.yml`: runs `validate.sh`, shellcheck, agent model check, language artifact check on every push/PR

#### Developer Experience

- **`oc --init` stack detection** — `detect_stack()` identifies Node.js, Python, Rust, Go, Java, Docker, Terraform from project files; `detect_test_commands()` infers test commands; generated `CLAUDE.md` includes detected context
- **Memory JSONL index** — `create_observation()` now also writes to `memory/index.jsonl` for fast querying with `jq`, `fzf`, or `ripgrep`

---

### v1.8 (2026-05-01)

#### Profile Enforcement via Prompt Injection

Profiles previously stored rules like `requireTests: true` that OpenCode never read. Now the `oc` script reads the active profile JSON and injects the rules as explicit LLM instructions on every call.

- **`get_profile_rules()`** — reads active profile JSON, generates English instructions for the model
- **`_oc_run()` injects rules** — every prompt passing through `_oc_run()` automatically receives active profile constraints
- **Rules enforced**: `requireTests`, `requireExplanation`, `requireDiffReview`, `checkpointBeforeChanges`, `requireRollback`, `requireSecurityReview`, `trackDecisions`, `documentAllChanges`, `allowEnvEdit`, `maxFilesPerIteration`, `reportOnly`
- **Profiles cleaned** — removed `model`, `temperature`, `agents.default` (none read by OpenCode); removed reference to non-existent `@explore`/`@general` agents from `research.json`

#### Agents — Free Model Selection

- **Removed `model: minimax-coding-plan/MiniMax-M2.7`** from all 8 agents — OpenCode uses whatever model the user has selected; no hardcoded model

#### Language Standardization

- **All foreign-language LLM artifacts corrected**: `No容忍` → `Zero tolerance for`, `基础设施` → `Infrastructure`, `средний` → `medium`, `迁移` → `migration`, `報告ar` → `report`

#### Quality of Life

- **`quick_secure/review/docs/oncall` accept context argument** — e.g. `oc secure src/api/` audits a specific path
- **`--compact` is real** — invokes OpenCode with structured summarization prompt; counter resets after
- **`memory/ARCHITECTURE.md` is honest** — removed fictional "5-layer compaction pipeline" table; replaced with actual system documentation

#### Bilingual Documentation

- **`README.md`** — English version (international standard)
- **`README.es.md`** — Spanish version

---

### v1.7.1 (2026-05-01)

Cross-platform hardening: `install.sh` cleanup on failure via `trap EXIT`, `opencode.json` with real `$HOME` (not `~`), macOS full PATH support (`.bash_profile`, `.zshrc`, fish), POSIX `od` instead of `xxd` for ID generation, cleaned LLM artifacts from `CLAUDE.md`, fixed nested code fences in `docs-writer/SKILL.md`.

---

### v1.7 (2026-05-01)

Critical `oc` script fixes: removed `set -e` (caused silent exit on `search_memory`/`check_budget`), fixed `local` outside functions in `case` blocks, fixed `feature` workflow description capture, fixed fzf parsing with clean option list, fixed `generate_obs_id` timestamp collisions, removed fake `<private>` placeholder.

Profile propagation functional: `switch_profile` exports `OPENCODE_PROFILE`; `_oc_run()` wrapper passes active profile to all opencode calls. Security plugin upgraded with regex + whitespace normalization. 5 single-pass workflows implemented.

---

### v1.5 — v1.6 (2026-05-01)

Workflow system: 5 pipelines, `--interactive` flag for phase confirmation, single-pass refactor.

---

### v1.4 (2026-05-01)

3-layer memory retrieval, observation format, auto-capture functions, privacy tags.

---

### v1.3 (2026-05-01)

7 deny-first profiles, reversibility-weighted risk in `@oncall`, context budget tracking.

---

### v1.2 (2026-05-01)

4 Karpathy principles integrated into builder, planner, test-first skill.

---

### v1.1 (2026-05-01)

Interactive wizard, fzf menu, Memory Bank, Souls/Personas, 3 profiles, git hooks, quick commands, `oc init`.

---

### v1.0 (2026-05-01)

Initial release — 8 agents, 5 skills, safety plugin, `oc` command.

---

## License

MIT
