#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PAWS360 - Health Check"
echo "=========================================="
echo ""

all_ok=true

# Check PostgreSQL
echo -n "PostgreSQL:  "
if docker ps | grep -q paws360-postgres; then
    if docker exec paws360-postgres pg_isready -U paws360 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${YELLOW}⚠ Container running but not ready${NC}"
        all_ok=false
    fi
else
    echo -e "${RED}✗ Not running${NC}"
    all_ok=false
fi

# Check Backend
echo -n "Backend:     "
if curl -s http://localhost:8086/actuator/health > /dev/null 2>&1; then
    health=$(curl -s http://localhost:8086/actuator/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$health" = "UP" ]; then
        echo -e "${GREEN}✓ Healthy (port 8086)${NC}"
    else
        echo -e "${YELLOW}⚠ Responding but status: $health${NC}"
        all_ok=false
    fi
else
    if lsof -ti:8086 >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Running but not responding (port 8086)${NC}"
    else
        echo -e "${RED}✗ Not running${NC}"
    fi
    all_ok=false
fi

# Check Frontend
echo -n "Frontend:    "
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Running (port 3000)${NC}"
else
    if lsof -ti:3000 >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Running but not responding (port 3000)${NC}"
    else
        echo -e "${RED}✗ Not running${NC}"
    fi
    all_ok=false
fi

echo ""

if $all_ok; then
    echo -e "${GREEN}✓${NC} All services are healthy!"
    echo ""
    echo "Access the application at: ${GREEN}http://localhost:3000${NC}"
    echo ""
    echo "Test Login:"
    echo "  Email:    test@uwm.edu"
    echo "  Password: password"
else
    echo -e "${RED}✗${NC} Some services are not healthy"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check logs: /tmp/paws360-logs/"
    echo "  - Restart services: ./scripts/setup/start-app.sh"
    echo "  - View detailed errors above"
fi

echo ""
