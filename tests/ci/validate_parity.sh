#!/bin/bash
# Test: Configuration parity validation
# Purpose: Verify config-diff.sh correctly identifies differences between environments
# Related Tasks: T118

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIFF_SCRIPT="$PROJECT_ROOT/scripts/config-diff.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result function
test_result() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Handle range expectations like "0-2"
    if [[ "$expected" == *"-"* ]]; then
        local min=$(echo "$expected" | cut -d'-' -f1)
        local max=$(echo "$expected" | cut -d'-' -f2)
        if [ "$actual" -ge "$min" ] && [ "$actual" -le "$max" ]; then
            echo -e "${GREEN}✓${NC} $test_name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return
        fi
    elif [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return
    fi
    
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "=========================================="
echo "Configuration Parity Validation Test"
echo "=========================================="
echo ""

# Test 1: Script exists and is executable
echo "Test 1: Script executable check"
if [ -x "$CONFIG_DIFF_SCRIPT" ]; then
    test_result "config-diff.sh is executable" "true" "true"
else
    test_result "config-diff.sh is executable" "true" "false"
fi

# Test 2: Critical params schema exists
echo ""
echo "Test 2: Critical parameters schema"
CRITICAL_PARAMS="$PROJECT_ROOT/config/critical-params.json"
if [ -f "$CRITICAL_PARAMS" ]; then
    # Validate JSON syntax
    if jq empty "$CRITICAL_PARAMS" 2>/dev/null; then
        test_result "critical-params.json is valid JSON" "true" "true"
    else
        test_result "critical-params.json is valid JSON" "true" "false"
    fi
else
    test_result "critical-params.json exists" "true" "false"
fi

# Test 3: Reference configs exist
echo ""
echo "Test 3: Reference configuration files"
if [ -f "$PROJECT_ROOT/config/staging/docker-compose.yml" ]; then
    test_result "staging reference config exists" "true" "true"
else
    test_result "staging reference config exists" "true" "false"
fi

if [ -f "$PROJECT_ROOT/config/production/docker-compose.yml" ]; then
    test_result "production reference config exists" "true" "true"
else
    test_result "production reference config exists" "true" "false"
fi

# Test 4: Script accepts valid arguments
echo ""
echo "Test 4: Script argument validation"
set +e  # Allow script to fail
bash "$CONFIG_DIFF_SCRIPT" staging >/dev/null 2>&1
STAGING_EXIT=$?
set -e

# Exit codes 0, 1, 2 are all valid (0=match, 1=warnings, 2=critical)
if [ "$STAGING_EXIT" -le 2 ]; then
    test_result "staging argument accepted (exit $STAGING_EXIT)" "0-2" "$STAGING_EXIT"
else
    test_result "staging argument accepted (exit $STAGING_EXIT)" "0-2" "$STAGING_EXIT"
fi

set +e
bash "$CONFIG_DIFF_SCRIPT" production >/dev/null 2>&1
PROD_EXIT=$?
set -e

if [ "$PROD_EXIT" -le 2 ]; then
    test_result "production argument accepted (exit $PROD_EXIT)" "0-2" "$PROD_EXIT"
else
    test_result "production argument accepted (exit $PROD_EXIT)" "0-2" "$PROD_EXIT"
fi

# Test 5: Script rejects invalid arguments
echo ""
echo "Test 5: Invalid argument handling"
set +e
ERROR_OUTPUT=$(bash "$CONFIG_DIFF_SCRIPT" invalid 2>&1)
INVALID_EXIT=$?
set -e

if [ "$INVALID_EXIT" = "3" ] && echo "$ERROR_OUTPUT" | grep -q "Usage:"; then
    test_result "rejects invalid environment" "true" "true"
else
    test_result "rejects invalid environment (exit $INVALID_EXIT)" "true" "false"
fi

# Test 6: Output format validation
echo ""
echo "Test 6: Output format"
OUTPUT=$(bash "$CONFIG_DIFF_SCRIPT" staging 2>&1 || true)
if echo "$OUTPUT" | grep -qE "(✓|✗|⚠️|Summary)"; then
    test_result "output contains expected symbols" "true" "true"
else
    test_result "output contains expected symbols" "true" "false"
fi

# Test 7: jq dependency check
echo ""
echo "Test 7: Dependency validation"
if command -v jq >/dev/null 2>&1; then
    test_result "jq is installed" "true" "true"
else
    test_result "jq is installed" "true" "false"
fi

# Final summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total tests: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo "Failed: 0"
    echo ""
    echo -e "${GREEN}✅ All parity validation tests passed${NC}"
    exit 0
fi
