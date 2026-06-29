#!/usr/bin/env python3
"""Export codebase-memory-mcp graph to static HTML for offline visualization.

Reads the CBM SQLite database directly (read-only), produces:
  <out>/graph.json — same schema as graphify for tooling reuse
  <out>/graph.html — self-contained vis.js viewer (no server needed)

Usage:
  python3 export_graph.py                                  # default: ~/.cache/codebase-memory-mcp
  python3 export_graph.py /tmp/project.db /tmp/out         # explicit db + out
  python3 export_graph.py --project opencode-global-config # filter to one project
  python3 export_graph.py --help

Stdlib only. Idempotent. Does not modify CBM state, configs, or the DB.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from collections import defaultdict
from pathlib import Path

DEFAULT_CACHE = Path.home() / ".cache" / "codebase-memory-mcp"

PALETTE = {
    "Section": "#7C3AED",
    "Variable": "#0891B2",
    "File": "#475569",
    "Module": "#059669",
    "Function": "#DC2626",
    "Folder": "#0EA5E9",
    "Method": "#EA580C",
    "Class": "#DB2777",
    "Project": "#000000",
}

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>CBM Graph — {project}</title>
<script src="https://unpkg.com/vis-network@9.1.9/standalone/umd/vis-network.min.js"></script>
<style>
  html,body{{margin:0;padding:0;height:100%;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif;background:#0f172a;color:#e2e8f0}}
  #info{{position:absolute;top:0;left:0;right:0;padding:8px 14px;background:#1e293b;border-bottom:1px solid #334155;font-size:13px;z-index:10;display:flex;gap:18px;align-items:center;flex-wrap:wrap}}
  #info b{{color:#f1f5f9}}
  #info .pill{{padding:2px 8px;border-radius:10px;background:#334155;font-size:11px;color:#cbd5e1}}
  #info .pill b{{color:#fff;margin-right:4px}}
  #controls{{position:absolute;top:48px;left:14px;background:#1e293b;border:1px solid #334155;border-radius:6px;padding:10px;z-index:10;font-size:12px}}
  #controls div{{margin:3px 0;cursor:pointer;user-select:none}}
  #controls div:hover{{color:#fff}}
  #controls input{{margin-right:6px}}
  #detail{{position:absolute;top:48px;right:14px;width:340px;max-height:80vh;overflow:auto;background:#1e293b;border:1px solid #334155;border-radius:6px;padding:12px;font-size:12px;z-index:10;display:none;white-space:pre-wrap}}
  #detail h3{{margin:0 0 6px;font-size:13px;color:#f1f5f9}}
  #detail .kv{{color:#94a3b8}}
  #mynetwork{{position:absolute;top:48px;left:0;right:0;bottom:0}}
</style>
</head>
<body>
<div id="info">
  <div><b>codebase-memory-mcp</b> <span class="pill">v{version}</span> <span class="pill"><b id="node-total">…</b> nodes</span> <span class="pill"><b id="edge-total">…</b> edges</span></div>
  <div>project: <span class="pill">{project}</span></div>
  <div>freshness: <span id="freshness" class="pill">…</span></div>
  <div>filter labels: <input id="search" placeholder="search…" style="background:#0f172a;border:1px solid #334155;color:#e2e8f0;padding:3px 8px;border-radius:4px;font-size:12px;width:180px"></div>
</div>
<div id="controls">
  <div style="font-weight:bold;color:#f1f5f9;margin-bottom:6px">Show by label</div>
  <div id="legend">…</div>
</div>
<div id="detail" onclick="this.style.display='none'"></div>
<div id="mynetwork"></div>

<script>
const DATA_NODES = {nodes_json};
const DATA_EDGES = {edges_json};
const DATA_META = {meta_json};

let network, allNodes, allEdges, labelEnabled;

async function init() {{
  allNodes = new vis.DataSet(DATA_NODES.map(n => ({{
    id: n.id, label: n.name.length > 32 ? n.name.slice(0, 32) + '…' : n.name,
    title: (n.title || n.name) + (n.file_path ? '\\n' + n.file_path : ''),
    group: n.group, color: {{ background: n.color, border: '#0f172a', highlight: {{ background: n.color, border: '#fbbf24' }} }}
  }})));
  allEdges = new vis.DataSet(DATA_EDGES.map(e => ({{
    from: e.from, to: e.to, arrows: 'to', color: {{ color: '#475569', highlight: '#fbbf24' }},
    smooth: {{ type: 'continuous' }}
  }})));

  document.getElementById('node-total').textContent = DATA_META.nodes_total;
  document.getElementById('edge-total').textContent = DATA_META.edges_total;
  document.getElementById('freshness').textContent = new Date().toLocaleString('es-MX');

  const labels = {{}};
  DATA_NODES.forEach(n => {{ labels[n.label] = (labels[n.label] || 0) + 1; }});
  labelEnabled = {{}};
  const legend = document.getElementById('legend');
  Object.entries(labels).sort((a,b)=>b[1]-a[1]).forEach(([lab, count]) => {{
    labelEnabled[lab] = true;
    const wrap = document.createElement('div');
    const cb = document.createElement('input');
    cb.type = 'checkbox'; cb.checked = true;
    cb.onchange = () => {{ labelEnabled[lab] = cb.checked; updateFilter(); }};
    const lbl = document.createElement('span');
    lbl.textContent = ` ${{lab}} (${{count}})`;
    lbl.style.color = DATA_NODES.find(n => n.label === lab)?.color || '#888';
    wrap.appendChild(cb); wrap.appendChild(lbl);
    legend.appendChild(wrap);
  }});

  network = new vis.Network(document.getElementById('mynetwork'), {{ nodes: allNodes, edges: allEdges }}, {{
    physics: {{ stabilization: {{ iterations: 200 }}, barnesHut: {{ gravitationalConstant: -8000 }} }},
    interaction: {{ hover: true, tooltipDelay: 100 }},
    nodes: {{ shape: 'dot', size: 8, font: {{ color: '#cbd5e1', size: 10 }} }}
  }});

  network.on('selectNode', e => {{
    const id = e.nodes[0];
    const node = allNodes.get(id);
    const incoming = allEdges.get().filter(x => x.to === id).length;
    const outgoing = allEdges.get().filter(x => x.from === id).length;
    const detail = document.getElementById('detail');
    detail.innerHTML = `<h3>${{node.title || node.label}}</h3><div class="kv">label: ${{node.group}}</div><div class="kv">incoming: ${{incoming}}</div><div class="kv">outgoing: ${{outgoing}}</div><div class="kv" style="margin-top:6px">${{node.title || ''}}</div>` + (node.file_path ? `<div class="kv" style="margin-top:6px">file: ${{node.file_path}}${{node.start_line ? ':' + node.start_line : ''}}</div>` : '');
    detail.style.display = 'block';
  }});

  document.getElementById('search').oninput = updateFilter;
}}

function updateFilter() {{
  const q = document.getElementById('search').value.toLowerCase();
  const visible = allNodes.get().filter(n => {{
    if (!labelEnabled[n.group]) return false;
    if (!q) return true;
    return (n.label + ' ' + (n.title || '')).toLowerCase().includes(q);
  }});
  network.setData({{
    nodes: new vis.DataSet(visible),
    edges: new vis.DataSet(allEdges.get().filter(e => visible.some(n => n.id === e.from) && visible.some(n => n.id === e.to)))
  }});
}}

init();
</script>
</body>
</html>"""


def find_database(cache_dir: Path, project: str | None) -> tuple[Path, str | None]:
    """Pick the right .db file (only one if project specified, else raise)."""
    dbs = sorted(cache_dir.glob("*.db"))
    if not dbs:
        sys.exit(f"error: no .db files in {cache_dir}")
    if project:
        target = cache_dir / f"{project}.db"
        if not target.exists():
            names = [d.stem for d in dbs]
            sys.exit(f"error: project '{project}' not found. available: {names}")
        return target, None
    if len(dbs) == 1:
        return dbs[0], None
    sys.exit(
        f"error: {len(dbs)} db files in {cache_dir}. pass --project NAME to disambiguate. "
        f"available: {[d.stem for d in dbs]}"
    )


def export(db_path: Path, out_dir: Path) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    uri = f"file:{db_path}?mode=ro"
    con = sqlite3.connect(uri, uri=True)
    try:
        nodes_rows = con.execute(
            "SELECT id, label, name, qualified_name, file_path, start_line, end_line FROM nodes"
        ).fetchall()
        edges_rows = con.execute(
            "SELECT source_id, target_id, type FROM edges"
        ).fetchall()
        project_row = con.execute("SELECT name FROM projects LIMIT 1").fetchone()
        project_name = project_row[0] if project_row else db_path.stem
    finally:
        con.close()

    label_counts = defaultdict(int)
    for r in nodes_rows:
        label_counts[r[1]] += 1

    node_list = []
    for r in nodes_rows:
        nid, label, name, qn, fp, sl, el = r
        node_list.append({
            "id": nid,
            "label": label,
            "name": name or qn or f"#{nid}",
            "title": qn or name or "",
            "file_path": fp,
            "start_line": sl,
            "end_line": el,
            "group": label,
            "color": PALETTE.get(label, "#888888"),
        })

    edge_type_counts = defaultdict(int)
    edge_list = []
    node_ids = {n["id"] for n in node_list}
    for s, t, ttype in edges_rows:
        if s in node_ids and t in node_ids:
            edge_list.append({"from": s, "to": t, "type": ttype})
            edge_type_counts[ttype] += 1

    graph = {
        "nodes": node_list,
        "edges": edge_list,
        "meta": {
            "source": "codebase-memory-mcp",
            "project": project_name,
            "nodes_total": len(node_list),
            "edges_total": len(edge_list),
            "labels": dict(label_counts),
            "edge_types": dict(edge_type_counts),
        },
    }

    json_path = out_dir / "graph.json"
    html_path = out_dir / "graph.html"
    with json_path.open("w") as f:
        json.dump(graph, f, indent=2, default=str)
    with html_path.open("w") as f:
        f.write(HTML_TEMPLATE.format(
            project=project_name,
            version="0.6.0+",
            nodes_json=json.dumps(node_list),
            edges_json=json.dumps(edge_list),
            meta_json=json.dumps(graph["meta"]),
        ))

    return {
        "db": str(db_path),
        "out_dir": str(out_dir),
        "json": str(json_path),
        "html": str(html_path),
        "nodes": len(node_list),
        "edges": len(edge_list),
        "labels": dict(label_counts),
        "edges_by_type": dict(edge_type_counts),
        "project": project_name,
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n", 1)[0])
    p.add_argument("db", nargs="?", help="Path to a .db file. If omitted, scans ~/.cache/codebase-memory-mcp/")
    p.add_argument("out", nargs="?", default="./cbm-graph-out", help="Output directory (default: ./cbm-graph-out)")
    p.add_argument("--project", help="Project name (matches db filename stem)")
    args = p.parse_args()

    if args.db:
        db_path = Path(args.db)
        if not db_path.exists():
            sys.exit(f"error: {db_path} does not exist")
        out_dir = Path(args.out)
        summary = export(db_path, out_dir)
    else:
        project = args.project
        db_path, _ = find_database(DEFAULT_CACHE, project)
        out_dir = Path(args.out)
        summary = export(db_path, out_dir)

    print(f"project: {summary['project']}")
    print(f"db:      {summary['db']}")
    print(f"out:     {summary['out_dir']}")
    print(f"json:    {summary['json']} ({os.path.getsize(summary['json']):,} bytes)")
    print(f"html:    {summary['html']} ({os.path.getsize(summary['html']):,} bytes)")
    print(f"nodes:   {summary['nodes']:,}")
    print(f"edges:   {summary['edges']:,}")
    print("labels:  " + ", ".join(f"{k}={v}" for k, v in sorted(summary['labels'].items(), key=lambda x: -x[1])[:6]))
    print("edges:   " + ", ".join(f"{k}={v}" for k, v in sorted(summary['edges_by_type'].items(), key=lambda x: -x[1])[:5]))
    print()
    print(f"Open {summary['html']} in any browser (no server needed).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
