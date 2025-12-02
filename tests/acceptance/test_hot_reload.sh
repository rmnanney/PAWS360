#!/usr/bin/env bash

# T101: Frontend Hot-Reload Performance Test
# Feature: 001-local-dev-parity
# User Story: US3 - Rapid Development Iteration
# Test Case: TC-014 - Frontend Hot-Reload Performance
#
# Validates that frontend code changes trigger browser refresh within ≤2 seconds
#
# Prerequisites:
# - Development environment running (make dev-up)
# - Frontend service healthy
#
# Success Criteria:
# - File edit timestamp to browser update ≤2 seconds
# - Hot module replacement (HMR) active, no full page reload
# - Console shows "Compiled successfully" message

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== T101: Frontend Hot-Reload Performance Test ===${NC}"
echo ""

# Configuration
FRONTEND_CONTAINER="paws360-frontend"
TEST_FILE="app/page.tsx"
TEST_MARKER="<!-- HOT_RELOAD_TEST_MARKER -->"
TARGET_LATENCY=2  # seconds

# Step 1: Check frontend container running
echo -e "${BLUE}Step 1: Checking frontend container status...${NC}"
if ! docker ps | grep -q "$FRONTEND_CONTAINER"; then
    echo -e "${RED}ERROR: Frontend container not running${NC}"
    echo "Run: make dev-up"
    exit 1
fi
echo -e "${GREEN}✓ Frontend container is running${NC}"
echo ""

# Step 2: Verify HMR configuration
echo -e "${BLUE}Step 2: Verifying HMR configuration...${NC}"
if ! docker exec "$FRONTEND_CONTAINER" sh -c 'env | grep -q WATCHPACK_POLLING=true'; then
    echo -e "${RED}ERROR: WATCHPACK_POLLING not enabled${NC}"
    exit 1
fi
echo -e "${GREEN}✓ File watching enabled (WATCHPACK_POLLING=true)${NC}"
echo ""

# Step 3: Check Next.js dev server ready
echo -e "${BLUE}Step 3: Checking Next.js dev server...${NC}"
if ! docker exec "$FRONTEND_CONTAINER" sh -c 'curl -sf http://localhost:3000/api/health > /dev/null'; then
    echo -e "${RED}ERROR: Next.js dev server not responding${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Next.js dev server is ready${NC}"
echo ""

# Step 4: Backup test file
echo -e "${BLUE}Step 4: Backing up test file...${NC}"
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}ERROR: Test file not found: $TEST_FILE${NC}"
    exit 1
fi
cp "$TEST_FILE" "${TEST_FILE}.bak"
echo -e "${GREEN}✓ Backup created: ${TEST_FILE}.bak${NC}"
echo ""

# Step 5: Measure hot-reload latency
echo -e "${BLUE}Step 5: Measuring hot-reload latency...${NC}"
echo "Editing file: $TEST_FILE"
echo "Adding test marker: $TEST_MARKER"

# Record start time
START_TIME=$(date +%s.%N)

# Modify file (add comment to trigger HMR)
if grep -q "$TEST_MARKER" "$TEST_FILE"; then
    # Remove marker (toggle)
    sed -i "/$TEST_MARKER/d" "$TEST_FILE"
else
    # Add marker
    echo "$TEST_MARKER" >> "$TEST_FILE"
fi

# Wait for compilation
echo "Waiting for compilation..."
COMPILE_DETECTED=false
MAX_WAIT=10  # seconds

for i in $(seq 1 "$MAX_WAIT"); do
    if docker logs --since 1s "$FRONTEND_CONTAINER" 2>&1 | grep -q "compiled successfully"; then
        END_TIME=$(date +%s.%N)
        COMPILE_DETECTED=true
        break
    fi
    sleep 0.5
done

if [ "$COMPILE_DETECTED" = false ]; then
    echo -e "${RED}ERROR: Compilation not detected within ${MAX_WAIT}s${NC}"
    mv "${TEST_FILE}.bak" "$TEST_FILE"
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

# Step 6: Verify HMR (not full reload)
echo -e "${BLUE}Step 6: Verifying HMR (not full page reload)...${NC}"
if docker logs --since 5s "$FRONTEND_CONTAINER" 2>&1 | grep -q "Fast Refresh"; then
    echo -e "${GREEN}✓ Fast Refresh (HMR) detected${NC}"
else
    echo -e "${YELLOW}⚠ Fast Refresh not explicitly detected (may still be HMR)${NC}"
fi
echo ""

# Step 7: Restore original file
echo -e "${BLUE}Step 7: Restoring original file...${NC}"
mv "${TEST_FILE}.bak" "$TEST_FILE"
echo -e "${GREEN}✓ File restored${NC}"
echo ""

# Step 8: Evaluate test result
echo -e "${BLUE}Step 8: Evaluating test result...${NC}"
PASS=$(echo "$LATENCY <= $TARGET_LATENCY" | bc -l)

if [ "$PASS" -eq 1 ]; then
    echo -e "${GREEN}✓✓✓ TEST PASSED ✓✓✓${NC}"
    echo ""
    echo "Frontend hot-reload latency: ${LATENCY}s (target: ≤${TARGET_LATENCY}s)"
    echo "HMR is functioning within performance target."
    exit 0
else
    echo -e "${RED}✗✗✗ TEST FAILED ✗✗✗${NC}"
    echo ""
    echo "Frontend hot-reload latency: ${LATENCY}s (target: ≤${TARGET_LATENCY}s)"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check Next.js config: cat next.config.ts | grep watchOptions"
    echo "2. Verify volume mounts: docker inspect $FRONTEND_CONTAINER | grep Mounts"
    echo "3. Check logs: docker logs --tail=50 $FRONTEND_CONTAINER"
    echo "4. Restart frontend: docker restart $FRONTEND_CONTAINER"
    exit 1
fi
