#!/usr/bin/env bash
set -euo pipefail
# Test script: runs Next build and export in the app/ workspace and collects diagnostics
# Usage: ./scripts/test-next-build-export.sh

ROOT=$(dirname "$(realpath "$0")")/..
APP_DIR="$ROOT/app"
LOG_DIR="$ROOT/logs/next-build-export"
mkdir -p "$LOG_DIR"

echo "Running Next build+export test in $APP_DIR"
cd "$APP_DIR"

echo "Installing dependencies (npm ci)"
npm ci --no-audit --no-fund --prefer-offline > "$LOG_DIR/npm-ci.log" 2>&1 || {
  echo "npm ci failed — see $LOG_DIR/npm-ci.log" >&2
  tail -n 200 "$LOG_DIR/npm-ci.log" >&2 || true
  exit 1
}

echo "Starting production build (npm run build)"
if ! npm run build > "$LOG_DIR/next-build.log" 2>&1; then
  echo "Next build failed — writing tail of logs (next-build.log)" >&2
  tail -n 400 "$LOG_DIR/next-build.log" >&2 || true
  echo "Full log available at $LOG_DIR/next-build.log" >&2
  exit 1
fi

echo "Running static export (npm run export)"
if ! npm run export > "$LOG_DIR/next-export.log" 2>&1; then
  echo "Next export failed — writing tail of logs (next-export.log)" >&2
  tail -n 400 "$LOG_DIR/next-export.log" >&2 || true

  # Next 15+ has removed `next export` in favor of `output: 'export'` in next.config.
  # In that case treat the absence of the export command as a non-fatal condition —
  # the important check is the build (prerender) step which caught the errors we care about.
  if grep -q "has been removed in favor of 'output: export'" "$LOG_DIR/next-export.log" 2>/dev/null; then
    echo "Note: 'next export' removed on this Next.js version — skipping export step (ok)." >&2
    echo "Full log available at $LOG_DIR/next-export.log" >&2
  else
    echo "Full log available at $LOG_DIR/next-export.log" >&2
    exit 1
  fi
fi

echo "Build+export succeeded — artifacts are in $APP_DIR/out (if applicable)"
echo "Logs saved under $LOG_DIR"

exit 0
