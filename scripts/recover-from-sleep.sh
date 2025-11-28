#!/bin/bash
# Sleep/Hibernate Recovery Script
# Detects clock skew and cluster health issues after system sleep/hibernate
# Automatically restarts services if needed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Sleep/Hibernate Recovery Check ===${NC}"
echo

# Check if running inside a container
if [ -f /.dockerenv ]; then
    echo -e "${YELLOW}⚠ Running inside container - host recovery only${NC}"
    exit 0
fi

# Detect clock skew
echo -e "${BLUE}Step 1: Checking for clock skew...${NC}"
CURRENT_TIME=$(date +%s)
LAST_BOOT=$(uptime -s 2>/dev/null | xargs -I {} date -d {} +%s 2>/dev/null || echo 0)
UPTIME_SECONDS=$((CURRENT_TIME - LAST_BOOT))

# Check Docker daemon time
DOCKER_TIME=$(docker run --rm alpine date +%s 2>/dev/null || echo 0)
TIME_DIFF=$((CURRENT_TIME - DOCKER_TIME))
ABS_TIME_DIFF=${TIME_DIFF#-}  # Absolute value

if [ $ABS_TIME_DIFF -gt 5 ]; then
    echo -e "  ${YELLOW}⚠ Clock skew detected: ${ABS_TIME_DIFF}s difference${NC}"
    CLOCK_SKEW=true
else
    echo -e "  ${GREEN}✓ No clock skew detected${NC}"
    CLOCK_SKEW=false
fi
echo

# Check etcd cluster health
echo -e "${BLUE}Step 2: Checking etcd cluster health...${NC}"
ETCD_HEALTHY=false

if curl -sf http://localhost:2379/health 2>/dev/null | grep -q '"health":"true"'; then
    echo -e "  ${GREEN}✓ etcd cluster is healthy${NC}"
    ETCD_HEALTHY=true
else
    echo -e "  ${RED}✗ etcd cluster is unhealthy${NC}"
    ETCD_HEALTHY=false
fi
echo

# Check Patroni cluster health
echo -e "${BLUE}Step 3: Checking Patroni cluster health...${NC}"
PATRONI_HEALTHY=false

for PORT in 8008 8009 8010; do
    if curl -sf http://localhost:$PORT/health 2>/dev/null | grep -q '"state":"running"'; then
        echo -e "  ${GREEN}✓ Patroni node on port $PORT is healthy${NC}"
        PATRONI_HEALTHY=true
        break
    fi
done

if [ "$PATRONI_HEALTHY" = false ]; then
    echo -e "  ${RED}✗ No healthy Patroni nodes found${NC}"
fi
echo

# Check Redis health
echo -e "${BLUE}Step 4: Checking Redis health...${NC}"
REDIS_HEALTHY=false

if docker exec paws360-redis-master redis-cli -a "${REDIS_PASSWORD:-dev_redis_password_change_me}" ping 2>/dev/null | grep -q "PONG"; then
    echo -e "  ${GREEN}✓ Redis master is healthy${NC}"
    REDIS_HEALTHY=true
else
    echo -e "  ${RED}✗ Redis master is unhealthy${NC}"
    REDIS_HEALTHY=false
fi
echo

# Determine recovery action
NEEDS_RECOVERY=false

if [ "$CLOCK_SKEW" = true ] || [ "$ETCD_HEALTHY" = false ] || [ "$PATRONI_HEALTHY" = false ] || [ "$REDIS_HEALTHY" = false ]; then
    NEEDS_RECOVERY=true
fi

if [ "$NEEDS_RECOVERY" = true ]; then
    echo -e "${YELLOW}=== Recovery Required ===${NC}"
    echo -e "${YELLOW}Detected issues after system sleep/hibernate${NC}"
    echo
    echo -e "Recovery options:"
    echo -e "  1. Restart services: ${BLUE}make dev-restart${NC}"
    echo -e "  2. Full restart:     ${BLUE}make dev-down && make dev-up${NC}"
    echo -e "  3. Manual check:     ${BLUE}make health${NC}"
    echo
    
    # Ask for confirmation to auto-restart
    read -p "Automatically restart services now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Restarting services...${NC}"
        docker-compose restart
        
        echo -e "${BLUE}Waiting for services to stabilize...${NC}"
        sleep 10
        
        # Verify health
        if ./scripts/health-check.sh; then
            echo -e "${GREEN}✓ Services recovered successfully${NC}"
            exit 0
        else
            echo -e "${RED}✗ Services still unhealthy. Try: make dev-down && make dev-up${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Manual intervention required${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ All services healthy - no recovery needed${NC}"
    exit 0
fi
