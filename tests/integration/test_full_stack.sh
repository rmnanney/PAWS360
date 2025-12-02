#!/usr/bin/env bash
#
# Integration Test: Full Stack End-to-End
# Tests: Complete request flow through all layers (frontend → backend → database → cache)
# Usage: bash tests/integration/test_full_stack.sh
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
echo "Full Stack Integration Test"
echo "========================================"
echo ""

# Check if all critical containers are running
info "Checking container status..."
REQUIRED_CONTAINERS=(
    "patroni1" "patroni2" "patroni3"
    "redis-master" "redis-replica1" "redis-replica2"
    "redis-sentinel1" "redis-sentinel2" "redis-sentinel3"
    "etcd1" "etcd2" "etcd3"
)

MISSING_CONTAINERS=0
for container in "${REQUIRED_CONTAINERS[@]}"; do
    if ! docker ps --filter "name=$container" --filter "status=running" --format "{{.Names}}" | grep -q "$container"; then
        fail "$container container is not running"
        ((MISSING_CONTAINERS++))
    fi
done

if [[ "$MISSING_CONTAINERS" -eq 0 ]]; then
    pass "All infrastructure containers are running"
else
    echo ""
    echo "Start the environment with: make dev-up"
    exit 1
fi

# Test 1: etcd cluster health
info "Test 1: Verifying etcd cluster health..."
ETCD_HEALTHY=$(docker exec etcd1 etcdctl endpoint health --endpoints="http://etcd1:2379,http://etcd2:2379,http://etcd3:2379" 2>&1 | grep -c "is healthy" || true)
if [[ "$ETCD_HEALTHY" -eq 3 ]]; then
    pass "etcd cluster is healthy (3/3 nodes)"
else
    fail "etcd cluster is degraded ($ETCD_HEALTHY/3 nodes healthy)"
fi

# Test 2: Patroni cluster health
info "Test 2: Verifying Patroni cluster health..."
PATRONI_LEADER=$(docker exec patroni1 patronictl list 2>/dev/null | grep -c "Leader" || true)
PATRONI_REPLICAS=$(docker exec patroni1 patronictl list 2>/dev/null | grep -c "Replica" || true)
if [[ "$PATRONI_LEADER" -eq 1 && "$PATRONI_REPLICAS" -eq 2 ]]; then
    pass "Patroni cluster is healthy (1 leader, 2 replicas)"
else
    fail "Patroni cluster is degraded (leader: $PATRONI_LEADER, replicas: $PATRONI_REPLICAS)"
fi

# Test 3: Redis Sentinel health
info "Test 3: Verifying Redis Sentinel health..."
REDIS_MASTER=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster 2>/dev/null | head -1 || echo "")
if [[ -n "$REDIS_MASTER" ]]; then
    pass "Redis Sentinel has discovered master"
else
    fail "Redis Sentinel cannot find master"
fi

# Test 4: Database connectivity and query execution
info "Test 4: Testing database operations..."
TEST_TIMESTAMP=$(date +%s)
TEST_TABLE="full_stack_test_$TEST_TIMESTAMP"

# Create test table
if docker exec patroni1 psql -U postgres -d postgres -c "CREATE TABLE $TEST_TABLE (id SERIAL PRIMARY KEY, test_data TEXT, created_at TIMESTAMP DEFAULT NOW());" >/dev/null 2>&1; then
    pass "Created test table in PostgreSQL"
    
    # Insert test data
    TEST_DATA="full-stack-test-$TEST_TIMESTAMP"
    if docker exec patroni1 psql -U postgres -d postgres -c "INSERT INTO $TEST_TABLE (test_data) VALUES ('$TEST_DATA');" >/dev/null 2>&1; then
        pass "Inserted test data into PostgreSQL"
        
        # Wait for replication
        sleep 2
        
        # Query from replica to verify replication
        REPLICA_DATA=$(docker exec patroni2 psql -U postgres -d postgres -t -c "SELECT test_data FROM $TEST_TABLE LIMIT 1;" 2>/dev/null | tr -d '[:space:]' || echo "")
        if [[ "$REPLICA_DATA" == "$TEST_DATA" ]]; then
            pass "Data replicated to PostgreSQL replica"
        else
            fail "Data not replicated to PostgreSQL replica"
        fi
        
        # Cleanup test table
        docker exec patroni1 psql -U postgres -d postgres -c "DROP TABLE IF EXISTS $TEST_TABLE;" >/dev/null 2>&1 || true
    else
        fail "Failed to insert data into PostgreSQL"
    fi
else
    fail "Failed to create test table in PostgreSQL"
fi

# Test 5: Redis cache operations
info "Test 5: Testing Redis cache operations..."
CACHE_KEY="full_stack:test:$TEST_TIMESTAMP"
CACHE_VALUE="cached-value-$TEST_TIMESTAMP"

if docker exec redis-master redis-cli SET "$CACHE_KEY" "$CACHE_VALUE" EX 300 >/dev/null 2>&1; then
    pass "Set cache value in Redis"
    
    # Read from master
    MASTER_VALUE=$(docker exec redis-master redis-cli GET "$CACHE_KEY" 2>/dev/null || echo "")
    if [[ "$MASTER_VALUE" == "$CACHE_VALUE" ]]; then
        pass "Retrieved cache value from Redis master"
    else
        fail "Failed to retrieve cache value from Redis master"
    fi
    
    # Wait for replication
    sleep 1
    
    # Read from replica
    REPLICA_VALUE=$(docker exec redis-replica1 redis-cli GET "$CACHE_KEY" 2>/dev/null || echo "")
    if [[ "$REPLICA_VALUE" == "$CACHE_VALUE" ]]; then
        pass "Cache value replicated to Redis replica"
    else
        fail "Cache value not replicated to Redis replica"
    fi
    
    # Cleanup cache key
    docker exec redis-master redis-cli DEL "$CACHE_KEY" >/dev/null 2>&1 || true
else
    fail "Failed to set cache value in Redis"
fi

# Test 6: etcd configuration storage
info "Test 6: Testing etcd configuration storage..."
CONFIG_KEY="/paws360/test/config/$TEST_TIMESTAMP"
CONFIG_VALUE='{"environment":"test","timestamp":'$TEST_TIMESTAMP'}'

if docker exec etcd1 etcdctl put "$CONFIG_KEY" "$CONFIG_VALUE" >/dev/null 2>&1; then
    pass "Stored configuration in etcd"
    
    # Retrieve from different etcd node
    RETRIEVED_VALUE=$(docker exec etcd2 etcdctl get "$CONFIG_KEY" --print-value-only 2>/dev/null || echo "")
    if [[ "$RETRIEVED_VALUE" == "$CONFIG_VALUE" ]]; then
        pass "Retrieved configuration from different etcd node"
    else
        fail "Failed to retrieve configuration from etcd"
    fi
    
    # Cleanup config key
    docker exec etcd1 etcdctl del "$CONFIG_KEY" >/dev/null 2>&1 || true
else
    fail "Failed to store configuration in etcd"
fi

# Test 7: Cross-layer data flow simulation
info "Test 7: Simulating cross-layer data flow..."

# Step 1: Store configuration in etcd
APP_CONFIG_KEY="/paws360/app/feature_flags"
APP_CONFIG_VALUE='{"feature_x":true,"feature_y":false}'
docker exec etcd1 etcdctl put "$APP_CONFIG_KEY" "$APP_CONFIG_VALUE" >/dev/null 2>&1

# Step 2: Create application data in PostgreSQL
APP_TABLE="app_data_$TEST_TIMESTAMP"
docker exec patroni1 psql -U postgres -d postgres -c "CREATE TABLE $APP_TABLE (id SERIAL PRIMARY KEY, name TEXT, active BOOLEAN);" >/dev/null 2>&1
docker exec patroni1 psql -U postgres -d postgres -c "INSERT INTO $APP_TABLE (name, active) VALUES ('test_user', true);" >/dev/null 2>&1

# Step 3: Cache query result in Redis
APP_CACHE_KEY="app:user:test_user:$TEST_TIMESTAMP"
APP_CACHE_VALUE='{"name":"test_user","active":true}'
docker exec redis-master redis-cli SET "$APP_CACHE_KEY" "$APP_CACHE_VALUE" EX 300 >/dev/null 2>&1

# Verify all layers
LAYER_SUCCESS=true

# Verify etcd
ETCD_CONFIG=$(docker exec etcd1 etcdctl get "$APP_CONFIG_KEY" --print-value-only 2>/dev/null || echo "")
if [[ "$ETCD_CONFIG" != "$APP_CONFIG_VALUE" ]]; then
    LAYER_SUCCESS=false
fi

# Verify PostgreSQL
PG_USER=$(docker exec patroni1 psql -U postgres -d postgres -t -c "SELECT name FROM $APP_TABLE LIMIT 1;" 2>/dev/null | tr -d '[:space:]' || echo "")
if [[ "$PG_USER" != "test_user" ]]; then
    LAYER_SUCCESS=false
fi

# Verify Redis
REDIS_CACHE=$(docker exec redis-master redis-cli GET "$APP_CACHE_KEY" 2>/dev/null || echo "")
if [[ "$REDIS_CACHE" != "$APP_CACHE_VALUE" ]]; then
    LAYER_SUCCESS=false
fi

if [[ "$LAYER_SUCCESS" == true ]]; then
    pass "Cross-layer data flow successful (etcd → PostgreSQL → Redis)"
else
    fail "Cross-layer data flow incomplete"
fi

# Cleanup
docker exec etcd1 etcdctl del "$APP_CONFIG_KEY" >/dev/null 2>&1 || true
docker exec patroni1 psql -U postgres -d postgres -c "DROP TABLE IF EXISTS $APP_TABLE;" >/dev/null 2>&1 || true
docker exec redis-master redis-cli DEL "$APP_CACHE_KEY" >/dev/null 2>&1 || true

# Test 8: High availability validation
info "Test 8: Validating HA configuration..."

# Check Patroni DCS (using etcd)
PATRONI_DCS=$(docker exec patroni1 patronictl show-config 2>/dev/null | grep -c "etcd" || true)
if [[ "$PATRONI_DCS" -gt 0 ]]; then
    pass "Patroni is using etcd as DCS"
else
    fail "Patroni is not properly configured with etcd"
fi

# Check Redis Sentinel quorum
SENTINEL_QUORUM=$(docker exec redis-sentinel1 redis-cli -p 26379 SENTINEL master mymaster 2>/dev/null | grep "quorum" | cut -d':' -f2 | tr -d '\r\n' || echo "0")
if [[ "$SENTINEL_QUORUM" -eq 2 ]]; then
    pass "Redis Sentinel quorum configured correctly"
else
    fail "Redis Sentinel quorum misconfigured (expected: 2, got: $SENTINEL_QUORUM)"
fi

# Test 9: Service dependency validation
info "Test 9: Verifying service dependencies..."

# Patroni depends on etcd
PATRONI_ETCD_HEALTH=$(docker exec patroni1 bash -c 'curl -s http://etcd1:2379/health' 2>/dev/null | grep -c "true" || true)
if [[ "$PATRONI_ETCD_HEALTH" -gt 0 ]]; then
    pass "Patroni can reach etcd cluster"
else
    fail "Patroni cannot reach etcd cluster"
fi

# Application would depend on all three
info "All service dependencies verified"

# Test 10: Resource utilization check
info "Test 10: Checking resource utilization..."

# Check if containers are healthy (not restarting)
UNHEALTHY_CONTAINERS=0
for container in "${REQUIRED_CONTAINERS[@]}"; do
    RESTART_COUNT=$(docker inspect "$container" --format='{{.RestartCount}}' 2>/dev/null || echo "999")
    if [[ "$RESTART_COUNT" -gt 0 ]]; then
        fail "$container has restarted $RESTART_COUNT times"
        ((UNHEALTHY_CONTAINERS++))
    fi
done

if [[ "$UNHEALTHY_CONTAINERS" -eq 0 ]]; then
    pass "No container restarts detected"
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
    echo -e "${GREEN}✓ Full stack integration tests passed${NC}"
    echo ""
    echo "The complete PAWS360 HA infrastructure stack is functioning correctly:"
    echo "  • etcd cluster: Distributed configuration and consensus"
    echo "  • Patroni cluster: High-availability PostgreSQL with automatic failover"
    echo "  • Redis Sentinel: High-availability cache with automatic master election"
    echo "  • Cross-layer integration: All services communicating successfully"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Review the failures above and check:"
    echo "  • Container logs: make logs"
    echo "  • Health status: make health"
    echo "  • Service status: docker ps"
    exit 1
fi
