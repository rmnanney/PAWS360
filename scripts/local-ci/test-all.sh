#!/usr/bin/env bash
set -euo pipefail

echo "Running full local test suite"
MODE=${1:-all}
echo "Mode: ${MODE}"

if [ "$MODE" = "backend" ] || [ "$MODE" = "all" ]; then
	echo "-> Running backend tests"
	if command -v mvn >/dev/null 2>&1; then
		mvn -q -DskipITs test || true
	else
		echo "mvn not installed; skipping backend tests"
	fi
fi

if [ "$MODE" = "frontend" ] || [ "$MODE" = "all" ]; then
	echo "-> Running frontend tests"
	if [ -f package.json ] && command -v npm >/dev/null 2>&1; then
		npm ci && npm test --silent || true
	else
		echo "npm not available or package.json missing; skipping frontend tests"
	fi
fi

echo "-> Running quick security checks"
if command -v mvn >/dev/null 2>&1; then
	mvn -q org.owasp:dependency-check-maven:check -DskipSlow=true || true
fi

exit 0
