#!/bin/bash
# Platform Validation Script
# Validates OS, Docker version, and architecture for local dev environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Platform Validation ==="
echo

# Detect OS
echo -n "Operating System: "
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_VERSION="$NAME $VERSION"
    fi
    echo -e "${GREEN}${OS_VERSION}${NC}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    OS_VERSION=$(sw_vers -productVersion)
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        echo -e "${GREEN}macOS ${OS_VERSION} (Apple Silicon)${NC}"
    else
        echo -e "${GREEN}macOS ${OS_VERSION} (Intel)${NC}"
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="WSL2"
        echo -e "${GREEN}Windows WSL2${NC}"
    else
        OS="Windows"
        echo -e "${YELLOW}Windows (native not supported - use WSL2)${NC}"
        exit 1
    fi
else
    echo -e "${RED}Unknown: $OSTYPE${NC}"
    exit 1
fi

# Detect Architecture
echo -n "Architecture: "
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        echo -e "${GREEN}x86_64 (amd64)${NC}"
        ;;
    aarch64|arm64)
        echo -e "${GREEN}ARM64${NC}"
        echo -e "${YELLOW}Note: Some images may require --platform=linux/amd64${NC}"
        ;;
    *)
        echo -e "${RED}Unsupported: $ARCH${NC}"
        exit 1
        ;;
esac

# Check Docker
echo -n "Docker: "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${GREEN}$DOCKER_VERSION${NC}"
    
    # Verify Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker daemon is not running${NC}"
        exit 1
    fi
    
    # Check minimum version (20.10.0)
    MIN_VERSION="20.10.0"
    if [ "$(printf '%s\n' "$MIN_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_VERSION" ]; then
        echo -e "${YELLOW}Warning: Docker version $DOCKER_VERSION is below recommended $MIN_VERSION${NC}"
    fi
else
    # Check for Podman as alternative
    if command -v podman &> /dev/null; then
        PODMAN_VERSION=$(podman --version | awk '{print $3}')
        echo -e "${GREEN}Podman $PODMAN_VERSION (Docker alternative)${NC}"
    else
        echo -e "${RED}Not found - Docker or Podman required${NC}"
        exit 1
    fi
fi

# Check Docker Compose
echo -n "Docker Compose: "
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
    echo -e "${GREEN}$COMPOSE_VERSION${NC}"
elif docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "${GREEN}$COMPOSE_VERSION (plugin)${NC}"
elif command -v podman-compose &> /dev/null; then
    COMPOSE_VERSION=$(podman-compose --version)
    echo -e "${GREEN}$COMPOSE_VERSION${NC}"
else
    echo -e "${RED}Not found - Docker Compose required${NC}"
    exit 1
fi

# Check minimum Compose version (2.0.0)
MIN_COMPOSE_VERSION="2.0.0"
if [ "$(printf '%s\n' "$MIN_COMPOSE_VERSION" "$COMPOSE_VERSION" | sort -V | head -n1)" != "$MIN_COMPOSE_VERSION" ]; then
    echo -e "${YELLOW}Warning: Compose version $COMPOSE_VERSION is below recommended $MIN_COMPOSE_VERSION${NC}"
fi

echo
echo -e "${GREEN}✓ Platform validation passed${NC}"
exit 0
