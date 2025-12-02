#!/bin/bash
# Test Production Deployment Locally
# This script waits for the CI/CD workflow to build the Docker image,
# then deploys it locally using docker-compose

set -euo pipefail

echo "🚀 PAWS360 Local Production Deployment Test"
echo "============================================"

# Get the current commit SHA
GIT_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(git rev-parse --short HEAD)
IMAGE_NAME="paws360-app:${GIT_SHA}"

echo ""
echo "📦 Target Image: ${IMAGE_NAME}"
echo ""

# Check if image already exists
if docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    echo "✅ Docker image already exists!"
else
    echo "⏳ Waiting for Docker image to be built by CI/CD workflow..."
    echo "   (The workflow must complete the 'docker-build' job first)"
    echo ""
    echo "   You can monitor the workflow at:"
    echo "   https://github.com/rmnanney/PAWS360/actions"
    echo ""
    
    # Poll for image availability
    WAIT_TIME=0
    MAX_WAIT=1800  # 30 minutes
    
    while ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; do
        if [ $WAIT_TIME -ge $MAX_WAIT ]; then
            echo "❌ Timeout waiting for Docker image after ${MAX_WAIT}s"
            echo ""
            echo "💡 Options:"
            echo "   1. Wait for CI/CD workflow to complete"
            echo "   2. Build manually: docker build -f Dockerfile -t ${IMAGE_NAME} ."
            exit 1
        fi
        
        echo -ne "\r   Waiting... ${WAIT_TIME}s elapsed (checking every 30s)"
        sleep 30
        WAIT_TIME=$((WAIT_TIME + 30))
    done
    
    echo ""
    echo "✅ Docker image found!"
fi

echo ""
echo "🔧 Starting production test environment..."
echo ""

# Export GIT_SHA for docker-compose
export GIT_SHA

# Stop any existing deployment
if docker-compose -f docker-compose.prod-test.yml ps | grep -q "Up"; then
    echo "⚠️  Stopping existing deployment..."
    docker-compose -f docker-compose.prod-test.yml down
    echo ""
fi

# Start the deployment
echo "🚀 Deploying PAWS360 with docker-compose..."
docker-compose -f docker-compose.prod-test.yml up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
echo ""

# Wait for services to be healthy
TIMEOUT=300
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check postgres health
    POSTGRES_HEALTH=$(docker inspect paws360-postgres-test --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    
    # Check app health  
    APP_HEALTH=$(docker inspect paws360-prod-test --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    
    echo "   PostgreSQL: ${POSTGRES_HEALTH} | App: ${APP_HEALTH}"
    
    if [ "$POSTGRES_HEALTH" = "healthy" ] && [ "$APP_HEALTH" = "healthy" ]; then
        echo ""
        echo "✅ All services are healthy!"
        break
    fi
    
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "⚠️  Services did not become healthy within ${TIMEOUT}s"
    echo "    Check logs with: docker-compose -f docker-compose.prod-test.yml logs"
fi

echo ""
echo "============================================"
echo "✅ Deployment Complete!"
echo "============================================"
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.prod-test.yml ps
echo ""
echo "🌐 Access Points:"
echo "   • Backend API:  http://localhost:8080"
echo "   • Frontend:     http://localhost:3000"
echo "   • PostgreSQL:   localhost:5432"
echo ""
echo "📋 Useful Commands:"
echo "   • View logs:    docker-compose -f docker-compose.prod-test.yml logs -f"
echo "   • Stop:         docker-compose -f docker-compose.prod-test.yml down"
echo "   • Restart:      docker-compose -f docker-compose.prod-test.yml restart"
echo "   • Shell (app):  docker exec -it paws360-prod-test /bin/bash"
echo "   • Shell (db):   docker exec -it paws360-postgres-test psql -U paws360"
echo ""
echo "🔍 Health Checks:"
echo "   • Backend:      curl http://localhost:8080/actuator/health"
echo "   • Database:     docker exec paws360-postgres-test pg_isready -U paws360"
echo ""
