#!/bin/bash
# Resource Validation Script
# Validates system has sufficient RAM, CPU, and disk space

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Minimum requirements (allow override via MIN_RAM_GB env var)
MIN_RAM_GB=${MIN_RAM_GB:-16}
MIN_CPU_CORES=4
MIN_DISK_GB=40

echo "=== Resource Validation ==="
echo

# Check RAM
echo -n "Memory: "
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "msys" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
elif [[ "$OSTYPE" == "darwin"* ]]; then
    TOTAL_RAM_BYTES=$(sysctl -n hw.memsize)
    TOTAL_RAM_GB=$((TOTAL_RAM_BYTES / 1024 / 1024 / 1024))
else
    echo -e "${RED}Unable to detect${NC}"
    exit 1
fi

if [ $TOTAL_RAM_GB -ge $MIN_RAM_GB ]; then
    echo -e "${GREEN}${TOTAL_RAM_GB}GB (≥${MIN_RAM_GB}GB required)${NC}"
else
    echo -e "${RED}${TOTAL_RAM_GB}GB (${MIN_RAM_GB}GB required)${NC}"
    echo -e "${RED}✗ Insufficient RAM for full HA stack${NC}"
    echo -e "${YELLOW}Consider using dev-up-fast mode (single instances) or upgrading hardware${NC}"
    # Allow a non-fatal override for cases where CI uses smaller hosted runners
    if [ "${ALLOW_LOW_RAM}" = "true" ] || [ "${ALLOW_LESS_RAM}" = "true" ]; then
        echo -e "${YELLOW}Warning: ALLOW_LOW_RAM/ALLOW_LESS_RAM=true — continuing despite insufficient RAM${NC}"
    else
        exit 1
    fi
fi

# Check CPU cores
echo -n "CPU Cores: "
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "msys" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    CPU_CORES=$(nproc)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    CPU_CORES=$(sysctl -n hw.ncpu)
else
    echo -e "${RED}Unable to detect${NC}"
    exit 1
fi

if [ $CPU_CORES -ge $MIN_CPU_CORES ]; then
    echo -e "${GREEN}${CPU_CORES} (≥${MIN_CPU_CORES} required)${NC}"
else
    echo -e "${YELLOW}${CPU_CORES} (${MIN_CPU_CORES} recommended)${NC}"
    echo -e "${YELLOW}⚠ May experience slow startup and performance issues${NC}"
fi

# Check disk space
echo -n "Disk Space: "
if command -v df &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        AVAILABLE_DISK_GB=$(df -g . | tail -1 | awk '{print $4}')
    else
        AVAILABLE_DISK_KB=$(df -k . | tail -1 | awk '{print $4}')
        AVAILABLE_DISK_GB=$((AVAILABLE_DISK_KB / 1024 / 1024))
    fi
    
    if [ $AVAILABLE_DISK_GB -ge $MIN_DISK_GB ]; then
        echo -e "${GREEN}${AVAILABLE_DISK_GB}GB available (≥${MIN_DISK_GB}GB required)${NC}"
    else
        echo -e "${RED}${AVAILABLE_DISK_GB}GB available (${MIN_DISK_GB}GB required)${NC}"
        echo -e "${RED}✗ Insufficient disk space${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Unable to detect${NC}"
fi

# Check Docker daemon resources (if applicable)
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo
    echo "Docker Daemon Resources:"
    
    # Get Docker memory limit (macOS/Windows)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        DOCKER_MEM=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0)
        if [ $DOCKER_MEM -gt 0 ]; then
            DOCKER_MEM_GB=$((DOCKER_MEM / 1024 / 1024 / 1024))
            if [ $DOCKER_MEM_GB -ge $MIN_RAM_GB ]; then
                echo -e "  Memory allocated: ${GREEN}${DOCKER_MEM_GB}GB${NC}"
            else
                echo -e "  Memory allocated: ${YELLOW}${DOCKER_MEM_GB}GB (increase to ${MIN_RAM_GB}GB in Docker Desktop)${NC}"
            fi
        fi
    fi
    
    # Get Docker CPUs (macOS/Windows)
    DOCKER_CPUS=$(docker info --format '{{.NCPU}}' 2>/dev/null || echo 0)
    if [ $DOCKER_CPUS -gt 0 ]; then
        if [ $DOCKER_CPUS -ge $MIN_CPU_CORES ]; then
            echo -e "  CPUs allocated: ${GREEN}${DOCKER_CPUS}${NC}"
        else
            echo -e "  CPUs allocated: ${YELLOW}${DOCKER_CPUS} (increase to ${MIN_CPU_CORES} in Docker Desktop)${NC}"
        fi
    fi
fi

echo
echo -e "${GREEN}✓ Resource validation passed${NC}"
exit 0
