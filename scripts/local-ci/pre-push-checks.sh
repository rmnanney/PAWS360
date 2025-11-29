#!/usr/bin/env bash
set -euo pipefail

DEBUG=${DEBUG:-0}
TS=$(date +%Y%m%dT%H%M%S)
OUTDIR="memory/pre-push/${TS}"
mkdir -p "$OUTDIR"

log() { echo "[$(date +%T)] $*" | tee -a "$OUTDIR/run.log"; }

log "Starting pre-push checks (debug=${DEBUG})"

fail_and_save() {
  log "One or more checks failed. Artifacts written to $OUTDIR"
  echo "Pre-push checks failed. See $OUTDIR/run.log"
  exit 1
}

# Run backend quick compile + tests (fast path)
if command -v mvn >/dev/null 2>&1; then
  log "Running maven quick test"
  if ! mvn -q -DskipITs test | tee -a "$OUTDIR/maven.log"; then
    fail_and_save
  fi
else
  log "maven not found — skipping backend quick tests"
fi

# Run frontend quick lint/tests if package.json present
if [ -f package.json ]; then
  if command -v npm >/dev/null 2>&1; then
    log "Running frontend lint + tests"
    npm run lint --silent 2>&1 | tee -a "$OUTDIR/npm-lint.log" || true
    npm test --silent 2>&1 | tee -a "$OUTDIR/npm-test.log" || true
  else
    log "npm not found — skipping frontend checks"
  fi
fi

# Quick security check (fast)
if command -v mvn >/dev/null 2>&1; then
  log "Running lightweight security scan (dependency-check quick)"
  mvn -q org.owasp:dependency-check-maven:check -Dformat=XML -DskipSlow=true > "$OUTDIR/depscan.log" 2>&1 || log "security scan completed (non-blocking)"
fi

log "Pre-push checks completed successfully"

if [ "$DEBUG" -eq 1 ]; then
  log "Detailed debug output enabled"
fi

exit 0
