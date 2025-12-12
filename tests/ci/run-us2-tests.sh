#!/usr/bin/env bash
# Test Runner for User Story 2 Validation
# Executes all diagnostic test scenarios with proper environment setup
# JIRA: INFRA-472, INFRA-474 (US2)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}User Story 2 - Diagnostics Test Suite${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Setup test environment
export PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
export GRAFANA_URL="${GRAFANA_URL:-http://192.168.0.200:3000}"
export LOKI_URL="${LOKI_URL:-http://192.168.0.200:3100}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-rmnanney/PAWS360}"

# Force DRY_RUN mode for local testing unless explicitly disabled
if [ "${FORCE_LIVE:-false}" = "true" ]; then
  export GITHUB_TOKEN="${GITHUB_TOKEN:-}"
  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}ERROR: FORCE_LIVE=true but GITHUB_TOKEN not set${NC}"
    exit 1
  fi
  export DRY_RUN=false
  echo -e "${GREEN}✓ GITHUB_TOKEN set - running in LIVE mode${NC}"
else
  export DRY_RUN=true
  echo -e "${YELLOW}⚠️  Running in DRY RUN mode${NC}"
  echo "   Set FORCE_LIVE=true to run actual API calls"
fi

echo ""
echo "Configuration:"
echo "  PROMETHEUS_URL: $PROMETHEUS_URL"
echo "  GRAFANA_URL: $GRAFANA_URL"
echo "  LOKI_URL: $LOKI_URL"
echo "  GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "  DRY_RUN: $DRY_RUN"
echo ""

# Test execution tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test scenario
run_test() {
  local test_script="$1"
  local test_name="$2"
  
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Running: $test_name${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Run test in subshell to avoid set -e terminating parent
  if (bash "$test_script"); then
    echo -e "${GREEN}✅ PASS: $test_name${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}❌ FAIL: $test_name${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$test_name")
  fi
}

# Execute all test scenarios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_test "$SCRIPT_DIR/test-runner-degradation-detection.sh" "Test 2.1: Runner Degradation Detection"
run_test "$SCRIPT_DIR/test-automatic-failover.sh" "Test 2.2: Automatic Failover"
run_test "$SCRIPT_DIR/test-monitoring-alerts.sh" "Test 2.3: Monitoring Alerts"
run_test "$SCRIPT_DIR/test-system-recovery.sh" "Test 2.4: System Recovery"

# Report results
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Execution Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "${RED}Failed tests:${NC}"
  for test in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}✗${NC} $test"
  done
  echo ""
  echo -e "${RED}❌ Test suite FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}✅ All tests PASSED${NC}"
  exit 0
fi
