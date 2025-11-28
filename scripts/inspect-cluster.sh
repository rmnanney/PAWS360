#!/usr/bin/env bash
# Cluster Inspection Script - Displays status of etcd, Patroni, Redis
# Usage: ./inspect-cluster.sh [--etcd|--patroni|--redis|--all] [--json]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
INSPECT_ETCD=false
INSPECT_PATRONI=false
INSPECT_REDIS=false
JSON_OUTPUT=false

if [ $# -eq 0 ]; then
    # Default: inspect all
    INSPECT_ETCD=true
    INSPECT_PATRONI=true
    INSPECT_REDIS=true
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            --etcd) INSPECT_ETCD=true; shift ;;
            --patroni) INSPECT_PATRONI=true; shift ;;
            --redis) INSPECT_REDIS=true; shift ;;
            --all) INSPECT_ETCD=true; INSPECT_PATRONI=true; INSPECT_REDIS=true; shift ;;
            --json) JSON_OUTPUT=true; shift ;;
            *) echo "Usage: $0 [--etcd|--patroni|--redis|--all] [--json]"; exit 1 ;;
        esac
    done
fi

# etcd Inspection
inspect_etcd() {
    echo -e "${BLUE}=== etcd Cluster Status ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Member List:${NC}"
    docker exec paws360-etcd1 etcdctl member list --write-out=table 2>/dev/null || echo "  ❌ Failed to get member list"
    echo ""
    
    echo -e "${YELLOW}Endpoint Health:${NC}"
    docker exec paws360-etcd1 etcdctl endpoint health --cluster --write-out=table 2>/dev/null || echo "  ❌ Failed to get endpoint health"
    echo ""
    
    echo -e "${YELLOW}Endpoint Status:${NC}"
    docker exec paws360-etcd1 etcdctl endpoint status --cluster --write-out=table 2>/dev/null || echo "  ❌ Failed to get endpoint status"
    echo ""
}

# Patroni Inspection
inspect_patroni() {
    echo -e "${BLUE}=== Patroni Cluster Status ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Cluster List:${NC}"
    docker exec paws360-patroni1 patronictl list 2>/dev/null || echo "  ❌ Failed to get cluster list"
    echo ""
    
    echo -e "${YELLOW}Replication Lag:${NC}"
    for node in patroni1 patroni2 patroni3; do
        echo -n "  $node: "
        ROLE=$(docker exec paws360-$node patronictl list -f json 2>/dev/null | jq -r '.[] | select(.Member == "'$node'") | .Role' 2>/dev/null || echo "unknown")
        if [ "$ROLE" = "Leader" ]; then
            echo -e "${GREEN}Leader (no lag)${NC}"
        elif [ "$ROLE" = "Replica" ]; then
            LAG=$(docker exec paws360-$node patronictl list -f json 2>/dev/null | jq -r '.[] | select(.Member == "'$node'") | .Lag' 2>/dev/null || echo "unknown")
            if [ "$LAG" = "0" ] || [ "$LAG" = "unknown" ]; then
                echo -e "${GREEN}Replica (lag: $LAG)${NC}"
            else
                echo -e "${YELLOW}Replica (lag: $LAG)${NC}"
            fi
        else
            echo -e "${RED}$ROLE${NC}"
        fi
    done
    echo ""
    
    echo -e "${YELLOW}Timeline:${NC}"
    docker exec paws360-patroni1 patronictl history 2>/dev/null || echo "  ❌ Failed to get timeline history"
    echo ""
}

# Redis Inspection
inspect_redis() {
    echo -e "${BLUE}=== Redis Sentinel Status ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Master Info:${NC}"
    docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL masters 2>/dev/null | head -20 || echo "  ❌ Failed to get master info"
    echo ""
    
    echo -e "${YELLOW}Sentinel Quorum:${NC}"
    docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL ckquorum mymaster 2>/dev/null || echo "  ❌ Failed to check quorum"
    echo ""
    
    echo -e "${YELLOW}Replicas:${NC}"
    docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL replicas mymaster 2>/dev/null | grep -E "(name|ip|port|flags)" || echo "  ❌ Failed to get replica info"
    echo ""
    
    echo -e "${YELLOW}Sentinels:${NC}"
    docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels mymaster 2>/dev/null | grep -E "(name|ip|port|flags)" || echo "  ❌ Failed to get sentinel info"
    echo ""
}

# Main execution
if [ "$JSON_OUTPUT" = true ]; then
    echo "{"
    [ "$INSPECT_ETCD" = true ] && echo "  \"etcd\": \"json output not yet implemented\","
    [ "$INSPECT_PATRONI" = true ] && echo "  \"patroni\": \"json output not yet implemented\","
    [ "$INSPECT_REDIS" = true ] && echo "  \"redis\": \"json output not yet implemented\""
    echo "}"
else
    [ "$INSPECT_ETCD" = true ] && inspect_etcd
    [ "$INSPECT_PATRONI" = true ] && inspect_patroni
    [ "$INSPECT_REDIS" = true ] && inspect_redis
    
    echo -e "${GREEN}✅ Cluster inspection complete${NC}"
fi
