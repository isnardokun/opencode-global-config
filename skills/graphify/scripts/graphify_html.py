#!/usr/bin/env python3
"""
graphify_html.py — Generate interactive HTML visualization from graph.json.

Reads graph.json (produced by `graphify update` or `graphify extract`) and
writes graph.html (a vis.js-based interactive visualization) into the same
directory. Stdlib-only, no third-party deps required at runtime.

Usage:
    python3 scripts/graphify_html.py [graph_dir] [output_html]

Defaults:
    graph_dir  = ./graphify-out
    output_html = <graph_dir>/graph.html

Exit codes:
    0 — success
    1 — graph.json missing (run `graphify update` first)
    2 — graph.json malformed
    3 — write error

Cherry-picked/adapted from safishamsi/graphify — the v8 CLI does not
expose a graph.html subcommand, so we use the to_html() API directly.
"""

import json
import sys
import os
from pathlib import Path

# Lazy import: graphify must be installed (via install.sh --with-graphify).
# If not, print install hint and exit.
try:
    import networkx as nx
    from graphify.export import to_html
except ImportError:
    sys.stderr.write(
        "ERROR: graphify is not installed. Run:\n"
        "  bash install.sh --with-graphify\n"
        "  # or: uv tool install graphifyy\n"
    )
    sys.exit(4)


def load_graph_from_json(path: Path) -> tuple:
    """Load graph.json and return (nx.Graph, communities, community_labels)."""
    with path.open() as f:
        data = json.load(f)

    if "nodes" not in data or "links" not in data:
        raise ValueError(f"graph.json missing required keys (need 'nodes' and 'links')")

    G = nx.Graph()
    for n in data["nodes"]:
        nid = n.get("id") or n.get("name")
        if nid is None:
            continue
        attrs = {k: v for k, v in n.items() if k not in ("id", "name")}
        G.add_node(nid, **attrs)

    for link in data["links"]:
        src = link.get("source") or link.get("from")
        tgt = link.get("target") or link.get("to")
        if src in G.nodes and tgt in G.nodes:
            attrs = {k: v for k, v in link.items()
                     if k not in ("source", "target", "from", "to")}
            G.add_edge(src, tgt, **attrs)

    # Communities: prefer explicit; fallback to connected components
    if "communities" in data:
        cd = data["communities"]
        if isinstance(cd, dict):
            communities = {int(k): list(v) for k, v in cd.items()}
        elif isinstance(cd, list):
            communities = {i: list(lst) for i, lst in enumerate(cd)}
        else:
            communities = {}
    else:
        communities = {i: list(c) for i, c in enumerate(nx.connected_components(G))}

    # Community labels: prefer explicit; fallback to "Community N"
    cl_data = data.get("community_labels", {})
    community_labels = {}
    for i in communities.keys():
        community_labels[i] = cl_data.get(str(i), cl_data.get(i, f"Community {i}"))

    return G, communities, community_labels


def main() -> int:
    if len(sys.argv) >= 2:
        graph_dir = Path(sys.argv[1]).resolve()
    else:
        graph_dir = Path("./graphify-out").resolve()

    if len(sys.argv) >= 3:
        output_html = Path(sys.argv[2]).resolve()
    else:
        output_html = graph_dir / "graph.html"

    graph_json = graph_dir / "graph.json"
    if not graph_json.exists():
        sys.stderr.write(
            f"ERROR: {graph_json} not found.\n"
            f"Run `graphify update {graph_dir.parent}` first.\n"
        )
        return 1

    try:
        G, communities, community_labels = load_graph_from_json(graph_json)
    except (json.JSONDecodeError, ValueError) as e:
        sys.stderr.write(f"ERROR: malformed graph.json: {e}\n")
        return 2

    try:
        to_html(G, communities, str(output_html), community_labels)
    except ValueError as e:
        # Graph too large for inline HTML viz
        sys.stderr.write(f"ERROR: {e}\n")
        return 3
    except OSError as e:
        sys.stderr.write(f"ERROR: cannot write {output_html}: {e}\n")
        return 3

    size = output_html.stat().st_size
    print(f"OK: {output_html} ({size:,} bytes, {G.number_of_nodes()} nodes, "
          f"{G.number_of_edges()} edges, {len(communities)} communities)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
