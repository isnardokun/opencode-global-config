---
name: cbm-graph-export
description: Export the codebase-memory-mcp knowledge graph from its SQLite store into a self-contained, offline HTML viewer (vis.js) and a machine-readable graph.json. Use when the user wants to visualize the CBM graph without opening an MCP client, share it with someone who can't run CBM, or commit a snapshot for diffing over time. Reads CBM's SQLite read-only — does not modify the index, configs, or the opencode MCP registration. Stdlib-only Python (no dependencies).
---

# CBM Graph Export — offline viewer

A small stdlib Python script that reads `~/.cache/codebase-memory-mcp/*.db` (the SQLite backend that `codebase-memory-mcp` writes when you index a repo) and produces two artefacts:

- `graph.json` — the nodes + edges + meta, the same shape graphify produces (so downstream tooling can swap one for the other)
- `graph.html` — self-contained vis.js viewer, ~600 KB with the data inlined. No server, no fetch — open with `file://` in any modern browser

This fills a gap left by CBM v0.6.0: its `--ui=true --port=9749` HTTP server only spins up when an MCP client is connected. For an offline snapshot you can archive, commit, or email, you need a different path.

## When to use this skill

Invoke when:

- You want to **share the graph** with someone who can't run CBM
- You want to **commit a snapshot** of the graph at a known point (e.g., before a refactor, after onboarding a new module)
- You want a **graph diff** across two indexes (diff `graph.json` between two `git` revisions)
- You want a **web view** without keeping an opencode session alive
- You're working on a **remote box** and don't want to forward port 9749

Don't use when:

- The user wants live query results (`get_architecture`, `trace_path`, etc.) — let the agent invoke the MCP tools directly
- The graph is huge (>50k nodes) — the HTML file becomes >10MB and the browser lags during stabilization

## Install

Already in this repo (this skill). No dependencies. The script lives at `skills/cbm-graph-export/scripts/export_graph.py`.

## Usage

```bash
# Default: scan ~/.cache/codebase-memory-mcp/, requires --project if >1 db present
python3 skills/cbm-graph-export/scripts/export_graph.py --project <name>

# Explicit db + out dir
python3 skills/cbm-graph-export/scripts/export_graph.py \
  ~/.cache/codebase-memory-mcp/<project>.db \
  ./cbm-graph-out

# Help
python3 skills/cbm-graph-export/scripts/export_graph.py --help
```

Then open `cbm-graph-out/graph.html` in any browser. No HTTP server required.

## What you get

```
cbm-graph-out/
├── graph.json    1818 nodes / 1935 edges (opencode-global-config snapshot)
└── graph.html    ~600 KB self-contained, vis.js, pan/zoom + label filter + search
```

The viewer exposes:

- **Pan + zoom** with physics-based layout (200 stabilization iterations)
- **Click a node** → right-side panel with in/out degree + file path
- **Filter by label** (left-side checkboxes) — hide Section/Variable noise, keep Function/File
- **Search by name** (top-right) — substring match on node name + qualified name

## Schema

`graph.json` follows graphify's shape for tooling compat:

```json
{
  "nodes": [{"id": 1, "label": "Function", "name": "...", "title": "...", "file_path": "...", "start_line": 12, "end_line": 34, "group": "Function", "color": "#DC2626"}],
  "edges": [{"from": 1, "to": 2, "type": "CALLS"}],
  "meta": {"source": "codebase-memory-mcp", "project": "...", "nodes_total": 1818, "edges_total": 1935, "labels": {...}, "edge_types": {...}}
}
```

This means downstream tooling (e.g., Mermaid export, dot/graphviz render, or graphify) can consume both `graph.json` flavours without forking.

## Caveats (from upstream v0.6.0 quirks)

- **Section nodes dominate** — CBM extracts section headings from Markdown aggressively (1012 in a typical repo). Hide them in the viewer to see structure.
- **Variable nodes without anchors** — many Variable nodes have no `file_path`/`start_line` (extracted from comments or docs). They show up as orphan dots in the layout.
- **Function count is conservative** — 52 Functions in a 124-file repo. CBM's Hybrid LSP adds more on v0.7+; v0.6.0 only catches AST-level definitions.

## Privacy

The script reads `~/.cache/codebase-memory-mcp/*.db` read-only (`?mode=ro` URI). It never writes back, never sends anything off-host, and never modifies opencode.json or AGENTS.md. The output HTML embeds the graph verbatim — if your graph contains sensitive file paths or symbol names, treat `graph.html` like a `git bundle`: don't publish.

## Anti-patterns

- **Don't run it inside an opencode session** — the file lock on SQLite can race with CBM's writes. Close opencode first, or use a snapshot DB.
- **Don't commit the HTML file** unless you mean it — 600 KB of static content, grows with graph size. Commit the script + the JSON, regenerate the HTML locally.
- **Don't expect live updates** — this is a snapshot. Re-run the script after `codebase-memory-mcp cli index_repository` for fresh data.

## Coexistence

Both can be used together, in any order, with no interference:

| Tool | Reads | Writes | UI | When |
|---|---|---|---|---|
| `codebase-memory-mcp` (MCP) | your code | SQLite + AGENTS.md | needs agent connected | live, structural queries |
| `cbm-graph-export` (this) | the same SQLite | a directory of files | offline HTML | snapshot, share, commit |

The graphify v1.17.0 `--with-graphify` flow is independent (different store at `~/.config/opencode/graphify-out/`, Markdown/PDF focus). Both graphs are complementary; neither supersedes the other.

## Provenance

Skill authored for opencode-global-config on 2026-06-29. Motivation: validated locally that CBM v0.6.0's `--ui=true --port=9749` HTTP server does not bind when no MCP client is connected — leaving no offline way to inspect a graph index. The `export_graph.py` script reads the same SQLite backend and generates a static viewer using the same vis.js approach as `skills/graphify/scripts/graphify_html.py`.

## Source

Upstream CBM: `DeusData/codebase-memory-mcp` (MIT). This skill does NOT modify CBM, vendor its binary, or interact with its MCP registration.
