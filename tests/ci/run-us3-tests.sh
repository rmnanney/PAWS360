#!/usr/bin/env bash
# Test Runner for User Story 3 Validation
# Executes all deployment safeguard test scenarios with proper environment setup
# JIRA: INFRA-472, INFRA-475 (US3)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}User Story 3 - Deployment Safeguards Test Suite${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Setup test environment
export PRODUCTION_HOST="${PRODUCTION_HOST:-192.168.0.100}"
export ANSIBLE_INVENTORY="${ANSIBLE_INVENTORY:-infrastructure/ansible/inventories/production/hosts}"

# Force DRY_RUN mode for local testing unless explicitly disabled
if [ "${FORCE_LIVE:-false}" = "true" ]; then
  if [ -z "${ANSIBLE_INVENTORY}" ]; then
    echo -e "${RED}ERROR: FORCE_LIVE=true but ANSIBLE_INVENTORY not set${NC}"
    exit 1
  fi
  export DRY_RUN=false
  echo -e "${GREEN}✓ ANSIBLE_INVENTORY set - running in LIVE mode${NC}"
  echo -e "${YELLOW}⚠️  WARNING: Live mode will execute actual deployments!${NC}"
else
  export DRY_RUN=true
  echo -e "${YELLOW}⚠️  Running in DRY RUN mode${NC}"
  echo "   Set FORCE_LIVE=true to run actual deployments (use with caution)"
fi

echo ""
echo "Configuration:"
echo "  PRODUCTION_HOST: $PRODUCTION_HOST"
echo "  ANSIBLE_INVENTORY: $ANSIBLE_INVENTORY"
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

run_test "$SCRIPT_DIR/test-deploy-interruption-rollback.sh" "Test 3.1: Mid-Deployment Interruption Rollback"
run_test "$SCRIPT_DIR/test-deploy-healthcheck-rollback.sh" "Test 3.2: Failed Health Check Rollback"
run_test "$SCRIPT_DIR/test-deploy-partial-prevention.sh" "Test 3.3: Partial Deployment Prevention"
run_test "$SCRIPT_DIR/test-deploy-safe-retry.sh" "Test 3.4: Safe Retry After Safeguard Trigger"

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
  exit 1
else
  echo -e "${GREEN}✅ All tests passed!${NC}"
  echo ""
  exit 0
fi
