#!/bin/bash

# T058 E2E Testing Framework - Environment Setup Script
# Constitutional Requirement: Article V (Test-Driven Infrastructure)

set -e

echo "🚀 Setting up PAWS360 E2E Testing Environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if ports are available
check_port() {
    local port=$1
    local service_name=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        print_warning "Port $port is already in use (may be $service_name)"
        return 1
    else
        print_status "Port $port is available"
        return 0
    fi
}

# Kill processes on specific ports
kill_port() {
    local port=$1
    local service_name=$2
    
    echo "Killing processes on port $port ($service_name)..."
    lsof -ti:$port | xargs kill -9 2>/dev/null || echo "No processes found on port $port"
}

# Setup database with test data
setup_database() {
    echo "📊 Setting up test database..."
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Start PostgreSQL via Docker Compose if not running
    cd ../
    if ! docker-compose -f infrastructure/docker/docker-compose.yml ps postgres | grep -q "Up"; then
        echo "Starting PostgreSQL container..."
        docker-compose -f infrastructure/docker/docker-compose.yml up -d postgres
        sleep 5
    fi
    
    print_status "Database is ready"
}

# Start backend service
start_backend() {
    echo "🔧 Starting Spring Boot backend..."
    
    cd ../
    
    # Kill any existing process on port 8081
    kill_port 8081 "Spring Boot"
    
    # Start Spring Boot in test profile
    echo "Starting Spring Boot server on port 8081..."
    ./mvnw spring-boot:run -Dspring-boot.run.profiles=test &
    BACKEND_PID=$!
    
    # Wait for backend to be ready
    echo "Waiting for backend to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8081/actuator/health >/dev/null; then
            print_status "Backend is ready"
            return 0
        fi
        echo "Waiting for backend... ($i/30)"
        sleep 2
    done
    
    print_error "Backend failed to start within 60 seconds"
    exit 1
}

# Start frontend service
start_frontend() {
    echo "⚛️  Starting Next.js frontend..."
    
    cd ../
    
    # Kill any existing process on port 3000
    kill_port 3000 "Next.js"
    
    # Start Next.js development server
    echo "Starting Next.js server on port 3000..."
    npm run dev &
    FRONTEND_PID=$!
    
    # Wait for frontend to be ready
    echo "Waiting for frontend to start..."
    for i in {1..20}; do
        if curl -s http://localhost:3000 >/dev/null; then
            print_status "Frontend is ready"
            return 0
        fi
        echo "Waiting for frontend... ($i/20)"
        sleep 3
    done
    
    print_error "Frontend failed to start within 60 seconds"
    exit 1
}

# Validate environment
validate_environment() {
    echo "🔍 Validating environment..."
    
    # Check backend health
    if curl -s http://localhost:8081/actuator/health | grep -q '"status":"UP"'; then
        print_status "Backend health check passed"
    else
        print_error "Backend health check failed"
        exit 1
    fi
    
    # Check frontend accessibility
    if curl -s http://localhost:3000 >/dev/null; then
        print_status "Frontend accessibility check passed"
    else
        print_error "Frontend accessibility check failed"
        exit 1
    fi
    
    # Verify test user exists
    if curl -s -X POST http://localhost:8081/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"demo.student@uwm.edu","password":"password"}' | grep -q "Login Successful"; then
        print_status "Test user authentication verified"
    else
        print_warning "Test user authentication check failed (may need database seeding)"
    fi
}

# Main execution
main() {
    echo "🎯 PAWS360 E2E Test Environment Setup"
    echo "======================================"
    
    # Store process IDs for cleanup
    export E2E_BACKEND_PID=""
    export E2E_FRONTEND_PID=""
    
    # Setup database
    setup_database
    
    # Start services
    start_backend
    E2E_BACKEND_PID=$BACKEND_PID
    
    start_frontend
    E2E_FRONTEND_PID=$FRONTEND_PID
    
    # Validate environment
    validate_environment
    
    echo ""
    echo "🎉 Environment is ready for E2E testing!"
    echo "======================================"
    echo "Backend:  http://localhost:8081"
    echo "Frontend: http://localhost:3000"
    echo ""
    echo "To run E2E tests:"
    echo "  npm run test:e2e"
    echo "  npm run test:e2e:headed    # With browser UI"
    echo "  npm run test:e2e:debug     # Debug mode"
    echo ""
    echo "To run specific SSO tests:"
    echo "  cd tests/ui && npm run test:sso"
    echo ""
    echo "To stop services:"
    echo "  ./stop-e2e-env.sh"
    echo ""
    
    # Save PIDs for cleanup script
    echo "export E2E_BACKEND_PID=$E2E_BACKEND_PID" > .e2e-env-pids
    echo "export E2E_FRONTEND_PID=$E2E_FRONTEND_PID" >> .e2e-env-pids
}

# Handle interruption
cleanup() {
    echo ""
    print_warning "Setup interrupted. Cleaning up..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    exit 1
}

trap cleanup INT TERM

# Check if this script should stop running services instead
if [ "$1" = "stop" ]; then
    echo "🛑 Stopping E2E test environment..."
    kill_port 8081 "Spring Boot"
    kill_port 3000 "Next.js"
    if [ -f .e2e-env-pids ]; then
        source .e2e-env-pids
        kill $E2E_BACKEND_PID 2>/dev/null || true
        kill $E2E_FRONTEND_PID 2>/dev/null || true
        rm .e2e-env-pids
    fi
    print_status "Environment stopped"
    exit 0
fi

# Run main setup
main