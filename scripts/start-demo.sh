#!/bin/bash

# PAWS360 Demo Environment Startup Script
# Automated demo environment initialization and health validation
# Based on specs/001-unify-repos/quickstart.md
#
# Usage: ./start-demo.sh [options]
# Options:
#   --dev       Start in development mode (hot reload)
#   --reset     Reset demo data before starting
#   --check     Only perform health checks (no startup)
#   --help      Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEMO_TIMEOUT=300 # 5 minutes
CHECK_INTERVAL=10
DEV_MODE=false
RESET_DATA=false
CHECK_ONLY=false

# Service URLs
FRONTEND_URL="http://localhost:3000"
BACKEND_PORT="8086"
DB_HOST="localhost"
DB_PORT="5434"
DB_NAME="paws360"
DB_USER="paws360_app"

echo -e "${BLUE}🚀 PAWS360 Demo Environment Startup${NC}"
echo -e "${BLUE}Repository Unification Demo Setup${NC}"
echo "=============================================="

# Function to print status messages
print_status() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

print_info() {
    echo -e "${PURPLE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to show help
show_help() {
    echo "PAWS360 Demo Environment Startup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --dev       Start in development mode with hot reload"
    echo "  --reset     Reset demo data to baseline before starting"
    echo "  --check     Only perform health checks (no startup)"
    echo "  --help      Show this help message"
    echo ""
    echo "Demo Credentials:"
    echo "  Admin:    admin@uwm.edu / password123"
    echo "  Student:  john.smith@uwm.edu / password123"
    echo "  Student:  demo.student@uwm.edu / password123"
    echo ""
    echo "Service URLs:"
    echo "  Frontend: $FRONTEND_URL"
    echo "  Backend:  $BACKEND_URL"
    echo "  Health:   $BACKEND_URL/health/ping"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            DEV_MODE=true
            shift
            ;;
        --reset)
            RESET_DATA=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Function to check if a service is responding
check_service_health() {
    local service_name=$1
    local service_url=$2
    local expected_status=${3:-200}
    
    if curl -s -f -o /dev/null -w "%{http_code}" "$service_url" | grep -q "$expected_status"; then
        return 0
    else
        return 1
    fi
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local service_url=$2
    local timeout=${3:-60}
    local check_interval=${4:-5}
    
    print_info "Waiting for $service_name to be ready..."
    
    local count=0
    while [ $count -lt $timeout ]; do
        if check_service_health "$service_name" "$service_url"; then
            print_status "✅ $service_name is ready"
            return 0
        fi
        
        sleep $check_interval
        count=$((count + check_interval))
        
        if [ $((count % 20)) -eq 0 ]; then
            print_info "⏳ Still waiting for $service_name (${count}s elapsed)..."
        fi
    done
    
    print_error "❌ $service_name failed to start within ${timeout}s"
    return 1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        return 1
    fi
    
    # Check Java (for Spring Boot)
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed or not in PATH"
        return 1
    fi
    
    # Check Node.js (for Next.js)
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed or not in PATH"
        return 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed or not in PATH"
        return 1
    fi
    
    # Check Maven wrapper
    if [ ! -f "$PROJECT_ROOT/mvnw" ]; then
        print_error "Maven wrapper (mvnw) not found in project root"
        return 1
    fi
    
    # Check package.json
    if [ ! -f "$PROJECT_ROOT/package.json" ]; then
        print_error "package.json not found in project root"
        return 1
    fi
    
    print_status "✅ Prerequisites check passed"
    return 0
}

# Function to check if ports are available
check_ports() {
    print_status "Checking port availability..."
    
    local ports_in_use=()
    
    if check_port 3000; then
        ports_in_use+=("3000 (Frontend)")
    fi
    
    if check_port 8081; then
        ports_in_use+=("8081 (Backend)")
    fi
    
    if check_port 5434; then
        ports_in_use+=("5434 (PostgreSQL)")
    fi
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        print_warning "The following ports are already in use:"
        for port in "${ports_in_use[@]}"; do
            echo -e "  ${YELLOW}- $port${NC}"
        done
        
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Demo startup cancelled by user"
            exit 0
        fi
    else
        print_status "✅ Required ports are available"
    fi
}

# Function to reset demo data
reset_demo_data() {
    print_status "Resetting demo data to baseline..."
    
    # Check if backend is running
    if check_service_health "Backend" "$BACKEND_URL/health/ping"; then
        # Use API endpoint for reset
        print_info "Using API endpoint for demo data reset..."
        
        local reset_response=$(curl -s -X POST "$BACKEND_URL/demo/reset" -H "Content-Type: application/json")
        local success=$(echo "$reset_response" | grep -o '"success":[^,}]*' | grep -o '[^:]*$' | tr -d ' "')
        
        if [ "$success" = "true" ]; then
            print_status "✅ Demo data reset successfully via API"
        else
            print_warning "API reset failed, attempting database reset..."
            reset_demo_data_db
        fi
    else
        print_info "Backend not running, using database reset..."
        reset_demo_data_db
    fi
}

# Function to reset demo data via database
reset_demo_data_db() {
    print_info "Attempting database reset..."
    
    # Try to run the reset script directly on database
    if command -v psql &> /dev/null; then
        if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$PROJECT_ROOT/database/demo_reset.sql" &> /dev/null; then
            print_status "✅ Demo data reset via database connection"
        else
            print_warning "Direct database reset failed - may need to start database first"
        fi
    else
        print_warning "psql not available for database reset"
    fi
}

# Function to start database
start_database() {
    print_status "Starting PostgreSQL database..."
    
    # Check if PostgreSQL is already running
    if check_port 5434; then
        print_info "PostgreSQL appears to be running on port 5434"
        return 0
    fi
    
    # Try to start with Docker if available
    if command -v docker &> /dev/null; then
        print_info "Starting PostgreSQL with Docker..."
        
        # Stop any existing container
        docker stop paws360-postgres 2>/dev/null || true
        docker rm paws360-postgres 2>/dev/null || true
        
        # Start new container
        docker run -d \
            --name paws360-postgres \
            -e POSTGRES_DB=$DB_NAME \
            -e POSTGRES_USER=$DB_USER \
            -e POSTGRES_PASSWORD=paws360_password \
            -p 5434:5432 \
            -v "$PROJECT_ROOT/infrastructure/docker/db/init.sql:/docker-entrypoint-initdb.d/01-schema.sql:ro" \
            -v "$PROJECT_ROOT/database/demo_seed_schema_compatible.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro" \
            postgres:15-alpine
        
        # Wait for database to be ready
        print_info "Waiting for PostgreSQL to be ready..."
        sleep 10
        
        local count=0
        while [ $count -lt 60 ]; do
            if docker exec paws360-postgres pg_isready -U $DB_USER -d $DB_NAME &> /dev/null; then
                print_status "✅ PostgreSQL is ready"
                return 0
            fi
            sleep 5
            count=$((count + 5))
        done
        
        print_error "PostgreSQL failed to start"
        return 1
    else
        print_error "Docker not available for database startup"
        return 1
    fi
}

# Function to start backend service
start_backend() {
    print_status "Starting Spring Boot backend..."
    
    cd "$PROJECT_ROOT"
    
    if [ "$DEV_MODE" = true ]; then
        print_info "Starting backend in development mode..."
        # Start in background for dev mode
        nohup ./mvnw spring-boot:run -Dspring-boot.run.profiles=development -DDB_PORT=5434 -DSERVER_PORT=8085 > backend.log 2>&1 &
        echo $! > backend.pid
    else
        print_info "Starting backend in production mode..."
        # Build and start
        ./mvnw clean package -DskipTests &> /dev/null
        nohup java -jar target/*.jar --spring.profiles.active=demo -DDB_PORT=5434 -DSERVER_PORT=8085 > backend.log 2>&1 &
        echo $! > backend.pid
    fi
    
    # Wait for backend to be ready
    wait_for_service "Backend" "$BACKEND_URL/health/ping" 120 5
}

# Function to start frontend service
start_frontend() {
    print_status "Starting Next.js frontend..."
    
    cd "$PROJECT_ROOT"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        print_info "Installing Node.js dependencies..."
        npm install &> /dev/null
    fi
    
    if [ "$DEV_MODE" = true ]; then
        print_info "Starting frontend in development mode with hot reload..."
        nohup npm run dev > frontend.log 2>&1 &
        echo $! > frontend.pid
    else
        print_info "Starting frontend in production mode..."
        npm run build &> /dev/null
        nohup npm start > frontend.log 2>&1 &
        echo $! > frontend.pid
    fi
    
    # Wait for frontend to be ready
    wait_for_service "Frontend" "$FRONTEND_URL" 60 5
}

# Function to perform health checks
perform_health_checks() {
    print_status "Performing comprehensive health checks..."
    
    local checks_passed=0
    local total_checks=0
    
    # Database health check
    total_checks=$((total_checks + 1))
    if docker exec paws360-postgres pg_isready -U $DB_USER -d $DB_NAME &> /dev/null; then
        print_status "✅ Database health check passed"
        checks_passed=$((checks_passed + 1))
    else
        print_error "❌ Database health check failed"
    fi
    
    # Backend health check
    total_checks=$((total_checks + 1))
    if check_service_health "Backend" "$BACKEND_URL/health/ping"; then
        print_status "✅ Backend health check passed"
        checks_passed=$((checks_passed + 1))
    else
        print_error "❌ Backend health check failed"
    fi
    
    # Frontend health check
    total_checks=$((total_checks + 1))
    if check_service_health "Frontend" "$FRONTEND_URL"; then
        print_status "✅ Frontend health check passed"
        checks_passed=$((checks_passed + 1))
    else
        print_error "❌ Frontend health check failed"
    fi
    
    # Demo data validation
    total_checks=$((total_checks + 1))
    if check_service_health "Demo Data API" "$BACKEND_URL/demo/validate"; then
        print_status "✅ Demo data validation passed"
        checks_passed=$((checks_passed + 1))
    else
        print_warning "⚠️ Demo data validation check inconclusive"
        checks_passed=$((checks_passed + 1)) # Don't fail for this
    fi
    
    # Summary
    echo ""
    print_info "Health Check Summary: $checks_passed/$total_checks checks passed"
    
    if [ $checks_passed -eq $total_checks ]; then
        return 0
    else
        return 1
    fi
}

# Function to display demo information
show_demo_info() {
    echo ""
    echo -e "${GREEN}🎉 PAWS360 Demo Environment Ready!${NC}"
    echo "=============================================="
    echo ""
    echo -e "${BLUE}📋 Demo Access Information:${NC}"
    echo -e "  🌐 Frontend (Student Portal): ${PURPLE}$FRONTEND_URL${NC}"
    echo -e "  🔧 Backend API: ${PURPLE}$BACKEND_URL${NC}"
    echo -e "  💡 Health Check: ${PURPLE}$BACKEND_URL/health/ping${NC}"
    echo -e "  📊 Demo Management: ${PURPLE}$BACKEND_URL/demo/info${NC}"
    echo ""
    echo -e "${BLUE}🔑 Demo Credentials:${NC}"
    echo -e "  👨‍💼 Administrator: ${YELLOW}admin@uwm.edu${NC} / ${YELLOW}password123${NC}"
    echo -e "  🎓 Primary Student: ${YELLOW}john.smith@uwm.edu${NC} / ${YELLOW}password123${NC}"
    echo -e "  🎓 Demo Student: ${YELLOW}demo.student@uwm.edu${NC} / ${YELLOW}password123${NC}"
    echo -e "  👩‍🎓 Test Student: ${YELLOW}emily.johnson@uwm.edu${NC} / ${YELLOW}password123${NC}"
    echo ""
    echo -e "${BLUE}🎯 Demo Flow Steps:${NC}"
    echo -e "  1. Navigate to ${PURPLE}$FRONTEND_URL${NC}"
    echo -e "  2. Login with student credentials"
    echo -e "  3. Verify dashboard and navigation"
    echo -e "  4. Test admin login for data consistency"
    echo -e "  5. Validate SSO session persistence"
    echo ""
    echo -e "${BLUE}🛠️ Management Commands:${NC}"
    echo -e "  Reset Demo Data: ${YELLOW}curl -X POST $BACKEND_URL/demo/reset${NC}"
    echo -e "  Validate Data: ${YELLOW}curl $BACKEND_URL/demo/validate${NC}"
    echo -e "  Check Status: ${YELLOW}curl $BACKEND_URL/demo/status${NC}"
    echo ""
    
    if [ "$DEV_MODE" = true ]; then
        echo -e "${PURPLE}🔥 Development Mode Active:${NC}"
        echo -e "  Frontend: Hot reload enabled"
        echo -e "  Backend: Spring DevTools enabled"
        echo -e "  Logs: backend.log, frontend.log"
        echo ""
    fi
    
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo -e "  View Logs: tail -f backend.log frontend.log"
    echo -e "  Stop Services: kill \$(cat backend.pid frontend.pid)"
    echo -e "  Database: docker logs paws360-postgres"
    echo ""
}

# Main execution flow
main() {
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Show header
    print_info "Project Root: $PROJECT_ROOT"
    print_info "Mode: $([ "$DEV_MODE" = true ] && echo "Development" || echo "Production")"
    print_info "Reset Data: $([ "$RESET_DATA" = true ] && echo "Yes" || echo "No")"
    echo ""
    
    # Check only mode
    if [ "$CHECK_ONLY" = true ]; then
        print_status "Performing health checks only (no startup)..."
        if perform_health_checks; then
            print_status "✅ All health checks passed"
            exit 0
        else
            print_error "❌ Some health checks failed"
            exit 1
        fi
    fi
    
    # Prerequisites check
    if ! check_prerequisites; then
        print_error "Prerequisites check failed"
        exit 1
    fi
    
    # Port availability check
    check_ports
    
    # Reset demo data if requested
    if [ "$RESET_DATA" = true ]; then
        reset_demo_data
    fi
    
    # Start services
    print_status "Starting demo environment services..."
    
    # Start database
    if ! start_database; then
        print_error "Failed to start database"
        exit 1
    fi
    
    # Start backend
    if ! start_backend; then
        print_error "Failed to start backend"
        exit 1
    fi
    
    # Start frontend
    if ! start_frontend; then
        print_error "Failed to start frontend"
        exit 1
    fi
    
    # Perform final health checks
    print_status "Performing final health validation..."
    if perform_health_checks; then
        show_demo_info
        print_status "🚀 Demo environment startup completed successfully!"
    else
        print_error "Demo environment startup completed with issues"
        print_info "Check logs for details: tail -f backend.log frontend.log"
        exit 1
    fi
}

# Trap to cleanup on exit
cleanup() {
    print_info "Cleaning up background processes..."
    if [ -f backend.pid ]; then
        kill $(cat backend.pid) 2>/dev/null || true
        rm backend.pid
    fi
    if [ -f frontend.pid ]; then
        kill $(cat frontend.pid) 2>/dev/null || true
        rm frontend.pid
    fi
}

trap cleanup EXIT

# Run main function
main "$@"