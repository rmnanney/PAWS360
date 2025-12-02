#!/bin/bash
# Failover Simulation Script
# Simulates Patroni leader failure and measures failover time

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Patroni Leader Failover Simulation ===${NC}"
echo

# Step 1: Detect current leader
echo -e "${BLUE}Step 1: Detecting current Patroni leader...${NC}"
LEADER=""
LEADER_PORT=""

for PORT in 8008 8009 8010; do
    PATRONI_STATUS=$(curl -sf http://localhost:$PORT/patroni 2>/dev/null || echo "{}")
    ROLE=$(echo "$PATRONI_STATUS" | grep -o '"role": *"[^"]*"' | sed 's/"role": *"\([^"]*\)"/\1/' || echo "")
    
    if [ "$ROLE" = "master" ] || [ "$ROLE" = "leader" ]; then
        LEADER="patroni$((PORT - 8007))"
        LEADER_PORT=$PORT
        CONTAINER_NAME="paws360-$LEADER"
        break
    fi
done

if [ -z "$LEADER" ]; then
    echo -e "${RED}✗ No leader found. Is the cluster running?${NC}"
    exit 1
fi

echo -e "  Current leader: ${GREEN}$LEADER${NC} (API port: $LEADER_PORT)"
echo

# Step 2: Record baseline metrics
echo -e "${BLUE}Step 2: Recording baseline metrics...${NC}"
REPLICAS_BEFORE=$(curl -sf http://localhost:$LEADER_PORT/cluster 2>/dev/null | grep -o '"role":"replica"' | wc -l)
echo -e "  Replicas streaming: ${GREEN}$REPLICAS_BEFORE${NC}"
echo

# Step 3: Pause leader container
echo -e "${BLUE}Step 3: Pausing leader container ($CONTAINER_NAME)...${NC}"
START_TIME=$(date +%s)
docker pause $CONTAINER_NAME
echo -e "  ${YELLOW}Leader paused at $(date '+%H:%M:%S')${NC}"
echo

# Step 4: Wait for new leader election
echo -e "${BLUE}Step 4: Waiting for new leader election...${NC}"
NEW_LEADER=""
NEW_LEADER_PORT=""
TIMEOUT=90
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    for PORT in 8008 8009 8010; do
        if [ $PORT -eq $LEADER_PORT ]; then
            continue  # Skip the paused leader
        fi
        
        PATRONI_STATUS=$(curl -sf http://localhost:$PORT/patroni 2>/dev/null || echo "{}")
        ROLE=$(echo "$PATRONI_STATUS" | grep -o '"role": *"[^"]*"' | sed 's/"role": *"\([^"]*\)"/\1/' || echo "")
        STATE=$(echo "$PATRONI_STATUS" | grep -o '"state": *"[^"]*"' | sed 's/"state": *"\([^"]*\)"/\1/' || echo "")
        
        if [ "$ROLE" = "master" ] || [ "$ROLE" = "leader" ]; then
            if [ "$STATE" = "running" ]; then
                NEW_LEADER="patroni$((PORT - 8007))"
                NEW_LEADER_PORT=$PORT
                END_TIME=$(date +%s)
                FAILOVER_TIME=$((END_TIME - START_TIME))
                break 2
            fi
        fi
    done
    
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    echo -e "  Waiting... ${ELAPSED}s elapsed"
done

if [ -z "$NEW_LEADER" ]; then
    echo -e "${RED}✗ Failover timeout after ${TIMEOUT}s${NC}"
    echo -e "${YELLOW}Resuming original leader...${NC}"
    docker unpause $CONTAINER_NAME
    exit 1
fi

echo -e "  ${GREEN}New leader elected: $NEW_LEADER${NC}"
echo

# Step 5: Verify new leader health
echo -e "${BLUE}Step 5: Verifying new leader health...${NC}"
LEADER_STATUS=$(curl -sf http://localhost:$NEW_LEADER_PORT/health 2>/dev/null || echo "{}")
if echo "$LEADER_STATUS" | grep -q '"state":"running"'; then
    echo -e "  ${GREEN}✓ New leader is healthy and running${NC}"
else
    echo -e "  ${YELLOW}⚠ New leader state unknown${NC}"
fi
echo

# Step 6: Check replication
echo -e "${BLUE}Step 6: Checking replication status...${NC}"
sleep 3  # Allow time for replication to stabilize
REPLICAS_AFTER=$(curl -sf http://localhost:$NEW_LEADER_PORT/cluster 2>/dev/null | grep -o '"role":"replica"' | wc -l)
echo -e "  Replicas streaming: ${GREEN}$REPLICAS_AFTER${NC}"
echo

# Step 7: Resume paused leader
echo -e "${BLUE}Step 7: Resuming paused leader ($CONTAINER_NAME)...${NC}"
docker unpause $CONTAINER_NAME
echo -e "  ${GREEN}Leader resumed and will rejoin as replica${NC}"
echo

# Summary
echo -e "${BLUE}=== Failover Test Summary ===${NC}"
echo -e "  Original leader:    ${YELLOW}$LEADER${NC}"
echo -e "  New leader:         ${GREEN}$NEW_LEADER${NC}"
echo -e "  Failover time:      ${GREEN}${FAILOVER_TIME}s${NC}"
echo -e "  Target:             ≤60s"
echo

if [ $FAILOVER_TIME -le 60 ]; then
    echo -e "${GREEN}✓ Failover completed successfully within target time${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Failover took longer than 60s target${NC}"
    exit 1
fi
