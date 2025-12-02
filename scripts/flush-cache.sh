#!/usr/bin/env bash
# Feature: 001-local-dev-parity
# Task: T092 - Cache flush helper script
# Purpose: Flush Redis cache with confirmation prompt

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REDIS_CONTAINER="${REDIS_CONTAINER:-paws360-redis-master}"
REDIS_CLI="docker exec -i $REDIS_CONTAINER redis-cli"

echo -e "${BLUE}🗑️  Redis Cache Flush Utility${NC}"
echo "=============================="
echo ""

# Check if Redis container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${REDIS_CONTAINER}$"; then
    echo -e "${RED}❌ Error: Redis container '${REDIS_CONTAINER}' is not running${NC}"
    echo -e "${YELLOW}💡 Start the environment with: make dev-up${NC}"
    exit 1
fi

# Get cache statistics before flush
echo -e "${BLUE}📊 Current cache statistics:${NC}"
echo ""

db_size=$($REDIS_CLI DBSIZE | grep -oE '[0-9]+' || echo "0")
memory_used=$($REDIS_CLI INFO memory | grep "used_memory_human" | cut -d':' -f2 | tr -d '\r' || echo "unknown")
keys_total=$($REDIS_CLI INFO keyspace | grep "keys=" | grep -oE 'keys=[0-9]+' | cut -d'=' -f2 || echo "0")

echo -e "  Keys:   ${YELLOW}${db_size}${NC}"
echo -e "  Memory: ${YELLOW}${memory_used}${NC}"
echo ""

if [ "$db_size" -eq 0 ]; then
    echo -e "${GREEN}✓ Cache is already empty${NC}"
    exit 0
fi

# Show sample keys
echo -e "${BLUE}📋 Sample keys (first 10):${NC}"
$REDIS_CLI KEYS '*' | head -10 | while read -r key; do
    echo -e "  - ${key}"
done
if [ "$db_size" -gt 10 ]; then
    echo -e "  ... and $((db_size - 10)) more"
fi
echo ""

# Confirmation prompt
echo -e "${YELLOW}⚠️  WARNING: This will delete ALL cached data${NC}"
echo -e "${YELLOW}   This action cannot be undone!${NC}"
echo ""
echo -n -e "${BLUE}Are you sure you want to flush the cache? [y/N] ${NC}"
read -r response

case "$response" in
    [yY][eE][sS]|[yY]) 
        echo ""
        echo -e "${YELLOW}🔄 Flushing Redis cache...${NC}"
        
        if $REDIS_CLI FLUSHALL >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Cache flushed successfully${NC}"
            echo ""
            
            # Verify flush
            new_db_size=$($REDIS_CLI DBSIZE | grep -oE '[0-9]+' || echo "0")
            echo -e "${BLUE}📊 New cache statistics:${NC}"
            echo -e "  Keys:   ${GREEN}${new_db_size}${NC}"
            echo -e "  Memory: ${GREEN}$(docker exec -i $REDIS_CONTAINER redis-cli INFO memory | grep "used_memory_human" | cut -d':' -f2 | tr -d '\r')${NC}"
            echo ""
            echo -e "${GREEN}✓ Cache is now empty${NC}"
            echo -e "${BLUE}💡 Next request will repopulate cache from database${NC}"
        else
            echo -e "${RED}❌ Error: Failed to flush cache${NC}"
            exit 1
        fi
        ;;
    *)
        echo ""
        echo -e "${BLUE}ℹ️  Cache flush cancelled${NC}"
        exit 0
        ;;
esac
