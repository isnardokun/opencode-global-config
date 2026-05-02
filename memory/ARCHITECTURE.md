# OpenCode Memory Bank

Persistent file-based memory system for tracking context across sessions.

## Design Principles

- **File-based** — fully inspectable, editable by humans, version-control compatible
- **Header-indexed** — search by frontmatter fields, not vector similarity
- **No vector DB required** — plain markdown, no embeddings

## Structure

```
memory/
├── INDEX.md              # Header index for fast lookup
├── ARCHITECTURE.md       # This file
├── projects/             # Per-project memory
│   └── [project]/
│       ├── context.md        # Current project state
│       ├── decisions/        # Architecture decisions (ADR)
│       └── patterns/         # Detected code patterns
└── context/              # Global context
    └── global.md
```

## Observation Format

Each memory entry is a markdown file with frontmatter:

```markdown
---
id: obs_20260501-143000-a1b2
date: 2026-05-01 14:30:00
project: my-project
type: bugfix|feature|decision|note|config|refactor|review
summary: Short description
---

Full content here...
```

## 3-Layer Retrieval

Memory is loaded progressively to minimize token use:

| Layer | What it loads | Tokens |
|-------|--------------|--------|
| **search** | IDs + summaries only | ~50-100 |
| **timeline** | Chronological context | ~200 |
| **get** | Full observation content | ~500-1000 |

Use `oc --memory "query"` to search. `oc --memory --context "query"` loads with full content.

## Context Compaction

`oc --compact` asks the model to summarize the current session into a structured document and saves it to `memory/sessions.log`. This is a real summarization prompt — not automatic compaction.

## Commands

```bash
# Search
oc --memory "docker"                      # Search by keyword
oc --memory --context "auth"              # Search with full content

# Save
oc --remember "note"                      # Save to global context
oc --remember -p project "note"           # Save to project context
oc --remember -p project -t decision "." # Save as ADR

# Compact session context
oc --compact
```
