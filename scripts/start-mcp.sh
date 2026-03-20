#!/usr/bin/env bash
set -euo pipefail
# Simple helper to start Chrome (local) with remote debugging and run chrome-devtools-mcp
# Usage: ./scripts/start-mcp.sh [PORT] [PROFILE_DIR] [CHROME_PATH]
PORT=${1:-9222}
PROFILE_DIR=${2:-"$HOME/.config/google-chrome/Profile 1"}
CHROME_CMD=${3:-google-chrome}

echo "Starting Chrome with remote debugging on port $PORT using profile: $PROFILE_DIR"
echo "If Chrome is running, please close it first."
sleep 1

"$CHROME_CMD" --remote-debugging-port="$PORT" --user-data-dir="$PROFILE_DIR" &
CHROME_PID=$!
echo "Chrome started (pid=$CHROME_PID). Waiting a moment for the debug endpoint to appear..."
sleep 2

echo "Starting chrome-devtools-mcp (npx). Press Ctrl+C to stop both MCP and Chrome started by this script."
exec npx -y chrome-devtools-mcp@latest --browser-url="http://127.0.0.1:$PORT"
