---
name: graphify
description: Map any folder of code, docs, papers, images, or videos into a navigable knowledge graph with an interactive HTML viewer, a queryable JSON, and a plain-language GRAPH_REPORT.md. Use when the user wants to understand a codebase, visualize architecture, find surprising connections, or explore relationships between files. Adapted from safishamsi/graphify for opencode-global-config.
---

# Graphify — code/docs/anything → knowledge graph

Adapted from `safishamsi/graphify` (v8, 2026-06-28). Original is a 1204-line skill designed for Claude Code with parallel subagents. This is a **lightweight manual** for opencode-global-config: graphify itself is a separate Python package (`graphifyy` on PyPI) that does the heavy lifting; this skill explains when to use it, what to expect, and how to integrate with `occo`.

## What graphify does

Run `graphify .` (or `graphify /path/to/project`) and it produces three files:

```
graphify-out/
├── graph.html       Open in any browser — click nodes, filter, search
├── GRAPH_REPORT.md  Highlights: key concepts, surprising connections, suggested questions
└── graph.json       Full graph — query it anytime without re-reading files
```

The graph is built from:
- **Code** — local tree-sitter AST, no API calls
- **Docs** (md, html, txt, yaml) — semantic extraction via your LLM
- **PDFs** — text extraction, semantic enrichment
- **Images** — visual description, semantic extraction
- **Videos** — transcription (requires `graphifyy[video]`)
- **Office** (docx, xlsx) — requires `graphifyy[office]`
- **MCP configs**, **package manifests** (pyproject.toml, go.mod, etc.) — structure

Every inferred relationship is tagged `EXTRACTED` (literal), `INFERRED` (LLM-guessed), or `AMBIGUOUS`. You always know what was found vs guessed.

## When to use this skill

Invoke when the user wants to:

- Understand a new codebase fast ("map this repo", "what's in here?")
- Visualize architecture before refactoring
- Find surprising connections between files ("what connects auth to the database?")
- Onboard onto a project ("I'm new to this codebase, give me a map")
- Audit complexity ("which modules are god objects?")
- Generate a Mermaid call-flow diagram (`graphify export callflow-html`)
- Search semantically instead of grepping (`graphify query "..."`)

Do **not** use when:
- The user has a specific bug or refactor in mind — use `/investigate` or `/plan` instead
- The corpus is tiny (< 20 files) — graphify overhead exceeds value
- The user wants a quick file lookup — use `Grep` directly

## Installation

**Already installed in this environment?** Run `command -v graphify` to check. If present, skip to "Basic usage" below.

**Not installed.** The user can install with `uv tool install graphifyy` (or `pipx install graphifyy`). The opencode-global-config installer offers this via `bash install.sh --with-graphify` (opt-in, see install.sh).

After installing, register the upstream skill with opencode:

```bash
graphify opencode install
```

This writes a small `AGENTS.md` section in `~/.config/opencode/AGENTS.md` that nudges the agent to consult the graph before grepping raw files. It's persistent — every session starts with graphify-query-first behavior.

## Basic usage

The user invokes one of:

```bash
graphify .                          # build graph for current dir
graphify ./src --update             # re-extract only changed files
graphify . --cluster-only           # rerun clustering without re-extracting
graphify . --no-viz                 # skip HTML, just report + JSON
graphify . --wiki                   # build markdown wiki from graph
graphify export callflow-html       # Mermaid call-flow diagram
```

Or query an existing graph:

```bash
graphify query "what connects auth to the database?"
graphify path "UserService" "DatabasePool"
graphify explain "RateLimiter"
```

Outputs go to `graphify-out/`. The HTML is the killer feature — open it in a browser, click nodes, follow edges, search.

## Integration with `occo`

opencode-global-config has its own memory system (`occo --memory`, `occo --remember`, `memory-retrieval` skill). They complement graphify, not replace it:

| Use case | Tool | Why |
|---|---|---|
| "What did we do last session on this project?" | `occo --memory "auth bug"` | fast, file-based, indexed JSONL |
| "What is the structure of this codebase?" | `graphify query "auth"` | graph-aware, shows connections |
| "What is the exact text of file X at line Y?" | `occo --read X:L-Y` or Grep | direct file access |
| "What are the high-level concepts and how do they relate?" | `graphify query "..."` then read `graphify-out/GRAPH_REPORT.md` | graph + LLM summary |

**Recommended workflow:** build a graph once, commit `graphify-out/` (except `cost.json`), and use `graphify query` for codebase-wide questions. Use `occo` memory for project-specific observations over time.

## Auto-graphify at install time

`install.sh` (opencode-global-config) supports `--with-graphify` which:

1. Installs `graphifyy` via `uv tool install` (~50 MB) or `pipx` fallback
2. Runs `graphify opencode install` to register the skill + AGENTS.md hook
3. If `~/.config/opencode/` exists, runs `graphify .` against it and writes `~/.config/opencode/graphify-out/`

This is **opt-in** and **non-default** — the base install remains zero-deps. Pass `--with-graphify` to enable.

The auto-graphify at install time is a **snapshot** of the installed config. Run `graphify .` manually when the config changes significantly (e.g., new skill added, major refactor).

### Auto-rebuild + interactive viewer (v1.17.0+)

`install.sh --with-graphify` also generates `graph.html` (interactive vis.js visualization) at install time via `scripts/graphify_html.py` (stdlib-only, no deps).

For continuous auto-rebuild, run the HTTP server with watch:

```bash
# Default: port 8765, rebuild every 5 minutes
python3 skills/graphify/scripts/graphify_serve.py

# Custom port + interval
python3 skills/graphify/scripts/graphify_serve.py --port 9000 --interval 60

# Build once and exit (no server)
python3 skills/graphify/scripts/graphify_serve.py --once
```

Endpoints:
- `/graph.html` — interactive visualization (click, search, filter by community)
- `/GRAPH_REPORT.md` — plain-language report (god nodes, surprising connections, suggested questions)
- `/graph.json` — raw graph data
- `/health` — JSON status with last build time and node counts

The server runs as a background process and can be stopped with `pkill -f graphify_serve` or `kill <pid>`. To run on system boot, add a systemd unit or cron entry — the script is idempotent.

## Tool detection

graphify's --platform flag detects which AI assistant you use. For opencode-global-config:

```bash
graphify opencode install           # opencode-specific install
graphify install --project          # project-scoped (writes to ./.opencode/ or ./.agents/)
graphify install                    # default: Claude Code (may still work as skill consumer)
```

If `graphify opencode install` doesn't exist in your version, the universal install works: `graphify install --platform opencode`.

## What you get

- **God nodes** — the most-connected concepts. Everything flows through these.
- **Surprising connections** — links between things in different files. Ranked by unexpectedness.
- **The "why"** — inline comments (`# NOTE:`, `# WHY:`, `# HACK:`) and docstrings are extracted as separate nodes linked to the code they explain.
- **Suggested questions** — 4-5 questions the graph is uniquely positioned to answer.
- **Mermaid call-flow** — `graphify export callflow-html` produces a clickable HTML diagram of module dependencies.

## Honesty rules (from original)

- Code is extracted locally with no API calls.
- Docs, PDFs, images, video go through the configured LLM backend.
- No telemetry, no analytics, no usage tracking.
- Every relationship has a confidence tag — you always know what was found vs guessed.
- graphify itself may return empty for some file types or fail on malformed input — handle gracefully.

## Privacy

graph.json is meant to be committed to your repo. Add to `.gitignore`:

```
graphify-out/cost.json        # local only (tracks API spend)
# graphify-out/cache/         # optional: commit for faster rebuilds
```

For data-residency requirements, use `--backend ollama` (fully local) or `--backend claude` with a custom `ANTHROPIC_BASE_URL` pointing at an internal gateway.

## Anti-patterns

- **Don't graphify for trivial tasks.** "What does this function do?" → read the function. "What is the architecture of this 50-file project?" → graphify.
- **Don't grep when graphify query would answer.** `grep -r "auth"` returns lines. `graphify query "auth"` returns the concepts that mention auth, ranked by connection strength, with paths between them.
- **Don't commit `graphify-out/cost.json`** — it tracks per-run API spend and is local-only.
- **Don't auto-rebuild on every commit unless you've set up `graphify hook install`** — incremental rebuilds save tokens but require setup.

## Provenance

Adapted from `safishamsi/graphify/skills/graphify/skill.md` (v8, cherry-pick 2026-06-28). Original is 1204 lines covering every command and edge case for Claude Code. This adaptation is ~190 lines focused on: when to use, how to install, integration with `occo`, and the opt-in flow via `bash install.sh --with-graphify`. The original skill is for execution; this one is for orientation. The full skill is installed when the user runs `graphify opencode install`.

For the full reference (every command, every flag, every backend, troubleshooting), see `https://github.com/safishamsi/graphify/blob/main/skills/graphify/skill.md` after `graphify opencode install` is run.
