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

echo "\nℹ️  Step 2b: Ensure DB schema is present (apply init.sql if needed)"
POSTGRES_CONTAINER=$(docker ps --format '{{.Names}}' | grep postgres || echo "")
if [ -n "$POSTGRES_CONTAINER" ]; then
    info "Checking DB schema in container: $POSTGRES_CONTAINER"
    # Query for the users table existence; to_regclass returns NULL when absent
    HAS_USERS=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d test_db -At -c "SELECT to_regclass('public.users');" || echo "")
    if [ -z "$HAS_USERS" ]; then
        info "users table missing, applying init.sql to populate schema and seed data"
        if docker exec "$POSTGRES_CONTAINER" psql -U postgres -d test_db -f /docker-entrypoint-initdb.d/init.sql; then
            success "Applied init.sql successfully"
        else
            warning "Applying init.sql failed (non-fatal)"
        fi
    else
        info "DB schema already present, no action needed"
    fi
else
    warning "Postgres container not found - skipping DB init check"
fi

echo ""
info "Step 3: Wait for backend health check"
cd ../..
max_attempts=60
attempt=0
BACKEND_PORT=${TEST_APP_PORT:-8081}
export BACKEND_URL="http://localhost:${BACKEND_PORT}"
while [ $attempt -lt $max_attempts ]; do
    if curl -sf http://localhost:$BACKEND_PORT/actuator/health >/dev/null 2>&1; then
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
NEXT_PUBLIC_API_BASE_URL=http://localhost:$BACKEND_PORT nohup npm run dev -- -p 3000 --hostname 0.0.0.0 > /tmp/next-dev.log 2>&1 &
export BASE_URL="http://localhost:3000"
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
AUTH_RESPONSE=$(curl -s -X POST http://localhost:$BACKEND_PORT/auth/login \
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
    info "Step 6b: Create Playwright storageStates from backend auth responses"
    # Create storageStates for Playwright (admin and student) so pre-auth tests work reliably
    mkdir -p tests/ui/storageStates
    create_state() {
        local email=$1
        local password=$2
        local key=$3
        local resp
        local bodyResp
        resp=$(curl -i -s -X POST http://localhost:$BACKEND_PORT/auth/login \
            -H "Content-Type: application/json" -H "X-Service-Origin: student-portal" \
            -d "{\"email\": \"$email\", \"password\": \"$password\"}")
        # Also capture the raw JSON body so we can extract any session_token payload the API
        # returns (the frontend stores tokens in localStorage under `authToken`)
        bodyResp=$(curl -s -X POST http://localhost:$BACKEND_PORT/auth/login \
            -H "Content-Type: application/json" -H "X-Service-Origin: student-portal" \
            -d "{\"email\": \"$email\", \"password\": \"$password\"}")
        # Try fallback to /login
        if ! echo "$resp" | grep -qi "Set-Cookie"; then
            resp=$(curl -i -s -X POST http://localhost:$BACKEND_PORT/login \
                -H "Content-Type: application/json" -H "X-Service-Origin: student-portal" \
                -d "{\"email\": \"$email\", \"password\": \"$password\"}")
        fi
        cookie=$(echo "$resp" | grep -i "Set-Cookie" | grep PAWS360_SESSION | head -n1 | sed -E 's/Set-Cookie: *PAWS360_SESSION=([^;]+).*/\1/Ig')
        # If the backend returned a session cookie, use it. Otherwise if the response body
        # contains a session_token, store that token in localStorage (authToken) so the
        # frontend will consider this state authenticated.
        token=$(echo "$bodyResp" | sed -nE 's/.*"session_token"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')
        if [ -n "$cookie" ]; then
            cat > tests/ui/storageStates/${key}.json <<JSON
            {
                "cookies": [
                    {
                        "name": "PAWS360_SESSION",
                        "value": "$cookie",
                        "domain": "localhost",
                        "path": "/",
                        "expires": -1,
                        "httpOnly": true,
                        "secure": false,
                        "sameSite": "Lax"
                    }
                ],
                "origins": []
            }
JSON
            success "Created storageStates/${key}.json"
        elif [ -n "$token" ]; then
            cat > tests/ui/storageStates/${key}.json <<JSON
{
    "cookies": [],
    "origins": [
        {
            "origin": "http://localhost:3000",
            "localStorage": [
                { "name": "authToken", "value": "$token" }
            ]
        }
    ]
}
JSON
            success "Created storageStates/${key}.json (authToken via session_token)"
        else
            warning "Failed to create storageStates/${key}.json - no Set-Cookie found"
        fi
                # When both cookie and token exist, prefer storing both so Playwright tests
                # that look for either mechanism will succeed.
                if [ -n "$cookie" ] && [ -n "$token" ]; then
                        cat > tests/ui/storageStates/${key}.json <<JSON
{
    "cookies": [
        {
            "name": "PAWS360_SESSION",
            "value": "$cookie",
            "domain": "localhost",
            "path": "/",
            "expires": -1,
            "httpOnly": true,
            "secure": false,
            "sameSite": "Lax"
        }
    ],
    "origins": [
        {
            "origin": "http://localhost:3000",
            "localStorage": [ { "name": "authToken", "value": "$token" } ]
        },
        {
            "origin": "http://127.0.0.1:3000",
            "localStorage": [ { "name": "authToken", "value": "$token" } ]
        }
    ]
}
JSON
                        success "Created storageStates/${key}.json (cookie+token)"
                fi
    }

    # Generate storage states for demo accounts
    create_state "demo.student@uwm.edu" "password" "student"
    create_state "demo.admin@uwm.edu" "password" "admin"

echo ""
info "Step 7: Run Playwright tests"
cd tests/ui
echo "Using BACKEND_URL=$BACKEND_URL and BASE_URL=$BASE_URL for Playwright"
# Tell Playwright we're running against externally-managed servers (skip webServer tasks)
# Also signal that this local pipeline has pre-created SSO storageStates and
# we want global-setup to use them (do not enable the SSO retirement placeholder)
export RETIRE_SSO=false
export PW_EXTERNAL_SERVERS=1
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