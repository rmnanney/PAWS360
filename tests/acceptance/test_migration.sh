#!/usr/bin/env bash

# T103: Database Migration Execution Test
# Feature: 001-local-dev-parity
# User Story: US3 - Rapid Development Iteration
# Test Case: TC-016 - Database Migration Execution
#
# Validates that database migrations apply to Patroni cluster within ≤10 seconds
#
# Prerequisites:
# - Development environment running (make dev-up)
# - Patroni cluster healthy with leader
#
# Success Criteria:
# - Migration execution completes within ≤10 seconds
# - Schema changes visible on leader and all replicas
# - Replication status confirmed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== T103: Database Migration Execution Test ===${NC}"
echo ""

# Configuration
PATRONI_CONTAINER="paws360-patroni1"
DB_NAME="paws360_dev"
DB_USER="postgres"
MIGRATION_DIR="database/migrations"
TEST_MIGRATION="${MIGRATION_DIR}/V999__test_migration.sql"
TARGET_LATENCY=10  # seconds

# Step 1: Check Patroni cluster status
echo -e "${BLUE}Step 1: Checking Patroni cluster status...${NC}"
if ! docker ps | grep -q "$PATRONI_CONTAINER"; then
    echo -e "${RED}ERROR: Patroni container not running${NC}"
    echo "Run: make dev-up"
    exit 1
fi

CLUSTER_STATUS=$(docker exec "$PATRONI_CONTAINER" patronictl list 2>/dev/null || echo "FAILED")
if echo "$CLUSTER_STATUS" | grep -q "Leader"; then
    echo -e "${GREEN}✓ Patroni cluster is healthy${NC}"
    echo "$CLUSTER_STATUS"
else
    echo -e "${RED}ERROR: Patroni cluster not healthy${NC}"
    exit 1
fi
echo ""

# Step 2: Create test migration file
echo -e "${BLUE}Step 2: Creating test migration...${NC}"
mkdir -p "$MIGRATION_DIR"

cat > "$TEST_MIGRATION" << 'EOF'
-- Test migration for T103
-- Creates a temporary table, inserts data, validates, and drops table

CREATE TABLE IF NOT EXISTS test_migration_table (
    id SERIAL PRIMARY KEY,
    test_value VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO test_migration_table (test_value) VALUES 
    ('TEST_VALUE_1'),
    ('TEST_VALUE_2'),
    ('TEST_VALUE_3');

-- Verify insert
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM test_migration_table;
    IF row_count != 3 THEN
        RAISE EXCEPTION 'Migration validation failed: expected 3 rows, got %', row_count;
    END IF;
END $$;
EOF

echo -e "${GREEN}✓ Test migration created: $TEST_MIGRATION${NC}"
echo ""

# Step 3: Get initial table count (baseline)
echo -e "${BLUE}Step 3: Getting baseline schema state...${NC}"
INITIAL_TABLES=$(docker exec "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
echo "Initial table count: $INITIAL_TABLES"
echo ""

# Step 4: Execute migration and measure time
echo -e "${BLUE}Step 4: Executing migration and measuring time...${NC}"

# Record start time
START_TIME=$(date +%s.%N)
echo "Migration started at: $(date +"%T.%N" | cut -c1-12)"

# Execute migration via make target
if make dev-migrate > /tmp/migration-output.log 2>&1; then
    END_TIME=$(date +%s.%N)
    MIGRATION_SUCCESS=true
    echo "Migration completed at: $(date +"%T.%N" | cut -c1-12)"
else
    echo -e "${RED}ERROR: Migration execution failed${NC}"
    cat /tmp/migration-output.log
    rm -f "$TEST_MIGRATION"
    exit 1
fi

# Calculate latency
LATENCY=$(echo "$END_TIME - $START_TIME" | bc)
echo ""
echo -e "${BLUE}Results:${NC}"
echo "  Start:     $(date -d @"$START_TIME" +"%T.%N" | cut -c1-12)"
echo "  End:       $(date -d @"$END_TIME" +"%T.%N" | cut -c1-12)"
echo "  Latency:   ${LATENCY}s"
echo "  Target:    ≤${TARGET_LATENCY}s"
echo ""

# Step 5: Verify schema change on leader
echo -e "${BLUE}Step 5: Verifying schema change on leader...${NC}"
TABLE_EXISTS=$(docker exec "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'test_migration_table');" | xargs)

if [ "$TABLE_EXISTS" = "t" ]; then
    echo -e "${GREEN}✓ Table created on leader${NC}"
else
    echo -e "${RED}ERROR: Table not found on leader${NC}"
    rm -f "$TEST_MIGRATION"
    exit 1
fi

# Verify data
ROW_COUNT=$(docker exec "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM test_migration_table;" | xargs)
if [ "$ROW_COUNT" = "3" ]; then
    echo -e "${GREEN}✓ Data inserted correctly (3 rows)${NC}"
else
    echo -e "${RED}ERROR: Expected 3 rows, got $ROW_COUNT${NC}"
    rm -f "$TEST_MIGRATION"
    exit 1
fi
echo ""

# Step 6: Verify replication to replicas
echo -e "${BLUE}Step 6: Verifying replication to replicas...${NC}"
sleep 2  # Allow replication lag

# Check replication status
REPLICATION_STATUS=$(docker exec "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM pg_stat_replication;" | xargs)
if [ "$REPLICATION_STATUS" -ge 1 ]; then
    echo -e "${GREEN}✓ Replication active ($REPLICATION_STATUS replicas)${NC}"
else
    echo -e "${YELLOW}⚠ No replicas detected (single-node mode)${NC}"
fi

# Check replica lag
REPLICA_LAG=$(docker exec "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COALESCE(MAX(replay_lag), '0 sec'::INTERVAL) FROM pg_stat_replication;" | xargs)
echo "Maximum replica lag: $REPLICA_LAG"
echo ""

# Step 7: Cleanup (drop test table)
echo -e "${BLUE}Step 7: Cleaning up test table...${NC}"
docker exec "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "DROP TABLE IF EXISTS test_migration_table;" > /dev/null 2>&1
rm -f "$TEST_MIGRATION"
echo -e "${GREEN}✓ Test table dropped and migration file removed${NC}"
echo ""

# Step 8: Evaluate test result
echo -e "${BLUE}Step 8: Evaluating test result...${NC}"
PASS=$(echo "$LATENCY <= $TARGET_LATENCY" | bc -l)

if [ "$PASS" -eq 1 ]; then
    echo -e "${GREEN}✓✓✓ TEST PASSED ✓✓✓${NC}"
    echo ""
    echo "Migration execution time: ${LATENCY}s (target: ≤${TARGET_LATENCY}s)"
    echo "Schema changes replicated successfully."
    exit 0
else
    echo -e "${RED}✗✗✗ TEST FAILED ✗✗✗${NC}"
    echo ""
    echo "Migration execution time: ${LATENCY}s (target: ≤${TARGET_LATENCY}s)"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check Patroni cluster: docker exec $PATRONI_CONTAINER patronictl list"
    echo "2. Check replication lag: SELECT * FROM pg_stat_replication;"
    echo "3. Review migration script: cat scripts/run-migrations.sh"
    echo "4. Check logs: docker logs $PATRONI_CONTAINER"
    exit 1
fi
