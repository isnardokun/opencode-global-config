# Architecture

OpenCode Global Config is a configuration package that layers onto [OpenCode CLI](https://opencode.ai). It does not fork or modify OpenCode — it works entirely through configuration files, agent definitions, and a wrapper script.

## System Overview

```
User
  │
  ▼
┌─────────────────────────────────────────────────────────┐
│  opencode (CLI)                                         │
│    │                                                    │
│    ├── loads ~/.config/opencode/opencode.json          │
│    ├── loads AGENTS.md + CLAUDE.md as instructions     │
│    ├── loads plugins/safety-guard.js                   │
│    └── runs agents/skills/profiles                      │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│  oc (wrapper script)                                   │
│    │                                                    │
│    ├── Profile enforcement (prompt injection)          │
│    ├── Memory operations (3-layer retrieval)            │
│    ├── Workflow orchestration (single-pass prompts)     │
│    ├── Natural language router (oc ask)                 │
│    └── Session tracking (turn counter + compact)        │
└─────────────────────────────────────────────────────────┘
```

## Components

### `oc` — Main Wrapper Script

The core CLI entry point (~1100 lines of bash). Handles:

- **Profile enforcement** — `get_profile_rules()` reads `profiles/*.json`, generates English instructions, injects via `_oc_run()` on every `opencode run` call
- **Memory** — `create_observation()`, `search_memory()`, `get_observations()`, `get_timeline()`
- **Workflows** — `run_workflow()` builds a single-pass prompt for: `bug-hunt`, `new-project`, `debug`, `document`, `feature`
- **Router** — `oc ask` maps natural language to agents/workflows using pattern matching
- **Session** — `track_turn()`, `check_budget()`, `compact_session()`

**Entry point:** `~/.local/bin/oc` (installed by `install.sh`)

### Agents (11 total)

Located in `agents/`. Each is a markdown file with YAML frontmatter:

| Agent | File | Permissions | Role |
|-------|------|-------------|------|
| `@architect` | `architect.md` | read-only | Analyze architecture, tradeoffs, risks |
| `@planner` | `planner.md` | read-only | Phase-based plans with verifiable success criteria |
| `@builder` | `builder.md` | edit + bash(ask) | Implementation with Karpathy principles |
| `@builder-safe` | `builder-safe.md` | edit: ask, bash: ask | Conservative implementation with confirmation |
| `@reviewer` | `reviewer.md` | read-only | Code review with precommit-review |
| `@security-auditor` | `security-auditor.md` | read-only | Vulnerability detection |
| `@docs-writer` | `docs-writer.md` | edit | Technical documentation |
| `@devops` | `devops.md` | edit + bash | Infrastructure, CI/CD, Docker |
| `@oncall` | `oncall.md` | bash(ask) | Production incident response with reversibility-weighted risk |
| `@migration-planner` | `migration-planner.md` | read-only | Incremental reversible migrations |
| `@performance-profiler` | `performance-profiler.md` | read-only | N+1, O(n²), blocking I/O, missing indexes |

All agents are model-free — they contain no `model:` field. OpenCode uses whatever model the user has selected.

### Profiles (9 total)

Located in `profiles/`. Each is a JSON with two sections:

- `opencode.permission` — declarative matrix (not enforced by OpenCode, validated by this repo)
- `policy` — rules injected as LLM instructions via `get_profile_rules()` in `oc`

Deny-first gradient:

```
deny → plan → review → default → work → research → auto → trusted → devops
```

**Most restrictive:** `deny` (read-only, no edits, no bash)
**Most permissive:** `trusted` (direct edits, bash allowed)

### Skills (6 total)

Located in `skills/` as directories with `SKILL.md`:

| Skill | Purpose |
|-------|---------|
| `project-map` | Project structure analysis |
| `safe-implementation` | Minimal, verifiable, reversible changes |
| `test-first` | Goal-Driven Execution (verify before implement) |
| `precommit-review` | Diff review before commit |
| `memory-retrieval` | 3-layer progressive disclosure (search/timeline/get) |
| `docs-writer` | Technical documentation generation |

### Commands (8 slash commands)

Located in `commands/`. These are native OpenCode TUI commands — usable as `/analyze`, `/review`, etc. inside an interactive `opencode` session without needing `oc`:

```
/analyze  → @architect
/review   → @reviewer + precommit-review
/secure   → @security-auditor
/feature  → workflow: architect → planner → builder → reviewer
/bug-hunt → workflow: architect → security-auditor → planner → builder → reviewer
/docs     → @docs-writer
/devops   → @devops
/oncall   → @oncall
```

### Rubrics (3 reusable gates)

Located in `rubrics/`:

- `code-review.md` — blocking criteria for code quality
- `security-review.md` — severity levels and remediation gates
- `plan-review.md` — verifiable planning and design criteria

### Plugins

Located in `plugins/`:

- `safety-guard.js` — ESM plugin that blocks destructive commands via regex, audits to `~/.config/opencode/logs/safety-guard.jsonl` with secret redaction
- `package.json` — declares `type: module` to avoid Node's `MODULE_TYPELESS_PACKAGE_JSON` warning

### Hooks

Located in `hooks/`:

- `pre-commit` — runs `@reviewer` with `precommit-review` against staged diff; blocks unless `BLOCKING_FINDINGS=false`
- `pre-push` — runs `@security-auditor` against diff; blocks unless `BLOCKING_FINDINGS=false`; runs `gitleaks` if installed

## Self-Improvement Agent

The system includes automatic self-improvement capabilities that require zero user intervention:

### Automatic Functions

| Function | Trigger | Behavior |
|----------|---------|----------|
| `detect_project()` | Always | Auto-detects project from PWD or git remote; eliminates need for `-p` manually |
| `auto_compact_if_needed()` | Every `_oc_run()` when turns > 20 | Compacts session silently, resets turn counter |
| `auto_reflect()` | Post-workflow completion | Creates observation in correct project automatically |
| `track_outcome()` | Post-workflow completion | Records workflow result in `memory/outcomes/` |
| `analyze_outcomes()` | Post-workflow completion | Detects failure patterns (3+ = warning) |

### Automation Flow

```
User runs: oc --workflow bug-hunt ~/myproject

1. run_workflow() executes with all phases in single-pass
2. detect_project("~/myproject") → "myproject" (from git remote or dirname)
3. Workflow completes → auto_reflect("bug-hunt", "~/myproject")
   → Creates observation in memory/projects/myproject/
4. track_outcome("bug-hunt", "success", "myproject")
   → Writes to memory/outcomes/bug-hunt-TIMESTAMP.json
5. analyze_outcomes() checks recent failures
   → If 3+ failures in 7 days, warns about pattern
6. auto_compact_if_needed() runs after every _oc_run()
   → If turns > 20, auto-generates structured summary + resets counter
```

### Memory Bank

Located in `memory/`:

```
memory/
├── INDEX.md           # Fast lookup index
├── ARCHITECTURE.md    # Design documentation
├── index.jsonl        # JSONL index for jq/fzf/ripgrep
├── projects/          # Per-project observations (auto-detected)
│   └── [project]/
│       └── [obs_id].md
├── outcomes/          # Workflow outcome tracking
│   └── [workflow]-[timestamp].json
├── decisions/         # Global ADR observations
└── patterns/         # Global pattern observations
```

**3-layer retrieval:**
1. **Search** (Layer 1) — IDs + summaries only, ~50-100 tokens/result
2. **Timeline** (Layer 2) — chronological context, ~200 tokens
3. **Get** (Layer 3) — full observation content, ~500-1000 tokens

### Souls

Located in `souls/souls.md`. Predefined personas for different work contexts:
- `senior-developer`
- `security-auditor`
- `devops-sre`
- `code-reviewer`
- `tech-lead`

## Data Flow

### Profile Enforcement

```
User runs: oc --profile trusted build "add feature"

1. switch_profile() exports OPENCODE_PROFILE=trusted
2. get_profile_rules() reads profiles/trusted.json → generates English rules
3. _oc_run() prepends rules to every opencode run call:
   "Use @builder with safe-implementation and test-first.
   
   [Active profile rules — follow these strictly:]
   - [rules from trusted.json]"
4. OpenCode executes with injected constraints
```

### Memory Lifecycle

```
oc --remember -p my-api -t bugfix "JWT fails on DST change"

1. create_observation() generates obs_id from timestamp + random bytes
2. Writes markdown file to memory/projects/my-api/
3. Appends JSONL entry to memory/index.jsonl for fast querying
4. Frontmatter: id, date, project, type, summary, tokens_est
```

### Workflow Execution (single-pass)

```
oc --workflow bug-hunt ~/project

1. run_workflow() builds a single prompt with all phases:
   - Phase 1: @architect + project-map
   - Phase 2: @security-auditor
   - Phase 3: @planner
   - Phase 4: @builder + test-first
   - Phase 5: @reviewer + precommit-review
2. Sends ONE opencode run call with full pipeline
3. OpenCode executes sequentially, maintaining context between phases
```

## Technical Decisions

### Why prompt injection for profiles instead of native OpenCode profiles?

OpenCode does not have a native profile system that reads custom JSON files. Profile rules are enforced by injecting them as explicit LLM instructions on every call. This approach:
- Requires no fork of OpenCode
- Works with any model
- Is transparent (rules visible in prompt)

### Why single-pass workflows?

Traditional multi-agent systems call OpenCode multiple times with timeout gaps between calls. Single-pass workflows send all phases in one `opencode run` call, maintaining full context without inter-call timeouts.

### Why file-based memory instead of vector DB?

Simplicity andinspectability. File-based markdown:
- Is version-control compatible
- Can be edited directly by humans
- Requires no external service
- Works offline

### Why ESM for safety-guard plugin?

Node.js emits `MODULE_TYPELESS_PACKAGE_JSON` warning when loading `.js` files without `package.json` sibling. Declaring `type: module` in `plugins/package.json` eliminates this warning during validation and testing.

## File Inventory

```
opencode-global-config/
├── oc                          # Main wrapper script (~1100 lines)
├── VERSION                     # "1.9.5"
├── opencode.json               # Native OpenCode config (permissions, plugins, instructions)
├── opencode.strict.json        # Paranoid mode: webfetch/websearch/external_dir: deny
│
├── agents/                     # 11 agent definitions
│   ├── architect.md
│   ├── builder.md
│   ├── builder-safe.md
│   ├── planner.md
│   ├── reviewer.md
│   ├── security-auditor.md
│   ├── docs-writer.md
│   ├── devops.md
│   ├── oncall.md
│   ├── migration-planner.md
│   └── performance-profiler.md
│
├── commands/                   # 8 native slash commands (OpenCode TUI)
│   ├── analyze.md
│   ├── review.md
│   ├── secure.md
│   ├── feature.md
│   ├── bug-hunt.md
│   ├── docs.md
│   ├── devops.md
│   └── oncall.md
│
├── skills/                     # 6 skills
│   ├── project-map/
│   ├── safe-implementation/
│   ├── test-first/
│   ├── precommit-review/
│   ├── memory-retrieval/
│   └── docs-writer/
│
├── profiles/                   # 9 deny-first profiles
│   ├── deny.json
│   ├── plan.json
│   ├── review.json
│   ├── default.json
│   ├── work.json
│   ├── research.json
│   ├── auto.json
│   ├── trusted.json
│   └── devops.json
│
├── rubrics/                    # 3 reusable review gates
│   ├── code-review.md
│   ├── security-review.md
│   └── plan-review.md
│
├── plugins/
│   ├── safety-guard.js         # ESM, blocks destructive commands, audit log
│   └── package.json            # type: module
│
├── hooks/                      # Git hooks
│   ├── pre-commit              # @reviewer + precommit-review
│   └── pre-push                # @security-auditor
│
├── souls/
│   └── souls.md                # 5 personas
│
├── memory/                     # File-based memory system
│   ├── INDEX.md
│   ├── ARCHITECTURE.md
│   ├── index.jsonl
│   └── projects/
│
├── workflows/
│   └── README.md
│
├── install.sh                  # Installation + --dry-run
├── uninstall.sh                # Safe removal with backup
├── validate.sh                 # Full repo validation + --installed
├── Makefile                    # check, test, validate, install, dry-run, uninstall, doctor
│
├── .github/workflows/
│   └── validate.yml            # CI: validate.sh + shellcheck + smoke tests
│
├── AGENTS.md                   # Global rules + intent mapping (Spanish)
├── CLAUDE.md                   # Compact system prompt
├── README.md                   # English documentation
├── README.es.md                # Spanish documentation
├── INSTALL.md                  # Installation guide (Spanish)
├── CHANGELOG.md                # Formal version history
├── CONTEXTO_PROYECTO.md        # Living context (Spanish)
└── LICENSE                     # MIT
```

## Validation

`validate.sh` checks:
- Required files/directories, agents, commands, skills
- JSON syntax (including `plugins/package.json`)
- Shell syntax for all scripts
- Plugin JavaScript syntax (Node --check if available)
- Legacy OpenCode CLI calls (`opencode -p`, `opencode --profile`)
- Profile permission actions (`ask|allow|deny`)
- Model-free agents (no hardcoded model:)
- Language artifact scan (Chinese, Russian, etc.)
- Documentation consistency (version, profile/agent/skill counts)
- Rubric files presence

`tests/run.sh` smoke tests:
- Memory search with project/type filters
- `--remember` creation
- Timeline lookup
- Profile switching
- Hook fail-closed behavior
- `oc --init`, `--compact`, `--doctor`
- `validate.sh --installed`
- Installer dry-run
- Safety guard blocking