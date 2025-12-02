#!/usr/bin/env bash
set -euo pipefail

OUTDIR="memory/ci-local"
mkdir -p "$OUTDIR"
START=$(date +%s)
echo "Starting local CI run at $(date -Iseconds)" | tee "$OUTDIR/run.log"

# Run docker-compose CI (best-effort)
docker-compose -f docker-compose.ci.yml up --build --abort-on-container-exit --exit-code-from paws360-app paws360-app 2>&1 | tee -a "$OUTDIR/run.log" || true

END=$(date +%s)
DURATION=$((END-START))
SUMMARY="{\"started_at\": \"$(date -d @$START -Iseconds)\", \"completed_at\": \"$(date -d @$END -Iseconds)\", \"duration_seconds\": ${DURATION}}"
echo "$SUMMARY" | tee "$OUTDIR/summary.json"

echo "Local CI run completed in ${DURATION}s"
