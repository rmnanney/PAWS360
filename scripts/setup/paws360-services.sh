#!/bin/bash

# PAWS360 AdminLTE Services Management Script
# Manages all services: Auth, Data, Analytics, and UI

set -euo pipefail

# Configuration
PROJECT_ROOT="/home/ryan/repos/PAWS360ProjectPlan"
MOCK_SERVICES_DIR="$PROJECT_ROOT/mock-services"
ADMIN_UI_DIR="$PROJECT_ROOT/admin-ui"
LOG_DIR="$PROJECT_ROOT/logs"

# Service configuration
declare -A SERVICES=(
    ["auth"]="8081"
    ["data"]="8082" 
    ["analytics"]="8083"
    ["ui"]="8080"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Create log directory
mkdir -p "$LOG_DIR"

# Check if service is running
is_service_running() {
    local service=$1
    local port=${SERVICES[$service]}
    
    if [[ "$service" == "ui" ]]; then
        pgrep -f "python3 -m http.server $port" > /dev/null 2>&1
    else
        pgrep -f "node ${service}-service.js" > /dev/null 2>&1
    fi
}

# Get service PID
get_service_pid() {
    local service=$1
    local port=${SERVICES[$service]}
    
    if [[ "$service" == "ui" ]]; then
        pgrep -f "python3 -m http.server $port" 2>/dev/null || echo ""
    else
        pgrep -f "node ${service}-service.js" 2>/dev/null || echo ""
    fi
}

# Health check for service
health_check() {
    local service=$1
    local port=${SERVICES[$service]}
    local max_attempts=10
    local attempt=1
    
    log "Health checking $service service on port $port..."
    
    while [[ $attempt -le $max_attempts ]]; do
        if [[ "$service" == "ui" ]]; then
            if curl -s -f "http://localhost:$port/" > /dev/null 2>&1; then
                success "$service service is healthy (attempt $attempt/$max_attempts)"
                return 0
            fi
        else
            if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
                success "$service service is healthy (attempt $attempt/$max_attempts)"
                return 0
            fi
        fi
        
        warn "$service service not ready, waiting... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    error "$service service failed health check after $max_attempts attempts"
    return 1
}

# Start individual service
start_service() {
    local service=$1
    local port=${SERVICES[$service]}
    
    if is_service_running "$service"; then
        warn "$service service is already running on port $port"
        return 0
    fi
    
    log "Starting $service service on port $port..."
    
    case $service in
        "auth"|"data"|"analytics")
            cd "$MOCK_SERVICES_DIR"
            nohup node "${service}-service.js" > "$LOG_DIR/${service}-service.log" 2>&1 &
            echo $! > "$LOG_DIR/${service}-service.pid"
            ;;
        "ui")
            cd "$ADMIN_UI_DIR"
            nohup python3 -m http.server $port > "$LOG_DIR/ui-service.log" 2>&1 &
            echo $! > "$LOG_DIR/ui-service.pid"
            ;;
        *)
            error "Unknown service: $service"
            return 1
            ;;
    esac
    
    # Wait a moment for service to start
    sleep 3
    
    if health_check "$service"; then
        success "$service service started successfully on port $port"
        return 0
    else
        error "Failed to start $service service"
        return 1
    fi
}

# Stop individual service
stop_service() {
    local service=$1
    local port=${SERVICES[$service]}
    
    log "Stopping $service service..."
    
    local pid
    pid=$(get_service_pid "$service")
    
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            warn "Service $service didn't stop gracefully, force killing..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        
        # Clean up PID file
        rm -f "$LOG_DIR/${service}-service.pid"
        success "$service service stopped"
    else
        warn "$service service was not running"
    fi
}

# Start all services
start_all() {
    log "🚀 Starting all PAWS360 AdminLTE services..."
    
    # Check dependencies
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        error "Python3 is not installed"
        exit 1
    fi
    
    # Install npm dependencies if needed
    if [[ ! -d "$MOCK_SERVICES_DIR/node_modules" ]]; then
        log "Installing Node.js dependencies..."
        cd "$MOCK_SERVICES_DIR"
        npm install
    fi
    
    # Start services in order
    local failed_services=()
    
    for service in auth data analytics ui; do
        if ! start_service "$service"; then
            failed_services+=("$service")
        fi
    done
    
    if [[ ${#failed_services[@]} -eq 0 ]]; then
        success "🎉 All services started successfully!"
        show_status
    else
        error "❌ Some services failed to start: ${failed_services[*]}"
        return 1
    fi
}

# Stop all services
stop_all() {
    log "🛑 Stopping all PAWS360 AdminLTE services..."
    
    for service in ui analytics data auth; do
        stop_service "$service"
    done
    
    success "🎉 All services stopped"
}

# Restart all services
restart_all() {
    log "🔄 Restarting all PAWS360 AdminLTE services..."
    stop_all
    sleep 2
    start_all
}

# Show service status
show_status() {
    echo
    log "📊 PAWS360 AdminLTE Service Status:"
    echo "============================================"
    
    for service in auth data analytics ui; do
        local port=${SERVICES[$service]}
        local status
        local health_status=""
        
        if is_service_running "$service"; then
            status="${GREEN}RUNNING${NC}"
            
            # Quick health check
            if [[ "$service" == "ui" ]]; then
                if curl -s -f "http://localhost:$port/" > /dev/null 2>&1; then
                    health_status="${GREEN}HEALTHY${NC}"
                else
                    health_status="${RED}UNHEALTHY${NC}"
                fi
            else
                if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
                    health_status="${GREEN}HEALTHY${NC}"
                else
                    health_status="${RED}UNHEALTHY${NC}"
                fi
            fi
        else
            status="${RED}STOPPED${NC}"
            health_status="${RED}N/A${NC}"
        fi
        
        printf "🔹 %-12s (:%s) %s %s\n" "${service^^}" "$port" "$status" "$health_status"
    done
    
    echo "============================================"
    echo
    log "🌐 Access URLs:"
    echo "   AdminLTE Dashboard: http://localhost:8080"
    echo "   AdminLTE (themes):  http://localhost:8080/themes/v4/"
    echo "   Auth Service:       http://localhost:8081"
    echo "   Data Service:       http://localhost:8082"
    echo "   Analytics Service:  http://localhost:8083"
    echo
}

# Test all endpoints
test_endpoints() {
    log "🧪 Testing all service endpoints..."
    
    local failed_tests=()
    
    # Test Auth Service
    echo -n "🔐 Auth Service (8081): "
    if curl -s -f "http://localhost:8081/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        failed_tests+=("auth")
    fi
    
    # Test Data Service
    echo -n "📊 Data Service (8082): "
    if curl -s -f "http://localhost:8082/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        failed_tests+=("data")
    fi
    
    # Test Analytics Service  
    echo -n "📈 Analytics Service (8083): "
    if curl -s -f "http://localhost:8083/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        failed_tests+=("analytics")
    fi
    
    # Test UI Service
    echo -n "🎨 AdminLTE UI (8080): "
    if curl -s -f "http://localhost:8080/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        failed_tests+=("ui")
    fi
    
    # Test themes path
    echo -n "🎨 AdminLTE Themes (8080/themes/v4/): "
    if curl -s -f "http://localhost:8080/themes/v4/" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        failed_tests+=("themes")
    fi
    
    echo
    if [[ ${#failed_tests[@]} -eq 0 ]]; then
        success "🎉 All endpoints are responding correctly!"
    else
        error "❌ Some endpoints failed: ${failed_tests[*]}"
        return 1
    fi
}

# Show logs for a service
show_logs() {
    local service=$1
    local lines=${2:-50}
    
    if [[ -f "$LOG_DIR/${service}-service.log" ]]; then
        log "📄 Last $lines lines of $service service logs:"
        echo "============================================"
        tail -n "$lines" "$LOG_DIR/${service}-service.log"
        echo "============================================"
    else
        warn "No log file found for $service service"
    fi
}

# Main command handling
case "${1:-help}" in
    "start")
        if [[ -n "${2:-}" ]]; then
            start_service "$2"
        else
            start_all
        fi
        ;;
    "stop")
        if [[ -n "${2:-}" ]]; then
            stop_service "$2"
        else
            stop_all
        fi
        ;;
    "restart")
        if [[ -n "${2:-}" ]]; then
            stop_service "$2"
            sleep 2
            start_service "$2"
        else
            restart_all
        fi
        ;;
    "status")
        show_status
        ;;
    "test")
        test_endpoints
        ;;
    "logs")
        if [[ -n "${2:-}" ]]; then
            show_logs "$2" "${3:-50}"
        else
            error "Please specify a service: auth, data, analytics, or ui"
            exit 1
        fi
        ;;
    "help"|"--help"|"-h")
        echo "PAWS360 AdminLTE Services Management Script"
        echo ""
        echo "Usage: $0 <command> [service] [options]"
        echo ""
        echo "Commands:"
        echo "  start [service]     Start all services or specific service"
        echo "  stop [service]      Stop all services or specific service"  
        echo "  restart [service]   Restart all services or specific service"
        echo "  status              Show status of all services"
        echo "  test                Test all service endpoints"
        echo "  logs <service> [n]  Show last n lines of service logs (default: 50)"
        echo "  help                Show this help message"
        echo ""
        echo "Services: auth, data, analytics, ui"
        echo ""
        echo "Examples:"
        echo "  $0 start            # Start all services"
        echo "  $0 start auth       # Start only auth service"
        echo "  $0 stop             # Stop all services"
        echo "  $0 restart ui       # Restart only UI service"
        echo "  $0 status           # Show service status"
        echo "  $0 test             # Test all endpoints"
        echo "  $0 logs auth 100    # Show last 100 lines of auth logs"
        ;;
    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac