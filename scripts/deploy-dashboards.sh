#!/usr/bin/env bash
# Grafana Dashboard Deployment Script
# JIRA: INFRA-474
# Purpose: Deploy Grafana dashboards to monitoring infrastructure

set -euo pipefail

# Configuration
GRAFANA_URL="${GRAFANA_URL:-http://192.168.0.200:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"
DASHBOARD_DIR="${DASHBOARD_DIR:-./monitoring/grafana/dashboards}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
DEPLOYED=0
FAILED=0
SKIPPED=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    # Check Grafana availability
    if ! curl -sf "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
        log_error "Grafana is not accessible at ${GRAFANA_URL}"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Deploy a single dashboard
deploy_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "${dashboard_file}" .json)
    
    log_info "Deploying dashboard: ${dashboard_name}"
    
    # Read and validate JSON
    if ! jq empty "${dashboard_file}" 2>/dev/null; then
        log_error "Invalid JSON in ${dashboard_file}"
        ((FAILED++))
        return 1
    fi
    
    # Prepare dashboard payload
    local dashboard_json=$(cat "${dashboard_file}")
    local payload=$(jq -n --argjson dashboard "${dashboard_json}" '{
        dashboard: $dashboard.dashboard,
        overwrite: true,
        message: "Deployed by deploy-dashboards.sh"
    }')
    
    # Deploy to Grafana
    local response
    response=$(curl -sf -X POST "${GRAFANA_URL}/api/dashboards/db" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        -H "Content-Type: application/json" \
        -d "${payload}" \
        2>&1) || {
        log_error "Failed to deploy ${dashboard_name}"
        if [[ -n "${response}" ]]; then
            echo "  Response: ${response}"
        fi
        ((FAILED++))
        return 1
    }
    
    # Parse response
    local status
    status=$(echo "${response}" | jq -r '.status' 2>/dev/null || echo "unknown")
    
    if [[ "${status}" == "success" ]]; then
        local uid
        local url
        uid=$(echo "${response}" | jq -r '.uid' 2>/dev/null || echo "unknown")
        url=$(echo "${response}" | jq -r '.url' 2>/dev/null || echo "unknown")
        
        log_success "Deployed ${dashboard_name}"
        log_info "  UID: ${uid}"
        log_info "  URL: ${GRAFANA_URL}${url}"
        ((DEPLOYED++))
        return 0
    else
        log_error "Deployment failed for ${dashboard_name}"
        echo "  Response: ${response}"
        ((FAILED++))
        return 1
    fi
}

# Deploy all dashboards
deploy_all_dashboards() {
    log_info "Deploying dashboards from: ${DASHBOARD_DIR}"
    
    if [[ ! -d "${DASHBOARD_DIR}" ]]; then
        log_error "Dashboard directory not found: ${DASHBOARD_DIR}"
        exit 1
    fi
    
    # Find all JSON files
    local dashboard_files
    dashboard_files=$(find "${DASHBOARD_DIR}" -name "*.json" -type f)
    
    if [[ -z "${dashboard_files}" ]]; then
        log_warn "No dashboard files found in ${DASHBOARD_DIR}"
        exit 0
    fi
    
    # Deploy each dashboard
    while IFS= read -r dashboard_file; do
        deploy_dashboard "${dashboard_file}"
    done <<< "${dashboard_files}"
}

# Create datasources if needed
setup_datasources() {
    log_info "Setting up datasources..."
    
    # Check if Prometheus datasource exists
    local prom_exists
    prom_exists=$(curl -sf -X GET "${GRAFANA_URL}/api/datasources/name/Prometheus" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        2>/dev/null || echo "")
    
    if [[ -z "${prom_exists}" ]]; then
        log_info "Creating Prometheus datasource..."
        
        local prom_config='{
          "name": "Prometheus",
          "type": "prometheus",
          "url": "http://prometheus:9090",
          "access": "proxy",
          "isDefault": true,
          "jsonData": {
            "timeInterval": "30s"
          }
        }'
        
        curl -sf -X POST "${GRAFANA_URL}/api/datasources" \
            -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
            -H "Content-Type: application/json" \
            -d "${prom_config}" > /dev/null 2>&1 && {
            log_success "Prometheus datasource created"
        } || {
            log_warn "Failed to create Prometheus datasource (may already exist)"
        }
    else
        log_info "Prometheus datasource already exists"
    fi
    
    # Check if Loki datasource exists
    local loki_exists
    loki_exists=$(curl -sf -X GET "${GRAFANA_URL}/api/datasources/name/Loki" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        2>/dev/null || echo "")
    
    if [[ -z "${loki_exists}" ]]; then
        log_info "Creating Loki datasource..."
        
        local loki_config='{
          "name": "Loki",
          "type": "loki",
          "url": "http://loki:3100",
          "access": "proxy",
          "jsonData": {
            "maxLines": 1000
          }
        }'
        
        curl -sf -X POST "${GRAFANA_URL}/api/datasources" \
            -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
            -H "Content-Type: application/json" \
            -d "${loki_config}" > /dev/null 2>&1 && {
            log_success "Loki datasource created"
        } || {
            log_warn "Failed to create Loki datasource (may already exist)"
        }
    else
        log_info "Loki datasource already exists"
    fi
}

# Create dashboard folder
create_dashboard_folder() {
    log_info "Creating CI/CD dashboard folder..."
    
    local folder_config='{
      "title": "CI/CD Infrastructure",
      "uid": "cicd-infra"
    }'
    
    curl -sf -X POST "${GRAFANA_URL}/api/folders" \
        -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
        -H "Content-Type: application/json" \
        -d "${folder_config}" > /dev/null 2>&1 && {
        log_success "Dashboard folder created"
    } || {
        log_info "Dashboard folder already exists or creation failed"
    }
}

# Main execution
main() {
    echo "=========================================="
    echo "Grafana Dashboard Deployment"
    echo "=========================================="
    echo "Grafana URL: ${GRAFANA_URL}"
    echo "Dashboard Dir: ${DASHBOARD_DIR}"
    echo "=========================================="
    echo ""
    
    # Run deployment steps
    check_prerequisites
    setup_datasources
    create_dashboard_folder
    deploy_all_dashboards
    
    # Summary
    echo ""
    echo "=========================================="
    echo "Deployment Summary"
    echo "=========================================="
    echo "Deployed: ${DEPLOYED}"
    echo "Failed:   ${FAILED}"
    echo "Skipped:  ${SKIPPED}"
    echo "=========================================="
    
    if [[ ${FAILED} -eq 0 ]]; then
        log_success "All dashboards deployed successfully"
        echo ""
        echo "Access dashboards at: ${GRAFANA_URL}/dashboards"
        exit 0
    else
        log_error "Some dashboards failed to deploy"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            GRAFANA_URL="$2"
            shift 2
            ;;
        --user)
            GRAFANA_USER="$2"
            shift 2
            ;;
        --password)
            GRAFANA_PASSWORD="$2"
            shift 2
            ;;
        --dir)
            DASHBOARD_DIR="$2"
            shift 2
            ;;
        --help|-h)
            cat <<EOF
Grafana Dashboard Deployment Script

Usage: $0 [OPTIONS]

Options:
  --url URL           Grafana URL (default: http://192.168.0.200:3000)
  --user USER         Grafana admin user (default: admin)
  --password PASS     Grafana admin password (default: admin)
  --dir DIR           Dashboard directory (default: ./monitoring/grafana/dashboards)
  -h, --help          Show this help message

Examples:
  $0
  $0 --url http://localhost:3000 --user admin --password secret
  $0 --dir /path/to/dashboards

EOF
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

main
