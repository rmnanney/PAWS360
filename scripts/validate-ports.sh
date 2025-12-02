#!/bin/bash
# Port Conflict Detection Script
# Checks if required ports are available

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Required ports
PORTS=(
    "5432:PostgreSQL (Patroni leader)"
    "5433:PostgreSQL (Patroni replica 1)"
    "5434:PostgreSQL (Patroni replica 2)"
    "6379:Redis master"
    "26379:Redis Sentinel 1"
    "26380:Redis Sentinel 2"
    "26381:Redis Sentinel 3"
    "2379:etcd client (shared)"
    "2380:etcd peer (shared)"
    "8008:Patroni API 1"
    "8009:Patroni API 2"
    "8010:Patroni API 3"
    "8080:Backend API"
    "3000:Frontend"
)

echo "=== Port Conflict Detection ==="
echo

CONFLICTS=0

for PORT_DESC in "${PORTS[@]}"; do
    PORT=$(echo $PORT_DESC | cut -d: -f1)
    DESC=$(echo $PORT_DESC | cut -d: -f2-)
    
    echo -n "Port $PORT ($DESC): "
    
    # Check if port is in use
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            PROCESS=$(lsof -Pi :$PORT -sTCP:LISTEN -t | head -1)
            PROCESS_NAME=$(ps -p $PROCESS -o comm= 2>/dev/null || echo "unknown")
            echo -e "${RED}IN USE (PID: $PROCESS, Process: $PROCESS_NAME)${NC}"
            CONFLICTS=$((CONFLICTS + 1))
        else
            echo -e "${GREEN}Available${NC}"
        fi
    else
        # Linux/WSL2
        if ss -ltn "sport = :$PORT" 2>/dev/null | grep -q ":$PORT"; then
            PROCESS_INFO=$(ss -ltnp "sport = :$PORT" 2>/dev/null | grep ":$PORT" | awk '{print $6}' | head -1)
            echo -e "${RED}IN USE ($PROCESS_INFO)${NC}"
            CONFLICTS=$((CONFLICTS + 1))
        elif netstat -ltn 2>/dev/null | grep -q ":$PORT "; then
            echo -e "${RED}IN USE${NC}"
            CONFLICTS=$((CONFLICTS + 1))
        else
            echo -e "${GREEN}Available${NC}"
        fi
    fi
done

echo

if [ $CONFLICTS -gt 0 ]; then
    echo -e "${RED}✗ Found $CONFLICTS port conflict(s)${NC}"
    echo
    echo "Resolution options:"
    echo "  1. Stop conflicting services"
    echo "  2. Modify ports in .env.local"
    echo "  3. Use docker-compose port overrides"
    exit 1
else
    echo -e "${GREEN}✓ All required ports are available${NC}"
    exit 0
fi
