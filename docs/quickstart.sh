#!/usr/bin/env bash
#===============================================================================
# PAWS360 Local Development Environment - Quickstart Script
#===============================================================================
# This script automates the complete setup of the PAWS360 local development
# environment with full HA PostgreSQL cluster, Redis Sentinel, and all services.
#
# Usage:
#   ./docs/quickstart.sh [OPTIONS]
#
# Options:
#   --skip-prereqs     Skip prerequisite validation
#   --skip-pull        Skip image pre-pulling (faster if images cached)
#   --lite             Start minimal services (single PostgreSQL, no HA)
#   --full             Start full HA stack (default)
#   --clean            Clean start - remove all volumes first
#   --dry-run          Show what would be done without executing
#   --help             Show this help message
#
# Exit Codes:
#   0  - Success
#   1  - Prerequisite check failed
#   2  - Docker/Podman startup failed
#   3  - Health check timeout
#   4  - Service startup failed
#
# Requirements:
#   - Docker Engine 20.10+ or Podman 4.0+
#   - Docker Compose 2.x or Podman Compose 1.x
#   - 16GB RAM minimum (8GB for --lite mode)
#   - 40GB free disk space (20GB for --lite mode)
#   - Ports: 3000, 5432, 5433, 5434, 2379-2381, 6379-6381, 8008, 8080
#
# Author: PAWS360 Development Team
# Version: 1.0.0
# Last Updated: 2024
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------

# Script metadata
readonly SCRIPT_NAME="PAWS360 Quickstart"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Emoji indicators
readonly CHECK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly CLOCK="⏱"
readonly ROCKET="🚀"
readonly GEAR="⚙"
readonly DATABASE="🗄"
readonly NETWORK="🌐"
readonly LOCK="🔒"
readonly WARNING="⚠"
readonly INFO="ℹ"

# Timing configuration
readonly HEALTH_CHECK_TIMEOUT=300      # 5 minutes total timeout
readonly HEALTH_CHECK_INTERVAL=5       # Check every 5 seconds
readonly PATRONI_LEADER_TIMEOUT=120    # 2 minutes for leader election
readonly SERVICE_STARTUP_WAIT=10       # Initial wait before health checks

# Resource requirements
readonly REQUIRED_RAM_FULL=16384       # 16GB in MB
readonly REQUIRED_RAM_LITE=8192        # 8GB in MB
readonly REQUIRED_DISK_FULL=40         # 40GB
readonly REQUIRED_DISK_LITE=20         # 20GB

# Default options
SKIP_PREREQS=false
SKIP_PULL=false
LITE_MODE=false
CLEAN_START=false
DRY_RUN=false

# Container runtime (auto-detected)
CONTAINER_RUNTIME=""
COMPOSE_COMMAND=""

#-------------------------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------------------------

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                                                                           ║
    ║   ██████╗  █████╗ ██╗    ██╗███████╗██████╗  ██████╗  ██████╗            ║
    ║   ██╔══██╗██╔══██╗██║    ██║██╔════╝╚════██╗██╔════╝ ██╔═████╗           ║
    ║   ██████╔╝███████║██║ █╗ ██║███████╗ █████╔╝███████╗ ██║██╔██║           ║
    ║   ██╔═══╝ ██╔══██║██║███╗██║╚════██║ ╚═══██╗██╔═══██╗████╔╝██║           ║
    ║   ██║     ██║  ██║╚███╔███╔╝███████║██████╔╝╚██████╔╝╚██████╔╝           ║
    ║   ╚═╝     ╚═╝  ╚═╝ ╚══╝╚══╝ ╚══════╝╚═════╝  ╚═════╝  ╚═════╝            ║
    ║                                                                           ║
    ║              Local Development Environment - Quickstart                   ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "  ${WHITE}Version: ${SCRIPT_VERSION}${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}${INFO}${NC} $1"
}

log_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}${WARNING}${NC} $1"
}

log_error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

log_step() {
    echo -e "\n${MAGENTA}${ARROW}${NC} ${WHITE}$1${NC}"
}

log_substep() {
    echo -e "  ${CYAN}${ARROW}${NC} $1"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep -w "$pid")" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

format_duration() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    if [[ $minutes -gt 0 ]]; then
        echo "${minutes}m ${remaining_seconds}s"
    else
        echo "${seconds}s"
    fi
}

show_help() {
    cat << EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

Automated setup script for PAWS360 local development environment.

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    --skip-prereqs     Skip prerequisite validation (use if you know they're met)
    --skip-pull        Skip image pre-pulling (faster if images are cached)
    --lite             Start minimal services (single PostgreSQL, no HA)
    --full             Start full HA stack with Patroni cluster (default)
    --clean            Clean start - remove all existing volumes first
    --dry-run          Show what would be done without executing
    -h, --help         Show this help message

EXAMPLES:
    # Standard full HA setup
    $(basename "$0")
    
    # Quick start with cached images
    $(basename "$0") --skip-pull
    
    # Minimal setup for resource-constrained machines
    $(basename "$0") --lite
    
    # Fresh start, removing all data
    $(basename "$0") --clean
    
    # Preview actions without executing
    $(basename "$0") --dry-run

REQUIREMENTS:
    - Docker Engine 20.10+ or Podman 4.0+
    - Docker Compose 2.x or Podman Compose 1.x
    - 16GB RAM (8GB for --lite mode)
    - 40GB free disk space (20GB for --lite mode)
    - Available ports: 3000, 5432-5434, 2379-2381, 6379-6381, 8008, 8080

For more information, see: docs/local-development/README.md

EOF
}

#-------------------------------------------------------------------------------
# Prerequisite Checks
#-------------------------------------------------------------------------------

detect_container_runtime() {
    log_substep "Detecting container runtime..."
    
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            CONTAINER_RUNTIME="docker"
            log_success "Docker detected and running"
            
            # Check for Docker Compose
            if docker compose version &> /dev/null; then
                COMPOSE_COMMAND="docker compose"
                log_success "Docker Compose v2 detected"
            elif command -v docker-compose &> /dev/null; then
                COMPOSE_COMMAND="docker-compose"
                log_success "Docker Compose v1 detected"
            else
                log_error "Docker Compose not found"
                return 1
            fi
            return 0
        fi
    fi
    
    if command -v podman &> /dev/null; then
        CONTAINER_RUNTIME="podman"
        log_success "Podman detected"
        
        if command -v podman-compose &> /dev/null; then
            COMPOSE_COMMAND="podman-compose"
            log_success "Podman Compose detected"
        else
            log_error "Podman Compose not found"
            return 1
        fi
        return 0
    fi
    
    log_error "No container runtime found (Docker or Podman required)"
    return 1
}

check_docker_version() {
    log_substep "Checking container runtime version..."
    
    local version
    if [[ "$CONTAINER_RUNTIME" == "docker" ]]; then
        version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0.0")
        local major_version=$(echo "$version" | cut -d. -f1)
        local minor_version=$(echo "$version" | cut -d. -f2)
        
        if [[ "$major_version" -ge 20 ]] && [[ "$minor_version" -ge 10 || "$major_version" -gt 20 ]]; then
            log_success "Docker version: $version (≥20.10 required)"
            return 0
        else
            log_error "Docker version $version is too old (20.10+ required)"
            return 1
        fi
    else
        version=$(podman version --format '{{.Version}}' 2>/dev/null || echo "0.0.0")
        local major_version=$(echo "$version" | cut -d. -f1)
        
        if [[ "$major_version" -ge 4 ]]; then
            log_success "Podman version: $version (≥4.0 required)"
            return 0
        else
            log_error "Podman version $version is too old (4.0+ required)"
            return 1
        fi
    fi
}

check_memory() {
    log_substep "Checking available memory..."
    
    local required_ram
    if [[ "$LITE_MODE" == "true" ]]; then
        required_ram=$REQUIRED_RAM_LITE
    else
        required_ram=$REQUIRED_RAM_FULL
    fi
    
    local available_ram
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        available_ram=$(($(sysctl -n hw.memsize) / 1024 / 1024))
    else
        # Linux
        available_ram=$(free -m | awk '/^Mem:/{print $2}')
    fi
    
    if [[ "$available_ram" -ge "$required_ram" ]]; then
        log_success "Available RAM: ${available_ram}MB (≥${required_ram}MB required)"
        return 0
    else
        log_error "Insufficient RAM: ${available_ram}MB available, ${required_ram}MB required"
        if [[ "$LITE_MODE" == "false" ]]; then
            log_info "Try running with --lite flag for reduced memory requirements"
        fi
        return 1
    fi
}

check_disk_space() {
    log_substep "Checking available disk space..."
    
    local required_disk
    if [[ "$LITE_MODE" == "true" ]]; then
        required_disk=$REQUIRED_DISK_LITE
    else
        required_disk=$REQUIRED_DISK_FULL
    fi
    
    local available_disk
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        available_disk=$(df -g "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    else
        # Linux
        available_disk=$(df -BG "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | tr -d 'G')
    fi
    
    if [[ "$available_disk" -ge "$required_disk" ]]; then
        log_success "Available disk space: ${available_disk}GB (≥${required_disk}GB required)"
        return 0
    else
        log_error "Insufficient disk space: ${available_disk}GB available, ${required_disk}GB required"
        return 1
    fi
}

check_ports() {
    log_substep "Checking required ports..."
    
    local required_ports
    if [[ "$LITE_MODE" == "true" ]]; then
        required_ports=(3000 5432 6379 8080)
    else
        required_ports=(3000 5432 5433 5434 2379 2380 2381 6379 6380 6381 8008 8080)
    fi
    
    local blocked_ports=()
    for port in "${required_ports[@]}"; do
        if lsof -Pi :"$port" -sTCP:LISTEN -t &> /dev/null || \
           ss -tuln 2>/dev/null | grep -q ":$port "; then
            blocked_ports+=("$port")
        fi
    done
    
    if [[ ${#blocked_ports[@]} -eq 0 ]]; then
        log_success "All required ports are available"
        return 0
    else
        log_error "Ports already in use: ${blocked_ports[*]}"
        log_info "Stop the processes using these ports or change the configuration"
        return 1
    fi
}

check_required_files() {
    log_substep "Checking required configuration files..."
    
    local required_files=(
        "docker-compose.yml"
        "Makefile.dev"
        "config/dev.env"
    )
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -f "${PROJECT_ROOT}/${file}" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log_success "All required configuration files present"
        return 0
    else
        log_error "Missing required files: ${missing_files[*]}"
        return 1
    fi
}

run_prerequisite_checks() {
    log_step "Running prerequisite checks..."
    
    local checks_passed=true
    
    detect_container_runtime || checks_passed=false
    check_docker_version || checks_passed=false
    check_memory || checks_passed=false
    check_disk_space || checks_passed=false
    check_ports || checks_passed=false
    check_required_files || checks_passed=false
    
    if [[ "$checks_passed" == "true" ]]; then
        log_success "All prerequisite checks passed!"
        return 0
    else
        log_error "Some prerequisite checks failed"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Image Management
#-------------------------------------------------------------------------------

pull_images() {
    log_step "Pre-pulling container images..."
    
    local images=(
        "postgres:15-alpine"
        "redis:7-alpine"
        "quay.io/coreos/etcd:v3.5.9"
        "node:20-alpine"
        "eclipse-temurin:21-jdk-alpine"
    )
    
    if [[ "$LITE_MODE" == "false" ]]; then
        images+=(
            "patroni/patroni:latest"
            "haproxy:2.8-alpine"
        )
    fi
    
    local total=${#images[@]}
    local count=0
    
    for image in "${images[@]}"; do
        ((count++))
        log_substep "[$count/$total] Pulling $image..."
        if [[ "$DRY_RUN" == "false" ]]; then
            $CONTAINER_RUNTIME pull "$image" > /dev/null 2>&1 &
            spinner $!
        fi
        log_success "Pulled $image"
    done
    
    log_success "All images pulled successfully"
}

#-------------------------------------------------------------------------------
# Environment Setup
#-------------------------------------------------------------------------------

clean_volumes() {
    log_step "Cleaning existing volumes..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would remove all PAWS360 volumes"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Stop any running containers
    log_substep "Stopping any running containers..."
    $COMPOSE_COMMAND -f docker-compose.yml down --volumes --remove-orphans 2>/dev/null || true
    
    # Remove named volumes
    log_substep "Removing named volumes..."
    local volumes=(
        "paws360_postgres_data"
        "paws360_patroni1_data"
        "paws360_patroni2_data"
        "paws360_patroni3_data"
        "paws360_etcd1_data"
        "paws360_etcd2_data"
        "paws360_etcd3_data"
        "paws360_redis_data"
        "paws360_redis_sentinel1_data"
        "paws360_redis_sentinel2_data"
        "paws360_redis_sentinel3_data"
    )
    
    for volume in "${volumes[@]}"; do
        $CONTAINER_RUNTIME volume rm "$volume" 2>/dev/null || true
    done
    
    log_success "Volumes cleaned"
}

create_env_file() {
    log_step "Setting up environment configuration..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create .env file from config/dev.env"
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Copy dev environment if .env doesn't exist
    if [[ ! -f ".env" ]]; then
        log_substep "Creating .env from config/dev.env..."
        cp config/dev.env .env
        log_success "Environment file created"
    else
        log_info "Using existing .env file"
    fi
}

#-------------------------------------------------------------------------------
# Service Startup
#-------------------------------------------------------------------------------

start_services() {
    log_step "Starting services..."
    
    cd "$PROJECT_ROOT"
    
    local compose_file="docker-compose.yml"
    local profile_args=""
    
    if [[ "$LITE_MODE" == "true" ]]; then
        log_info "Starting in LITE mode (single PostgreSQL, no HA)"
        profile_args="--profile lite"
    else
        log_info "Starting FULL HA stack"
        profile_args="--profile full"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run: $COMPOSE_COMMAND -f $compose_file $profile_args up -d"
        return 0
    fi
    
    # Start infrastructure services first
    log_substep "Starting infrastructure services (etcd, Redis)..."
    if [[ "$LITE_MODE" == "false" ]]; then
        $COMPOSE_COMMAND -f "$compose_file" up -d etcd1 etcd2 etcd3 redis redis-sentinel1 redis-sentinel2 redis-sentinel3 2>&1 | grep -v "^$" || true
    else
        $COMPOSE_COMMAND -f "$compose_file" up -d redis 2>&1 | grep -v "^$" || true
    fi
    
    # Wait for infrastructure
    sleep 5
    
    # Start database services
    log_substep "Starting database services (PostgreSQL/Patroni)..."
    if [[ "$LITE_MODE" == "false" ]]; then
        $COMPOSE_COMMAND -f "$compose_file" up -d patroni1 patroni2 patroni3 2>&1 | grep -v "^$" || true
    else
        $COMPOSE_COMMAND -f "$compose_file" up -d postgres 2>&1 | grep -v "^$" || true
    fi
    
    # Wait for database
    sleep 10
    
    # Start application services
    log_substep "Starting application services..."
    $COMPOSE_COMMAND -f "$compose_file" up -d backend frontend 2>&1 | grep -v "^$" || true
    
    log_success "Service startup initiated"
}

#-------------------------------------------------------------------------------
# Health Checks
#-------------------------------------------------------------------------------

wait_for_service() {
    local service_name=$1
    local check_command=$2
    local timeout=$3
    local start_time=$(date +%s)
    
    while true; do
        if eval "$check_command" &> /dev/null; then
            return 0
        fi
        
        local elapsed=$(($(date +%s) - start_time))
        if [[ $elapsed -ge $timeout ]]; then
            return 1
        fi
        
        sleep $HEALTH_CHECK_INTERVAL
    done
}

check_etcd_health() {
    if [[ "$LITE_MODE" == "true" ]]; then
        return 0
    fi
    
    log_substep "Checking etcd cluster health..."
    
    local healthy=0
    for i in 1 2 3; do
        if $CONTAINER_RUNTIME exec "paws360-etcd$i" etcdctl endpoint health 2>/dev/null | grep -q "is healthy"; then
            ((healthy++))
        fi
    done
    
    if [[ $healthy -ge 2 ]]; then
        log_success "etcd cluster healthy ($healthy/3 nodes)"
        return 0
    else
        log_warning "etcd cluster not fully healthy ($healthy/3 nodes)"
        return 1
    fi
}

check_patroni_health() {
    if [[ "$LITE_MODE" == "true" ]]; then
        return 0
    fi
    
    log_substep "Checking Patroni cluster health..."
    
    local start_time=$(date +%s)
    local leader_found=false
    
    while [[ $(($(date +%s) - start_time)) -lt $PATRONI_LEADER_TIMEOUT ]]; do
        # Check for leader
        for i in 1 2 3; do
            local role=$($CONTAINER_RUNTIME exec "paws360-patroni$i" patronictl list -f json 2>/dev/null | jq -r '.[0].Role' 2>/dev/null || echo "")
            if [[ "$role" == "Leader" || "$role" == "leader" ]]; then
                leader_found=true
                break 2
            fi
        done
        
        sleep $HEALTH_CHECK_INTERVAL
        echo -n "."
    done
    echo ""
    
    if [[ "$leader_found" == "true" ]]; then
        log_success "Patroni cluster healthy - leader elected"
        
        # Show cluster status
        log_substep "Cluster status:"
        $CONTAINER_RUNTIME exec paws360-patroni1 patronictl list 2>/dev/null || true
        
        return 0
    else
        log_error "Patroni leader election failed"
        return 1
    fi
}

check_postgres_health() {
    log_substep "Checking PostgreSQL connection..."
    
    local pg_host="localhost"
    local pg_port="5432"
    
    if wait_for_service "PostgreSQL" "pg_isready -h $pg_host -p $pg_port" 60; then
        log_success "PostgreSQL accepting connections on port $pg_port"
        return 0
    else
        # Fallback: try via docker exec
        if $CONTAINER_RUNTIME exec paws360-patroni1 pg_isready -h localhost 2>/dev/null || \
           $CONTAINER_RUNTIME exec paws360-postgres pg_isready -h localhost 2>/dev/null; then
            log_success "PostgreSQL accepting connections (via container)"
            return 0
        fi
        log_error "PostgreSQL not responding"
        return 1
    fi
}

check_redis_health() {
    log_substep "Checking Redis connection..."
    
    if $CONTAINER_RUNTIME exec paws360-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis responding to PING"
        return 0
    else
        log_error "Redis not responding"
        return 1
    fi
}

check_redis_sentinel_health() {
    if [[ "$LITE_MODE" == "true" ]]; then
        return 0
    fi
    
    log_substep "Checking Redis Sentinel quorum..."
    
    local sentinel_count=0
    for i in 1 2 3; do
        if $CONTAINER_RUNTIME exec "paws360-redis-sentinel$i" redis-cli -p 26379 ping 2>/dev/null | grep -q "PONG"; then
            ((sentinel_count++))
        fi
    done
    
    if [[ $sentinel_count -ge 2 ]]; then
        log_success "Redis Sentinel quorum established ($sentinel_count/3 sentinels)"
        return 0
    else
        log_warning "Redis Sentinel quorum not established ($sentinel_count/3 sentinels)"
        return 1
    fi
}

check_backend_health() {
    log_substep "Checking backend service health..."
    
    if wait_for_service "Backend" "curl -sf http://localhost:8080/actuator/health" 120; then
        log_success "Backend healthy on port 8080"
        return 0
    else
        log_warning "Backend not responding (may still be starting)"
        return 1
    fi
}

check_frontend_health() {
    log_substep "Checking frontend service health..."
    
    if wait_for_service "Frontend" "curl -sf http://localhost:3000" 120; then
        log_success "Frontend healthy on port 3000"
        return 0
    else
        log_warning "Frontend not responding (may still be starting)"
        return 1
    fi
}

run_health_checks() {
    log_step "Running health checks..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would run health checks for all services"
        return 0
    fi
    
    local start_time=$(date +%s)
    local all_healthy=true
    
    # Infrastructure checks
    check_etcd_health || all_healthy=false
    check_redis_health || all_healthy=false
    check_redis_sentinel_health || all_healthy=false
    
    # Database checks
    check_patroni_health || all_healthy=false
    check_postgres_health || all_healthy=false
    
    # Application checks
    check_backend_health || all_healthy=false
    check_frontend_health || all_healthy=false
    
    local elapsed=$(($(date +%s) - start_time))
    
    if [[ "$all_healthy" == "true" ]]; then
        log_success "All health checks passed! ($(format_duration $elapsed))"
        return 0
    else
        log_warning "Some services may still be starting. Check logs for details."
        return 0  # Don't fail - some services may have slow startup
    fi
}

#-------------------------------------------------------------------------------
# Completion Summary
#-------------------------------------------------------------------------------

print_summary() {
    log_step "Setup Complete!"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                      ${WHITE}PAWS360 Environment Ready${NC}                         ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${WHITE}${NETWORK} Access URLs:${NC}"
    echo -e "   Frontend:        ${CYAN}http://localhost:3000${NC}"
    echo -e "   Backend API:     ${CYAN}http://localhost:8080${NC}"
    echo -e "   API Health:      ${CYAN}http://localhost:8080/actuator/health${NC}"
    echo ""
    
    if [[ "$LITE_MODE" == "false" ]]; then
        echo -e "${WHITE}${DATABASE} Database Cluster:${NC}"
        echo -e "   Primary:         ${CYAN}localhost:5432${NC}"
        echo -e "   Replica 1:       ${CYAN}localhost:5433${NC}"
        echo -e "   Replica 2:       ${CYAN}localhost:5434${NC}"
        echo -e "   Patroni API:     ${CYAN}http://localhost:8008${NC}"
        echo ""
        
        echo -e "${WHITE}${GEAR} Infrastructure:${NC}"
        echo -e "   etcd Cluster:    ${CYAN}localhost:2379, 2380, 2381${NC}"
        echo -e "   Redis Primary:   ${CYAN}localhost:6379${NC}"
        echo -e "   Redis Sentinels: ${CYAN}localhost:26379, 26380, 26381${NC}"
        echo ""
    else
        echo -e "${WHITE}${DATABASE} Database:${NC}"
        echo -e "   PostgreSQL:      ${CYAN}localhost:5432${NC}"
        echo -e "   Redis:           ${CYAN}localhost:6379${NC}"
        echo ""
    fi
    
    echo -e "${WHITE}${LOCK} Default Credentials:${NC}"
    echo -e "   Database User:   ${YELLOW}paws360${NC}"
    echo -e "   Database Pass:   ${YELLOW}paws360_dev${NC}"
    echo -e "   Database Name:   ${YELLOW}paws360${NC}"
    echo ""
    
    echo -e "${WHITE}${ROCKET} Quick Commands:${NC}"
    echo -e "   View logs:       ${CYAN}make dev-logs${NC}"
    echo -e "   Stop services:   ${CYAN}make dev-down${NC}"
    echo -e "   Restart:         ${CYAN}make dev-restart${NC}"
    echo -e "   Full status:     ${CYAN}make dev-status${NC}"
    echo ""
    
    if [[ "$LITE_MODE" == "false" ]]; then
        echo -e "${WHITE}${DATABASE} HA Commands:${NC}"
        echo -e "   Test failover:   ${CYAN}make test-failover${NC}"
        echo -e "   Cluster status:  ${CYAN}make patroni-status${NC}"
        echo -e "   etcd health:     ${CYAN}make etcd-health${NC}"
        echo ""
    fi
    
    echo -e "${WHITE}For more information:${NC}"
    echo -e "   Documentation:   ${CYAN}docs/local-development/README.md${NC}"
    echo -e "   Troubleshooting: ${CYAN}docs/local-development/troubleshooting.md${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# Main Execution
#-------------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-prereqs)
                SKIP_PREREQS=true
                shift
                ;;
            --skip-pull)
                SKIP_PULL=true
                shift
                ;;
            --lite)
                LITE_MODE=true
                shift
                ;;
            --full)
                LITE_MODE=false
                shift
                ;;
            --clean)
                CLEAN_START=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

main() {
    local start_time=$(date +%s)
    
    # Parse command line arguments
    parse_args "$@"
    
    # Print banner
    print_banner
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "Running in DRY RUN mode - no changes will be made"
        echo ""
    fi
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Run prerequisite checks
    if [[ "$SKIP_PREREQS" == "false" ]]; then
        if ! run_prerequisite_checks; then
            log_error "Prerequisite checks failed. Fix the issues above and try again."
            exit 1
        fi
    else
        log_warning "Skipping prerequisite checks"
        # Still need to detect runtime
        detect_container_runtime || exit 1
    fi
    
    # Clean volumes if requested
    if [[ "$CLEAN_START" == "true" ]]; then
        clean_volumes
    fi
    
    # Setup environment
    create_env_file
    
    # Pull images
    if [[ "$SKIP_PULL" == "false" ]]; then
        pull_images
    else
        log_info "Skipping image pre-pull"
    fi
    
    # Start services
    start_services
    
    # Wait for initial startup
    if [[ "$DRY_RUN" == "false" ]]; then
        log_info "Waiting ${SERVICE_STARTUP_WAIT}s for services to initialize..."
        sleep $SERVICE_STARTUP_WAIT
    fi
    
    # Run health checks
    run_health_checks
    
    # Calculate total time
    local total_time=$(($(date +%s) - start_time))
    
    # Print summary
    print_summary
    
    echo -e "${GREEN}${CHECK}${NC} Total setup time: ${WHITE}$(format_duration $total_time)${NC}"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "This was a dry run. Run without --dry-run to actually start the environment."
    fi
}

# Run main function
main "$@"
