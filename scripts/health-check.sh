#!/bin/bash
# Unified Health Check Script
# Checks health of all infrastructure components

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
OUTPUT_MODE="human"  # human or json
if [ "$1" = "--json" ]; then
    OUTPUT_MODE="json"
fi

# Helper functions
check_service() {
    local service=$1
    local check_command=$2
    
    if eval "$check_command" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# JSON output initialization
if [ "$OUTPUT_MODE" = "json" ]; then
    echo "{"
    echo '  "timestamp": "'$(date -Iseconds)'",'
    echo '  "checks": {'
fi

# ===== etcd Cluster Health =====
if [ "$OUTPUT_MODE" = "human" ]; then
    echo -e "${BLUE}=== etcd Cluster Health ===${NC}"
fi

ETCD_HEALTHY=0
ETCD_MEMBERS=0
ETCD_QUORUM=false

if check_service "etcd1" "curl -sf http://localhost:2379/health"; then
    # Get cluster health
    ETCD_HEALTH=$(curl -sf http://localhost:2379/health 2>/dev/null || echo '{"health":"false"}')
    ETCD_MEMBERS=$(curl -sf http://localhost:2379/v2/members 2>/dev/null | grep -o '"id"' | wc -l)
    
    if echo "$ETCD_HEALTH" | grep -q '"health":"true"'; then
        ETCD_HEALTHY=1
        if [ $ETCD_MEMBERS -ge 2 ]; then
            ETCD_QUORUM=true
        fi
    fi
fi

if [ "$OUTPUT_MODE" = "human" ]; then
    if [ $ETCD_HEALTHY -eq 1 ]; then
        echo -e "  Cluster health: ${GREEN}HEALTHY${NC}"
        echo -e "  Members: ${GREEN}${ETCD_MEMBERS}/3${NC}"
        if [ "$ETCD_QUORUM" = true ]; then
            echo -e "  Quorum: ${GREEN}ACHIEVED${NC}"
        else
            echo -e "  Quorum: ${YELLOW}AT RISK (need 2/3)${NC}"
        fi
    else
        echo -e "  Cluster health: ${RED}UNHEALTHY${NC}"
    fi
else
    echo '    "etcd": {'
    echo "      \"healthy\": $ETCD_HEALTHY,"
    echo "      \"members\": $ETCD_MEMBERS,"
    echo "      \"quorum\": $([ "$ETCD_QUORUM" = true ] && echo true || echo false)"
    echo '    },'
fi

# ===== Patroni Cluster Health =====
if [ "$OUTPUT_MODE" = "human" ]; then
    echo
    echo -e "${BLUE}=== Patroni/PostgreSQL Cluster Health ===${NC}"
fi

PATRONI_LEADER=""
PATRONI_REPLICAS=0
PATRONI_LAG_MS=0
PATRONI_HEALTHY=0

if check_service "patroni1" "curl -sf http://localhost:8008/health"; then
    # Check each Patroni node
    for PORT in 8008 8009 8010; do
        if PATRONI_STATUS=$(curl -sf http://localhost:$PORT/patroni 2>/dev/null); then
            ROLE=$(echo "$PATRONI_STATUS" | grep -o '"role": *"[^"]*"' | sed 's/"role": *"\([^"]*\)"/\1/')
            STATE=$(echo "$PATRONI_STATUS" | grep -o '"state": *"[^"]*"' | sed 's/"state": *"\([^"]*\)"/\1/')
            
            if [ "$ROLE" = "master" ] || [ "$ROLE" = "leader" ]; then
                PATRONI_LEADER="patroni$((PORT - 8007))"
                if [ "$STATE" = "running" ]; then
                    PATRONI_HEALTHY=1
                fi
            elif [ "$ROLE" = "replica" ]; then
                if [ "$STATE" = "streaming" ] || [ "$STATE" = "running" ]; then
                    PATRONI_REPLICAS=$((PATRONI_REPLICAS + 1))
                fi
            fi
        fi
    done
fi

if [ "$OUTPUT_MODE" = "human" ]; then
    if [ -n "$PATRONI_LEADER" ]; then
        echo -e "  Leader: ${GREEN}${PATRONI_LEADER}${NC}"
    else
        echo -e "  Leader: ${RED}NONE ELECTED${NC}"
    fi
    echo -e "  Replicas streaming: ${GREEN}${PATRONI_REPLICAS}/2${NC}"
    if [ $PATRONI_HEALTHY -eq 1 ]; then
        echo -e "  Cluster status: ${GREEN}HEALTHY${NC}"
    else
        echo -e "  Cluster status: ${RED}UNHEALTHY${NC}"
    fi
else
    echo '    "patroni": {'
    echo "      \"leader\": \"$PATRONI_LEADER\","
    echo "      \"replicas\": $PATRONI_REPLICAS,"
    echo "      \"healthy\": $PATRONI_HEALTHY"
    echo '    },'
fi

# ===== Redis Sentinel Health =====
if [ "$OUTPUT_MODE" = "human" ]; then
    echo
    echo -e "${BLUE}=== Redis Sentinel Health ===${NC}"
fi

REDIS_MASTER=""
REDIS_REPLICAS=0
REDIS_SENTINELS=0
REDIS_HEALTHY=0

if check_service "redis-master" "docker exec paws360-redis-master redis-cli -a \${REDIS_PASSWORD:-dev_redis_password_change_me} ping 2>/dev/null"; then
    # Get master info
    REDIS_MASTER="redis-master"
    REDIS_HEALTHY=1
    
    # Count replicas
    REDIS_REPLICAS=$(docker exec paws360-redis-master redis-cli -a "${REDIS_PASSWORD:-dev_redis_password_change_me}" INFO replication 2>/dev/null | grep "connected_slaves" | cut -d: -f2 | tr -d '\r\n' || echo 0)
    
    # Count sentinels
    SENTINEL_INFO=$(docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL master paws360-redis-master 2>/dev/null || echo "")
    REDIS_SENTINELS=$(echo "$SENTINEL_INFO" | grep "num-other-sentinels" | awk '{print $2}' || echo 0)
    REDIS_SENTINELS=$((REDIS_SENTINELS + 1))  # Add 1 for the sentinel we queried
fi

if [ "$OUTPUT_MODE" = "human" ]; then
    if [ -n "$REDIS_MASTER" ]; then
        echo -e "  Master: ${GREEN}${REDIS_MASTER}${NC}"
    else
        echo -e "  Master: ${RED}NONE ASSIGNED${NC}"
    fi
    echo -e "  Replicas: ${GREEN}${REDIS_REPLICAS}/2${NC}"
    echo -e "  Sentinels: ${GREEN}${REDIS_SENTINELS}/3${NC}"
    if [ $REDIS_HEALTHY -eq 1 ]; then
        echo -e "  Cluster status: ${GREEN}HEALTHY${NC}"
    else
        echo -e "  Cluster status: ${RED}UNHEALTHY${NC}"
    fi
else
    echo '    "redis": {'
    echo "      \"master\": \"$REDIS_MASTER\","
    echo "      \"replicas\": $REDIS_REPLICAS,"
    echo "      \"sentinels\": $REDIS_SENTINELS,"
    echo "      \"healthy\": $REDIS_HEALTHY"
    echo '    }'
fi

# ===== Application Services Health =====
# if [ "$OUTPUT_MODE" = "human" ]; then
#     echo
#     echo -e "${BLUE}=== Application Services Health ===${NC}"
# fi

# BACKEND_HEALTHY=0
# FRONTEND_HEALTHY=0

# if check_service "backend" "curl -sf http://localhost:8080/actuator/health"; then
#     BACKEND_HEALTHY=1
# fi

# if check_service "frontend" "curl -sf http://localhost:3000/api/health"; then
#     FRONTEND_HEALTHY=1
# fi

# if [ "$OUTPUT_MODE" = "human" ]; then
#     if [ $BACKEND_HEALTHY -eq 1 ]; then
#         echo -e "  Backend: ${GREEN}HEALTHY${NC}"
#     else
#         echo -e "  Backend: ${RED}UNHEALTHY${NC}"
#     fi
    
#     if [ $FRONTEND_HEALTHY -eq 1 ]; then
#         echo -e "  Frontend: ${GREEN}HEALTHY${NC}"
#     else
#         echo -e "  Frontend: ${RED}UNHEALTHY${NC}"
#     fi
# else
#     echo ','
#     echo '    "applications": {'
#     echo "      \"backend\": $BACKEND_HEALTHY,"
#     echo "      \"frontend\": $FRONTEND_HEALTHY"
#     echo '    }'
# fi

# Close JSON
if [ "$OUTPUT_MODE" = "json" ]; then
    echo '  }'
    echo "}"
fi

# Overall health check
OVERALL_HEALTHY=0
if [ $ETCD_HEALTHY -eq 1 ] && [ $PATRONI_HEALTHY -eq 1 ] && [ $REDIS_HEALTHY -eq 1 ]; then
    OVERALL_HEALTHY=1
fi

if [ "$OUTPUT_MODE" = "human" ]; then
    echo
    if [ $OVERALL_HEALTHY -eq 1 ]; then
        echo -e "${GREEN}✓ All infrastructure services are healthy${NC}"
    else
        echo -e "${RED}✗ Some infrastructure services are unhealthy${NC}"
        exit 1
    fi
fi

exit $((1 - OVERALL_HEALTHY))
