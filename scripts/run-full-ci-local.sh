#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; NC="\033[0m"
start_all=$(date +%s)

echo -e "${YELLOW}==> PAWS360 Local CI Orchestrator${NC}"
echo "Working directory: $(pwd)"

usage() {
  cat <<EOF
run-full-ci-local.sh [options]

Runs (roughly) what the GitHub Actions pipeline does, in order:
  1. Backend tests + coverage (Maven)
  2. Build artifact JAR
  3. (Optional) Docker image build (main/develop equivalent)
  4. UI tests via docker-compose.test.yml (re-using built jar)
  5. (Optional) Trivy security scan

Options:
  --include-docker       Build Docker image (simulates docker-build job)
  --include-security     Run Trivy filesystem scan if installed
  --skip-ui              Skip UI (Playwright) tests
  --skip-backend         Skip backend unit/integration tests
  --fast                 Skip coverage + security + docker image build
  -h|--help              Show this help

Environment variables honored:
  TEST_APP_PORT (default 8091)

Requires: Java 21, Maven, Node 18+, docker, docker compose plugin.
EOF
}

INCLUDE_DOCKER=false
INCLUDE_SECURITY=false
SKIP_UI=false
SKIP_BACKEND=false
FAST=false
for arg in "$@"; do
  case "$arg" in
    --include-docker) INCLUDE_DOCKER=true ;;
    --include-security) INCLUDE_SECURITY=true ;;
    --skip-ui) SKIP_UI=true ;;
    --skip-backend) SKIP_BACKEND=true ;;
    --fast) FAST=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

TEST_APP_PORT="${TEST_APP_PORT:-8081}"

section() { echo -e "\n${YELLOW}==> $1${NC}"; }
success() { echo -e "${GREEN}✔ $1${NC}"; }
fail() { echo -e "${RED}✖ $1${NC}"; }

cleanup() {
  section "Cleanup"
  # Navigate to repo root first to ensure infrastructure/docker path exists
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  cd "$SCRIPT_DIR/.." 2>/dev/null || true
  # Preserve volumes (like node_modules cache) unless CLEAN_VOLUMES=true
  if [ "${CLEAN_VOLUMES:-false}" = "true" ]; then
    (cd infrastructure/docker && docker compose -f docker-compose.test.yml down --remove-orphans -v 2>/dev/null || true)
  else
    (cd infrastructure/docker && docker compose -f docker-compose.test.yml down --remove-orphans 2>/dev/null || true)
  fi
}
trap cleanup EXIT

section "1. Backend tests"
if $SKIP_BACKEND; then
  echo "Skipping backend tests (--skip-backend)."
else
  if $FAST; then
    echo "FAST mode: skipping coverage generation."
    mvn -T 1C test -Dspring.profiles.active=test
  else
    mvn -T 1C test jacoco:report -Dspring.profiles.active=test
  fi
  success "Backend tests complete"
fi

section "2. Build JAR artifact"
mvn -T 1C clean package -DskipTests
JAR_PATH=$(ls target/*SNAPSHOT.jar | head -1)
echo "Built artifact: $JAR_PATH"
success "JAR build complete"

if $INCLUDE_DOCKER && ! $FAST; then
  section "3. Docker image build"
  docker build -t paws360:local -f infrastructure/docker/Dockerfile .
  success "Docker image built"
else
  echo "Skipping Docker image build (use --include-docker)."
fi

if ! $SKIP_UI; then
  section "4. UI tests (docker-compose)"
  mkdir -p services
  cp -f "$JAR_PATH" services/
  # Ensure .next directory is writable by container
  chmod -R 777 .next 2>/dev/null || true
  pushd infrastructure/docker >/dev/null
  docker compose -f docker-compose.test.yml down --remove-orphans || true
  TEST_APP_PORT=$TEST_APP_PORT docker compose -f docker-compose.test.yml up -d
  echo "Waiting for backend on :$TEST_APP_PORT ..."
  set +e
  for i in {1..60}; do
    if curl -sf "http://localhost:$TEST_APP_PORT/actuator/health" | grep -q UP; then
      success "Backend is UP"
      break
    fi
    sleep 5
    if [ $i -eq 60 ]; then
      fail "Backend failed to become healthy"; docker compose ps; docker compose logs app || true; exit 1
    fi
  done
  set -e
  echo "Waiting for frontend on :3000 ..."
  for i in {1..60}; do
    if curl -sf "http://localhost:3000" >/dev/null; then
      success "Frontend responding"
      break
    fi
    sleep 5
    # Every 6 iterations (~30s), print a brief status and last logs
    if (( i % 6 == 0 )); then
      echo "...still waiting for frontend (elapsed $((i*5))s)"
      docker compose ps || true
      docker compose logs --tail=50 frontend || true
    fi
    if [ $i -eq 60 ]; then
      fail "Frontend failed to respond"; docker compose logs frontend || true; exit 1
    fi
  done
  popd >/dev/null

  pushd tests/ui >/dev/null
  if [ ! -f package-lock.json ]; then npm install; fi
  npm ci
  npx playwright install chromium
  if $FAST; then echo "FAST mode: running only jest tests if configured"; fi
  # Run Playwright in CI mode with external servers and parallel workers
  # Respect BACKEND_URL for global-setup API logins; default to localhost:${TEST_APP_PORT}
  CI=true PW_EXTERNAL_SERVERS=1 PW_WORKERS="${PW_WORKERS:-$(nproc)}" \
  BASE_URL=http://localhost:3000 BACKEND_URL="http://localhost:${TEST_APP_PORT}" npm test || { fail "UI tests failed"; exit 1; }
  popd >/dev/null
  success "UI tests complete"
else
  echo "Skipping UI tests (use --skip-ui to disable)"
fi

if $INCLUDE_SECURITY && ! $FAST; then
  section "5. Security scan (Trivy)"
  if command -v trivy >/dev/null 2>&1; then
    trivy fs --exit-code 0 --severity HIGH,CRITICAL . || true
    success "Trivy scan completed (non-blocking)"
  else
    echo "Trivy not installed; skipping."
  fi
else
  echo "Skipping security scan (use --include-security)."
fi

total=$(( $(date +%s) - start_all ))
section "Summary"
echo "Total elapsed: ${total}s"
echo "FAST=$FAST INCLUDE_DOCKER=$INCLUDE_DOCKER INCLUDE_SECURITY=$INCLUDE_SECURITY SKIP_UI=$SKIP_UI"
success "Local CI emulation finished"
