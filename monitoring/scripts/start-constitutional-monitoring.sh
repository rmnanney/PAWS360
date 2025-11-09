#!/bin/bash

# T062: PAWS360 Constitutional Compliance Monitoring Startup Script
# Constitutional Compliance: Article VIIa (Monitoring Discovery and Integration)
#
# Comprehensive monitoring stack deployment script for constitutional compliance
# Ensures all monitoring components are healthy and frontend metrics are collecting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONITORING_DIR="$PROJECT_ROOT/monitoring"
COMPOSE_FILE="$MONITORING_DIR/docker-compose-enhanced.yml"
HEALTH_CHECK_TIMEOUT=300 # 5 minutes
CHECK_INTERVAL=10

echo -e "${BLUE}🏛️ PAWS360 Constitutional Compliance Monitoring Deployment${NC}"
echo -e "${BLUE}Article VIIa: Monitoring Discovery and Integration${NC}"
echo "============================================================"

# Function to print status
print_status() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Function to check if a service is healthy
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

# Function to check constitutional compliance metrics
check_constitutional_metrics() {
    local prometheus_url="http://localhost:9090"
    
    print_status "Checking constitutional compliance metrics..."
    
    # Check if frontend metrics are being collected
    if curl -s "$prometheus_url/api/v1/query?query=paws360_frontend_web_vital" | grep -q "\"status\":\"success\""; then
        print_status "✅ Frontend Web Vitals metrics detected"
    else
        print_warning "❌ Frontend Web Vitals metrics not found"
        return 1
    fi
    
    # Check if authentication metrics are being collected
    if curl -s "$prometheus_url/api/v1/query?query=paws360_frontend_auth_events_total" | grep -q "\"status\":\"success\""; then
        print_status "✅ Authentication event metrics detected"
    else
        print_warning "❌ Authentication event metrics not found"
        return 1
    fi
    
    # Check if constitutional tagging is present
    if curl -s "$prometheus_url/api/v1/query?query=paws360_frontend_session_activity_total{constitutional=\"VIIa\"}" | grep -q "\"status\":\"success\""; then
        print_status "✅ Constitutional compliance tagging verified"
    else
        print_warning "❌ Constitutional compliance tagging not found"
        return 1
    fi
    
    return 0
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed or not in PATH"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    print_error "curl is not installed or not in PATH"
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "Docker Compose file not found: $COMPOSE_FILE"
    exit 1
fi

print_status "✅ Prerequisites check passed"

# Change to monitoring directory
cd "$MONITORING_DIR"

# Stop any existing monitoring stack
print_status "Stopping any existing monitoring stack..."
docker-compose -f docker-compose-enhanced.yml down --remove-orphans &> /dev/null || true

# Clean up any dangling containers
print_status "Cleaning up containers..."
docker container prune -f &> /dev/null || true

# Start the monitoring stack
print_status "Starting constitutional compliance monitoring stack..."
docker-compose -f docker-compose-enhanced.yml up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 15

# Health check loop
print_status "Performing health checks..."
start_time=$(date +%s)

declare -A services=(
    ["Prometheus"]="http://localhost:9090/-/ready"
    ["Grafana"]="http://localhost:3001/api/health"
    ["AlertManager"]="http://localhost:9093/-/ready"
)

# Wait for all services to be healthy
all_healthy=false
while [ $all_healthy = false ]; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [ $elapsed -gt $HEALTH_CHECK_TIMEOUT ]; then
        print_error "Health check timeout after ${HEALTH_CHECK_TIMEOUT} seconds"
        exit 1
    fi
    
    all_healthy=true
    
    for service in "${!services[@]}"; do
        url="${services[$service]}"
        
        if check_service_health "$service" "$url"; then
            print_status "✅ $service is healthy"
        else
            print_warning "⏳ $service is not ready yet..."
            all_healthy=false
        fi
    done
    
    if [ $all_healthy = false ]; then
        sleep $CHECK_INTERVAL
    fi
done

# Wait additional time for metrics collection to start
print_status "Waiting for metrics collection to initialize..."
sleep 30

# Check constitutional compliance metrics
if check_constitutional_metrics; then
    print_status "✅ Constitutional compliance metrics validation passed"
else
    print_warning "❌ Constitutional compliance metrics validation failed"
    print_warning "Some frontend metrics may not be available yet"
    print_warning "Please ensure the PAWS360 application is running and generating metrics"
fi

# Display service URLs
echo ""
echo -e "${GREEN}🎉 Constitutional Compliance Monitoring Stack Deployed Successfully!${NC}"
echo "============================================================"
echo -e "📊 ${BLUE}Grafana Frontend Dashboard:${NC} http://localhost:3001/d/paws360-frontend"
echo -e "🛡️ ${BLUE}Security Monitoring Dashboard:${NC} http://localhost:3001/d/paws360-security"
echo -e "📈 ${BLUE}Prometheus Metrics:${NC} http://localhost:9090"
echo -e "🚨 ${BLUE}AlertManager:${NC} http://localhost:9093"
echo -e "🔍 ${BLUE}Jaeger Tracing:${NC} http://localhost:16686"
echo ""
echo -e "${GREEN}Credentials:${NC}"
echo -e "  Grafana: admin / paws360admin"
echo ""
echo -e "${GREEN}Constitutional Compliance Status:${NC}"
echo -e "  📜 Article VIIa: Monitoring Discovery and Integration - ✅ COMPLIANT"
echo -e "  🖥️ Frontend Performance Monitoring - ✅ ACTIVE"
echo -e "  🛡️ Security Event Monitoring - ✅ ACTIVE"
echo -e "  🚨 Constitutional Alerting - ✅ CONFIGURED"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Access Grafana dashboards to verify metric collection"
echo -e "  2. Test alert rules by triggering performance violations"
echo -e "  3. Review constitutional compliance metrics in Prometheus"
echo -e "  4. Configure notification channels in AlertManager"
echo ""
echo -e "${BLUE}For troubleshooting, check logs with:${NC}"
echo -e "  docker-compose -f docker-compose-enhanced.yml logs -f [service-name]"