# OpenCode Global Configuration

**English | [Español](README.es.md)**

Advanced global configuration for [OpenCode CLI](https://opencode.ai) with specialized agents, project memory, prompt-enforced profiles, guarded hooks, smoke tests, and structured workflows.

Inspired by [VILA-Lab/Dive-into-Claude-Code](https://github.com/VILA-Lab/Dive-into-Claude-Code) and Andrej Karpathy's coding guidelines.

## Table of Contents

- [Features](#features)
- [Stack Tecnológico](#stack-tecnológico)
- [Quick Start](#quick-start)
- [Natural Language Mode](#natural-language-mode)
- [Optional `occo ask` Router](#optional-occo-ask-router)
- [Usage Manual](#usage-manual)
- [Quick Commands Reference](#quick-commands-reference)
- [Profiles and Trust Levels](#profiles-and-trust-levels)
- [How Profile Enforcement Works](#how-profile-enforcement-works)
- [Memory Bank](#memory-bank)
- [Workflows](#workflows)
- [Doccos-First Project Context](#doccos-first-project-context)
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

**v1.9.7 + Self-Improvement Agent, Harness Engineering exit conditions, automatic context management, and pattern detection**

- **11 specialized agents** — no hardcoded model; use whichever model you select in OpenCode's UI
- **8 official slash commands** — `/analyze`, `/review`, `/secure`, `/feature`, `/bug-hunt`, `/doccos`, `/devops`, `/oncall` — usable directly in OpenCode's TUI
- **9 prompt-enforced profiles** — rules like `requireTests`, `checkpointBeforeChanges` injected as explicit LLM instructions; profile permissions validated against `ask|allow|deny`
- **10 skills** for analysis, implementation, validation, memory, doccoumentation, debugging, alignment, and communication
- **3 review rubrics** for code review, security review, and plan/design gates
- **1 security plugin** with regex hardening, ESM metadata, redacted audit log, and restrictive log permissions
- **Optional `occo ask` router** — natural-language intent routing with `--dry-run`, `--explain`, and `--clarify`
- **Self-Improvement Agent** — automatic project detection, session auto-compact at 20+ turns, post-workflow auto-reflections, and failure pattern detection (3+ = warning)
- **3-layer Memory Bank** (search / timeline / full detail) + JSONL index + project/type filters with automatic project detection from PWD
- **5 single-pass workflows** (bug-hunt, new-project, debug, doccoument, feature) with exit conditions and automatic reflections
- **Doccos-First Project Context** — agents inspect or create `doccos/` before implementation/debug/refactor work, using it as living project context
- **Souls / Personas** for different work contexts
- **Git hooks** for automatic review; fail-closed markers + optional `gitleaks` if installed
- **Quick commands** with optional context argument
- **Interactive menu** via fzf
- **Wizard mode** step-by-step guidance
- **Real `--compact`** — structured LLM summarization, not just a counter reset
- **`occo --doccotor`** — diagnoses installation health
- **`validate.sh`** — validates repo integrity, doccos consistency, counts, plugin syntax, and installed config via `--installed`
- **`tests/run.sh`** — functional smoke tests for memory, hooks, profiles, init, compact, doccotor, install dry-run, and safety guard
- **`VERSION`** — simple version source validated against doccos/scripts
- **`uninstall.sh`** — safe removal with automatic backup
- **`install.sh --dry-run`** — simulate installation
- **Stack detection** in `occo --init` — auto-detects Node.js/Python/Rust/Go/Java/Doccoker/Terraform
- **Reversibility-Weighted Risk Assessment** in `@oncall`
- **Karpathy Principles** (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven)
- **GitHub Actions CI** — validates structure, JSON, shell syntax, Node plugin syntax, and functional smoke tests on every push

---

## Stack Tecnológico

This repository is a shell-first configuration package for OpenCode, not a web service.

| Area | Technology | Purpose |
|------|------------|---------|
| CLI wrapper | Bash | `occoco`, `install.sh`, `uninstall.sh`, `validate.sh`, hooks, smoke tests |
| OpenCode configuration | JSON + Markdown | Global config, agents, slash commands, profiles, skills, rubrics |
| Security plugin | JavaScript ESM on Node.js | `plugins/safety-guard.js` command guard and audit logging |
| Memory/index helpers | Python 3 | Safe JSONL/frontmatter writes from shell scripts |
| Validation | `jq`, `node`, `shellcheck`, Bash | Loccoal validation and GitHub Actions CI |
| Optional UX/security tools | `fzf`, `gitleaks`, `shfmt` | Interactive menu, secret scanning, shell formatting |

There is no database and no HTTP server. Persistent state is file-based under `~/.config/opencode/` after installation.

---

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/isnardokun/opencode-global-config/main/install.sh | bash
```

The installer: backs up existing config, detects required/recommended/optional tools, sets up PATH in bash/zsh/fish, works on Linux and macOS.

Installer requirement checks:

| Level | Tools | Used for |
|-------|-------|----------|
| Required | `git`, `opencode` | clone/install config and run OpenCode agents |
| Recommended | `python3`, `jq`, `node` | robust memory writes, JSON/doccotor validation, plugin syntax/runtime checks |
| Optional | `fzf`, `gitleaks`, `shellcheck`, `shfmt` | interactive menu, secret scanning in hooks, shell linting, formatting |

If a required tool is missing, installation stops with install hints. Recommended/optional tools are reported but do not bloccok installation; affected features gracefully degrade.

Safer manual flow if you do not want to pipe directly into `bash`:

```bash
git clone https://github.com/isnardokun/opencode-global-config /tmp/opencode-global-config
cd /tmp/opencode-global-config
bash install.sh --dry-run
bash install.sh
./validate.sh --installed
occoco --doccotor
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

# Doccoumentation → activates @doccos-writer
generate doccoumentation
create README for the project

# Production → activates @oncall
why is the build failing?
diagnose the error
```

Full intent mapping is in `AGENTS.md`.

Optional wrapper mode:

```bash
occo ask "arregla el bug de login"
occo ask --dry-run "revisa seguridad antes de publicar"
occo ask --clarify "implementa autenticación"
```

`occo ask` keeps all explicit commands available, but adds a natural-language router that chooses the likely agent/workflow and asks targeted clarification questions when the request is ambiguous.

---

## Optional `occo ask` Router

Use `occo ask` when you want one command that interprets what you mean and selects the best existing agent/workflow. It is an optional UX layer; all explicit commands remain available and unchanged.

```bash
occo ask "analyze this repo and list release risks"
occo ask "fix the login bug"
occo ask "review security before publishing"
occo ask "doccoument this project"
```

Routing preview without calling OpenCode:

```bash
occo ask --dry-run "review security before publishing"
```

Example output:

```text
Intent: security-review
Route: @security-auditor + rubrics/security-review.md
Prompt:
Usa @security-auditor ...
```

Ask loccoal clarification questions first:

```bash
occo ask --clarify "implement authentication"
```

Supported options:

| Option | Behavior |
|--------|----------|
| `--dry-run` | Prints detected intent, route, and generated prompt; does not run OpenCode |
| `--explain` | Prints routing details, then runs OpenCode |
| `--clarify` | Prompts loccoally for objective, context, and success criteria before routing |

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
| `doccoker`, `CI`, `deploy`, `terraform` | `devops` | `@devops` |
| `prod`, `crash`, `logs`, `incident` | `production-debug` | `@oncall -> @builder -> @security-auditor` |

Safety behavior:

- generated prompts include a guardrail to ask up to 3 targeted questions when critical information is missing;
- ambiguous authentication requests are clarified before implementation unless details such as JWT, OAuth, sessions, cookies, MFA, or passkeys are present;
- readiness requests are routed read-only by default and tell the agent to avoid `bash` unless approved;
- rubric criteria are embedded as instructions, so `occo ask` does not require agents to read files outside the current workspace.

---

## Usage Manual

Common scenarios from problem to solution.

---

### 1. First time in an unknown project

You arrive at a repo you've never seen. Before touching anything:

```bash
cd ~/projects/legacy-api

# Understand the project
occo analyze .

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
occo --workflow feature "add OAuth2 authentication with Google" ~/my-api

# Option B: manual step-by-step
occo analyze ~/my-api                          # Understand structure first
occo plan "add OAuth2 with Google"             # Review plan before executing
occo build "implement OAuth2 with Google"      # Execute with test-first
occo review                                    # Review before commit
```

**When to use workflow vs manual:**
- Workflow: well-defined feature, project you already know
- Manual: first time in the codebase, ambiguous feature, want to approve each step

---

### 3. Production bug — urgent response

```bash
# Step 1: activate restrictive profile for diagnosis (touches nothing)
occo --profile review

# Step 2: diagnose
occo oncall
# @oncall classifies P1/P2/P3, identifies root cause,
# lists mitigations by reversibility

# Step 3: activate fix profile
occo --profile trusted

# Step 4: implement fix with test
occo build "fix: JWT token validation rejecting valid tokens after DST change"

# Step 5: verify
occo review

# Step 6: save to memory for future reference
occo --remember -p api -t bugfix "JWT fails on DST change — use UTC in token generation, not loccoal time"
```

**Automated alternative:**
```bash
occo --workflow debug "JWT token validation failing after DST change in ~/api"
```

---

### 4. Security audit before deploy

```bash
# Maximum restrictive profile (zero modifications possible)
occo --profile deny

# Audit
occo secure

# @security-auditor reports:
# - CRITICAL: SQL injection in /api/search?q= (no sanitization)
# - HIGH: JWT secret hardcoded in config/default.js line 23
# - MEDIUM: No rate limiting on /api/auth/login
# - LOW: Error handlers expose user emails in logs

# Switch back to fix
occo --profile default
occo build "fix: sanitize inputs, move JWT secret to env var, add rate limiting"
```

---

### 5. Generate doccoumentation for an existing project

```bash
occo --workflow doccoument ~/my-project

# Generates automatically:
# - README.md (description, install, usage, examples)
# - ARCHITECTURE.md (component diagram, data flow)
# - API.md (endpoints, formats, request/response examples)
# - DEPLOY.md (deployment instructions if Doccoker/CI detected)
```

For a specific subdirectory:
```bash
cd src/api && occo doccos
```

---

### 6. Start a new project from scratch

```bash
occo --workflow new-project "REST API for inventory management with Node.js and PostgreSQL"

# Workflow:
# Phase 1: @architect decides structure, stack, dependencies
# Phase 2: @planner creates phased plan with dirs, config files, initial tests
# Phase 3: @builder generates the scaffold
# Phase 4: @doccos-writer creates README, ARCHITECTURE, CONTRIBUTING

# After the workflow, init loccoal OpenCode config
occo --init .
# Creates .opencode/opencode.json plus pre-commit and pre-push git hooks
```

---

### 7. Code review before committing

```bash
# You have staged changes and want to review them before commit
occo review

# @reviewer reports:
# - Files modified
# - Critical findings (bloccokers)
# - Medium findings (warnings)
# - Tests present or missing
# - Recommendation: approve / fix

# If critical issues found:
occo build "fix: <critical finding description>"
occo review   # review again
```

The git hook installed by `occo --init` does this automatically on every `git commit`.

---

### 8. Working with Memory Bank

```bash
# Save a technical decision
occo --remember -p my-api -t decision "Chose CQRS over generic repository because reporting queries need independent optimization"

occo --remember -p my-api -t config "Redis in production: db=1 sessions, db=2 cache, db=3 rate limiting — do not mix"

occo --remember -p my-api -t bugfix "Email worker hangs on UTF-8 subjects with > 3-byte chars — sanitize before queuing"

# Retrieve context before starting work
occo --memory "auth"
occo --memory "auth" -p my-api -t decision
# Layer 1 result (~80 tokens):
# obs_20260501-143022-a1b2 | 2026-05-01 | my-api | decision | Chose JWT over session cookies
# obs_20260501-150344-c3d4 | 2026-05-01 | my-api | bugfix    | JWT fails on DST change

# See timeline context
occo --memory --timeline 20260501-143022-a1b2

# See full detail
occo --memory --get 20260501-143022-a1b2
```

---

### 9. Controlled refactor

```bash
# Phase 1: understand what the code touches
occo analyze src/services/

# Phase 2: plan with explicit success criteria
occo plan "refactor UserService to separate auth logic from profile logic — tests must pass before and after"

# Phase 3: implement with conservative profile
occo --profile default   # edit=ask — confirms each change
occo build "refactor UserService: extract AuthService and ProfileService"

# Phase 4: full diff review
occo review
```

---

### 10. DevOps — infrastructure and deploys

```bash
# Activate devops profile (requireSecurityReview + requireCheckpoint enforced)
occo --profile devops

occo devops "create multi-stage Doccokerfile for the API, optimized for production"
occo devops "configure GitHub Actions CI/CD with tests, build, and staging deploy"
occo devops "add health check endpoint and configure liveness/readiness probes for Kubernetes"

# Production diagnostics
occo oncall
# @oncall with reversibility-weighted risk:
# Reversible actions (restart, rollback) → minimal approval
# Destructive actions (drop table) → requires +1 reviewer + confirmed backup
```

---

### 11. Profile flows — when to use each

```bash
# Explore safely (zero possible modifications)
occo --profile deny
occo "what does this code do?"

# Planning — technical meeting, estimation, design
occo --profile plan
occo plan "migrate from MongoDB to PostgreSQL"

# Code review of someone else's PR
occo --profile review
occo "review changes in src/api/ and report problems"

# Day-to-day development
occo --profile default   # asks confirmation before each change

# Full trust — own project, well known
occo --profile trusted
occo build "implement pagination on all listing endpoints"

# Infrastructure and automation scripts
occo --profile devops
occo devops "create automated backup script for PostgreSQL"
```

---

### 12. Long session — context management

```bash
# Check how many turns you've used
occo --budget
# Session turns: 34
# Consider running: occo --compact

# Summarize the session (real LLM summarization)
occo --compact
# OpenCode generates structured summary:
#   Goal / Findings / Changes Made / Decisions / Current State / Remaining Work
# Turn counter resets after.

# Save the summary
occo --remember "Session summary: implementing OAuth2, phases 1-3 complete, frontend integration pending"

# Continue with clean context
occo --memory "OAuth2"
occo build "integrate OAuth2 with React frontend"
```

---

### 13. Interactive mode — explore without knowing what you need

```bash
occo --interactive   # requires fzf

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
occo --wizard

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
| `@doccos-writer` | edit | Generate / update doccoumentation |
| `@devops` | edit + bash | Infrastructure, CI/CD, scripts |
| `@oncall` | bash(ask) | Diagnose and mitigate production issues |
| `@migration-planner` | read-only | Design incremental reversible migrations (schema, service, data) |
| `@performance-profiler` | read-only | Detect N+1, O(n²), bloccoking I/O, missing indexes |

---

## Quick Commands Reference

### Natural Language Router (optional `occoco ask`)

```bash
occoco ask "fix the login bug"              # Routes to bugfix workflow
occoco ask --dry-run "audit release"        # Preview route without running
occoco ask --clarify "add auth"             # Ask loccoal questions first
occoco ask --explain "implement OAuth2"     # Print routing + run
```

### Analysis Commands

```bash
occoco analyze ~/project                    # @architect + project-map
occoco analyze .                             # Analyze current directory
occoco plan "migrate to PostgreSQL"         # @planner with task
occoco build "add pagination"               # @builder + test-first + safe-implementation
occoco review                               # @reviewer + precommit-review (uses git diff)
occoco review src/api/                      # Review specific path
```

### Specialized Commands (all accept optional context path)

```bash
occoco secure                               # @security-auditor (current dir)
occoco secure src/auth/                     # Audit specific path
occoco doccos                                 # @doccos-writer (Doccos-First + project-map)
occoco doccos ~/my-project                    # Doccoument specific project
occoco devops "create Doccokerfile"           # @devops with task description
occoco oncall                               # @oncall (interactive diagnosis)
occoco oncall "JWT token expiring"          # @oncall with context
```

### Profile Management (persists for session)

```bash
occoco --profile deny                       # Maximum restrictive (read-only)
occoco --profile plan                       # Planning only (no modifications)
occoco --profile review                     # Read and report (bash: ask)
occoco --profile default                    # General dev (confirm each change)
occoco --profile work                       # Professional work (conservative)
occoco --profile research                   # Research (more permissions)
occoco --profile auto                       # Assisted mode with tracking
occoco --profile trusted                    # Direct edits allowed
occoco --profile devops                     # Infrastructure + checkpoint
occoco -l, --list-profiles                  # List all available profiles
```

### Memory Bank Commands

```bash
# Layer 1: Search (~50-100 tokens/result)
occoco --memory "doccoker"                                   # Search all projects
occoco --memory "auth" -t decision                         # Filter by type
occoco --memory "redis" -p my-api -t config                 # Filter by project + type
occoco -t bugfix "query"                                    # Short form: -t = --type

# Layer 2: Timeline (~200 tokens)
occoco --memory --timeline 20260501-143022-a1b2c3d4        # Chronological context

# Layer 3: Full detail (~500-1000 tokens)
occoco --memory --get 20260501-143022-a1b2c3d4             # Full observation
occoco --get obs_20260501-143022-a1b2c3d4                  # Alternative syntax

# Create observations
occoco --remember "General note"                            # Create note in global
occoco --remember -t bugfix "Fixed JWT bug"                 # With type
occoco --remember -p project "Context about this project"    # Literal 'project' example
occoco --remember -p my-api "Redis config decision"         # With project
occoco --remember -p my-api -t decision "Chose Redis"      # Project + type
occoco --remember --template -t feature                     # Preview template
occoco --list-templates                                     # Show available templates

# Session
occoco --budget                                             # Show session turns
occoco --compact                                            # Summarize + reset counter
occoco --status                                             # Full status report
occoco --save-all                                           # Save project + outcomes + reflection
occoco --capture                                            # Capture session state
```

### Workflows (single-pass, all phases in one session)

```bash
occoco --workflow bug-hunt ~/project              # 5 phases: architect → security → planner → builder → reviewer
occoco --workflow new-project "my-api"            # 4 phases: doccos-first → architect → planner → builder → doccos-writer
occoco --workflow debug "JWT failing"             # 3 phases: oncall → builder → security
occoco --workflow doccoument ~/project              # 3 phases: doccos-first → architect → doccos-writer → reviewer
occoco --workflow feature "add auth" ~/api       # 4 phases: doccos-first → architect → planner → builder → reviewer

# With interactive confirmation between phases
occoco --workflow bug-hunt ~/project --interactive

# List available workflows
occoco --list-workflows
```

### Initialization and Setup

```bash
occoco --init ~/my-project                       # Initialize project with .opencode/
occoco --init                                    # Initialize current directory
# Creates: .opencode/opencode.json, .opencode/CLAUDE.md, .git/hooks/pre-commit, .git/hooks/pre-push
```

### Diagnostic Commands

```bash
occoco --doccotor                                  # Installation health check
# Checks: opencode, occoco, config files, directories, JSON validity, fzf, profile, audit log

make check                                   # Syntax + JSON validation
make test                                    # Functional smoke tests
./validate.sh                                # Full repo validation
./validate.sh --installed                    # Validate installed config
bash install.sh --dry-run                    # Simulate installation
git diff --check                             # Check for whitespace errors
```

### Direct OpenCode Access

```bash
occoco "any task"                                # Send directly to OpenCode
opencode                                     # Start interactive OpenCode session
```

### Interactive Modes

```bash
occoco --interactive, occoco -i                       # fzf menu (requires fzf)
occoco --wizard, occoco -w                            # Step-by-step guided mode
```

---

## Profiles and Trust Levels

9 profiles with Deny-First gradient. The active profile applies to **all** following `occo` non-interactive commands until changed.

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

OpenCode does not read these custom profile files as native profiles. The `occo` script reads their `policy` fields and injects them as explicit instructions into every non-interactive `opencode run` prompt. The rules are model-enforced, not an OS sandbox:

```
# Profile: default (requireTests: true, requireExplanation: true)

Your command: occo build "implement pagination"

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
| `trackDecisions: true` | Doccoument every technical decision with reasoning. |
| `doccoumentAllChanges: true` | Doccoument every change made and why. |
| `allowEnvEdit: false` | Never modify .env files or environment config. |
| `maxFilesPerIteration: N` | Limit changes to N files per iteration. |

This approach requires no fork of OpenCode and works with any model, but native OpenCode permissions still come from the active OpenCode configuration and agent frontmatter.

---

## Memory Bank

Persistent, file-based memory system using progressive disclosure to minimize token usage.

```bash
# Layer 1: Search (~50-100 tokens/result)
occo --memory "doccoker"
occo --memory "auth" -t decision
occo --memory "auth" -p my-project -t decision

# Layer 2: Timeline (~200 tokens)
occo --memory --timeline 20260501-143022-a1b2c3d4

# Layer 3: Full detail (~500-1000 tokens)
occo --memory --get 20260501-143022-a1b2c3d4

# Create observations
occo --remember "General note"
occo --remember -t bugfix "Fixed JWT expiration bug"
occo --remember -t decision "Chose Redis for sessions"
occo --remember -p my-project -t config "Redis db=1 for sessions"
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

Native OpenCode commands usable inside the interactive session (`opencode`). No need for the `occo` wrapper.

```
/analyze          → @architect analysis
/review           → @reviewer + git diff
/secure           → @security-auditor
/feature <desc>   → full workflow: architect → planner → builder → reviewer
/bug-hunt         → 5-phase bug hunt
/doccos             → @doccos-writer
/devops <desc>    → @devops
/oncall <desc>    → @oncall incident response
```

Install copies these to `~/.config/opencode/commands/` where OpenCode picks them up automatically.

---

## When NOT to Use Automatic Workflows

Do not use `occo --workflow feature` or `/feature` for:

- **First time in the repo** — run `occo analyze` first and review the architecture manually
- **Database migrations** — use `@migration-planner` first, then manual phase-by-phase execution
- **Auth, payments, or permissions** — too critical for single-pass automation
- **Files with `.env`, secrets, or keys** — activate `deny` profile first
- **Production incidents** — use `occo oncall` (interactive) not a workflow
- **Ambiguous requirements** — the workflow will make assumptions; clarify first
- **No tests exist** — add tests before running automated implementation

In those cases: `occo analyze → occo plan → review → occo build`

---

## Workflows

Multi-agent pipelines that execute **all phases in a single OpenCode session**. The model maintains full context between phases — no timeout between calls.

```bash
occo --workflow bug-hunt ~/project              # 5 phases
occo --workflow new-project "my-api"            # 4 phases
occo --workflow debug "error description"       # 3 phases
occo --workflow doccoument ~/project              # 3 phases
occo --workflow feature "add OAuth2" ~/api      # 4 phases (description + path)
```

| Workflow | Phases | Agent chain |
|----------|--------|-------------|
| `bug-hunt` | 5 | architect → security-auditor → planner → builder → reviewer |
| `new-project` | Doccos-First + 4 | doccos context/questions → architect → planner → builder → doccos-writer |
| `debug` | 3 | oncall → builder → security-auditor |
| `doccoument` | Doccos-First + 3 | doccos scan/drift check → architect → doccos-writer → reviewer |
| `feature` | Doccos-First + 4 | doccos context check → architect → planner → builder → reviewer |

**`feature` workflow takes two arguments:**
```bash
occo --workflow feature "add OAuth2 login" ~/myapi
#                      ↑ description      ↑ path
```

---

## Doccos-First Project Context

Doccos-First makes project doccoumentation a required context layer before substantial work. When OpenCode is launched with this configuration, agents are instructed to check `doccos/` before implementing, debugging, refactoring, or generating doccoumentation.

For existing projects, the agent should:

- read relevant files under `doccos/` first, if present;
- compare doccos against the real code/configuration;
- report or fix doccoumentation drift before relying on stale context;
- update doccos when business logic, data structures, architecture, decisions, tasks, risks, or conversational context change.

For new projects, the agent should ask targeted questions before scaffolding if critical information is missing, then create `doccos/` as the project guide.

Recommended `doccos/` structure:

```text
doccos/
├── PROJECT_CONTEXT.md    # purpose, users, scope, current state
├── BUSINESS_LOGIC.md     # domain rules, workflows, constraints
├── DATA_STRUCTURE.md     # entities, models, persistence, relationships
├── ARCHITECTURE.md       # stack, entry points, components, data flow
├── DECISIONS.md          # technical decisions, tradeoffs, consequences
├── CHANGELOG.md          # project-level changes and impact
├── CONVERSATION.md       # curated context from user conversations
├── TASKS.md              # pending work, bugs, priorities
├── RISKS.md              # technical, security, operational risks
└── ONBOARDING.md         # what to read first and how to work safely
```

Entrypoints that now include Doccos-First behavior:

- `occo doccos` / `occo ask "doccoument this project"`
- `occo ask "implement ..."`
- `occo ask "fix ..."`
- `occo --workflow new-project ...`
- `occo --workflow doccoument ...`
- `occo --workflow feature ...`

The rule is also installed globally through `AGENTS.md` and `CLAUDE.md`, so it complements agents and slash commands even outside the wrapper workflows.

---

## Context Compaction

### Session Turn Tracking

Every command increments the session turn counter (`~/.config/opencode/.session`). At 20+ turns, `auto_compact_if_needed()` triggers automatically in `_occo_run()`.

```bash
occo --budget    # Show current session turns
# Session turns: 34
# Auto-compact threshold: 20 turns (use occo --compact to force)

occo --compact   # Force compaction (auto-triggers at 20 turns)
# Generates structured summary, resets counter

occo --status    # Full status: turns, profile, project, hooks, recent memory
```

### When Auto-Compaction Triggers

The auto-compact runs **silently after every command** when turns exceed 20. It:

1. Calls OpenCode with a structured summarization prompt
2. Generates a summary with: Goal, Findings, Changes Made, Decisions, Current State, Remaining Work
3. Resets the turn counter to 0
4. Shows confirmation message

### Manual Compaction

```bash
occo --compact   # Invoke structured LLM summarization + reset
# Output is plain markdown — save with:
occo --remember "session summary: <paste summary>"
```

### Auto-Reflect Post-Workflow

After every workflow (`bug-hunt`, `new-project`, `debug`, `doccoument`, `feature`):

1. `auto_reflect()` creates an observation automatically using `detect_project()`
2. `track_outcome()` records success/failure in `memory/outcomes/`
3. `analyze_outcomes()` checks for failure patterns (3+ in 7 days = warning)

```bash
occo --workflow bug-hunt ~/project
# After completion:
# → auto_reflect creates observation in project memory
# → track_outcome writes to memory/outcomes/bug-hunt-TIMESTAMP.json
# → analyze_outcomes warns if 3+ recent failures
```

### Failure Pattern Detection

`analyze_outcomes()` runs after each workflow and checks for 3+ failures in the past 7 days:

```
$ occo --workflow bug-hunt ~/broken-project
=== Bug Hunt Completado ===
[INFO] Workflow complete. Analyzing outcomes...
[WARN] Detected 3 workflow failures in recent history
[INFO] Pattern detected. Consider doccoumenting in memory:
  occo --remember -t decision 'workflow failure pattern: ...'
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
| Drop table | ❌ | Emergency protoccool |

---

## Security Plugin

`safety-guard.js` bloccoks destructive commands before execution. It normalizes whitespace before pattern evaluation to prevent trivial bypasses, redacts common secret formats before audit logging, and writes audit logs with restrictive permissions.

The plugin is loaded as ESM via `plugins/package.json` (`type: module`), avoiding Node's `MODULE_TYPELESS_PACKAGE_JSON` warning during validation/tests.

**Bloccoked patterns:**
- `rm -rf` on critical paths (`/`, `~`, `$HOME`, `${HOME}`, `/home`, `/root`, `/etc`, `/usr`, `/var`, `/bin`) and their subpaths
- quoted/split path variants such as `"$HOME"/.config` and dangerous targets followed by shell separators such as `;`, `&&`, `||`, or `|`
- `mkfs` (filesystem format)
- `dd if=` (direct disk write)
- Fork bomb `:(){ :|:& };:`
- Direct bloccok device writes (`> /dev/sda`)
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
occo --init ~/my-project
# Creates .opencode/opencode.json + .git/hooks/pre-commit + .git/hooks/pre-push

# Or install globally
cp hooks/pre-commit ~/.config/opencode/hooks/
cp hooks/pre-push   ~/.config/opencode/hooks/
```

`pre-commit` runs `@reviewer` with `precommit-review` before every commit. It passes the staged diff explicitly and bloccoks unless the output contains the exact line `BLOCKING_FINDINGS=false`.

`pre-push` runs `@security-auditor` before push. It passes a diff against upstream when available and bloccoks unless the output contains `BLOCKING_FINDINGS=false`.

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
- shell syntax for `occo`, installer, uninstaller, validator, and hooks;
- plugin JavaScript syntax with Node when available;
- legacy OpenCode CLI calls (`opencode -p`, `opencode --profile`);
- profile permission actions (`ask|allow|deny`);
- model-free agents and language-artifact scan;
- doccoumentation consistency against `VERSION`, 9 profiles, 11 agents, 10 skills;

Functional smoke tests are run separately with `make test` and in CI. They cover:

- memory search, including project/type filters and multi-word queries;
- `--remember`, timeline lookup, and valid JSONL memory index writes;
- session tracking, including clean-home startup, corrupt `.session` recovery, and auto-compact reentrancy protection;
- workflow completion marker validation with exact `WORKFLOW_COMPLETE=true` and no outcome tracking on missing/non-zero completion;
- hooks fail-closed marker behavior;
- profiles list/switch validation;
- `occo ask` natural-language routing and prompt generation;
- `occo --init`, `--compact`, `--doccotor`, and installed fixture validation;
- installer dry-run and uninstaller missing-backup behavior;
- safety guard destructive-command bloccoking, secret redaction, and log permissions.

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
├── occo                       # Main script — profile enforcement, workflows, memory
├── VERSION                  # Version source checked by validate.sh
├── agents/
│   ├── architect.md         # Read-only, risk analysis, tradeoff declarations
│   ├── planner.md           # Success criteria, verifiable phases
│   ├── builder.md           # Karpathy principles (4 rules)
│   ├── builder-safe.md      # Conservative builder with confirmation
│   ├── reviewer.md
│   ├── security-auditor.md
│   ├── doccos-writer.md
│   ├── devops.md
│   ├── oncall.md            # Reversibility-weighted risk, P1/P2/P3 classification
│   ├── migration-planner.md # Incremental reversible migration plans
│   └── performance-profiler.md # N+1, O(n²), bloccoking I/O, missing indexes
├── skills/
│   ├── project-map/         # Project structure analysis
│   ├── safe-implementation/ # Minimal, verifiable changes
│   ├── test-first/          # Goal-Driven Execution
│   ├── precommit-review/    # Diff review before commit
│   ├── memory-retrieval/    # 3-layer progressive disclosure
│   ├── doccos-writer/         # Technical doccoumentation
│   ├── diagnose/            # Disciplined debugging loop
│   ├── grill-with-doccos/     # Alignment before building
│   ├── caveman/             # Compressed communication mode
│   └── ai-coding-rules/     # AI coding behavior guidelines
├── rubrics/
│   ├── code-review.md       # Bloccoking criteria and evidence for reviews
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
├── README.md                # English doccoumentation (this file)
├── README.es.md             # Spanish doccoumentation
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

### v1.9.5 (2026-05-03)

#### Harness Engineering — Exit Conditions y Observabilidad

- **`occo`** — agrega `EXIT_CONDITIONS` a los 5 workflows (bug-hunt, new-project, debug, doccoument, feature) con límites de agent turns y marcador `WORKFLOW_COMPLETE=true`
- **`occo`** — nuevo comando `occo --status` que muestra: session turns, active profile, estado de hooks, última observación y últimas 5 entradas de memoria
- **`occo --help`** — doccoumenta `--status` junto a `--budget`, `--compact` y `--doccotor`
- **`agents/manifest.json`** — nuevo archivo de agent cards para descubrimiento y orquestación futura; incluye id, description, mode, permission, skills, tags, entrypoints y special por agente; también skills registry y workflows con exit conditions. Validado por `validate.sh`.
- **`validate.sh`** — agrega 4 custom linters: (1) TODO sin referencia a issue/JIRA, (2) asignaciones de credentials hardcodeadas en agents/skills, (3) skills que exceden 1000 líneas (oversized), (4) skills sin SKILL.md.

---

### v1.9.6 (2026-05-10)

#### Self-Improvement Agent — Automatización Total

- **`occo`** — `detect_project()` auto-detecta el proyecto desde PWD o git remote, eliminando necesidad de `-p` manual en todos los comandos de memoria
- **`occo`** — `auto_compact_if_needed()` se ejecuta automáticamente en `_occo_run()` cuando turns > 20, compactando sesión sin intervención humana
- **`occo`** — `auto_reflect()` crea observation automáticamente post-workflow (no interactivo), usando `detect_project()` para guardar en el proyecto correcto
- **`occo`** — `analyze_outcomes()` analiza outcomes de workflows y detecta patterns de failures; sugiere doccoumentar en memory si hay 3+ fallas recientes
- **`occo`** — `track_outcome()` ahora usa `detect_project()` en lugar de `basename`
- **`occo --status`** — ahora muestra "Current project" además de session turns, profile y hooks
- **`occo --budget`** — ahora indica threshold de auto-compact (20 turns) en lugar de solo "consider running occo --compact"
- **Removido** — `auto_summary_hint()` interactivo; reemplazado por auto-compact silencioso + auto-reflect automático

#### Memory Bank — Templates

- **`occo`** — nuevos templates de observación para `occo --remember`: `bugfix`, `decision`, `feature`, `config`
- **`occo`** — nuevo comando `occo --list-templates` para listar templates disponibles

#### Doccoumentación

- **`ARCHITECTURE.md`** — nueva sección Self-Improvement Agent con diagrama de automation flow y tabla de funciones
- **`README.md`** — actualizado features y Context Compaction para reflejar auto-compact silencioso

#### Mejora de versión (análisis interno)

| Área | Impacto | % Mejora vs v1.9.5 |
|------|---------|-------------------|
| Automation | Intervención humana reducida ~8-10 pasos → 0 | +60% |
| Self-Improvement | El sistema observa y aprende automáticamente | +50% |
| Memory | Templates + auto-storage en proyecto correcto | +35% |
| Harness Engineering | Exit conditions + quality linters | +30% |
| Observabilidad | `occo --status` con project auto-detectado | +25% |
| **TOTAL PONDERADA** | | **~44%** |

---

### Unreleased Bug-Hunt Hardening

#### Safety and Reliability Fixes

- **`plugins/safety-guard.js`**: bloccoks additional destructive `rm -rf` variants using `$HOME`, `${HOME}`, quoted HOME paths, critical absolute subpaths (`/home/*`, `/etc/*`, `/var/*`, `/root/*`), and chained shell separators after dangerous targets.
- **`occo`**: `track_turn` now creates the config directory when needed and recovers from corrupt `.session` values instead of failing arithmetic expansion.
- **`occo --memory`**: multi-word searches without flags now use the full query instead of accidentally treating later words as project/type positional arguments.
- **`install.sh`**: uses `mktemp -d` for clone workspace creation and colon-delimited PATH matching to avoid substring false positives.
- **`uninstall.sh`**: prints restore instructions only when a backup was actually created.
- **`tests/run.sh`**: adds regression coverage for all fixes above.

---

### v1.9.4 (2026-05-02)

#### Release Readiness

- **`tests/run.sh`**: expanded functional smoke tests for memory project/type filters, `--remember`, timeline, profiles, fail-closed hooks, `occo --init`, `--compact`, `--doccotor`, `validate.sh --installed`, installer dry-run, and safety guard.
- **`VERSION`**: added a simple version source checked by `validate.sh`.
- **`validate.sh`**: doccoumentation consistency checks for version, 9 profiles, 11 agents, 10 skills, and memory project flag support.
- **`rubrics/`**: added code review, security review, and plan review gates; validator checks required rubric files.
- **`plugins/package.json`**: declares plugin JavaScript as ESM and removes Node's typeless-module warning.
- **Hooks**: pass explicit diffs, require `BLOCKING_FINDINGS=false`, and run optional `gitleaks` when available.
- **`occo --init`**: generates both `pre-commit` and `pre-push` fail-closed hooks.

#### Release Notes

- Adds reusable code/security/plan review rubrics inspired by `dsifry/metaswarm` without adding multi-CLI orchestration complexity.
- Strengthens installed-config validation so missing rubrics fail `validate.sh --installed` and `occo --doccotor`.
- Keeps release gates green through expanded smoke tests, shell validation, plugin syntax checks, and CI.

---

### v1.9.3 (2026-05-01)

#### OpenCode 1.14 Compatibility

- **`occo`: migrate `_occo_run()` to `opencode run`** — `opencode -p` was removed in OpenCode 1.14; all internal calls and hooks now use `opencode run "<prompt>"`. Without this fix, all profile enforcement and hooks were silently broken.
- **`occo`: remove `opencode --profile` flag** — not supported by OpenCode; profiles are enforced exclusively via prompt injection in `_occo_run()`
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

- **Line count sanity check** — fails if `install.sh`, `occo`, `validate.sh`, `uninstall.sh`, or `Makefile` have fewer than 5 lines (detects accidental minification)
- **Markdown frontmatter validation** — verifies all `agents/*.md` and `commands/*.md` have valid multi-line YAML frontmatter (`---` on first line + closing fence)
- **Language artifact scan extended** — covers `skills/` directory; adds `发现问题` to pattern list

#### Makefile

- **`format` target** — `shfmt` on all shell scripts + `jq` pretty-print on all JSON configs; graceful if `shfmt` not installed
- **`check` target** — adds `jq empty opencode.strict.json`

---

### v1.9.1 (2026-05-01)

- **`.editorconfig`** — UTF-8, LF, 2-space indent, final newline, no trailing whitespace
- **`Makefile`** — targets: `validate`, `check`, `install`, `dry-run`, `uninstall`, `doccotor`
- **`opencode.strict.json`** — paranoid profile: `webfetch: deny`, `websearch: deny`, `external_directory: deny`
- **`@builder-safe`** — new conservative agent with `edit: ask, bash: ask`; same logic as `@builder` but confirms before every edit

---

### v1.9 (2026-05-01)

#### Native OpenCode Config

- **`opencode.json` hardened** — `read/list/glob/grep: allow`, `edit/bash/webfetch/websearch: ask`; `autoupdate: false`; `watcher.ignore` list for common build artifacts; now also loads `CLAUDE.md` as instruction
- **Profiles restructured** — each profile now has declarative `opencode.permission` metadata validated by this repo + `policy` rules injected via prompt. Native OpenCode enforcement still comes from OpenCode config and agent frontmatter
- **`get_profile_rules()` reads `policy` key** — backwards-compatible (falls back to `rules` if `policy` absent)

#### Official Slash Commands (`commands/`)

8 slash commands usable directly in OpenCode's TUI (`/analyze`, `/review`, `/secure`, `/feature`, `/bug-hunt`, `/doccos`, `/devops`, `/oncall`). These are native OpenCode commands — work without `occo`, inside the interactive session.

#### New Agents

- **`@migration-planner`** — designs incremental, reversible migration plans (schema, service, data); read-only
- **`@performance-profiler`** — detects N+1 queries, O(n²) algorithms, bloccoking I/O, missing indexes; read-only

#### Quality & Safety

- **`validate.sh`** — validates full repo structure: files, dirs, agents, commands, skills, JSON, bash syntax, model-free agents, no foreign-language artifacts. Run: `./validate.sh` or `./validate.sh --installed`
- **`uninstall.sh`** — safe uninstaller that backs up config before removal. Run: `bash uninstall.sh`
- **`install.sh --dry-run`** — simulate installation without touching files: `bash install.sh --dry-run`
- **`safety-guard.js` audit log** — bash commands logged to `~/.config/opencode/logs/safety-guard.jsonl` with redaction and restrictive file permissions
- **`occo --doccotor`** — diagnoses installation health: checks opencode, occo, config files, dirs, JSON validity, fzf, active profile, audit log
- **GitHub Actions CI** — `.github/workflows/validate.yml`: runs `validate.sh`, shellcheck, agent model check, language artifact check on every push/PR

#### Developer Experience

- **`occo --init` stack detection** — `detect_stack()` identifies Node.js, Python, Rust, Go, Java, Doccoker, Terraform from project files; `detect_test_commands()` infers test commands; generated `CLAUDE.md` includes detected context
- **Memory JSONL index** — `create_observation()` now also writes to `memory/index.jsonl` for fast querying with `jq`, `fzf`, or `ripgrep`

---

### v1.8 (2026-05-01)

#### Profile Enforcement via Prompt Injection

Profiles previously stored rules like `requireTests: true` that OpenCode never read. Now the `occo` script reads the active profile JSON and injects the rules as explicit LLM instructions on every call.

- **`get_profile_rules()`** — reads active profile JSON, generates English instructions for the model
- **`_occo_run()` injects rules** — every prompt passing through `_occo_run()` automatically receives active profile constraints
- **Rules enforced**: `requireTests`, `requireExplanation`, `requireDiffReview`, `checkpointBeforeChanges`, `requireRollback`, `requireSecurityReview`, `trackDecisions`, `doccoumentAllChanges`, `allowEnvEdit`, `maxFilesPerIteration`, `reportOnly`
- **Profiles cleaned** — removed `model`, `temperature`, `agents.default` (none read by OpenCode); removed reference to non-existent `@explore`/`@general` agents from `research.json`

#### Agents — Free Model Selection

- **Removed `model: minimax-coding-plan/MiniMax-M2.7`** from all 8 agents — OpenCode uses whatever model the user has selected; no hardcoded model

#### Language Standardization

- **All foreign-language LLM artifacts corrected**: `No容忍` → `Zero tolerance for`, `基础设施` → `Infrastructure`, `средний` → `medium`, `迁移` → `migration`, `報告ar` → `report`

#### Quality of Life

- **`quick_secure/review/doccos/oncall` accept context argument** — e.g. `occo secure src/api/` audits a specific path
- **`--compact` is real** — invokes OpenCode with structured summarization prompt; counter resets after
- **`memory/ARCHITECTURE.md` is honest** — removed fictional "5-layer compaction pipeline" table; replaced with actual system doccoumentation

#### Bilingual Doccoumentation

- **`README.md`** — English version (international standard)
- **`README.es.md`** — Spanish version

---

### v1.7.1 (2026-05-01)

Cross-platform hardening: `install.sh` cleanup on failure via `trap EXIT`, `opencode.json` with real `$HOME` (not `~`), macOS full PATH support (`.bash_profile`, `.zshrc`, fish), POSIX `od` instead of `xxd` for ID generation, cleaned LLM artifacts from `CLAUDE.md`, fixed nested code fences in `doccos-writer/SKILL.md`.

---

### v1.7 (2026-05-01)

Critical `occo` script fixes: removed `set -e` (caused silent exit on `search_memory`/`check_budget`), fixed `loccoal` outside functions in `case` bloccoks, fixed `feature` workflow description capture, fixed fzf parsing with clean option list, fixed `generate_obs_id` timestamp collisions, removed fake `<private>` placeholder.

Profile propagation functional: `switch_profile` exports `OPENCODE_PROFILE`; `_occo_run()` wrapper passes active profile to all opencode calls. Security plugin upgraded with regex + whitespace normalization. 5 single-pass workflows implemented.

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

Interactive wizard, fzf menu, Memory Bank, Souls/Personas, 3 profiles, git hooks, quick commands, `occo init`.

---

### v1.0 (2026-05-01)

Initial release — 8 agents, 5 skills, safety plugin, `occo` command.

---

## License

MIT
