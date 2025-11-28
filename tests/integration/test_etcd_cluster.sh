#!/usr/bin/env bash
#
# Integration Test: etcd Cluster Health
# Tests: Quorum validation, member list verification, endpoint health checks
# Usage: bash tests/integration/test_etcd_cluster.sh
# Exit: 0=pass, 1=fail
#

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
    ((TESTS_RUN++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
    ((TESTS_RUN++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Test setup
echo "========================================"
echo "etcd Cluster Health Integration Test"
echo "========================================"
echo ""

# Check if etcd containers are running
info "Checking etcd container status..."
for i in 1 2 3; do
    if ! docker ps --filter "name=etcd${i}" --filter "status=running" --format "{{.Names}}" | grep -q "etcd${i}"; then
        fail "etcd${i} container is not running"
        echo ""
        echo "Start the environment with: make dev-up"
        exit 1
    fi
done
pass "All etcd containers are running"

# Test 1: Cluster member list
info "Test 1: Verifying cluster member list..."
MEMBER_COUNT=$(docker exec etcd1 etcdctl member list 2>/dev/null | wc -l)
if [[ "$MEMBER_COUNT" -eq 3 ]]; then
    pass "Cluster has 3 members"
else
    fail "Cluster has $MEMBER_COUNT members (expected 3)"
fi

# Test 2: Endpoint health checks
info "Test 2: Checking endpoint health..."
ENDPOINTS="http://etcd1:2379,http://etcd2:2379,http://etcd3:2379"
HEALTH_OUTPUT=$(docker exec etcd1 etcdctl --endpoints="$ENDPOINTS" endpoint health 2>&1)

HEALTHY_COUNT=$(echo "$HEALTH_OUTPUT" | grep -c "is healthy" || true)
if [[ "$HEALTHY_COUNT" -eq 3 ]]; then
    pass "All 3 endpoints are healthy"
else
    fail "Only $HEALTHY_COUNT/3 endpoints are healthy"
    echo "$HEALTH_OUTPUT"
fi

# Test 3: Quorum verification (write operation)
info "Test 3: Verifying quorum with write operation..."
TEST_KEY="test-$(date +%s)"
TEST_VALUE="integration-test-value"

if docker exec etcd1 etcdctl put "$TEST_KEY" "$TEST_VALUE" >/dev/null 2>&1; then
    pass "Write operation succeeded (quorum functional)"
    
    # Verify value can be read
    READ_VALUE=$(docker exec etcd1 etcdctl get "$TEST_KEY" --print-value-only 2>/dev/null || echo "")
    if [[ "$READ_VALUE" == "$TEST_VALUE" ]]; then
        pass "Read operation succeeded (value matches)"
    else
        fail "Read operation failed (expected: $TEST_VALUE, got: $READ_VALUE)"
    fi
    
    # Cleanup test key
    docker exec etcd1 etcdctl del "$TEST_KEY" >/dev/null 2>&1 || true
else
    fail "Write operation failed (quorum issue)"
fi

# Test 4: Leader election status
info "Test 4: Checking leader election status..."
LEADER_COUNT=$(docker exec etcd1 etcdctl endpoint status --endpoints="$ENDPOINTS" --write-out=table 2>/dev/null | grep -c "true" || true)
if [[ "$LEADER_COUNT" -eq 1 ]]; then
    pass "Exactly one leader elected"
else
    fail "Leader count is $LEADER_COUNT (expected 1)"
fi

# Test 5: Data consistency across members
info "Test 5: Verifying data consistency across all members..."
CONSISTENCY_KEY="consistency-test-$(date +%s)"
CONSISTENCY_VALUE="consistency-value-$(date +%s)"

# Write to etcd1
docker exec etcd1 etcdctl put "$CONSISTENCY_KEY" "$CONSISTENCY_VALUE" >/dev/null 2>&1

# Small delay for replication
sleep 1

# Read from all three nodes
CONSISTENT=true
for i in 1 2 3; do
    VALUE=$(docker exec "etcd${i}" etcdctl get "$CONSISTENCY_KEY" --print-value-only 2>/dev/null || echo "")
    if [[ "$VALUE" != "$CONSISTENCY_VALUE" ]]; then
        CONSISTENT=false
        fail "etcd${i} has inconsistent value (expected: $CONSISTENCY_VALUE, got: $VALUE)"
    fi
done

if [[ "$CONSISTENT" == true ]]; then
    pass "Data is consistent across all 3 members"
fi

# Cleanup consistency test key
docker exec etcd1 etcdctl del "$CONSISTENCY_KEY" >/dev/null 2>&1 || true

# Test 6: Cluster revision synchronization
info "Test 6: Checking cluster revision synchronization..."
REVISIONS=()
for i in 1 2 3; do
    REV=$(docker exec "etcd${i}" etcdctl endpoint status --endpoints="http://etcd${i}:2379" --write-out=json 2>/dev/null | grep -o '"revision":[0-9]*' | head -1 | cut -d':' -f2 || echo "0")
    REVISIONS+=("$REV")
done

# All revisions should be close (within 5 revisions of each other due to system operations)
MIN_REV=$(printf '%s\n' "${REVISIONS[@]}" | sort -n | head -1)
MAX_REV=$(printf '%s\n' "${REVISIONS[@]}" | sort -n | tail -1)
REV_DIFF=$((MAX_REV - MIN_REV))

if [[ "$REV_DIFF" -le 5 ]]; then
    pass "Cluster revisions are synchronized (diff: $REV_DIFF)"
else
    fail "Cluster revisions are out of sync (diff: $REV_DIFF, min: $MIN_REV, max: $MAX_REV)"
fi

# Test 7: Alarm status check
info "Test 7: Checking for cluster alarms..."
ALARM_OUTPUT=$(docker exec etcd1 etcdctl alarm list 2>/dev/null || echo "")
if [[ -z "$ALARM_OUTPUT" ]]; then
    pass "No cluster alarms detected"
else
    fail "Cluster alarms detected: $ALARM_OUTPUT"
fi

# Summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ "$TESTS_FAILED" -eq 0 ]]; then
    echo -e "${GREEN}✓ All etcd cluster tests passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
