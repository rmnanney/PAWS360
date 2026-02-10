#!/usr/bin/env bash
# Feature: 001-local-dev-parity
# Task: T091 - Database migration execution script
# Purpose: Wait for Patroni leader, apply migrations, validate schema

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAX_WAIT=60
RETRY_INTERVAL=2
PATRONI_CONTAINER="paws360-patroni1"
DB_NAME="${PAWS360_DB_NAME:-paws360_dev}"
DB_USER="${PAWS360_DB_USER:-postgres}"
MIGRATION_DIR="${MIGRATION_DIR:-database/migrations}"

echo -e "${BLUE}🗄️  Database Migration Script${NC}"
echo "================================"
echo ""

# Function to check if Patroni leader is ready
check_patroni_leader() {
    docker exec -i "$PATRONI_CONTAINER" patronictl list 2>/dev/null | grep -q "Leader" && \
    docker exec -i "$PATRONI_CONTAINER" pg_isready -U "$DB_USER" >/dev/null 2>&1
}

# Function to get leader node
get_leader_node() {
    docker exec -i "$PATRONI_CONTAINER" patronictl list 2>/dev/null | \
        grep "Leader" | awk '{print $2}' || echo "patroni1"
}

# Wait for Patroni leader to be ready
echo -e "${YELLOW}⏳ Waiting for Patroni leader to be ready...${NC}"
elapsed=0
while ! check_patroni_leader; do
    if [ $elapsed -ge $MAX_WAIT ]; then
        echo -e "${RED}❌ Error: Patroni leader did not become ready within ${MAX_WAIT}s${NC}"
        exit 1
    fi
    sleep $RETRY_INTERVAL
    elapsed=$((elapsed + RETRY_INTERVAL))
    echo -n "."
done
echo ""

LEADER=$(get_leader_node)
echo -e "${GREEN}✓ Patroni leader ready: ${LEADER}${NC}"
echo ""

# Check if migration directory exists
if [ ! -d "$MIGRATION_DIR" ]; then
    echo -e "${YELLOW}⚠️  Migration directory not found: ${MIGRATION_DIR}${NC}"
    echo -e "${YELLOW}Creating migration directory...${NC}"
    mkdir -p "$MIGRATION_DIR"
    echo -e "${GREEN}✓ Migration directory created${NC}"
    echo ""
    echo -e "${BLUE}ℹ️  Place your SQL migration files in: ${MIGRATION_DIR}${NC}"
    echo -e "${BLUE}   Files should be named with version prefix: V001__initial_schema.sql${NC}"
    exit 0
fi

# Check if migration tool (Flyway/Liquibase) is available
# For now, using simple SQL file execution
# TODO: Integrate Flyway or Liquibase for production-grade migrations

echo -e "${BLUE}📋 Checking for migration files...${NC}"
migration_files=$(find "$MIGRATION_DIR" -name "*.sql" -type f | sort)

if [ -z "$migration_files" ]; then
    echo -e "${YELLOW}⚠️  No migration files found in ${MIGRATION_DIR}${NC}"
    echo -e "${BLUE}ℹ️  Create migration files with .sql extension${NC}"
    exit 0
fi

echo -e "${GREEN}✓ Found $(echo "$migration_files" | wc -l) migration file(s)${NC}"
echo ""

# Apply migrations
echo -e "${BLUE}🔄 Applying migrations...${NC}"
migration_count=0
failed_count=0

while IFS= read -r migration_file; do
    filename=$(basename "$migration_file")
    echo -e "${YELLOW}  Applying: ${filename}...${NC}"
    
    if docker exec -i "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$migration_file" >/dev/null 2>&1; then
        echo -e "${GREEN}    ✓ Success${NC}"
        migration_count=$((migration_count + 1))
    else
        echo -e "${RED}    ✗ Failed${NC}"
        failed_count=$((failed_count + 1))
        # Show error details
        docker exec -i "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$migration_file" 2>&1 | head -10
    fi
done <<< "$migration_files"

echo ""

# Validate schema
echo -e "${BLUE}🔍 Validating database schema...${NC}"
table_count=$(docker exec -i "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")

echo -e "${GREEN}✓ Database has ${table_count} tables${NC}"

# Check replication status
echo -e "${BLUE}🔗 Checking replication status...${NC}"
docker exec -i "$PATRONI_CONTAINER" patronictl list 2>/dev/null || true

echo ""
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✅ Migration Summary:${NC}"
echo -e "   Applied: ${migration_count}"
echo -e "   Failed:  ${failed_count}"
echo -e "   Tables:  ${table_count}"

if [ $failed_count -gt 0 ]; then
    echo -e "${RED}⚠️  Some migrations failed. Review errors above.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All migrations applied successfully${NC}"
