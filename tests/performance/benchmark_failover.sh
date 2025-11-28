#!/usr/bin/env bash
# Feature: 001-local-dev-parity
# Task: T096 - Failover performance benchmark script
# Purpose: Measure Patroni/Redis failover times

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}⚡ Failover Performance Benchmark${NC}"
echo "====================================="
echo ""

# Results storage
RESULTS_FILE="/tmp/paws360-failover-benchmark-$(date +%Y%m%d-%H%M%S).txt"

# Helper function to measure failover time
measure_failover() {
    local service="$1"
    local container="$2"
    local check_command="$3"
    
    echo -e "${YELLOW}📊 Testing ${service} failover...${NC}"
    
    # Record start time
    start_time=$(date +%s)
    
    # Pause primary
    echo -e "  ⏸️  Pausing ${container}..."
    docker pause "$container" >/dev/null 2>&1
    
    # Wait for failover
    echo -e "  ⏳ Waiting for failover..."
    while ! eval "$check_command" >/dev/null 2>&1; do
        sleep 1
    done
    
    # Record end time
    end_time=$(date +%s)
    failover_time=$((end_time - start_time))
    
    echo -e "${GREEN}✓ ${service} failover: ${failover_time}s${NC}"
    echo "${service} failover: ${failover_time}s" >> "$RESULTS_FILE"
    
    # Resume original primary
    echo -e "  ▶️  Resuming ${container}..."
    docker unpause "$container" >/dev/null 2>&1
    sleep 5
    
    return $failover_time
}

# Ensure environment is running
echo -e "${BLUE}🔍 Checking environment status...${NC}"
if ! docker ps | grep -q "paws360-patroni1"; then
    echo -e "${RED}❌ Error: Environment not running${NC}"
    echo -e "${YELLOW}💡 Start with: make dev-up${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment running${NC}"
echo ""

# Test 1: Patroni failover
echo -e "${BLUE}Test 1: PostgreSQL/Patroni Failover${NC}"
echo "---------------------------------------"
measure_failover "Patroni" "paws360-patroni1" \
    "docker exec paws360-patroni2 patronictl list | grep -q Leader"

echo ""

# Test 2: Redis Sentinel failover
echo -e "${BLUE}Test 2: Redis Sentinel Failover${NC}"
echo "----------------------------------"
measure_failover "Redis" "paws360-redis-master" \
    "docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL masters | grep -q 'redis-replica1\\|redis-replica2'"

echo ""
echo "====================================="
echo -e "${GREEN}✅ Benchmark Complete${NC}"
echo ""
echo -e "${BLUE}📊 Results Summary:${NC}"
cat "$RESULTS_FILE"
echo ""
echo -e "${BLUE}💾 Full results saved to: ${RESULTS_FILE}${NC}"

# Performance targets
echo ""
echo -e "${BLUE}🎯 Performance Targets:${NC}"
echo "  Patroni failover:  ≤60s"
echo "  Redis failover:    ≤45s"
