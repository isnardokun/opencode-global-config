# Graph Report - /home/ram/Documentos/claudecode/opencode-global-config  (2026-06-28)

## Corpus Check
- 8 files · ~68,616 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 55 nodes · 64 edges · 9 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]

## God Nodes (most connected - your core abstractions)
1. `GraphHandler` - 7 edges
2. `rebuild()` - 5 edges
3. `generate_benchmark()` - 5 edges
4. `log()` - 4 edges
5. `rebuild_loop()` - 4 edges
6. `serve()` - 4 edges
7. `aggregate_results()` - 4 edges
8. `package_skill()` - 4 edges
9. `main()` - 3 edges
10. `load_graph_from_json()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `serve()` --calls--> `GraphHandler`  [EXTRACTED]
  /home/ram/Documentos/claudecode/opencode-global-config/skills/graphify/scripts/graphify_serve.py → /home/ram/Documentos/claudecode/opencode-global-config/skills/graphify/scripts/graphify_serve.py  _Bridges community 3 → community 1_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.24
Nodes (11): aggregate_results(), calculate_stats(), generate_benchmark(), generate_markdown(), load_run_results(), main(), Aggregate run results into summary statistics.      Returns run_summary with sta, Generate complete benchmark.json from run results. (+3 more)

### Community 1 - "Community 1"
Cohesion: 0.33
Nodes (9): log(), main(), Background thread: rebuild every `interval` seconds., Shared state between HTTP handler and auto-rebuild thread., Run graphify update + graphify_html. Returns True on success., rebuild(), rebuild_loop(), serve() (+1 more)

### Community 2 - "Community 2"
Cohesion: 0.33
Nodes (0): 

### Community 3 - "Community 3"
Cohesion: 0.4
Nodes (2): GraphHandler, HTTP handler that serves graphify-out/ and adds /health endpoint.

### Community 4 - "Community 4"
Cohesion: 0.47
Nodes (5): main(), package_skill(), Check if a path should be excluded from packaging., Package a skill folder into a .skill file.      Args:         skill_path: Path t, should_exclude()

### Community 5 - "Community 5"
Cohesion: 0.5
Nodes (0): 

### Community 6 - "Community 6"
Cohesion: 0.67
Nodes (3): load_graph_from_json(), main(), Load graph.json and return (nx.Graph, communities, community_labels).

### Community 7 - "Community 7"
Cohesion: 0.67
Nodes (3): is_server_ready(), main(), Wait for server to be ready by polling the port.

### Community 8 - "Community 8"
Cohesion: 0.67
Nodes (2): Basic validation of a skill, validate_skill()

## Knowledge Gaps
- **14 isolated node(s):** `Shared state between HTTP handler and auto-rebuild thread.`, `Run graphify update + graphify_html. Returns True on success.`, `Background thread: rebuild every `interval` seconds.`, `HTTP handler that serves graphify-out/ and adds /health endpoint.`, `Load graph.json and return (nx.Graph, communities, community_labels).` (+9 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GraphHandler` connect `Community 3` to `Community 1`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **What connects `Shared state between HTTP handler and auto-rebuild thread.`, `Run graphify update + graphify_html. Returns True on success.`, `Background thread: rebuild every `interval` seconds.` to the rest of the system?**
  _14 weakly-connected nodes found - possible documentation gaps or missing edges._