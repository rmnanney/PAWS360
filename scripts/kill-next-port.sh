#!/usr/bin/env bash
# Kill any processes bound to port 3000 or running 'next dev'
set -euo pipefail

PORT=3000
# Kill by port
pids=$(lsof -ti tcp:$PORT || true)
if [ -n "$pids" ]; then
  echo "Killing processes on port $PORT: $pids"
  kill -9 $pids || true
fi
# Also kill any 'next dev' processes (if any)
pgids=$(pgrep -f "next dev" || true)
if [ -n "$pgids" ]; then
  echo "Killing next dev processes: $pgids"
  pkill -f "next dev" || true
fi

# Display status
ss -lntp | grep ":$PORT " || true
