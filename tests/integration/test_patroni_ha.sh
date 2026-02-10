#!/usr/bin/env bash
#
# Integration Test: Patroni High Availability
# Tests: Leader election, replication lag, failover simulation
# Usage: bash tests/integration/test_patroni_ha.sh
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
echo "Patroni HA Integration Test"
echo "========================================"
echo ""

# Check if Patroni containers are running
info "Checking Patroni container status..."
for i in 1 2 3; do
    if ! docker ps --filter "name=patroni${i}" --filter "status=running" --format "{{.Names}}" | grep -q "patroni${i}"; then
        fail "patroni${i} container is not running"
        echo ""
        echo "Start the environment with: make dev-up"
        exit 1
    fi
done
pass "All Patroni containers are running"

# Test 1: Cluster member detection
info "Test 1: Verifying cluster member count..."
MEMBER_COUNT=$(docker exec patroni1 patronictl list 2>/dev/null | grep -c "patroni" || true)
if [[ "$MEMBER_COUNT" -eq 3 ]]; then
    pass "Cluster has 3 members"
else
    fail "Cluster has $MEMBER_COUNT members (expected 3)"
fi

# Test 2: Leader election verification
info "Test 2: Verifying leader election..."
LEADER_COUNT=$(docker exec patroni1 patronictl list 2>/dev/null | grep -c "Leader" || true)
if [[ "$LEADER_COUNT" -eq 1 ]]; then
    pass "Exactly one leader elected"
else
    fail "Leader count is $LEADER_COUNT (expected 1)"
fi

# Get current leader name
CURRENT_LEADER=$(docker exec patroni1 patronictl list 2>/dev/null | grep "Leader" | awk '{print $2}' || echo "")
if [[ -n "$CURRENT_LEADER" ]]; then
    info "Current leader: $CURRENT_LEADER"
fi

# Test 3: Replica status verification
info "Test 3: Verifying replica status..."
REPLICA_COUNT=$(docker exec patroni1 patronictl list 2>/dev/null | grep -c "Replica" || true)
if [[ "$REPLICA_COUNT" -eq 2 ]]; then
    pass "Cluster has 2 replicas"
else
    fail "Cluster has $REPLICA_COUNT replicas (expected 2)"
fi

# Test 4: Replication lag check
info "Test 4: Checking replication lag..."
MAX_LAG=0
for i in 1 2 3; do
    LAG=$(docker exec "patroni${i}" patronictl list 2>/dev/null | grep "patroni${i}" | awk '{print $5}' | grep -o '[0-9]*' || echo "0")
    if [[ "$LAG" -gt "$MAX_LAG" ]]; then
        MAX_LAG="$LAG"
    fi
done

# Replication lag should be minimal (< 10MB)
if [[ "$MAX_LAG" -lt 10 ]]; then
    pass "Replication lag is minimal (max: ${MAX_LAG}MB)"
else
    fail "Replication lag is high (max: ${MAX_LAG}MB)"
fi

# Test 5: Database connectivity from all nodes
info "Test 5: Verifying database connectivity..."
DB_ERRORS=0
for i in 1 2 3; do
    if ! docker exec "patroni${i}" psql -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        fail "Cannot connect to database on patroni${i}"
        ((DB_ERRORS++))
    fi
done

if [[ "$DB_ERRORS" -eq 0 ]]; then
    pass "Database connectivity verified on all nodes"
fi

# Test 6: Write/Read consistency test
info "Test 6: Testing write/read consistency..."
TEST_TABLE="test_patroni_ha_$(date +%s)"

# Create test table on leader
if docker exec patroni1 psql -U postgres -d postgres -c "CREATE TABLE $TEST_TABLE (id SERIAL PRIMARY KEY, value TEXT);" >/dev/null 2>&1; then
    pass "Created test table on cluster"
    
    # Insert test data
    TEST_VALUE="test-value-$(date +%s)"
    if docker exec patroni1 psql -U postgres -d postgres -c "INSERT INTO $TEST_TABLE (value) VALUES ('$TEST_VALUE');" >/dev/null 2>&1; then
        pass "Inserted test data"
        
        # Wait for replication
        sleep 2
        
        # Verify data on all nodes
        CONSISTENT=true
        for i in 1 2 3; do
            READ_VALUE=$(docker exec "patroni${i}" psql -U postgres -d postgres -t -c "SELECT value FROM $TEST_TABLE LIMIT 1;" 2>/dev/null | tr -d '[:space:]' || echo "")
            if [[ "$READ_VALUE" != "$TEST_VALUE" ]]; then
                CONSISTENT=false
                fail "Data not replicated to patroni${i} (expected: $TEST_VALUE, got: $READ_VALUE)"
            fi
        done
        
        if [[ "$CONSISTENT" == true ]]; then
            pass "Data replicated to all nodes"
        fi
    else
        fail "Failed to insert test data"
    fi
    
    # Cleanup test table
    docker exec patroni1 psql -U postgres -d postgres -c "DROP TABLE IF EXISTS $TEST_TABLE;" >/dev/null 2>&1 || true
else
    fail "Failed to create test table"
fi

# Test 7: Patroni REST API health check
info "Test 7: Checking Patroni REST API health..."
API_HEALTHY=0
for i in 1 2 3; do
    HTTP_CODE=$(docker exec "patroni${i}" curl -s -o /dev/null -w "%{http_code}" http://localhost:8008/health 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        ((API_HEALTHY++))
    else
        fail "patroni${i} REST API returned HTTP $HTTP_CODE"
    fi
done

if [[ "$API_HEALTHY" -eq 3 ]]; then
    pass "REST API healthy on all 3 nodes"
fi

# Test 8: Failover simulation (optional, requires cluster restart capability)
info "Test 8: Simulating leader failover..."
if [[ -n "$CURRENT_LEADER" ]]; then
    info "Pausing current leader: $CURRENT_LEADER"
    
    # Record current leader
    OLD_LEADER="$CURRENT_LEADER"
    
    # Pause the leader container
    docker pause "$CURRENT_LEADER" >/dev/null 2>&1
    
    # Wait for failover (max 60 seconds)
    FAILOVER_TIME=0
    NEW_LEADER=""
    while [[ "$FAILOVER_TIME" -lt 60 ]]; do
        sleep 2
        ((FAILOVER_TIME+=2))
        
        # Check for new leader (from a different node)
        if [[ "$OLD_LEADER" == "patroni1" ]]; then
            NEW_LEADER=$(docker exec patroni2 patronictl list 2>/dev/null | grep "Leader" | awk '{print $2}' || echo "")
        else
            NEW_LEADER=$(docker exec patroni1 patronictl list 2>/dev/null | grep "Leader" | awk '{print $2}' || echo "")
        fi
        
        if [[ -n "$NEW_LEADER" && "$NEW_LEADER" != "$OLD_LEADER" ]]; then
            break
        fi
    done
    
    # Unpause the old leader
    docker unpause "$OLD_LEADER" >/dev/null 2>&1
    
    if [[ -n "$NEW_LEADER" && "$NEW_LEADER" != "$OLD_LEADER" ]]; then
        pass "Failover completed in ${FAILOVER_TIME}s (new leader: $NEW_LEADER)"
    else
        fail "Failover did not complete within 60s"
    fi
    
    # Wait for old leader to rejoin as replica
    info "Waiting for $OLD_LEADER to rejoin as replica..."
    sleep 5
    
    REJOIN_STATUS=$(docker exec patroni1 patronictl list 2>/dev/null | grep "$OLD_LEADER" | awk '{print $4}' || echo "")
    if [[ "$REJOIN_STATUS" == "running" ]]; then
        pass "$OLD_LEADER rejoined cluster as replica"
    else
        fail "$OLD_LEADER failed to rejoin (status: $REJOIN_STATUS)"
    fi
else
    fail "Cannot perform failover test (no leader detected)"
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
    echo -e "${GREEN}✓ All Patroni HA tests passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
