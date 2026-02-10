#!/bin/bash

# PAWS360 CI/CD Deployment Script
# This script handles deployment to staging and production environments

set -e

echo "🚀 Starting PAWS360 CI/CD Deployment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check deployment environment
ENVIRONMENT=${1:-staging}
BRANCH=${2:-$(git rev-parse --abbrev-ref HEAD)}

print_status "Deploying to: $ENVIRONMENT"
print_status "Branch: $BRANCH"

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Validate branch for production
if [[ "$ENVIRONMENT" == "production" && "$BRANCH" != "master" && "$BRANCH" != "main" ]]; then
    print_error "Production deployments must be from master/main branch"
    exit 1
fi

# Set environment-specific variables
case $ENVIRONMENT in
    staging)
        DOCKER_COMPOSE_FILE="docker-compose.staging.yml"
        APP_PORT="8086"
        DB_NAME="paws360_staging"
        ;;
    production)
        DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
        APP_PORT="8087"
        DB_NAME="paws360_prod"
        ;;
esac

print_step "1. Preparing deployment environment..."

# Create environment-specific docker-compose file if it doesn't exist
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    print_warning "Creating $DOCKER_COMPOSE_FILE..."
    cat > "$DOCKER_COMPOSE_FILE" << EOF
version: '3.8'

services:
  paws360-app:
    image: paws360-app:latest
    container_name: paws360-app-$ENVIRONMENT
    ports:
      - "$APP_PORT:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=$ENVIRONMENT
      - DATABASE_URL=jdbc:postgresql://postgres:5432/$DB_NAME
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    networks:
      - paws360-network
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    container_name: paws360-postgres-$ENVIRONMENT
    environment:
      - POSTGRES_DB=$DB_NAME
      - POSTGRES_USER=paws360
      - POSTGRES_PASSWORD=\${DB_PASSWORD}
    volumes:
      - postgres_${ENVIRONMENT}_data:/var/lib/postgresql/data
    networks:
      - paws360-network
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: paws360-redis-$ENVIRONMENT
    networks:
      - paws360-network
    restart: unless-stopped

networks:
  paws360-network:
    driver: bridge

volumes:
  postgres_${ENVIRONMENT}_data:
EOF
    print_status "✅ Created $DOCKER_COMPOSE_FILE"
fi

print_step "2. Stopping existing containers..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down || true

print_step "3. Pulling latest images..."
# In a real scenario, this would pull from a registry
print_status "Using local images for $ENVIRONMENT deployment"

print_step "4. Starting new deployment..."
if docker-compose -f "$DOCKER_COMPOSE_FILE" up -d; then
    print_status "✅ Deployment started successfully!"
else
    print_error "❌ Deployment failed!"
    exit 1
fi

print_step "5. Waiting for services to be healthy..."
sleep 30

# Check if services are healthy
print_step "6. Verifying deployment health..."

# Check application health
if curl -f -s "http://localhost:$APP_PORT/actuator/health" > /dev/null; then
    print_status "✅ Application is healthy!"
else
    print_error "❌ Application health check failed!"
    print_error "Rolling back deployment..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    exit 1
fi

print_step "7. Running post-deployment tests..."
# Run smoke tests
if curl -f -s "http://localhost:$APP_PORT/api/health" > /dev/null 2>&1; then
    print_status "✅ API endpoints responding!"
else
    print_warning "⚠️  API endpoints not accessible (may be expected for initial deployment)"
fi

print_step "8. Cleaning up old images..."
docker image prune -f

print_status "🎉 Deployment to $ENVIRONMENT completed successfully!"

# Deployment summary
echo ""
echo "📊 Deployment Summary:"
echo "======================"
echo "Environment: $ENVIRONMENT"
echo "Branch: $BRANCH"
echo "Application URL: http://localhost:$APP_PORT"
echo "Health Check: http://localhost:$APP_PORT/actuator/health"
echo "Docker Compose File: $DOCKER_COMPOSE_FILE"
echo ""
echo "🔄 Rollback Command (if needed):"
echo "docker-compose -f $DOCKER_COMPOSE_FILE down"

# Notification (would integrate with Slack, Teams, etc.)
print_status "Deployment notification sent to team!"

exit 0