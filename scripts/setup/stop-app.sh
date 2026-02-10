#!/bin/bash

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PAWS360 - Stopping Services"
echo "=========================================="
echo ""

# Stop backend (Spring Boot on port 8086)
if lsof -ti:8086 >/dev/null 2>&1; then
    echo "Stopping backend (port 8086)..."
    kill $(lsof -ti:8086) 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Backend stopped"
else
    echo "Backend not running"
fi

# Stop frontend (Next.js on port 3000)
if lsof -ti:3000 >/dev/null 2>&1; then
    echo "Stopping frontend (port 3000)..."
    kill $(lsof -ti:3000) 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Frontend stopped"
else
    echo "Frontend not running"
fi

# Optionally stop database
echo ""
read -p "Stop PostgreSQL database? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if docker ps | grep -q paws360-postgres; then
        echo "Stopping PostgreSQL..."
        docker stop paws360-postgres
        echo -e "${GREEN}✓${NC} Database stopped"
    else
        echo "Database not running"
    fi
fi

echo ""
echo -e "${GREEN}✓${NC} All services stopped"
echo ""
