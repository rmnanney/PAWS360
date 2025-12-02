#!/bin/bash

# PAWS360 Performance Testing Environment Cleanup
# This script stops all services started for performance testing

set -e

echo "🛑 PAWS360 Performance Testing Environment Cleanup"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="/home/ryan/repos/PAWS360"

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

# Function to stop a service by PID file
stop_service_by_pid() {
    local pid_file=$1
    local service_name=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_status "Stopping $service_name (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 2
            
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "Force stopping $service_name..."
                kill -9 "$pid" 2>/dev/null || true
            fi
            
            print_success "$service_name stopped"
        else
            print_warning "$service_name was already stopped"
        fi
        rm -f "$pid_file"
    else
        print_status "No PID file found for $service_name"
    fi
}

# Function to stop processes by port
stop_by_port() {
    local port=$1
    local service_name=$2
    
    local pids=$(lsof -ti:$port 2>/dev/null || true)
    if [ -n "$pids" ]; then
        print_status "Stopping $service_name processes on port $port..."
        echo "$pids" | xargs kill 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        local remaining_pids=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$remaining_pids" ]; then
            print_warning "Force stopping remaining $service_name processes..."
            echo "$remaining_pids" | xargs kill -9 2>/dev/null || true
        fi
        
        print_success "$service_name processes stopped"
    else
        print_status "No $service_name processes found on port $port"
    fi
}

# Main cleanup function
main() {
    cd "$PROJECT_ROOT"
    
    print_status "Starting cleanup of performance testing environment..."
    
    # Stop backend service
    print_status "Stopping Spring Boot backend..."
    stop_service_by_pid ".backend-perf.pid" "Spring Boot Backend"
    stop_by_port 8081 "Spring Boot Backend"
    
    # Stop frontend service
    print_status "Stopping Next.js frontend..."
    stop_service_by_pid ".frontend-perf.pid" "Next.js Frontend"
    stop_by_port 3000 "Next.js Frontend"
    
    # Stop PostgreSQL container
    print_status "Stopping PostgreSQL container..."
    if docker ps | grep -q "paws360-postgres-perf"; then
        docker stop paws360-postgres-perf || print_warning "Failed to stop PostgreSQL container"
        docker rm paws360-postgres-perf || print_warning "Failed to remove PostgreSQL container"
        print_success "PostgreSQL container stopped and removed"
    else
        print_status "PostgreSQL container was not running"
    fi
    
    # Clean up any remaining Java processes (Spring Boot)
    print_status "Cleaning up any remaining Java processes..."
    pkill -f "spring-boot:run" 2>/dev/null || true
    pkill -f "paws360" 2>/dev/null || true
    
    # Clean up any remaining Node.js processes (Next.js)
    print_status "Cleaning up any remaining Node.js processes..."
    pkill -f "next-server" 2>/dev/null || true
    pkill -f "npm.*dev" 2>/dev/null || true
    
    # Clean up log files if requested
    if [ "$1" = "--clean-logs" ]; then
        print_status "Cleaning up log files..."
        rm -f logs/backend-performance.log
        rm -f logs/frontend-performance.log
        rm -rf tests/performance/results/*
        print_success "Log files cleaned"
    fi
    
    # Remove PID files if they still exist
    rm -f .backend-perf.pid
    rm -f .frontend-perf.pid
    
    print_success "Performance testing environment cleanup complete!"
    
    # Verify cleanup
    print_status "Verifying cleanup..."
    local running_services=()
    
    if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
        running_services+=("Spring Boot (port 8081)")
    fi
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        running_services+=("Next.js (port 3000)")
    fi
    
    if lsof -Pi :5432 -sTCP:LISTEN -t >/dev/null 2>&1; then
        running_services+=("PostgreSQL (port 5432)")
    fi
    
    if [ ${#running_services[@]} -eq 0 ]; then
        print_success "✅ All services successfully stopped"
    else
        print_warning "⚠️  Some services may still be running:"
        for service in "${running_services[@]}"; do
            echo "    - $service"
        done
        print_status "You may need to manually stop these services"
    fi
    
    echo ""
    print_status "Environment is ready for a fresh setup"
    print_status "To restart: ./scripts/setup-perf-env.sh"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [--clean-logs]"
    echo ""
    echo "Options:"
    echo "  --clean-logs    Also remove performance test log files"
    echo "  -h, --help      Show this help message"
    echo ""
    exit 0
fi

# Run main cleanup
main "$@"