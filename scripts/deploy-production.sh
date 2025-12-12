#!/bin/bash
# Deploy PAWS360 to Production
# Makes the application available at https://paws360.ryannanney.com

set -euo pipefail

echo "🚀 PAWS360 Production Deployment"
echo "================================="
echo ""

# Get commit SHA
GIT_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(git rev-parse --short HEAD)

echo "📦 Deploying version: ${SHORT_SHA}"
echo "🌐 Domain: paws360.ryannanney.com"
echo ""

# Check if Docker image exists
IMAGE_NAME="paws360-app:${GIT_SHA}"
if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    echo "❌ Docker image not found: ${IMAGE_NAME}"
    echo ""
    echo "Building the image now..."
    docker build -f infrastructure/docker/Dockerfile -t "${IMAGE_NAME}" .
    echo ""
fi

# Create traefik network if it doesn't exist
if ! docker network inspect traefik-public >/dev/null 2>&1; then
    echo "📡 Creating traefik-public network..."
    docker network create traefik-public
fi

# Create letsencrypt directory
mkdir -p letsencrypt
chmod 600 letsencrypt 2>/dev/null || true

# Export environment variables
export GIT_SHA

# Generate secure passwords if not set
if [ ! -f .env.production ]; then
    echo "🔐 Generating secure credentials..."
    cat > .env.production << EOF
# PAWS360 Production Environment Variables
# Generated: $(date)

GIT_SHA=${GIT_SHA}

# Database
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Redis
REDIS_PASSWORD=$(openssl rand -base64 32)

# Application
SPRING_PROFILES_ACTIVE=prod
EOF
    echo "✅ Credentials saved to .env.production"
    echo ""
fi

# Load environment variables
set -a
source .env.production
set +a

# Stop existing deployment
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    echo "⚠️  Stopping existing deployment..."
    docker-compose -f docker-compose.production.yml down
    echo ""
fi

# Start the deployment
echo "🚀 Starting production deployment..."
docker compose -f docker-compose.production.yml up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
echo ""

# Wait for services (max 5 minutes)
TIMEOUT=300
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    POSTGRES_HEALTH=$(docker inspect paws360-postgres-prod --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    REDIS_HEALTH=$(docker inspect paws360-redis-prod --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    BACKEND_HEALTH=$(docker inspect paws360-backend-prod --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    
    echo "   PostgreSQL: ${POSTGRES_HEALTH} | Redis: ${REDIS_HEALTH} | Backend: ${BACKEND_HEALTH}"
    
    if [ "$POSTGRES_HEALTH" = "healthy" ] && [ "$REDIS_HEALTH" = "healthy" ] && [ "$BACKEND_HEALTH" = "healthy" ]; then
        echo ""
        echo "✅ All services are healthy!"
        break
    fi
    
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "⚠️  Timeout waiting for services. Check logs:"
    echo "    docker-compose -f docker-compose.production.yml logs"
    exit 1
fi

echo ""
echo "================================="
echo "✅ Deployment Complete!"
echo "================================="
echo ""
echo "📊 Service Status:"
docker-compose -f docker-compose.production.yml ps
echo ""
echo "🌐 Access Points:"
echo "   • PAWS360 Web:       https://paws360.ryannanney.com"
echo "   • API:               https://paws360.ryannanney.com/api"
echo "   • Traefik Dashboard: http://traefik.paws360.ryannanney.com:8080"
echo ""
echo "🔒 Security:"
echo "   • Credentials stored in: .env.production"
echo "   • SSL certificates in:   ./letsencrypt/"
echo ""
echo "📋 Management Commands:"
echo "   • View logs:    docker-compose -f docker-compose.production.yml logs -f"
echo "   • Stop:         docker-compose -f docker-compose.production.yml down"
echo "   • Restart:      docker-compose -f docker-compose.production.yml restart"
echo "   • Update:       git pull && ./scripts/deploy-production.sh"
echo ""
echo "🔍 Health Checks:"
echo "   • Backend:      curl -k https://paws360.ryannanney.com/api/actuator/health"
echo "   • Database:     docker exec paws360-postgres-prod pg_isready -U paws360_user"
echo "   • Redis:        docker exec paws360-redis-prod redis-cli ping"
echo ""
echo "📝 Note: First HTTPS access may take a moment while Let's Encrypt certificate is provisioned"
echo ""
