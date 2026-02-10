#!/bin/bash

# Quick Docker Compose Test for PAWS360
# Tests just the docker-compose.ci.yml setup

set -e

echo "🐳 Testing Docker Compose Setup"
echo "==============================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Set environment variables (simulate CI/CD)
export REGISTRY=""
export IMAGE_NAME="paws360"

# Set the full image name
if [ -z "$REGISTRY" ]; then
    export FULL_IMAGE_NAME="$IMAGE_NAME"
else
    export FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME"
fi

echo "Using image: $FULL_IMAGE_NAME"

# Build the test image first
echo -e "${YELLOW}Building test Docker image...${NC}"
if docker build -f infrastructure/docker/Dockerfile -t paws360:test .; then
    echo -e "${GREEN}✓ Docker build successful${NC}"
else
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi

echo ""

# Tag the image as latest for docker-compose
echo -e "${YELLOW}Tagging image as latest...${NC}"
docker tag paws360:test paws360:latest

echo ""

# Test docker-compose config
echo -e "${YELLOW}Validating docker-compose.ci.yml...${NC}"
if docker compose -f docker-compose.ci.yml config; then
    echo -e "${GREEN}✓ Docker Compose config is valid${NC}"
else
    echo -e "${RED}✗ Docker Compose config is invalid${NC}"
    exit 1
fi

echo ""

# Start services
echo -e "${YELLOW}Starting services...${NC}"
if docker compose -f docker-compose.ci.yml up -d; then
    echo -e "${GREEN}✓ Services started successfully${NC}"
else
    echo -e "${RED}✗ Failed to start services${NC}"
    exit 1
fi

echo ""

# Wait for application to start (check if port is responding)
echo -e "${YELLOW}Waiting for application to start...${NC}"
timeout=60
elapsed=0

while [ $elapsed -lt $timeout ]; do
    if curl -f http://localhost:8087/actuator/health >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is healthy!${NC}"
        break
    fi

    echo "Waiting... ($elapsed/$timeout seconds)"
    sleep 10
    elapsed=$((elapsed + 10))
done

if [ $elapsed -ge $timeout ]; then
    echo -e "${RED}✗ Application failed to become healthy within $timeout seconds${NC}"
    echo -e "${YELLOW}Showing logs:${NC}"
    docker compose -f docker-compose.ci.yml logs paws360-app
    docker compose -f docker-compose.ci.yml down -v
    exit 1
fi

echo ""

# Test database connection
echo -e "${YELLOW}Testing database connectivity...${NC}"
if docker compose -f docker-compose.ci.yml exec -T postgres pg_isready -U paws360 -d paws360_test >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Database is accessible${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
fi

echo ""

# Test Redis connection
echo -e "${YELLOW}Testing Redis connectivity...${NC}"
if docker compose -f docker-compose.ci.yml exec -T redis redis-cli --raw incr ping >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Redis is accessible${NC}"
else
    echo -e "${RED}✗ Redis connection failed${NC}"
fi

echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
docker compose -f docker-compose.ci.yml down -v
docker rmi paws360:test paws360:latest 2>/dev/null || true

echo ""
echo -e "${GREEN}🎉 Docker Compose test completed successfully!${NC}"
echo -e "${GREEN}The CI/CD pipeline should work now.${NC}"