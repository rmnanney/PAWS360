#!/usr/bin/env bash

# T102: Backend Incremental Rebuild Test
# Feature: 001-local-dev-parity
# User Story: US3 - Rapid Development Iteration
# Test Case: TC-015 - Incremental Service Rebuild
#
# Validates that backend code changes trigger automatic restart within ≤15 seconds
#
# Prerequisites:
# - Development environment running (make dev-up)
# - Backend service healthy
# - Spring Boot DevTools enabled
#
# Success Criteria:
# - Code change timestamp to service restart ≤15 seconds
# - DevTools restart mechanism (not full container restart)
# - New code is active after restart

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== T102: Backend Incremental Rebuild Test ===${NC}"
echo ""

# Configuration
BACKEND_CONTAINER="paws360-backend"
TEST_CLASS="src/main/java/com/paws360/TestController.java"
TARGET_LATENCY=15  # seconds

# Step 1: Check backend container running
echo -e "${BLUE}Step 1: Checking backend container status...${NC}"
if ! docker ps | grep -q "$BACKEND_CONTAINER"; then
    echo -e "${RED}ERROR: Backend container not running${NC}"
    echo "Run: make dev-up"
    exit 1
fi
echo -e "${GREEN}✓ Backend container is running${NC}"
echo ""

# Step 2: Verify DevTools enabled
echo -e "${BLUE}Step 2: Verifying Spring Boot DevTools...${NC}"
if ! docker exec "$BACKEND_CONTAINER" sh -c 'env | grep -q SPRING_DEVTOOLS_RESTART_ENABLED=true'; then
    echo -e "${RED}ERROR: Spring Boot DevTools not enabled${NC}"
    exit 1
fi
echo -e "${GREEN}✓ DevTools enabled (SPRING_DEVTOOLS_RESTART_ENABLED=true)${NC}"

# Check LiveReload server
if docker logs --tail=100 "$BACKEND_CONTAINER" 2>&1 | grep -q "LiveReload server is running"; then
    echo -e "${GREEN}✓ LiveReload server is running on port 35729${NC}"
else
    echo -e "${YELLOW}⚠ LiveReload server not detected (DevTools may still function)${NC}"
fi
echo ""

# Step 3: Check backend health
echo -e "${BLUE}Step 3: Checking backend health...${NC}"
if ! docker exec "$BACKEND_CONTAINER" sh -c 'curl -sf http://localhost:8080/actuator/health > /dev/null'; then
    echo -e "${RED}ERROR: Backend health check failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Backend is healthy${NC}"
echo ""

# Step 4: Create test controller (if doesn't exist)
echo -e "${BLUE}Step 4: Preparing test controller...${NC}"
mkdir -p "$(dirname "$TEST_CLASS")"

cat > "$TEST_CLASS" << 'EOF'
package com.paws360;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {
    
    @GetMapping("/api/test-rebuild")
    public String testRebuild() {
        return "REBUILD_TEST_V1";
    }
}
EOF

echo -e "${GREEN}✓ Test controller created: $TEST_CLASS${NC}"
echo ""

# Step 5: Compile initial version
echo -e "${BLUE}Step 5: Compiling initial version...${NC}"
if ! mvn compile -q; then
    echo -e "${RED}ERROR: Initial compilation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Initial compilation successful${NC}"

# Wait for backend to restart with initial version
echo "Waiting for backend to stabilize..."
sleep 5
echo ""

# Step 6: Test initial version
echo -e "${BLUE}Step 6: Testing initial version...${NC}"
INITIAL_RESPONSE=$(docker exec "$BACKEND_CONTAINER" curl -sf http://localhost:8080/api/test-rebuild || echo "FAILED")
if [ "$INITIAL_RESPONSE" != "REBUILD_TEST_V1" ]; then
    echo -e "${RED}ERROR: Initial version not working (got: $INITIAL_RESPONSE)${NC}"
    rm -f "$TEST_CLASS"
    exit 1
fi
echo -e "${GREEN}✓ Initial version working (response: $INITIAL_RESPONSE)${NC}"
echo ""

# Step 7: Modify code and measure rebuild time
echo -e "${BLUE}Step 7: Modifying code and measuring rebuild time...${NC}"

# Modify controller to return V2
sed -i 's/REBUILD_TEST_V1/REBUILD_TEST_V2/g' "$TEST_CLASS"

# Record start time
START_TIME=$(date +%s.%N)
echo "File modified at: $(date +"%T.%N" | cut -c1-12)"

# Recompile
echo "Compiling modified version..."
if ! mvn compile -q; then
    echo -e "${RED}ERROR: Recompilation failed${NC}"
    rm -f "$TEST_CLASS"
    exit 1
fi
echo -e "${GREEN}✓ Compilation successful${NC}"

# Wait for DevTools to detect change and restart
echo "Waiting for DevTools restart..."
RESTART_DETECTED=false
MAX_WAIT=20  # seconds

for i in $(seq 1 "$MAX_WAIT"); do
    # Check if new version is active
    RESPONSE=$(docker exec "$BACKEND_CONTAINER" curl -sf http://localhost:8080/api/test-rebuild 2>/dev/null || echo "FAILED")
    
    if [ "$RESPONSE" = "REBUILD_TEST_V2" ]; then
        END_TIME=$(date +%s.%N)
        RESTART_DETECTED=true
        echo "New version detected at: $(date +"%T.%N" | cut -c1-12)"
        break
    fi
    
    sleep 1
done

if [ "$RESTART_DETECTED" = false ]; then
    echo -e "${RED}ERROR: DevTools restart not detected within ${MAX_WAIT}s${NC}"
    echo "Current response: $RESPONSE"
    rm -f "$TEST_CLASS"
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

# Step 8: Verify DevTools restart (not full container restart)
echo -e "${BLUE}Step 8: Verifying DevTools restart mechanism...${NC}"
if docker logs --since 30s "$BACKEND_CONTAINER" 2>&1 | grep -q "Restarting due to"; then
    echo -e "${GREEN}✓ DevTools restart detected (incremental, not full container restart)${NC}"
else
    echo -e "${YELLOW}⚠ DevTools restart message not found (but restart occurred)${NC}"
fi
echo ""

# Step 9: Cleanup
echo -e "${BLUE}Step 9: Cleaning up test controller...${NC}"
rm -f "$TEST_CLASS"
rm -rf target/classes/com/paws360/TestController.class
echo -e "${GREEN}✓ Test controller removed${NC}"
echo ""

# Step 10: Evaluate test result
echo -e "${BLUE}Step 10: Evaluating test result...${NC}"
PASS=$(echo "$LATENCY <= $TARGET_LATENCY" | bc -l)

if [ "$PASS" -eq 1 ]; then
    echo -e "${GREEN}✓✓✓ TEST PASSED ✓✓✓${NC}"
    echo ""
    echo "Backend rebuild latency: ${LATENCY}s (target: ≤${TARGET_LATENCY}s)"
    echo "Spring Boot DevTools is functioning within performance target."
    exit 0
else
    echo -e "${RED}✗✗✗ TEST FAILED ✗✗✗${NC}"
    echo ""
    echo "Backend rebuild latency: ${LATENCY}s (target: ≤${TARGET_LATENCY}s)"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check DevTools config: docker exec $BACKEND_CONTAINER env | grep DEVTOOLS"
    echo "2. Verify volume mounts: docker inspect $BACKEND_CONTAINER | grep Mounts"
    echo "3. Check logs: docker logs --tail=50 $BACKEND_CONTAINER | grep -i restart"
    echo "4. Verify auto-build: IntelliJ → Settings → Build project automatically"
    exit 1
fi
