#!/usr/bin/env bash
# Feature: 001-local-dev-parity
# Task: T095 - Startup performance benchmark script
# Purpose: Measure cold start, warm start, fast mode, pause/resume times

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}⚡ Startup Performance Benchmark${NC}"
echo "=================================="
echo ""

# Configuration
COMPOSE_FILE="docker-compose.yml"
DOCKER_COMPOSE="docker compose"

# Results storage
RESULTS_FILE="/tmp/paws360-startup-benchmark-$(date +%Y%m%d-%H%M%S).txt"

# Helper function to measure time
measure_time() {
    local label="$1"
    local command="$2"
    
    echo -e "${YELLOW}📊 ${label}...${NC}"
    start_time=$(date +%s)
    eval "$command" >/dev/null 2>&1
    end_time=$(date +%s)
    elapsed=$((end_time - start_time))
    
    echo -e "${GREEN}✓ ${label}: ${elapsed}s${NC}"
    echo "${label}: ${elapsed}s" >> "$RESULTS_FILE"
    
    return $elapsed
}

# Ensure environment is down
echo -e "${BLUE}🧹 Cleaning environment...${NC}"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down -v >/dev/null 2>&1 || true
docker system prune -f >/dev/null 2>&1 || true

echo "" 

# Test 1: Cold start (no cached images)
echo -e "${BLUE}Test 1: Cold Start (first time)${NC}"
echo "-----------------------------------"
measure_time "Cold start" "$DOCKER_COMPOSE -f $COMPOSE_FILE up -d && sleep 30"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down >/dev/null 2>&1

echo ""

# Test 2: Warm start (images cached)
echo -e "${BLUE}Test 2: Warm Start (images cached)${NC}"
echo "--------------------------------------"
measure_time "Warm start" "$DOCKER_COMPOSE -f $COMPOSE_FILE up -d && sleep 10"

echo ""

# Test 3: Pause/resume cycle
echo -e "${BLUE}Test 3: Pause/Resume Cycle${NC}"
echo "-----------------------------"
sleep 5
measure_time "Pause" "$DOCKER_COMPOSE -f $COMPOSE_FILE pause"
measure_time "Resume" "$DOCKER_COMPOSE -f $COMPOSE_FILE unpause && sleep 3"

echo ""

# Cleanup
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down >/dev/null 2>&1

# Test 4: Fast mode (core services only)
echo -e "${BLUE}Test 4: Fast Mode (core services)${NC}"
echo "------------------------------------"
measure_time "Fast mode start" "$DOCKER_COMPOSE -f $COMPOSE_FILE up -d etcd1 patroni1 redis-master backend frontend && sleep 10"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down >/dev/null 2>&1

echo ""
echo "=================================="
echo -e "${GREEN}✅ Benchmark Complete${NC}"
echo ""
echo -e "${BLUE}📊 Results Summary:${NC}"
cat "$RESULTS_FILE"
echo ""
echo -e "${BLUE}💾 Full results saved to: ${RESULTS_FILE}${NC}"

# Performance targets
echo ""
echo -e "${BLUE}🎯 Performance Targets:${NC}"
echo "  Cold start:  ≤300s"
echo "  Warm start:  ≤60s"
echo "  Fast mode:   ≤30s"
echo "  Resume:      ≤5s"
