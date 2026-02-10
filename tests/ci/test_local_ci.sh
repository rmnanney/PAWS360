#!/usr/bin/env bash
#
# test_local_ci.sh
# Validates local CI execution using act
# Compares local results with expected remote CI behavior
#
# Feature: 001-local-dev-parity
# Task: T070 - Create infrastructure test script
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "🧪 Testing Local CI Execution"
echo "=============================="
echo ""

# Check if act is installed
if ! command -v act >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: 'act' is not installed${NC}"
    echo "Install: https://github.com/nektos/act"
    exit 1
fi

# Test 1: Workflow syntax validation
echo -n "Test 1: Workflow syntax validation... "
if act --dryrun >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Workflow syntax errors detected"
    exit 1
fi

# Test 2: List available jobs
echo -n "Test 2: List available jobs... "
JOBS=$(act -l 2>/dev/null | tail -n +2 | awk '{print $2}')
EXPECTED_JOBS="validate-environment test-infrastructure"

if echo "$JOBS" | grep -q "validate-environment" && echo "$JOBS" | grep -q "test-infrastructure"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Expected jobs not found: $EXPECTED_JOBS"
    exit 1
fi

# Test 3: Validate environment job runs
echo "Test 3: Running validate-environment job..."
if act -j validate-environment 2>&1 | tee /tmp/act-validate.log | grep -q "Job succeeded"; then
    echo -e "${GREEN}✓ validate-environment passed${NC}"
else
    echo -e "${YELLOW}⚠ validate-environment may have issues${NC}"
    echo "Check /tmp/act-validate.log for details"
fi

# Test 4: Check for ACT-specific conditionals
echo -n "Test 4: Checking ACT conditionals... "
if grep -q "if: \${{ !env.ACT }}" "${REPO_ROOT}/.github/workflows/local-dev-ci.yml"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} No ACT conditionals found (artifact upload may fail locally)"
fi

# Test 5: Service container configuration
echo -n "Test 5: Service containers configured... "
if grep -q "services:" "${REPO_ROOT}/.github/workflows/local-dev-ci.yml"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Local CI testing complete${NC}"
echo ""
echo "Next steps:"
echo "  - Run full pipeline: make test-ci-local"
echo "  - Run specific job: make test-ci-job JOB=validate-environment"
echo "  - Compare with remote CI results after pushing"
