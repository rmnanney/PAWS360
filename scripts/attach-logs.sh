#!/usr/bin/env bash
# Feature: 001-local-dev-parity
# Task: T094 - Log attachment helper script
# Purpose: Attach to service logs with timestamps

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE="${1:-}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DOCKER_COMPOSE="docker compose"

if [ -z "$SERVICE" ]; then
    echo -e "${RED}❌ Error: Service name required${NC}"
    echo ""
    echo -e "${BLUE}Usage: $0 <service-name>${NC}"
    echo ""
    echo -e "${BLUE}Available services:${NC}"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" ps --services 2>/dev/null | while read -r svc; do
        status=$($DOCKER_COMPOSE -f "$COMPOSE_FILE" ps "$svc" --format '{{.Status}}' 2>/dev/null || echo "Not running")
        if echo "$status" | grep -q "Up"; then
            echo -e "  ${GREEN}✓${NC} $svc"
        else
            echo -e "  ${RED}✗${NC} $svc (not running)"
        fi
    done
    echo ""
    echo -e "${YELLOW}💡 Example: $0 backend${NC}"
    exit 1
fi

# Check if service exists
if ! $DOCKER_COMPOSE -f "$COMPOSE_FILE" ps --services 2>/dev/null | grep -q "^${SERVICE}$"; then
    echo -e "${RED}❌ Error: Service '${SERVICE}' not found${NC}"
    echo ""
    echo -e "${BLUE}Available services:${NC}"
    $DOCKER_COMPOSE -f "$COMPOSE_FILE" ps --services 2>/dev/null
    exit 1
fi

echo -e "${BLUE}📋 Attaching to logs: ${SERVICE}${NC}"
echo -e "${YELLOW}💡 Press Ctrl+C to detach (container will keep running)${NC}"
echo ""

# Attach to logs with timestamps and follow
$DOCKER_COMPOSE -f "$COMPOSE_FILE" logs -f --timestamps "$SERVICE"
