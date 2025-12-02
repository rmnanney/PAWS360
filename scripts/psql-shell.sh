#!/usr/bin/env bash
# Feature: 001-local-dev-parity
# Task: T093 - PostgreSQL shell helper script
# Purpose: Open psql shell on Patroni leader node

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PATRONI_CONTAINER="${PATRONI_CONTAINER:-paws360-patroni1}"
DB_NAME="${PAWS360_DB_NAME:-paws360_dev}"
DB_USER="${PAWS360_DB_USER:-postgres}"

echo -e "${BLUE}🐘 PostgreSQL Shell${NC}"
echo "==================="
echo ""

# Check if Patroni container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${PATRONI_CONTAINER}$"; then
    echo -e "${RED}❌ Error: Patroni container '${PATRONI_CONTAINER}' is not running${NC}"
    echo -e "${YELLOW}💡 Start the environment with: make dev-up${NC}"
    exit 1
fi

# Check Patroni cluster status
echo -e "${BLUE}📊 Cluster Status:${NC}"
docker exec -i "$PATRONI_CONTAINER" patronictl list 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Unable to get cluster status${NC}"
}
echo ""

# Get leader node
leader=$(docker exec -i "$PATRONI_CONTAINER" patronictl list 2>/dev/null | \
    grep "Leader" | awk '{print $2}' || echo "patroni1")

echo -e "${GREEN}✓ Connecting to leader: ${leader}${NC}"
echo -e "${BLUE}  Database: ${DB_NAME}${NC}"
echo -e "${BLUE}  User:     ${DB_USER}${NC}"
echo ""
echo -e "${YELLOW}💡 Tip: Use \\q to exit${NC}"
echo -e "${YELLOW}💡 Tip: Use \\dt to list tables${NC}"
echo -e "${YELLOW}💡 Tip: Use \\d table_name to describe a table${NC}"
echo ""

# Open psql shell
docker exec -it "$PATRONI_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME"
