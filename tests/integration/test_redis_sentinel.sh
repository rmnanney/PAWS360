#!/usr/bin/env bash
#
# Integration Test: Redis Sentinel High Availability
# Tests: Master discovery, sentinel quorum, promotion testing
# Usage: bash tests/integration/test_redis_sentinel.sh
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
echo "Redis Sentinel HA Integration Test"
echo "========================================"
echo ""

# Check if Redis containers are running
info "Checking Redis container status..."
REQUIRED_CONTAINERS=("redis-master" "redis-replica1" "redis-replica2" "redis-sentinel1" "redis-sentinel2" "redis-sentinel3")
for container in "${REQUIRED_CONTAINERS[@]}"; do
    if ! docker ps --filter "name=$container" --filter "status=running" --format "{{.Names}}" | grep -q "$container"; then
        fail "$container container is not running"
        echo ""
        echo "Start the environment with: make dev-up"
        exit 1
    fi
done
pass "All Redis containers are running"

# Test 1: Master discovery
info "Test 1: Verifying master discovery..."
MASTER_INFO=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster 2>/dev/null || echo "")
if [[ -n "$MASTER_INFO" ]]; then
    MASTER_IP=$(echo "$MASTER_INFO" | head -1)
    MASTER_PORT=$(echo "$MASTER_INFO" | tail -1)
    pass "Master discovered at $MASTER_IP:$MASTER_PORT"
else
    fail "Failed to discover master"
fi

# Test 2: Sentinel quorum verification
info "Test 2: Verifying sentinel quorum..."
SENTINEL_COUNT=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels mymaster 2>/dev/null | grep -c "name" || true)
# sentinels mymaster returns other sentinels (not including self), so we expect 2
if [[ "$SENTINEL_COUNT" -eq 2 ]]; then
    pass "Sentinel quorum achieved (3 sentinels total)"
else
    fail "Sentinel count is $((SENTINEL_COUNT + 1)) (expected 3)"
fi

# Test 3: Replica count verification
info "Test 3: Verifying replica count..."
REPLICA_COUNT=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL replicas mymaster 2>/dev/null | grep -c "name" || true)
if [[ "$REPLICA_COUNT" -eq 2 ]]; then
    pass "2 replicas detected"
else
    fail "Replica count is $REPLICA_COUNT (expected 2)"
fi

# Test 4: Master reachability
info "Test 4: Testing master connectivity..."
if docker exec redis-master redis-cli PING 2>/dev/null | grep -q "PONG"; then
    pass "Master is reachable and responding"
else
    fail "Master is not responding to PING"
fi

# Test 5: Replica replication status
info "Test 5: Checking replica replication status..."
REPLICAS_OK=0
for replica in "redis-replica1" "redis-replica2"; do
    REPL_STATUS=$(docker exec "$replica" redis-cli INFO replication 2>/dev/null | grep "master_link_status" | cut -d':' -f2 | tr -d '\r\n' || echo "")
    if [[ "$REPL_STATUS" == "up" ]]; then
        ((REPLICAS_OK++))
    else
        fail "$replica replication status is $REPL_STATUS (expected: up)"
    fi
done

if [[ "$REPLICAS_OK" -eq 2 ]]; then
    pass "All replicas are replicating from master"
fi

# Test 6: Write/Read consistency test
info "Test 6: Testing write/read consistency..."
TEST_KEY="test:sentinel:$(date +%s)"
TEST_VALUE="test-value-$(date +%s)"

# Write to master
if docker exec redis-master redis-cli SET "$TEST_KEY" "$TEST_VALUE" >/dev/null 2>&1; then
    pass "Write to master succeeded"
    
    # Wait for replication
    sleep 1
    
    # Read from master
    MASTER_VALUE=$(docker exec redis-master redis-cli GET "$TEST_KEY" 2>/dev/null || echo "")
    if [[ "$MASTER_VALUE" == "$TEST_VALUE" ]]; then
        pass "Read from master succeeded"
    else
        fail "Read from master failed (expected: $TEST_VALUE, got: $MASTER_VALUE)"
    fi
    
    # Read from replicas
    REPLICAS_CONSISTENT=true
    for replica in "redis-replica1" "redis-replica2"; do
        REPLICA_VALUE=$(docker exec "$replica" redis-cli GET "$TEST_KEY" 2>/dev/null || echo "")
        if [[ "$REPLICA_VALUE" != "$TEST_VALUE" ]]; then
            REPLICAS_CONSISTENT=false
            fail "$replica has inconsistent value (expected: $TEST_VALUE, got: $REPLICA_VALUE)"
        fi
    done
    
    if [[ "$REPLICAS_CONSISTENT" == true ]]; then
        pass "Data replicated to all replicas"
    fi
    
    # Cleanup test key
    docker exec redis-master redis-cli DEL "$TEST_KEY" >/dev/null 2>&1 || true
else
    fail "Write to master failed"
fi

# Test 7: Sentinel monitoring status
info "Test 7: Checking sentinel monitoring status..."
MONITORING_STATUS=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL master mymaster 2>/dev/null | grep "flags" | cut -d':' -f2 | tr -d '\r\n' || echo "")
if [[ "$MONITORING_STATUS" == "master" ]]; then
    pass "Sentinel is monitoring master correctly"
else
    fail "Sentinel monitoring status is $MONITORING_STATUS (expected: master)"
fi

# Test 8: Failover simulation (optional, requires master restart capability)
info "Test 8: Simulating master failover..."

# Get current master container name
CURRENT_MASTER=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster 2>/dev/null | head -1 || echo "")
if [[ -n "$CURRENT_MASTER" ]]; then
    # Determine which container is the master
    MASTER_CONTAINER=""
    if docker exec redis-master redis-cli INFO replication 2>/dev/null | grep -q "role:master"; then
        MASTER_CONTAINER="redis-master"
    elif docker exec redis-replica1 redis-cli INFO replication 2>/dev/null | grep -q "role:master"; then
        MASTER_CONTAINER="redis-replica1"
    elif docker exec redis-replica2 redis-cli INFO replication 2>/dev/null | grep -q "role:master"; then
        MASTER_CONTAINER="redis-replica2"
    fi
    
    if [[ -n "$MASTER_CONTAINER" ]]; then
        info "Current master container: $MASTER_CONTAINER"
        
        # Pause the master
        docker pause "$MASTER_CONTAINER" >/dev/null 2>&1
        info "Paused $MASTER_CONTAINER, waiting for failover..."
        
        # Wait for failover (max 45 seconds)
        FAILOVER_TIME=0
        NEW_MASTER=""
        while [[ "$FAILOVER_TIME" -lt 45 ]]; do
            sleep 2
            ((FAILOVER_TIME+=2))
            
            NEW_MASTER=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster 2>/dev/null | head -1 || echo "")
            if [[ -n "$NEW_MASTER" && "$NEW_MASTER" != "$CURRENT_MASTER" ]]; then
                break
            fi
        done
        
        # Unpause the old master
        docker unpause "$MASTER_CONTAINER" >/dev/null 2>&1
        
        if [[ -n "$NEW_MASTER" && "$NEW_MASTER" != "$CURRENT_MASTER" ]]; then
            pass "Failover completed in ${FAILOVER_TIME}s (new master: $NEW_MASTER)"
        else
            fail "Failover did not complete within 45s"
        fi
        
        # Wait for old master to rejoin as replica
        info "Waiting for $MASTER_CONTAINER to rejoin as replica..."
        sleep 5
        
        OLD_MASTER_ROLE=$(docker exec "$MASTER_CONTAINER" redis-cli INFO replication 2>/dev/null | grep "^role:" | cut -d':' -f2 | tr -d '\r\n' || echo "")
        if [[ "$OLD_MASTER_ROLE" == "slave" ]]; then
            pass "$MASTER_CONTAINER rejoined as replica"
        else
            fail "$MASTER_CONTAINER did not rejoin as replica (role: $OLD_MASTER_ROLE)"
        fi
    else
        fail "Could not determine current master container"
    fi
else
    fail "Cannot perform failover test (no master detected)"
fi

# Test 9: Sentinel configuration consistency
info "Test 9: Verifying sentinel configuration consistency..."
QUORUM=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL master mymaster 2>/dev/null | grep "quorum" | cut -d':' -f2 | tr -d '\r\n' || echo "")
if [[ "$QUORUM" -eq 2 ]]; then
    pass "Sentinel quorum configured correctly (2)"
else
    fail "Sentinel quorum is $QUORUM (expected: 2)"
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
    echo -e "${GREEN}✓ All Redis Sentinel tests passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
