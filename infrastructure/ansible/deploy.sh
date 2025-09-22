#!/bin/bash
# AdminLTE Ansible Deployment Script
# Quick deployment commands for all environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    command -v ansible >/dev/null 2>&1 || error "Ansible not installed"
    command -v ansible-playbook >/dev/null 2>&1 || error "Ansible playbook not found"
    
    if [ ! -f "ansible.cfg" ]; then
        error "ansible.cfg not found. Run from ansible/ directory"
    fi
    
    success "Prerequisites check passed"
}

# Install requirements
install_requirements() {
    log "Installing Ansible Galaxy requirements..."
    ansible-galaxy install -r requirements.yml --force
    success "Requirements installed"
}

# Deploy function
deploy() {
    local env=$1
    local extra_vars=$2
    
    log "Starting deployment to $env environment..."
    
    # Check inventory exists
    if [ ! -f "inventories/$env/hosts" ]; then
        error "Inventory file not found: inventories/$env/hosts"
    fi
    
    # Run deployment
    ansible-playbook -i inventories/$env site.yml \
        --check --diff \
        ${extra_vars:+--extra-vars "$extra_vars"}
    
    read -p "🤔 Proceed with actual deployment? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ansible-playbook -i inventories/$env site.yml \
            ${extra_vars:+--extra-vars "$extra_vars"}
        success "Deployment to $env completed!"
    else
        warning "Deployment cancelled"
    fi
}

# Rolling update function
rolling_update() {
    local env=$1
    local batch_size=${2:-"25%"}
    
    log "Starting rolling update for $env environment (batch size: $batch_size)..."
    
    ansible-playbook -i inventories/$env rolling-update.yml \
        --extra-vars "rolling_update_batch=$batch_size"
    
    success "Rolling update completed!"
}

# Scale function
scale() {
    local env=$1
    local replicas=$2
    
    log "Scaling $env environment to $replicas replicas..."
    
    ansible-playbook -i inventories/$env scale.yml \
        --extra-vars "replicas=$replicas"
    
    success "Scaling completed!"
}

# Health check function
health_check() {
    local env=$1
    
    log "Running health check for $env environment..."
    
    ansible all -i inventories/$env -m shell \
        -a "curl -f http://localhost/admin/health || echo 'FAILED'"
    
    success "Health check completed!"
}

# Main menu
show_help() {
    echo "AdminLTE Ansible Deployment Tool"
    echo "================================="
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  setup                     - Install requirements and check prerequisites"
    echo "  deploy <env>             - Deploy to environment (development/staging/production)"
    echo "  update <env> [batch]     - Rolling update (default batch: 25%)"
    echo "  scale <env> <replicas>   - Scale services horizontally"
    echo "  health <env>             - Health check all services"
    echo "  status <env>             - Show deployment status"
    echo
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 deploy development"
    echo "  $0 deploy production"
    echo "  $0 update production 50%"
    echo "  $0 scale production 5"
    echo "  $0 health staging"
    echo
    echo "Environment files:"
    echo "  - inventories/development/hosts"
    echo "  - inventories/staging/hosts" 
    echo "  - inventories/production/hosts"
    echo
    echo "AdminLTE Components Deployed:"
    echo "  🌐 AdminLTE v4.0.0-rc4 UI (Nginx + dark theme)"
    echo "  🔐 Auth Service (SAML2 + RBAC + Java 21)"
    echo "  📊 Data Service (Student/Course management)"
    echo "  📈 Analytics Service (Chart.js + real-time data)"
    echo "  🗄️  PostgreSQL (with read replicas in production)"
    echo "  🚀 Redis (session + caching)"
    echo "  📊 Monitoring (Prometheus + Grafana)"
}

# Main script logic
case "$1" in
    setup)
        check_prerequisites
        install_requirements
        success "Setup complete! Ready to deploy."
        ;;
    deploy)
        if [ -z "$2" ]; then
            error "Environment required. Usage: $0 deploy <development|staging|production>"
        fi
        check_prerequisites
        deploy "$2" "$3"
        ;;
    update)
        if [ -z "$2" ]; then
            error "Environment required. Usage: $0 update <environment> [batch_size]"
        fi
        check_prerequisites
        rolling_update "$2" "$3"
        ;;
    scale)
        if [ -z "$2" ] || [ -z "$3" ]; then
            error "Environment and replica count required. Usage: $0 scale <environment> <replicas>"
        fi
        check_prerequisites
        scale "$2" "$3"
        ;;
    health)
        if [ -z "$2" ]; then
            error "Environment required. Usage: $0 health <environment>"
        fi
        health_check "$2"
        ;;
    status)
        if [ -z "$2" ]; then
            error "Environment required. Usage: $0 status <environment>"
        fi
        log "Checking deployment status for $2..."
        ansible all -i inventories/$2 -m setup --tree /tmp/facts
        success "Status check completed! See /tmp/facts/ for details."
        ;;
    *)
        show_help
        ;;
esac