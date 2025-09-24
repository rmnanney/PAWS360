#!/bin/bash
# PAWS360 Development Helper Script
# Provides shortcuts for common Ansible development tasks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
PAWS360 Ansible Development Helper

USAGE: $0 <command> [options]

COMMANDS:
    test                Run all tests
    test-syntax         Test playbook syntax only
    test-inventory      Test inventory configuration
    test-idempotency    Test playbook idempotency
    test-fresh-start    Test fresh start capability

    deploy-local-dev    Deploy local development environment (defaults only)
    deploy-demo         Deploy demo environment
    deploy-full         Deploy full production environment
    deploy-rolling      Perform rolling update
    deploy-scale        Scale services (requires scale_factor=N)

    clean               Clean up deployment artifacts
    reset               Reset environment to clean state
    logs                Show service logs
    status              Show deployment status

    lint                Run ansible-lint (if available)
    validate            Full validation (syntax + inventory + idempotency)

    help                Show this help message

EXAMPLES:
    $0 test                    # Run all tests
    $0 deploy-demo             # Deploy demo environment
    $0 deploy-scale 3          # Scale to 3 instances
    $0 logs auth-service       # Show auth service logs
    $0 status                  # Show current status

ENVIRONMENT VARIABLES:
    ANSIBLE_INVENTORY    Path to inventory file (default: auto-detect)
    ANSIBLE_EXTRA_VARS   Extra variables for playbooks
    VERBOSE              Enable verbose output (set to 1)

EOF
}

# Test functions
run_tests() {
    log_info "Running all tests..."
    ./test-playbooks.sh all
}

run_syntax_test() {
    log_info "Testing playbook syntax..."
    ./test-playbooks.sh syntax site.yml
}

run_inventory_test() {
    log_info "Testing inventory configuration..."
    ./test-playbooks.sh inventory
}

run_idempotency_test() {
    local playbook="${1:-site.yml}"
    log_info "Testing idempotency for $playbook..."
    ./test-playbooks.sh idempotency "$playbook"
}

run_fresh_start_test() {
    local playbook="${1:-deploy-demo.yml}"
    log_info "Testing fresh start for $playbook..."
    ./test-playbooks.sh fresh-start "$playbook"
}

# Deployment functions
deploy_local_dev() {
    log_info "Deploying local development environment (defaults only)..."
    ansible-playbook local-dev.yml
    log_success "Local development environment ready"
}

deploy_full() {
    log_info "Deploying full production environment..."
    ansible-playbook site.yml
    log_success "Full deployment completed"
}

deploy_rolling() {
    log_info "Performing rolling update..."
    ansible-playbook rolling-update.yml
    log_success "Rolling update completed"
}

deploy_scale() {
    local scale_factor="${1:-2}"
    log_info "Scaling services to factor $scale_factor..."
    ansible-playbook scale.yml -e "scale_factor=$scale_factor"
    log_success "Scaling completed"
}

# Utility functions
clean_deployment() {
    log_info "Cleaning deployment artifacts..."
    # Remove temporary files, logs, etc.
    find . -name "*.retry" -delete 2>/dev/null || true
    find . -name "*.tmp" -delete 2>/dev/null || true
    log_success "Cleanup completed"
}

reset_environment() {
    log_warning "Resetting environment to clean state..."
    log_warning "This will stop all services and remove data!"

    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Stop services
        sudo systemctl stop adminlte-auth adminlte-data adminlte-analytics adminlte-ui 2>/dev/null || true
        sudo systemctl stop postgresql redis nginx docker 2>/dev/null || true

        # Remove service files
        sudo rm -f /etc/systemd/system/adminlte-*

        # Clean directories
        sudo rm -rf /opt/adminlte/data/*
        sudo rm -rf /opt/adminlte/logs/*

        # Reload systemd
        sudo systemctl daemon-reload

        log_success "Environment reset completed"
    else
        log_info "Reset cancelled"
    fi
}

show_logs() {
    local service="$1"
    if [ -z "$service" ]; then
        log_error "Please specify a service name (auth-service, data-service, analytics-service, adminlte-ui)"
        exit 1
    fi

    case "$service" in
        auth-service|auth)
            sudo journalctl -u adminlte-auth -f
            ;;
        data-service|data)
            sudo journalctl -u adminlte-data -f
            ;;
        analytics-service|analytics)
            sudo journalctl -u adminlte-analytics -f
            ;;
        adminlte-ui|ui)
            sudo journalctl -u adminlte-ui -f
            ;;
        *)
            log_error "Unknown service: $service"
            log_info "Available services: auth-service, data-service, analytics-service, adminlte-ui"
            exit 1
            ;;
    esac
}

show_status() {
    log_info "Checking deployment status..."

    echo "=== System Services ==="
    for service in postgresql redis nginx docker; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $service: running"
        else
            echo -e "${RED}✗${NC} $service: stopped"
        fi
    done

    echo
    echo "=== Application Services ==="
    for service in adminlte-auth adminlte-data adminlte-analytics adminlte-ui; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $service: running"
        else
            echo -e "${RED}✗${NC} $service: stopped"
        fi
    done

    echo
    echo "=== Service Health Checks ==="
    for port in 8081 8082 8083 80; do
        if curl -s "http://localhost:$port/actuator/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} localhost:$port: healthy"
        else
            echo -e "${RED}✗${NC} localhost:$port: unhealthy"
        fi
    done
}

run_lint() {
    log_info "Running ansible-lint..."
    if command -v ansible-lint >/dev/null 2>&1; then
        ansible-lint . || log_warning "Linting completed with warnings/errors"
    else
        log_warning "ansible-lint not found. Install with: pip install ansible-lint"
    fi
}

run_validate() {
    log_info "Running full validation..."
    run_syntax_test
    run_inventory_test
    run_idempotency_test site.yml
    run_fresh_start_test deploy-demo.yml
    log_success "Validation completed"
}

# Main command handling
case "${1:-help}" in
    test)
        run_tests
        ;;
    test-syntax)
        run_syntax_test
        ;;
    test-inventory)
        run_inventory_test
        ;;
    test-idempotency)
        run_idempotency_test "$2"
        ;;
    test-fresh-start)
        run_fresh_start_test "$2"
        ;;
    deploy-local-dev)
        deploy_local_dev
        ;;
    deploy-demo)
        deploy_demo
        ;;
    deploy-full)
        deploy_full
        ;;
    deploy-rolling)
        deploy_rolling
        ;;
    deploy-scale)
        deploy_scale "$2"
        ;;
    clean)
        clean_deployment
        ;;
    reset)
        reset_environment
        ;;
    logs)
        show_logs "$2"
        ;;
    status)
        show_status
        ;;
    lint)
        run_lint
        ;;
    validate)
        run_validate
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac