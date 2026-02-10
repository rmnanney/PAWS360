#!/usr/bin/env bash
#
# validate-ci-parity.sh
# Validates that local development and remote CI use identical versions
# for critical dependencies (PostgreSQL, Redis, Node.js, Java)
#
# Feature: 001-local-dev-parity
# Task: T068 - Create CI parity validation script
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
WORKFLOW_FILE="${REPO_ROOT}/.github/workflows/local-dev-ci.yml"

echo "🔍 CI/Remote Parity Validation"
echo "==============================="
echo ""

# Track validation status
PARITY_PASS=true

# Function to extract version from docker-compose.yml
get_compose_version() {
    local service=$1
    grep -A5 "image: ${service}:" "$COMPOSE_FILE" | grep "image:" | sed -E "s/.*${service}:([0-9.]+).*/\1/" | head -1
}

# Function to extract version from GitHub Actions workflow
get_workflow_version() {
    local service=$1
    grep "image: ${service}:" "$WORKFLOW_FILE" | sed -E "s/.*${service}:([0-9.]+).*/\1/" | head -1
}

# Validate PostgreSQL version
echo -n "PostgreSQL version... "
COMPOSE_POSTGRES=$(get_compose_version "postgres")
WORKFLOW_POSTGRES=$(get_workflow_version "postgres")

if [ "$COMPOSE_POSTGRES" = "$WORKFLOW_POSTGRES" ]; then
    echo -e "${GREEN}✓${NC} Match: $COMPOSE_POSTGRES"
else
    echo -e "${RED}✗${NC} Mismatch: Compose=$COMPOSE_POSTGRES, Workflow=$WORKFLOW_POSTGRES"
    PARITY_PASS=false
fi

# Validate Redis version
echo -n "Redis version... "
COMPOSE_REDIS=$(get_compose_version "redis")
WORKFLOW_REDIS=$(get_workflow_version "redis")

if [ "$COMPOSE_REDIS" = "$WORKFLOW_REDIS" ]; then
    echo -e "${GREEN}✓${NC} Match: $COMPOSE_REDIS"
else
    echo -e "${RED}✗${NC} Mismatch: Compose=$COMPOSE_REDIS, Workflow=$WORKFLOW_REDIS"
    PARITY_PASS=false
fi

# Validate etcd version
echo -n "etcd version... "
COMPOSE_ETCD=$(get_compose_version "quay.io/coreos/etcd" || echo "custom")
if [ "$COMPOSE_ETCD" = "custom" ]; then
    echo -e "${YELLOW}ⓘ${NC} Custom build (check Dockerfile)"
else
    echo -e "${GREEN}✓${NC} Using: $COMPOSE_ETCD"
fi

# Validate Node.js version (if backend Dockerfile exists)
if [ -f "${REPO_ROOT}/Dockerfile" ] || [ -f "${REPO_ROOT}/frontend/Dockerfile" ]; then
    echo -n "Node.js version... "
    
    # Extract from Dockerfile
    COMPOSE_NODE=$(grep "FROM node:" "${REPO_ROOT}"/*/Dockerfile 2>/dev/null | head -1 | sed -E 's/.*node:([0-9.]+).*/\1/' || echo "not-specified")
    
    # Extract from workflow (if Node setup step exists)
    WORKFLOW_NODE=$(grep -A2 "uses: actions/setup-node" "$WORKFLOW_FILE" | grep "node-version:" | sed -E 's/.*node-version: ([0-9.]+)/\1/' || echo "not-specified")
    
    if [ "$COMPOSE_NODE" != "not-specified" ] && [ "$WORKFLOW_NODE" != "not-specified" ]; then
        if [ "$COMPOSE_NODE" = "$WORKFLOW_NODE" ]; then
            echo -e "${GREEN}✓${NC} Match: $COMPOSE_NODE"
        else
            echo -e "${RED}✗${NC} Mismatch: Compose=$COMPOSE_NODE, Workflow=$WORKFLOW_NODE"
            PARITY_PASS=false
        fi
    else
        echo -e "${YELLOW}ⓘ${NC} Not specified or not applicable"
    fi
fi

# Validate Java version (if backend exists)
if [ -f "${REPO_ROOT}/pom.xml" ]; then
    echo -n "Java version... "
    
    # Extract from pom.xml
    COMPOSE_JAVA=$(grep -A1 "<java.version>" "${REPO_ROOT}/pom.xml" | grep "<java.version>" | sed -E 's/.*<java.version>([0-9.]+)<\/java.version>.*/\1/' || echo "not-specified")
    
    # Extract from workflow (if Java setup step exists)
    WORKFLOW_JAVA=$(grep -A2 "uses: actions/setup-java" "$WORKFLOW_FILE" | grep "java-version:" | sed -E 's/.*java-version: ([0-9.]+)/\1/' || echo "not-specified")
    
    if [ "$COMPOSE_JAVA" != "not-specified" ] && [ "$WORKFLOW_JAVA" != "not-specified" ]; then
        if [ "$COMPOSE_JAVA" = "$WORKFLOW_JAVA" ]; then
            echo -e "${GREEN}✓${NC} Match: $COMPOSE_JAVA"
        else
            echo -e "${RED}✗${NC} Mismatch: Compose=$COMPOSE_JAVA, Workflow=$WORKFLOW_JAVA"
            PARITY_PASS=false
        fi
    else
        echo -e "${YELLOW}ⓘ${NC} Not specified or not applicable"
    fi
fi

echo ""
echo "==============================="

if [ "$PARITY_PASS" = true ]; then
    echo -e "${GREEN}✅ CI parity validation PASSED${NC}"
    echo "Local and remote CI use identical versions"
    exit 0
else
    echo -e "${RED}❌ CI parity validation FAILED${NC}"
    echo ""
    echo "Action required:"
    echo "  1. Review mismatched versions above"
    echo "  2. Update docker-compose.yml OR .github/workflows/local-dev-ci.yml"
    echo "  3. Ensure local and CI use identical dependency versions"
    echo "  4. Re-run: make validate-ci-parity"
    exit 1
fi
