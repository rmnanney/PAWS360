#!/usr/bin/env bash

# T104: Cache Debugging Capabilities Test
# Feature: 001-local-dev-parity
# User Story: US3 - Rapid Development Iteration
# Test Case: TC-017 - Cache Debugging Capabilities
#
# Validates that developers can flush cache and observe cache population behavior
#
# Prerequisites:
# - Development environment running (make dev-up)
# - Redis master healthy
#
# Success Criteria:
# - Cache flush completes successfully
# - Cache statistics visible before/after flush
# - Request after flush triggers cache population (observable)
# - Cache hit/miss metrics trackable

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== T104: Cache Debugging Capabilities Test ===${NC}"
echo ""

# Configuration
REDIS_CONTAINER="paws360-redis-master"
TEST_KEY="test:cache:debug:$(date +%s)"
TEST_VALUE="CACHE_DEBUG_TEST_VALUE"

# Step 1: Check Redis container running
echo -e "${BLUE}Step 1: Checking Redis container status...${NC}"
if ! docker ps | grep -q "$REDIS_CONTAINER"; then
    echo -e "${RED}ERROR: Redis container not running${NC}"
    echo "Run: make dev-up"
    exit 1
fi
echo -e "${GREEN}✓ Redis container is running${NC}"
echo ""

# Step 2: Get initial cache statistics
echo -e "${BLUE}Step 2: Getting initial cache statistics...${NC}"
INITIAL_DBSIZE=$(docker exec "$REDIS_CONTAINER" redis-cli DBSIZE | xargs)
INITIAL_MEMORY=$(docker exec "$REDIS_CONTAINER" redis-cli INFO memory | grep used_memory_human: | cut -d: -f2 | tr -d '\r')
INITIAL_HITS=$(docker exec "$REDIS_CONTAINER" redis-cli INFO stats | grep keyspace_hits: | cut -d: -f2 | tr -d '\r')
INITIAL_MISSES=$(docker exec "$REDIS_CONTAINER" redis-cli INFO stats | grep keyspace_misses: | cut -d: -f2 | tr -d '\r')

echo "Initial cache state:"
echo "  Keys:           $INITIAL_DBSIZE"
echo "  Memory:         $INITIAL_MEMORY"
echo "  Keyspace hits:  $INITIAL_HITS"
echo "  Keyspace miss:  $INITIAL_MISSES"
echo ""

# Step 3: Populate cache with test data
echo -e "${BLUE}Step 3: Populating cache with test data...${NC}"
for i in {1..10}; do
    docker exec "$REDIS_CONTAINER" redis-cli SET "${TEST_KEY}:${i}" "${TEST_VALUE}_${i}" EX 3600 > /dev/null
done
echo -e "${GREEN}✓ Added 10 test keys${NC}"

# Verify population
NEW_DBSIZE=$(docker exec "$REDIS_CONTAINER" redis-cli DBSIZE | xargs)
ADDED_KEYS=$((NEW_DBSIZE - INITIAL_DBSIZE))
echo "Keys added: $ADDED_KEYS"
echo ""

# Step 4: Test cache hit (read existing key)
echo -e "${BLUE}Step 4: Testing cache hit...${NC}"
CACHED_VALUE=$(docker exec "$REDIS_CONTAINER" redis-cli GET "${TEST_KEY}:1")
if [ "$CACHED_VALUE" = "${TEST_VALUE}_1" ]; then
    echo -e "${GREEN}✓ Cache hit successful (value: $CACHED_VALUE)${NC}"
else
    echo -e "${RED}ERROR: Cache hit failed (expected ${TEST_VALUE}_1, got $CACHED_VALUE)${NC}"
    exit 1
fi

# Check hit count increased
NEW_HITS=$(docker exec "$REDIS_CONTAINER" redis-cli INFO stats | grep keyspace_hits: | cut -d: -f2 | tr -d '\r')
HIT_DELTA=$((NEW_HITS - INITIAL_HITS))
echo "Hit count increased by: $HIT_DELTA"
echo ""

# Step 5: Test cache miss (read non-existent key)
echo -e "${BLUE}Step 5: Testing cache miss...${NC}"
MISSING_VALUE=$(docker exec "$REDIS_CONTAINER" redis-cli GET "nonexistent:key:$(date +%s)")
if [ -z "$MISSING_VALUE" ] || [ "$MISSING_VALUE" = "(nil)" ]; then
    echo -e "${GREEN}✓ Cache miss detected (key not found)${NC}"
else
    echo -e "${YELLOW}⚠ Unexpected value for missing key: $MISSING_VALUE${NC}"
fi

# Check miss count increased
NEW_MISSES=$(docker exec "$REDIS_CONTAINER" redis-cli INFO stats | grep keyspace_misses: | cut -d: -f2 | tr -d '\r')
MISS_DELTA=$((NEW_MISSES - INITIAL_MISSES))
echo "Miss count increased by: $MISS_DELTA"
echo ""

# Step 6: Display sample keys before flush
echo -e "${BLUE}Step 6: Displaying sample keys before flush...${NC}"
SAMPLE_KEYS=$(docker exec "$REDIS_CONTAINER" redis-cli --scan --count 10 | head -5)
if [ -n "$SAMPLE_KEYS" ]; then
    echo "Sample keys:"
    echo "$SAMPLE_KEYS" | while read -r key; do
        echo "  - $key"
    done
else
    echo "  (no keys found)"
fi
echo ""

# Step 7: Flush cache using make target
echo -e "${BLUE}Step 7: Flushing cache...${NC}"
echo "Note: Automated test will use direct Redis command (make dev-flush-cache requires confirmation)"

# Direct flush (bypass confirmation for test automation)
docker exec "$REDIS_CONTAINER" redis-cli FLUSHALL > /dev/null
echo -e "${GREEN}✓ Cache flushed${NC}"
echo ""

# Step 8: Verify cache empty
echo -e "${BLUE}Step 8: Verifying cache is empty...${NC}"
POST_FLUSH_DBSIZE=$(docker exec "$REDIS_CONTAINER" redis-cli DBSIZE | xargs)
POST_FLUSH_MEMORY=$(docker exec "$REDIS_CONTAINER" redis-cli INFO memory | grep used_memory_human: | cut -d: -f2 | tr -d '\r')

echo "Post-flush cache state:"
echo "  Keys:    $POST_FLUSH_DBSIZE"
echo "  Memory:  $POST_FLUSH_MEMORY"

if [ "$POST_FLUSH_DBSIZE" -eq 0 ]; then
    echo -e "${GREEN}✓ Cache is empty (0 keys)${NC}"
else
    echo -e "${RED}ERROR: Cache not empty after flush ($POST_FLUSH_DBSIZE keys)${NC}"
    exit 1
fi
echo ""

# Step 9: Test cache miss after flush (observe population trigger)
echo -e "${BLUE}Step 9: Testing cache miss after flush...${NC}"
FLUSHED_VALUE=$(docker exec "$REDIS_CONTAINER" redis-cli GET "${TEST_KEY}:1")
if [ -z "$FLUSHED_VALUE" ] || [ "$FLUSHED_VALUE" = "(nil)" ]; then
    echo -e "${GREEN}✓ Cache miss confirmed (key no longer exists)${NC}"
else
    echo -e "${RED}ERROR: Key still exists after flush: $FLUSHED_VALUE${NC}"
    exit 1
fi
echo ""

# Step 10: Repopulate cache and verify
echo -e "${BLUE}Step 10: Observing cache population behavior...${NC}"
docker exec "$REDIS_CONTAINER" redis-cli SET "${TEST_KEY}:repopulated" "REPOPULATED_VALUE" EX 3600 > /dev/null
REPOPULATED_DBSIZE=$(docker exec "$REDIS_CONTAINER" redis-cli DBSIZE | xargs)

if [ "$REPOPULATED_DBSIZE" -eq 1 ]; then
    echo -e "${GREEN}✓ Cache populated successfully (1 key)${NC}"
else
    echo -e "${YELLOW}⚠ Unexpected key count: $REPOPULATED_DBSIZE${NC}"
fi

# Verify value
REPOPULATED_VALUE=$(docker exec "$REDIS_CONTAINER" redis-cli GET "${TEST_KEY}:repopulated")
if [ "$REPOPULATED_VALUE" = "REPOPULATED_VALUE" ]; then
    echo -e "${GREEN}✓ Repopulated value correct${NC}"
else
    echo -e "${RED}ERROR: Repopulated value incorrect: $REPOPULATED_VALUE${NC}"
    exit 1
fi
echo ""

# Step 11: Test helper script (dev-flush-cache) exists
echo -e "${BLUE}Step 11: Verifying cache flush helper script...${NC}"
if [ -f "scripts/flush-cache.sh" ] && [ -x "scripts/flush-cache.sh" ]; then
    echo -e "${GREEN}✓ Cache flush helper script exists and is executable${NC}"
else
    echo -e "${RED}ERROR: Cache flush helper not found or not executable${NC}"
    exit 1
fi

# Verify Makefile target exists
if grep -q "dev-flush-cache:" Makefile.dev; then
    echo -e "${GREEN}✓ Makefile target 'dev-flush-cache' exists${NC}"
else
    echo -e "${RED}ERROR: Makefile target 'dev-flush-cache' not found${NC}"
    exit 1
fi
echo ""

# Step 12: Cleanup test keys
echo -e "${BLUE}Step 12: Cleaning up test keys...${NC}"
docker exec "$REDIS_CONTAINER" redis-cli DEL "${TEST_KEY}:repopulated" > /dev/null
echo -e "${GREEN}✓ Test keys removed${NC}"
echo ""

# Step 13: Final cache statistics
echo -e "${BLUE}Step 13: Final cache statistics...${NC}"
FINAL_DBSIZE=$(docker exec "$REDIS_CONTAINER" redis-cli DBSIZE | xargs)
FINAL_MEMORY=$(docker exec "$REDIS_CONTAINER" redis-cli INFO memory | grep used_memory_human: | cut -d: -f2 | tr -d '\r')
FINAL_HITS=$(docker exec "$REDIS_CONTAINER" redis-cli INFO stats | grep keyspace_hits: | cut -d: -f2 | tr -d '\r')
FINAL_MISSES=$(docker exec "$REDIS_CONTAINER" redis-cli INFO stats | grep keyspace_misses: | cut -d: -f2 | tr -d '\r')

echo "Final cache state:"
echo "  Keys:           $FINAL_DBSIZE"
echo "  Memory:         $FINAL_MEMORY"
echo "  Keyspace hits:  $FINAL_HITS"
echo "  Keyspace miss:  $FINAL_MISSES"
echo ""

# Step 14: Evaluate test result
echo -e "${BLUE}Step 14: Evaluating test result...${NC}"
echo -e "${GREEN}✓✓✓ TEST PASSED ✓✓✓${NC}"
echo ""
echo "Cache debugging capabilities validated:"
echo "  ✓ Cache statistics accessible (keys, memory, hits/misses)"
echo "  ✓ Cache flush functional (FLUSHALL)"
echo "  ✓ Cache miss observable after flush"
echo "  ✓ Cache population behavior trackable"
echo "  ✓ Helper script and Makefile target available"
echo ""
echo "Developers can now:"
echo "  - Run: make dev-flush-cache (interactive with confirmation)"
echo "  - Observe cache population after flush"
echo "  - Track hit/miss ratios for performance tuning"
exit 0
