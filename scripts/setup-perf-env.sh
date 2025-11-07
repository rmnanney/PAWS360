#!/bin/bash

# PAWS360 Performance Testing Environment Setup
# This script prepares the environment for K6 performance testing

set -e

echo "🚀 PAWS360 Performance Testing Environment Setup"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/home/ryan/repos/PAWS360"
BACKEND_PORT=8081
FRONTEND_PORT=3000
DB_PORT=5432
PERFORMANCE_TEST_DIR="$PROJECT_ROOT/tests/performance"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a port is in use
check_port() {
    local port=$1
    local service=$2
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_success "$service is running on port $port"
        return 0
    else
        print_warning "$service is not running on port $port"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start within timeout"
    return 1
}

# Function to install K6 if not present
install_k6() {
    if command -v k6 &> /dev/null; then
        local k6_version=$(k6 version 2>/dev/null | head -n1 | awk '{print $2}')
        print_success "K6 is already installed (version: $k6_version)"
        return 0
    fi
    
    print_status "Installing K6..."
    
    # Download and install K6
    cd /tmp
    curl -s https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.tar.gz -L | tar xvz --strip-components 1
    
    # Move to a directory in PATH or use local installation
    if [ -w "/usr/local/bin" ]; then
        sudo mv k6 /usr/local/bin/
        print_success "K6 installed to /usr/local/bin/"
    else
        mkdir -p "$HOME/.local/bin"
        mv k6 "$HOME/.local/bin/"
        export PATH="$HOME/.local/bin:$PATH"
        print_success "K6 installed to $HOME/.local/bin/"
        print_warning "Make sure $HOME/.local/bin is in your PATH"
    fi
    
    cd "$PROJECT_ROOT"
}

# Function to setup database
setup_database() {
    print_status "Setting up PostgreSQL database..."
    
    # Check if PostgreSQL is running
    if ! check_port $DB_PORT "PostgreSQL"; then
        print_status "Starting PostgreSQL with Docker..."
        
        # Start PostgreSQL container
        docker run -d \
            --name paws360-postgres-perf \
            -e POSTGRES_DB=paws360 \
            -e POSTGRES_USER=paws360_user \
            -e POSTGRES_PASSWORD=paws360_pass \
            -p $DB_PORT:5432 \
            postgres:15-alpine || print_warning "Database container may already exist"
        
        # Wait for database to be ready
        sleep 10
        if wait_for_service "postgresql://paws360_user:paws360_pass@localhost:$DB_PORT/paws360" "PostgreSQL"; then
            print_success "PostgreSQL is ready"
        else
            print_error "Failed to start PostgreSQL"
            return 1
        fi
    fi
    
    # Run database migrations
    print_status "Running database setup..."
    cd "$PROJECT_ROOT"
    
    if [ -f "db/schema.sql" ]; then
        print_status "Loading database schema..."
        PGPASSWORD=paws360_pass psql -h localhost -p $DB_PORT -U paws360_user -d paws360 -f db/schema.sql || print_warning "Schema loading failed or already applied"
    fi
    
    if [ -f "db/seed.sql" ]; then
        print_status "Loading database seed data..."
        PGPASSWORD=paws360_pass psql -h localhost -p $DB_PORT -U paws360_user -d paws360 -f db/seed.sql || print_warning "Seed data loading failed or already applied"
    fi
}

# Function to start backend service
start_backend() {
    print_status "Starting Spring Boot backend..."
    
    if check_port $BACKEND_PORT "Spring Boot Backend"; then
        print_success "Backend is already running"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Start Spring Boot in background
    print_status "Building and starting Spring Boot application..."
    ./mvnw clean compile spring-boot:run > logs/backend-performance.log 2>&1 &
    BACKEND_PID=$!
    
    # Save PID for cleanup
    echo $BACKEND_PID > .backend-perf.pid
    
    # Wait for backend to be ready
    if wait_for_service "http://localhost:$BACKEND_PORT/api/health" "Spring Boot Backend"; then
        print_success "Backend is ready for performance testing"
    else
        print_error "Backend failed to start"
        return 1
    fi
}

# Function to start frontend service
start_frontend() {
    print_status "Starting Next.js frontend..."
    
    if check_port $FRONTEND_PORT "Next.js Frontend"; then
        print_success "Frontend is already running"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_status "Installing frontend dependencies..."
        npm install
    fi
    
    # Start Next.js in background
    print_status "Starting Next.js development server..."
    npm run dev > logs/frontend-performance.log 2>&1 &
    FRONTEND_PID=$!
    
    # Save PID for cleanup
    echo $FRONTEND_PID > .frontend-perf.pid
    
    # Wait for frontend to be ready
    if wait_for_service "http://localhost:$FRONTEND_PORT" "Next.js Frontend"; then
        print_success "Frontend is ready for performance testing"
    else
        print_error "Frontend failed to start"
        return 1
    fi
}

# Function to validate environment
validate_environment() {
    print_status "Validating performance testing environment..."
    
    local all_good=true
    
    # Check all services
    if ! check_port $DB_PORT "PostgreSQL"; then
        all_good=false
    fi
    
    if ! check_port $BACKEND_PORT "Spring Boot Backend"; then
        all_good=false
    fi
    
    if ! check_port $FRONTEND_PORT "Next.js Frontend"; then
        all_good=false
    fi
    
    # Check K6 installation
    if ! command -v k6 &> /dev/null; then
        print_error "K6 is not installed or not in PATH"
        all_good=false
    fi
    
    # Validate test files
    local test_files=("auth-performance.js" "auth-stress.js" "auth-spike.js" "auth-volume.js")
    
    for test_file in "${test_files[@]}"; do
        if [ ! -f "$PERFORMANCE_TEST_DIR/$test_file" ]; then
            print_error "Performance test file missing: $test_file"
            all_good=false
        fi
    done
    
    if $all_good; then
        print_success "Environment validation passed!"
        return 0
    else
        print_error "Environment validation failed!"
        return 1
    fi
}

# Function to run basic connectivity tests
test_connectivity() {
    print_status "Testing service connectivity..."
    
    # Test backend health endpoint
    if curl -s "http://localhost:$BACKEND_PORT/api/health" | grep -q "UP"; then
        print_success "Backend health check passed"
    else
        print_warning "Backend health check failed"
    fi
    
    # Test frontend accessibility
    if curl -s -I "http://localhost:$FRONTEND_PORT" | grep -q "200 OK"; then
        print_success "Frontend accessibility check passed"
    else
        print_warning "Frontend accessibility check failed"
    fi
    
    # Test database connectivity (basic)
    if PGPASSWORD=paws360_pass psql -h localhost -p $DB_PORT -U paws360_user -d paws360 -c "SELECT 1;" > /dev/null 2>&1; then
        print_success "Database connectivity check passed"
    else
        print_warning "Database connectivity check failed"
    fi
}

# Main execution
main() {
    print_status "Starting PAWS360 Performance Testing Environment Setup"
    
    # Create logs directory
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/tests/performance/results"
    
    # Step 1: Install K6
    install_k6
    
    # Step 2: Setup database
    setup_database
    
    # Step 3: Start backend
    start_backend
    
    # Step 4: Start frontend
    start_frontend
    
    # Step 5: Validate environment
    if validate_environment; then
        print_success "Environment setup complete!"
    else
        print_error "Environment setup failed!"
        exit 1
    fi
    
    # Step 6: Test connectivity
    test_connectivity
    
    echo ""
    print_success "🎯 Performance Testing Environment Ready!"
    print_status "Environment Details:"
    echo "  • PostgreSQL: http://localhost:$DB_PORT"
    echo "  • Spring Boot: http://localhost:$BACKEND_PORT"
    echo "  • Next.js: http://localhost:$FRONTEND_PORT"
    echo ""
    print_status "Available Performance Tests:"
    echo "  • cd tests/performance && npm run test:performance  # Basic performance test"
    echo "  • cd tests/performance && npm run test:load        # Load testing"
    echo "  • cd tests/performance && npm run test:stress      # Stress testing"
    echo "  • cd tests/performance && npm run test:spike       # Spike testing"
    echo "  • cd tests/performance && npm run test:volume      # Volume testing"
    echo "  • cd tests/performance && npm run test:all         # Run all tests"
    echo ""
    print_status "To stop services: ./scripts/stop-perf-env.sh"
    echo ""
}

# Cleanup function
cleanup() {
    print_status "Cleaning up performance testing environment..."
    
    # Stop services if PIDs exist
    if [ -f "$PROJECT_ROOT/.backend-perf.pid" ]; then
        kill $(cat "$PROJECT_ROOT/.backend-perf.pid") 2>/dev/null || true
        rm -f "$PROJECT_ROOT/.backend-perf.pid"
    fi
    
    if [ -f "$PROJECT_ROOT/.frontend-perf.pid" ]; then
        kill $(cat "$PROJECT_ROOT/.frontend-perf.pid") 2>/dev/null || true
        rm -f "$PROJECT_ROOT/.frontend-perf.pid"
    fi
    
    # Stop database container
    docker stop paws360-postgres-perf 2>/dev/null || true
    docker rm paws360-postgres-perf 2>/dev/null || true
}

# Handle script interruption
trap cleanup EXIT

# Check if running in cleanup mode
if [ "$1" = "cleanup" ]; then
    cleanup
    exit 0
fi

# Run main function
main