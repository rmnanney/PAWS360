#!/bin/bash
set -e

echo "🧪 PAWS360 Local E2E Test Runner"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "ℹ️  $1"
}

# Cleanup function
cleanup() {
    echo ""
    info "Cleaning up..."
    docker compose -f infrastructure/docker/docker-compose.test.yml down -v 2>/dev/null || true
    pkill -f "npm run dev" 2>/dev/null || true
    pkill -f "next dev" 2>/dev/null || true
    rm -f /tmp/next-dev.log /tmp/backend.log
}

# Set trap to cleanup on exit
trap cleanup EXIT

echo ""
info "Step 1: Build backend JAR"
if ! mvn clean package -DskipTests -q; then
    error "Maven build failed"
    exit 1
fi
success "Backend built successfully"

# Copy JAR to services directory (matching CI)
mkdir -p services
cp target/paws360-*.jar services/
success "JAR copied to services/"

echo ""
info "Step 2: Start Docker services (postgres, redis, backend)"
cd infrastructure/docker
if ! docker compose -f docker-compose.test.yml up -d postgres redis app; then
    error "Failed to start Docker services"
    exit 1
fi

echo "Waiting for services to be ready..."
sleep 5
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo ""
info "Step 3: Wait for backend health check"
cd ../..
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -sf http://localhost:8081/actuator/health >/dev/null 2>&1; then
        success "Backend is healthy!"
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        error "Backend health check failed after 60 attempts"
        info "Backend logs:"
        docker logs $(docker ps --format '{{.ID}} {{.Names}}' | grep app | awk '{print $1}') | tail -20
        exit 1
    fi
    echo -n "."
    sleep 1
done

echo ""
info "Step 4: Reset demo account locks"
POSTGRES_CONTAINER=$(docker ps --format '{{.Names}}' | grep postgres || echo "")
if [ -n "$POSTGRES_CONTAINER" ]; then
    info "Found postgres container: $POSTGRES_CONTAINER"
    
    echo "Current users and students in database:"
    docker exec "$POSTGRES_CONTAINER" psql -U postgres -d test_db -c \
        "SELECT u.user_id, u.email, u.role, u.failed_attempts, u.account_locked, s.student_id, s.campus_id FROM users u LEFT JOIN student s ON u.user_id = s.user_id;" \
        || warning "Database query failed"
    
    echo ""
    info "Resetting account locks..."
    docker exec "$POSTGRES_CONTAINER" psql -U postgres -d test_db -c \
        "UPDATE users SET failed_attempts = 0, account_locked = false, account_locked_duration = null WHERE email IN ('demo.student@uwm.edu', 'demo.admin@uwm.edu');" \
        && success "Account reset successful" || warning "Account reset failed"
    
    echo "Account status after reset:"
    docker exec "$POSTGRES_CONTAINER" psql -U postgres -d test_db -c \
        "SELECT email, failed_attempts, account_locked FROM users WHERE email IN ('demo.student@uwm.edu', 'demo.admin@uwm.edu');" \
        || warning "Status check failed"
else
    warning "Postgres container not found - account reset skipped"
    docker ps
fi

echo ""
info "Step 5: Start Next.js frontend"
npm ci --silent
NEXT_PUBLIC_API_BASE_URL=http://localhost:8081 nohup npm run dev > /tmp/next-dev.log 2>&1 &
FRONTEND_PID=$!

echo "Waiting for frontend to be ready..."
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -sf http://localhost:3000 >/dev/null 2>&1; then
        success "Frontend is ready!"
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        error "Frontend failed to start within 60 seconds"
        echo "Frontend logs:"
        tail -20 /tmp/next-dev.log
        exit 1
    fi
    echo -n "."
    sleep 1
done

echo ""
info "Step 6: Test authentication manually"
echo "Testing demo.student@uwm.edu login..."
AUTH_RESPONSE=$(curl -s -X POST http://localhost:8081/auth/login \
    -H "Content-Type: application/json" \
    -H "X-Service-Origin: student-portal" \
    -d '{"email": "demo.student@uwm.edu", "password": "password"}' \
    -w "HTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$AUTH_RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$AUTH_RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$HTTP_STATUS" = "200" ]; then
    success "Demo student authentication successful!"
    echo "Response: $RESPONSE_BODY"
else
    error "Demo student authentication failed (HTTP $HTTP_STATUS)"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
info "Step 7: Run Playwright tests"
cd tests/ui
if npm test; then
    success "All Playwright tests passed!"
    echo ""
    success "🎉 Local E2E tests completed successfully!"
else
    error "Playwright tests failed"
    echo ""
    error "Test results are available in:"
    echo "  - tests/ui/test-results/"
    echo "  - tests/ui/playwright-report/"
    echo ""
    echo "Backend logs: /tmp/backend.log"
    echo "Frontend logs: /tmp/next-dev.log"
    exit 1
fi