#!/usr/bin/env bash
# Log Aggregation Helper - Filter and aggregate logs from all services
# Usage: ./aggregate-logs.sh [service-name] [--filter pattern] [--since duration] [--tail lines]

set -euo pipefail

# Colors
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
SERVICE=""
FILTER=""
SINCE="10m"
TAIL="100"
FOLLOW=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --filter) FILTER="$2"; shift 2 ;;
        --since) SINCE="$2"; shift 2 ;;
        --tail) TAIL="$2"; shift 2 ;;
        --follow|-f) FOLLOW=true; shift ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *) SERVICE="$1"; shift ;;
    esac
done

COMPOSE_CMD="docker-compose -f docker-compose.yml logs --timestamps --tail=$TAIL --since=$SINCE"

if [ "$FOLLOW" = true ]; then
    COMPOSE_CMD="$COMPOSE_CMD -f"
fi

if [ -n "$SERVICE" ]; then
    COMPOSE_CMD="$COMPOSE_CMD $SERVICE"
fi

# Execute and optionally filter
if [ -n "$FILTER" ]; then
    echo -e "${BLUE}Showing logs${SERVICE:+ for $SERVICE} matching: $FILTER${NC}"
    eval "$COMPOSE_CMD" 2>&1 | grep -i "$FILTER" --color=always
else
    echo -e "${BLUE}Showing all logs${SERVICE:+ for $SERVICE}${NC}"
    eval "$COMPOSE_CMD"
fi
