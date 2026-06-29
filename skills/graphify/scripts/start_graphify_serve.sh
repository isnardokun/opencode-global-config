#!/usr/bin/env bash
# Start graphify_serve detached from any shell session.
# Usage: ./start_graphify_serve.sh [port] [dir] [interval]

set -e

PORT="${1:-8765}"
DIR="${2:-/home/ram/.config/opencode/graphify-out}"
INTERVAL="${3:-300}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kill existing instance on this port
pkill -f "graphify_serve.py.*--port $PORT" 2>/dev/null || true
sleep 1

# Generate graph if missing
if [ ! -f "$DIR/graph.json" ]; then
    echo "No graph.json in $DIR. Running graphify update first..."
    graphify update "$(dirname "$DIR")"
fi

# Always regenerate HTML
python3 "$SCRIPT_DIR/graphify_html.py" "$DIR"

# Start server detached
echo "Starting graphify_serve on port $PORT serving $DIR (interval=${INTERVAL}s)..."
setsid nohup python3 "$SCRIPT_DIR/graphify_serve.py" --dir "$DIR" --port "$PORT" --interval "$INTERVAL" \
    < /dev/null > /tmp/graphify-serve.log 2>&1 &
disown

sleep 2

if ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
    echo "OK: server listening on http://127.0.0.1:$PORT/"
    echo "Endpoints:"
    echo "  http://127.0.0.1:$PORT/graph.html"
    echo "  http://127.0.0.1:$PORT/GRAPH_REPORT.md"
    echo "  http://127.0.0.1:$PORT/health"
    pgrep -af graphify_serve | head -1
else
    echo "ERROR: server did not start. Log:"
    cat /tmp/graphify-serve.log
    exit 1
fi
