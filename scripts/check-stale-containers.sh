#!/bin/bash
# Stale Container Detection Script
# Detects orphaned containers from previous sessions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Stale Container Detection ===${NC}"
echo

# Get all PAWS360 containers
PAWS360_CONTAINERS=$(docker ps -a --filter "name=paws360-" --format "{{.Names}}" 2>/dev/null || echo "")

if [ -z "$PAWS360_CONTAINERS" ]; then
    echo -e "${GREEN}✓ No PAWS360 containers found${NC}"
    exit 0
fi

# Check for stopped containers
STOPPED_CONTAINERS=$(docker ps -a --filter "name=paws360-" --filter "status=exited" --format "{{.Names}}" 2>/dev/null || echo "")
CREATED_CONTAINERS=$(docker ps -a --filter "name=paws360-" --filter "status=created" --format "{{.Names}}" 2>/dev/null || echo "")

STALE_COUNT=0

if [ -n "$STOPPED_CONTAINERS" ]; then
    echo -e "${YELLOW}Stopped containers:${NC}"
    for CONTAINER in $STOPPED_CONTAINERS; do
        EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $CONTAINER)
        FINISHED_AT=$(docker inspect --format='{{.State.FinishedAt}}' $CONTAINER | cut -d'.' -f1)
        echo -e "  ${YELLOW}- $CONTAINER${NC} (exit code: $EXIT_CODE, stopped: $FINISHED_AT)"
        STALE_COUNT=$((STALE_COUNT + 1))
    done
    echo
fi

if [ -n "$CREATED_CONTAINERS" ]; then
    echo -e "${YELLOW}Created but not started containers:${NC}"
    for CONTAINER in $CREATED_CONTAINERS; do
        CREATED_AT=$(docker inspect --format='{{.Created}}' $CONTAINER | cut -d'.' -f1)
        echo -e "  ${YELLOW}- $CONTAINER${NC} (created: $CREATED_AT)"
        STALE_COUNT=$((STALE_COUNT + 1))
    done
    echo
fi

# Check for containers from docker-compose.override.yml
OVERRIDE_CONTAINERS=$(docker ps -a --filter "label=com.docker.compose.project=paws360" --filter "status=exited" --format "{{.Names}}" 2>/dev/null || echo "")

if [ -n "$OVERRIDE_CONTAINERS" ]; then
    echo -e "${YELLOW}Docker Compose override containers:${NC}"
    for CONTAINER in $OVERRIDE_CONTAINERS; do
        if ! echo "$STOPPED_CONTAINERS $CREATED_CONTAINERS" | grep -q "$CONTAINER"; then
            echo -e "  ${YELLOW}- $CONTAINER${NC}"
            STALE_COUNT=$((STALE_COUNT + 1))
        fi
    done
    echo
fi

# Summary and recommendations
if [ $STALE_COUNT -gt 0 ]; then
    echo -e "${YELLOW}=== Found $STALE_COUNT stale container(s) ===${NC}"
    echo
    echo -e "Cleanup options:"
    echo -e "  1. Remove stale containers:  ${BLUE}docker-compose down${NC}"
    echo -e "  2. Remove with volumes:      ${BLUE}docker-compose down -v${NC}"
    echo -e "  3. Clean rebuild:            ${BLUE}make dev-reset${NC}"
    echo
    
    # Ask for confirmation to clean up
    read -p "Remove stale containers now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Removing stale containers...${NC}"
        docker-compose down
        echo -e "${GREEN}✓ Stale containers removed${NC}"
        echo -e "Run ${BLUE}make dev-up${NC} to start fresh environment"
        exit 0
    else
        echo -e "${YELLOW}Stale containers left in place${NC}"
        exit 1
    fi
else
    # Check for running containers
    RUNNING_CONTAINERS=$(docker ps --filter "name=paws360-" --format "{{.Names}}" | wc -l)
    
    if [ $RUNNING_CONTAINERS -gt 0 ]; then
        echo -e "${GREEN}✓ Environment is running with $RUNNING_CONTAINERS container(s)${NC}"
    else
        echo -e "${GREEN}✓ No stale containers found${NC}"
        echo -e "Run ${BLUE}make dev-up${NC} to start environment"
    fi
    exit 0
fi
