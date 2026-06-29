#!/usr/bin/env python3
"""
graphify_serve.py — HTTP server with auto-rebuild for the knowledge graph.

Serves graphify-out/ on a local port and rebuilds the graph periodically
(default: 5 minutes) so the visualizer reflects recent code changes.
Stdlib-only. No browser auto-open (we don't assume X11/headless env).

Usage:
    python3 scripts/graphify_serve.py [--port 8765] [--interval 300] [--once]
    # Once: build + serve + exit after first rebuild (no background loop).

Defaults:
    port      = 8765
    interval  = 300 seconds (5 minutes)
    graph_dir = ./graphify-out (relative to current dir)
    bind      = 0.0.0.0 (accessible from local network; use 127.0.0.1 if paranoid)

Endpoints:
    /              — redirects to /graph.html
    /graph.html    — interactive vis.js visualization
    /GRAPH_REPORT.md — plain-language report
    /graph.json    — raw graph data
    /health        — JSON status {last_build, next_build, nodes, edges}

Auto-rebuild:
    On startup and every `interval` seconds, runs:
        graphify update <graph_dir.parent>  (AST extraction, no LLM)
        python3 graphify_html.py <graph_dir>  (regenerate graph.html)
    The update is fast (seconds) because we use AST-only via tree-sitter.

Exit codes:
    0 — clean exit (after --once OR SIGTERM)
    1 — port already in use
    2 — graphify not installed
    3 — graphify-out not found

Caveats:
- Auto-rebuild runs in-process, not as a separate job. If graphify hangs,
  the HTTP server stops responding. Use --interval to control frequency.
- First build takes ~5s; subsequent builds ~1s (incremental).
- If you want a cron-style rebuild, use `graphify hook install` instead
  (post-commit hook). This script is for the always-on "browser view".
"""

import argparse
import http.server
import json
import os
import signal
import socketserver
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path


class State:
    """Shared state between HTTP handler and auto-rebuild thread."""
    last_build: str = "never"
    last_build_unix: float = 0.0
    next_build_unix: float = 0.0
    nodes: int = 0
    edges: int = 0
    lock: threading.Lock = threading.Lock()


STATE = State()
SHUTDOWN = threading.Event()


def log(msg: str) -> None:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {msg}", flush=True)


def rebuild(graph_dir: Path) -> bool:
    """Run graphify update + graphify_html. Returns True on success."""
    parent = graph_dir.parent
    log(f"rebuild: starting (target={graph_dir})")

    # Step 1: graphify update (AST extraction, no LLM, ~1-5s typical, 30-180s for large corpora)
    try:
        result = subprocess.run(
            ["graphify", "update", str(parent)],
            capture_output=True, text=True, timeout=180,
        )
        if result.returncode != 0:
            log(f"rebuild: graphify update failed (rc={result.returncode}): "
                f"{result.stderr.strip()[:200]}")
            return False
    except FileNotFoundError:
        log("rebuild: graphify not installed. Run `bash install.sh --with-graphify`.")
        return False
    except subprocess.TimeoutExpired:
        log("rebuild: graphify update timed out (>180s).")
        return False

    # Step 2: graphify_html (regenerate graph.html)
    html_script = Path(__file__).parent / "graphify_html.py"
    if not html_script.exists():
        log(f"rebuild: {html_script} not found, skipping HTML regen")
    else:
        try:
            result = subprocess.run(
                ["python3", str(html_script), str(graph_dir)],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode != 0:
                log(f"rebuild: graphify_html failed (rc={result.returncode}): "
                    f"{result.stderr.strip()[:200]}")
                return False
        except subprocess.TimeoutExpired:
            log("rebuild: graphify_html timed out (>30s).")
            return False

    # Step 3: update state
    graph_json = graph_dir / "graph.json"
    nodes, edges = 0, 0
    if graph_json.exists():
        try:
            with graph_json.open() as f:
                data = json.load(f)
            nodes = len(data.get("nodes", []))
            edges = len(data.get("links", []))
        except (json.JSONDecodeError, OSError):
            pass

    with STATE.lock:
        STATE.last_build = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        STATE.last_build_unix = time.time()
        STATE.nodes = nodes
        STATE.edges = edges
    log(f"rebuild: done ({nodes} nodes, {edges} edges)")
    return True


def rebuild_loop(graph_dir: Path, interval: int) -> None:
    """Background thread: rebuild every `interval` seconds."""
    # Initial build on startup
    rebuild(graph_dir)

    while not SHUTDOWN.is_set():
        with STATE.lock:
            STATE.next_build_unix = time.time() + interval

        # Wait for interval OR shutdown (interruptible)
        if SHUTDOWN.wait(timeout=interval):
            break

        if not SHUTDOWN.is_set():
            rebuild(graph_dir)

    log("rebuild loop: exiting")


class GraphHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler that serves graphify-out/ and adds /health endpoint."""

    def __init__(self, *args, directory=None, **kwargs):
        self.directory = directory
        super().__init__(*args, directory=directory, **kwargs)

    def do_GET(self):
        if self.path == "/" or self.path == "":
            self.path = "/graph.html"
        elif self.path == "/health":
            self.send_health()
            return
        return super().do_GET()

    def send_health(self) -> None:
        with STATE.lock:
            body = json.dumps({
                "status": "ok",
                "last_build": STATE.last_build,
                "last_build_unix": STATE.last_build_unix,
                "next_build_unix": STATE.next_build_unix,
                "nodes": STATE.nodes,
                "edges": STATE.edges,
                "graph_dir": str(Path(self.directory).resolve()),
            }, indent=2).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        # Quieter logging; main loop already prints rebuilds.
        if "/health" not in (args[0] if args else ""):
            super().log_message(format, *args)


def serve(graph_dir: Path, port: int, bind: str, interval: int) -> int:
    if not graph_dir.exists():
        sys.stderr.write(f"ERROR: {graph_dir} not found. Run graphify first.\n")
        return 3

    # Start background rebuild loop
    rebuild_thread = threading.Thread(
        target=rebuild_loop, args=(graph_dir, interval), daemon=True
    )
    rebuild_thread.start()

    # Serve HTTP
    handler = lambda *a, **kw: GraphHandler(*a, directory=str(graph_dir), **kw)
    try:
        with socketserver.TCPServer((bind, port), handler) as httpd:
            sa = httpd.socket.getsockname()
            log(f"serving {graph_dir} on http://{sa[0]}:{sa[1]}/ "
                f"(rebuild every {interval}s)")
            log(f"  /graph.html    — interactive visualization")
            log(f"  /GRAPH_REPORT.md — plain-language report")
            log(f"  /graph.json    — raw graph data")
            log(f"  /health        — JSON status")
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                log("SIGINT received, shutting down...")
            finally:
                SHUTDOWN.set()
                rebuild_thread.join(timeout=5)
    except OSError as e:
        if "Address already in use" in str(e):
            sys.stderr.write(f"ERROR: port {port} already in use.\n"
                             f"  Try: --port <other>\n"
                             f"  Or:  pkill -f graphify_serve\n")
            return 1
        raise
    except FileNotFoundError as e:
        sys.stderr.write(f"ERROR: graphify not installed: {e}\n")
        return 2

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Serve graphify-out/ with auto-rebuild (HTTP + watch)."
    )
    parser.add_argument("--port", type=int, default=8765,
                        help="HTTP port (default: 8765)")
    parser.add_argument("--bind", default="0.0.0.0",
                        help="Bind address (default: 0.0.0.0)")
    parser.add_argument("--interval", type=int, default=300,
                        help="Auto-rebuild interval in seconds (default: 300)")
    parser.add_argument("--once", action="store_true",
                        help="Build once and exit (no HTTP server)")
    parser.add_argument("--dir", default="./graphify-out",
                        help="graphify-out directory (default: ./graphify-out)")
    args = parser.parse_args()

    graph_dir = Path(args.dir).resolve()

    # Signal handlers for clean shutdown
    def handle_signal(signum, frame):
        log(f"signal {signum} received")
        SHUTDOWN.set()
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    if args.once:
        return 0 if rebuild(graph_dir) else 1

    return serve(graph_dir, args.port, args.bind, args.interval)


if __name__ == "__main__":
    sys.exit(main())
