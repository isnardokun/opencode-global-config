---
name: codebase-memory-mcp
description: Structural code analysis via MCP — 158 languages (tree-sitter), Hybrid LSP type resolution for the top 11, persistent SQLite knowledge graph, 14 MCP tools (search_graph, trace_path, get_architecture, query_graph, dead-code, ADR). Complements graphify with function-level call chains, dead-code detection, and git diff impact mapping. Use when the user wants to trace call paths, find unused functions, get a codebase architecture summary, or run Cypher-like graph queries. Not a substitute for graphify (which is document-level and Markdown-friendly); pick per task.
---

# Codebase-Memory MCP — type-aware structural code analysis

External MCP server from `DeusData/codebase-memory-mcp`. Single static binary, zero dependencies, 100% local. The agent that uses this skill is the query translator; the server itself contains no LLM.

## What it does

Builds a persistent knowledge graph of your codebase:

- **158 languages** via vendored tree-sitter grammars (everything from Python to COBOL)
- **Hybrid LSP** semantic type resolution for Python, TS/JS/JSX/TSX, PHP, C#, Go, C, C++, Java, Kotlin, Rust — resolves cross-module calls like `user.profile.display_name()` to its definition three modules away
- **Persistent**: SQLite at `~/.cache/codebase-memory-mcp/`, survives restarts, auto-syncs via file watcher
- **14 MCP tools** for structural queries

## When to use this skill

Invoke when the user wants:

- **Call chains** — "who calls `ProcessOrder`?" → `trace_path` with direction=inbound
- **Dead code** — "which functions have zero callers?" → `query_graph` with `WHERE NOT EXISTS { (f)<-[:CALLS]-() }`
- **Architecture summary** — "give me an overview of this codebase" → `get_architecture`
- **Diff impact** — "what does my current git diff touch?" → `detect_changes`
- **Cypher queries** — `query_graph` accepts a read-only openCypher subset
- **ADRs** — `manage_adr` persists architectural decisions across sessions
- **Cross-service links** — HTTP routes, gRPC, GraphQL, tRPC, channels (EMITS/LISTENS_ON)

Do **not** use when:

- The question is about docs, READMEs, Markdown → use `graphify` instead
- The user wants grep-like text search → use `Grep` directly
- The codebase is < 20 files → overhead exceeds value
- The user is asking about *this opencode-global-config repo* in casual conversation — `codebase-memory-mcp` is a tool, not a topic

## When to prefer codebase-memory-mcp over graphify

| Use case | Tool | Why |
|---|---|---|
| "What calls function X?" | `codebase-memory-mcp trace_path` | function-level call graph, type-resolved |
| "Show me unused functions" | `codebase-memory-mcp query_graph` (Cypher dead-code) | precise, language-aware |
| "Map the architecture of this 200-file project" | `get_architecture` | single call returns packages, layers, hotspots |
| "How are docs organized in this project?" | `graphify query` | semantic extraction of Markdown/PDFs |
| "What's the relationship between auth and billing modules?" | `graphify query` then read `graphify-out/GRAPH_REPORT.md` | graph + LLM summary, explains "why" |
| "Find similar code blocks" | `codebase-memory-mcp SIMILAR_TO` edges (MinHash+LSH) | near-clone detection with Jaccard score |

Both can coexist. `graphify-out/` (JSON+HTML) and `~/.cache/codebase-memory-mcp/*.db` (SQLite) are independent stores.

## Installation

**Already installed?** Run `command -v codebase-memory-mcp` to check.

**Not installed.** The opencode-global-config installer offers this via `bash install.sh --with-codebase-memory` (opt-in, see install.sh). Manual install:

```bash
# One-liner (autodetects platform, registers MCP for 11 agents including OpenCode):
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash

# Or grab the binary directly and run its install.sh:
curl -fsSL https://github.com/DeusData/codebase-memory-mcp/releases/latest/download/codebase-memory-mcp-$(uname -s | tr A-Z a-z)-$(uname -m | sed s/x86_64/amd64/).tar.gz | tar xz
./codebase-memory-mcp install
```

The install step:
1. Downloads the static binary to `~/.local/bin/codebase-memory-mcp`
2. Strips macOS quarantine and ad-hoc signs (macOS only)
3. Auto-registers an MCP server entry in `~/.config/opencode/opencode.json` (the same one we generate)
4. Writes an `AGENTS.md` section that nudges the agent to consult the graph before grepping

## Basic usage

After install, restart the agent. Index a repo:

```
You: "Index this project"

Agent calls: index_repository(repo_path="/abs/path")
Server returns: {status: "indexed", nodes: 49, edges: 59}
```

Then query:

```
You: "Who calls process_order?"

Agent calls: trace_path(function_name="process_order", direction="inbound")

Server returns: structured call chain with file:line for each caller
```

CLI mode (useful for scripting):

```bash
codebase-memory-mcp cli index_repository '{"repo_path": "/abs/path"}'
codebase-memory-mcp cli search_graph '{"name_pattern": ".*Handler.*", "label": "Function"}'
codebase-memory-mcp cli trace_path '{"function_name": "Search", "direction": "both"}'
codebase-memory-mcp cli query_graph '{"query": "MATCH (f:Function) RETURN f.name LIMIT 5"}'
codebase-memory-mcp cli list_projects
```

## MCP tools (14)

**Indexing**: `index_repository`, `list_projects`, `delete_project`, `index_status`

**Querying**: `search_graph`, `trace_path`, `detect_changes`, `query_graph`, `get_graph_schema`, `get_code_snippet`, `get_architecture`, `search_code`, `manage_adr`, `ingest_traces`

Run `get_graph_schema` first to discover node labels, edge types, and property definitions for the current project.

## Auto-index

Enable automatic indexing on session start:

```bash
codebase-memory-mcp config set auto_index true
codebase-memory-mcp config set auto_index_limit 50000
```

When enabled, new projects are indexed automatically on first connection. Previously-indexed projects get a background watcher for git-based change detection.

## Updating and uninstalling

```bash
codebase-memory-mcp update           # self-update to latest release
codebase-memory-mcp uninstall        # removes agent configs, skills, hooks, instructions
                                     # (does NOT remove the binary or SQLite DBs)
codebase-memory-mcp config reset all # restore default config
```

## Performance notes (from upstream benchmarks)

- Linux kernel (28M LOC, 75K files) full index: 3 min
- Average repo: milliseconds
- Cypher query: <1ms
- Dead-code scan: ~150ms
- Trace call path depth 5: <10ms
- Five structural queries ≈ 3,400 tokens vs ≈412,000 via grep (99.2% reduction)

## Privacy

100% local. No telemetry, no analytics, no API keys. Code and queries never leave your machine. SQLite at `~/.cache/codebase-memory-mcp/` (override with `CBM_CACHE_DIR`).

## Provenance

External tool. Not authored by opencode-global-config. This skill is an orientation document only — install via the binary's own installer. License: MIT (upstream). Upstream: https://github.com/DeusData/codebase-memory-mcp. Preprint: https://arxiv.org/abs/2603.27277.

## Anti-patterns

- **Don't use for tiny projects.** <20 files: `grep` is faster.
- **Don't use for Markdown/docs analysis.** graphify handles those better.
- **Don't re-index on every commit.** Use the watcher; it's already enabled by default after `auto_index true`.
- **Don't ignore Hybrid LSP results.** When the server says `RESOLVED_CALLS` vs plain `CALLS`, the resolved ones are type-aware — trust them more than grep.
- **Don't commit `.codebase-memory/graph.db.zst` to this repo.** It's a binary artifact that should live per-user, not in the opencode-global-config source.