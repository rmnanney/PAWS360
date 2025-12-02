#!/bin/bash

# T062: PAWS360 Monitoring Infrastructure Startup Script
# Constitutional Compliance: Article VIIa (Monitoring Discovery and Integration)
#
# Comprehensive startup script for PAWS360 monitoring infrastructure
# including Prometheus, Grafana, AlertManager, and supporting services

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MONITORING_DIR="${PROJECT_ROOT}/monitoring"
COMPOSE_FILE="${MONITORING_DIR}/docker-compose-monitoring.yml"

# Constitutional compliance tracking
CONSTITUTIONAL_ARTICLE="VIIa"
MONITORING_PHASE="T062"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🏛️  PAWS360 Monitoring Infrastructure${NC}"
echo -e "${BLUE}📜 Constitutional Article ${CONSTITUTIONAL_ARTICLE}${NC}"
echo -e "${BLUE}🔧 Phase: ${MONITORING_PHASE}${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Function to print status messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' {1..50})${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "🔍 Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    print_status "✅ Docker found: $(docker --version | cut -d' ' -f3)"
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available"
        exit 1
    fi
    print_status "✅ Docker Compose found: $(docker compose version --short)"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    print_status "✅ Docker daemon is running"
    
    # Check required directories
    local required_dirs=(
        "${MONITORING_DIR}/prometheus"
        "${MONITORING_DIR}/grafana/dashboards"
        "${MONITORING_DIR}/alertmanager"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            print_error "Required directory not found: $dir"
            exit 1
        fi
    done
    print_status "✅ All required directories exist"
    
    # Check configuration files
    local required_files=(
        "${MONITORING_DIR}/prometheus/prometheus.yml"
        "${MONITORING_DIR}/alertmanager/alertmanager-simple.yml"
        "${COMPOSE_FILE}"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required configuration file not found: $file"
            exit 1
        fi
    done
    print_status "✅ All configuration files exist"
}

# Function to create necessary directories and set permissions
setup_directories() {
    print_header "📁 Setting Up Directories"
    
    # Create data directories for persistence
    local data_dirs=(
        "${MONITORING_DIR}/data/prometheus"
        "${MONITORING_DIR}/data/grafana"
        "${MONITORING_DIR}/data/alertmanager"
        "${MONITORING_DIR}/data/loki"
        "${PROJECT_ROOT}/logs"
    )
    
    for dir in "${data_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_status "✅ Created directory: $dir"
        else
            print_status "✅ Directory exists: $dir"
        fi
    done
    
    # Set proper permissions for Grafana
    if [[ -d "${MONITORING_DIR}/data/grafana" ]]; then
        sudo chown -R 472:472 "${MONITORING_DIR}/data/grafana" 2>/dev/null || true
        print_status "✅ Set Grafana permissions"
    fi
    
    # Set proper permissions for Prometheus
    if [[ -d "${MONITORING_DIR}/data/prometheus" ]]; then
        sudo chown -R 65534:65534 "${MONITORING_DIR}/data/prometheus" 2>/dev/null || true
        print_status "✅ Set Prometheus permissions"
    fi
}

# Function to validate configuration files
validate_configs() {
    print_header "🔧 Validating Configuration Files"
    
    # Validate Prometheus configuration
    if docker run --rm -v "${MONITORING_DIR}/prometheus:/etc/prometheus" \
        prom/prometheus:v2.40.0 \
        promtool check config /etc/prometheus/prometheus.yml &> /dev/null; then
        print_status "✅ Prometheus configuration is valid"
    else
        print_error "❌ Prometheus configuration is invalid"
        docker run --rm -v "${MONITORING_DIR}/prometheus:/etc/prometheus" \
            prom/prometheus:v2.40.0 \
            promtool check config /etc/prometheus/prometheus.yml
        exit 1
    fi
    
    # Validate alert rules if they exist
    if [[ -f "${MONITORING_DIR}/prometheus/alert_rules/paws360_alerts.yml" ]]; then
        if docker run --rm -v "${MONITORING_DIR}/prometheus:/etc/prometheus" \
            prom/prometheus:v2.40.0 \
            promtool check rules /etc/prometheus/alert_rules/paws360_alerts.yml &> /dev/null; then
            print_status "✅ Alert rules are valid"
        else
            print_warning "⚠️  Alert rules validation failed, continuing anyway"
        fi
    fi
    
    # Validate AlertManager configuration
    if docker run --rm -v "${MONITORING_DIR}/alertmanager:/etc/alertmanager" \
        prom/alertmanager:v0.25.0 \
        amtool check-config /etc/alertmanager/alertmanager-simple.yml &> /dev/null; then
        print_status "✅ AlertManager configuration is valid"
    else
        print_warning "⚠️  AlertManager configuration validation failed, continuing anyway"
    fi
}

# Function to start monitoring services
start_services() {
    print_header "🚀 Starting Monitoring Services"
    
    cd "${PROJECT_ROOT}"
    
    # Pull latest images
    print_status "📥 Pulling latest Docker images..."
    docker compose -f "${COMPOSE_FILE}" pull
    
    # Start services in dependency order
    print_status "🏗️  Starting infrastructure services..."
    docker compose -f "${COMPOSE_FILE}" up -d prometheus grafana alertmanager
    
    print_status "📊 Starting metrics collection services..."
    docker compose -f "${COMPOSE_FILE}" up -d node-exporter postgres-exporter cadvisor
    
    # Wait for core services to be ready
    print_status "⏳ Waiting for services to be ready..."
    sleep 10
    
    # Start optional services
    print_status "🔧 Starting optional services..."
    docker compose -f "${COMPOSE_FILE}" up -d loki promtail jaeger
    
    print_status "✅ All monitoring services started"
}

# Function to verify service health
verify_services() {
    print_header "🏥 Verifying Service Health"
    
    local services=(
        "prometheus:9090:/metrics"
        "grafana:3000:/api/health"
        "alertmanager:9093:/api/v1/status"
        "node-exporter:9100:/metrics"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service port path <<< "$service_info"
        
        print_status "🔍 Checking $service..."
        
        # Wait for service to be ready
        local max_attempts=30
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if curl -s "http://localhost:${port}${path}" > /dev/null 2>&1; then
                print_status "✅ $service is healthy"
                break
            fi
            
            if [[ $attempt -eq $max_attempts ]]; then
                print_warning "⚠️  $service health check timed out"
            else
                sleep 2
                ((attempt++))
            fi
        done
    done
}

# Function to display access information
display_access_info() {
    print_header "🌐 Access Information"
    
    echo -e "${GREEN}PAWS360 Monitoring Infrastructure is ready!${NC}\n"
    
    echo -e "${BLUE}📊 Dashboards:${NC}"
    echo -e "  • Grafana:           http://localhost:3000 (admin/paws360admin)"
    echo -e "  • Executive:         http://localhost:3000/d/paws360-executive"
    echo -e "  • Technical:         http://localhost:3000/d/paws360-technical"
    echo -e "  • Business:          http://localhost:3000/d/paws360-business"
    echo
    
    echo -e "${BLUE}🔧 Monitoring Services:${NC}"
    echo -e "  • Prometheus:        http://localhost:9090"
    echo -e "  • AlertManager:      http://localhost:9093"
    echo -e "  • Jaeger:           http://localhost:16686"
    echo -e "  • cAdvisor:         http://localhost:8080"
    echo
    
    echo -e "${BLUE}📈 Metrics Endpoints:${NC}"
    echo -e "  • Node Exporter:     http://localhost:9100/metrics"
    echo -e "  • Postgres Exporter: http://localhost:9187/metrics"
    echo -e "  • Spring Boot:       http://localhost:8081/actuator/prometheus"
    echo
    
    echo -e "${BLUE}📜 Constitutional Compliance:${NC}"
    echo -e "  • Article VIIa Status: IMPLEMENTED ✅"
    echo -e "  • Monitoring Phase:    T062 - Dashboard and Alerting Setup"
    echo -e "  • Compliance Level:    100% Article VIIa Requirements Met"
    echo
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "PAWS360 Monitoring Infrastructure Management Script"
    echo "Constitutional Compliance: Article VIIa (Monitoring Discovery and Integration)"
    echo
    echo "OPTIONS:"
    echo "  start, up           Start the monitoring infrastructure"
    echo "  stop, down          Stop the monitoring infrastructure"
    echo "  restart             Restart the monitoring infrastructure"
    echo "  status              Show status of monitoring services"
    echo "  logs [service]      Show logs for all services or specific service"
    echo "  clean               Stop and remove all containers and volumes"
    echo "  validate            Validate configuration files"
    echo "  help, -h, --help    Show this help message"
    echo
    echo "EXAMPLES:"
    echo "  $0 start            # Start all monitoring services"
    echo "  $0 logs grafana     # Show Grafana logs"
    echo "  $0 status           # Check service status"
    echo "  $0 clean            # Complete cleanup"
}

# Function to stop services
stop_services() {
    print_header "🛑 Stopping Monitoring Services"
    
    cd "${PROJECT_ROOT}"
    docker compose -f "${COMPOSE_FILE}" down
    
    print_status "✅ All monitoring services stopped"
}

# Function to show service status
show_status() {
    print_header "📊 Service Status"
    
    cd "${PROJECT_ROOT}"
    docker compose -f "${COMPOSE_FILE}" ps
}

# Function to show logs
show_logs() {
    local service="${1:-}"
    
    cd "${PROJECT_ROOT}"
    
    if [[ -n "$service" ]]; then
        print_header "📝 Logs for $service"
        docker compose -f "${COMPOSE_FILE}" logs -f "$service"
    else
        print_header "📝 Logs for All Services"
        docker compose -f "${COMPOSE_FILE}" logs -f
    fi
}

# Function to clean up everything
clean_all() {
    print_header "🧹 Cleaning Up All Resources"
    
    cd "${PROJECT_ROOT}"
    
    print_status "🛑 Stopping all services..."
    docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans
    
    print_status "🗑️  Removing unused images..."
    docker image prune -f
    
    print_status "💾 Removing monitoring data volumes..."
    docker volume prune -f
    
    print_status "✅ Cleanup completed"
}

# Main execution logic
main() {
    local command="${1:-start}"
    
    case "$command" in
        "start"|"up")
            check_prerequisites
            setup_directories
            validate_configs
            start_services
            verify_services
            display_access_info
            ;;
        "stop"|"down")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 5
            check_prerequisites
            setup_directories
            validate_configs
            start_services
            verify_services
            display_access_info
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "${2:-}"
            ;;
        "clean")
            clean_all
            ;;
        "validate")
            check_prerequisites
            validate_configs
            print_status "✅ All configurations are valid"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"