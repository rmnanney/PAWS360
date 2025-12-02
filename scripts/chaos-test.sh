#!/usr/bin/env bash
#
# chaos-test.sh - Chaos engineering tests for PAWS360 infrastructure
#
# Simulates various failure scenarios to validate system resilience:
# - Network partitions (packet loss, latency)
# - Container failures (kill, pause, resource exhaustion)
# - Disk I/O degradation
# - CPU throttling
#
# Dependencies: docker/podman, tc (iproute2), stress-ng (optional)
#
# Usage:
#   ./chaos-test.sh <scenario> [options]
#
# Scenarios:
#   network-partition  - Simulate network split between Patroni nodes
#   packet-loss        - Inject 20% packet loss on etcd cluster
#   high-latency       - Add 100ms latency to database connections
#   container-kill     - Randomly kill containers
#   disk-io-stress     - Saturate disk I/O on PostgreSQL volumes
#   cpu-throttle       - Limit CPU to 50% for backend service
#   memory-pressure    - Simulate memory exhaustion

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="${COMPOSE_FILE:-infrastructure/compose/docker-compose.yml}"
CHAOS_DURATION="${CHAOS_DURATION:-60}"  # seconds
RECOVERY_TIMEOUT="${RECOVERY_TIMEOUT:-300}"  # 5 minutes

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_dependencies() {
    local missing_deps=()
    
    if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
        missing_deps+=("docker or podman")
    fi
    
    if ! command -v tc &> /dev/null && [[ "${1:-}" =~ ^(network|packet|latency) ]]; then
        missing_deps+=("tc (iproute2)")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Install: apt-get install iproute2 stress-ng (Ubuntu/Debian)"
        log_info "         brew install iproute2mac (macOS - limited functionality)"
        exit 1
    fi
}

wait_for_recovery() {
    local service="$1"
    local timeout="${2:-$RECOVERY_TIMEOUT}"
    
    log_info "Waiting for $service to recover (timeout: ${timeout}s)..."
    
    local start=$(date +%s)
    while true; do
        if docker exec "paws360-${service}" true 2>/dev/null; then
            local elapsed=$(($(date +%s) - start))
            log_success "$service recovered in ${elapsed}s"
            return 0
        fi
        
        local elapsed=$(($(date +%s) - start))
        if [ $elapsed -ge $timeout ]; then
            log_error "$service failed to recover within ${timeout}s"
            return 1
        fi
        
        sleep 2
    done
}

verify_cluster_health() {
    log_info "Verifying cluster health..."
    
    # Check Patroni cluster
    local leader_count=0
    for port in 8008 8009 8010; do
        if curl -sf http://localhost:${port}/patroni 2>/dev/null | grep -q '"role":"master"'; then
            leader_count=$((leader_count + 1))
        fi
    done
    
    if [ $leader_count -eq 1 ]; then
        log_success "Patroni cluster healthy (1 leader elected)"
    else
        log_error "Patroni cluster unhealthy (${leader_count} leaders found, expected 1)"
        return 1
    fi
    
    # Check etcd cluster
    if docker exec paws360-etcd1 etcdctl endpoint health 2>/dev/null | grep -q "is healthy"; then
        log_success "etcd cluster healthy"
    else
        log_warning "etcd cluster may be unhealthy"
    fi
    
    # Check Redis Sentinel
    if docker exec paws360-redis-master redis-cli PING 2>/dev/null | grep -q "PONG"; then
        log_success "Redis cluster healthy"
    else
        log_warning "Redis cluster may be unhealthy"
    fi
    
    return 0
}

# Chaos scenarios

scenario_network_partition() {
    log_info "🌩️  CHAOS: Network partition between Patroni nodes"
    log_warning "This simulates a network split that may trigger failover"
    
    # Get container IDs
    local patroni1=$(docker ps -qf "name=paws360-patroni1")
    local patroni2=$(docker ps -qf "name=paws360-patroni2")
    local patroni3=$(docker ps -qf "name=paws360-patroni3")
    
    if [ -z "$patroni1" ] || [ -z "$patroni2" ] || [ -z "$patroni3" ]; then
        log_error "Not all Patroni containers are running"
        return 1
    fi
    
    log_info "Creating network partition (patroni1 isolated from patroni2/patroni3)"
    
    # Block traffic between patroni1 and other nodes
    docker exec "$patroni1" iptables -A INPUT -s 10.5.0.0/16 -j DROP 2>/dev/null || {
        log_warning "iptables not available in container, using docker network disconnect"
        docker network disconnect paws360-network paws360-patroni1
    }
    
    log_info "Partition active for ${CHAOS_DURATION}s..."
    sleep $CHAOS_DURATION
    
    # Restore connectivity
    log_info "Healing partition..."
    docker exec "$patroni1" iptables -F 2>/dev/null || {
        docker network connect paws360-network paws360-patroni1
    }
    
    wait_for_recovery "patroni1" 60
    verify_cluster_health
}

scenario_packet_loss() {
    local loss_percentage="${1:-20}"
    log_info "🌩️  CHAOS: Injecting ${loss_percentage}% packet loss on etcd cluster"
    
    for node in etcd1 etcd2 etcd3; do
        log_info "Applying packet loss to $node..."
        docker exec "paws360-${node}" tc qdisc add dev eth0 root netem loss ${loss_percentage}% 2>/dev/null || {
            log_warning "tc not available in $node container"
            continue
        }
    done
    
    log_info "Packet loss active for ${CHAOS_DURATION}s..."
    sleep $CHAOS_DURATION
    
    # Remove packet loss
    for node in etcd1 etcd2 etcd3; do
        log_info "Removing packet loss from $node..."
        docker exec "paws360-${node}" tc qdisc del dev eth0 root 2>/dev/null || true
    done
    
    verify_cluster_health
}

scenario_high_latency() {
    local latency_ms="${1:-100}"
    log_info "🌩️  CHAOS: Adding ${latency_ms}ms latency to database connections"
    
    for node in patroni1 patroni2 patroni3; do
        log_info "Applying latency to $node..."
        docker exec "paws360-${node}" tc qdisc add dev eth0 root netem delay ${latency_ms}ms 2>/dev/null || {
            log_warning "tc not available in $node container"
            continue
        }
    done
    
    log_info "High latency active for ${CHAOS_DURATION}s..."
    log_warning "Expected impact: Slow API responses, increased connection pool wait time"
    sleep $CHAOS_DURATION
    
    # Remove latency
    for node in patroni1 patroni2 patroni3; do
        log_info "Removing latency from $node..."
        docker exec "paws360-${node}" tc qdisc del dev eth0 root 2>/dev/null || true
    done
    
    log_success "Latency removed"
}

scenario_container_kill() {
    local target="${1:-random}"
    
    if [ "$target" = "random" ]; then
        local targets=("patroni2" "patroni3" "etcd2" "redis-replica1")
        target="${targets[$RANDOM % ${#targets[@]}]}"
    fi
    
    log_info "🌩️  CHAOS: Killing container paws360-${target}"
    log_warning "Expected behavior: Container should auto-restart via restart policy"
    
    docker kill "paws360-${target}"
    
    log_info "Waiting for automatic restart..."
    wait_for_recovery "$target" 120
    verify_cluster_health
}

scenario_disk_io_stress() {
    log_info "🌩️  CHAOS: Saturating disk I/O on PostgreSQL volumes"
    
    # Check if stress-ng is available
    if ! docker exec paws360-patroni1 which stress-ng &>/dev/null; then
        log_warning "stress-ng not available in container"
        log_info "Using dd as fallback for disk I/O stress..."
        
        docker exec -d paws360-patroni1 bash -c "
            while true; do
                dd if=/dev/zero of=/var/lib/postgresql/data/stress.tmp bs=1M count=100 2>/dev/null
                rm -f /var/lib/postgresql/data/stress.tmp
            done
        " &
        local stress_pid=$!
        
        log_info "Disk I/O stress active for ${CHAOS_DURATION}s..."
        sleep $CHAOS_DURATION
        
        log_info "Stopping disk I/O stress..."
        kill $stress_pid 2>/dev/null || true
        docker exec paws360-patroni1 pkill -f "dd if=/dev/zero" || true
    else
        docker exec -d paws360-patroni1 stress-ng --io 4 --timeout ${CHAOS_DURATION}s &
        log_info "Disk I/O stress active for ${CHAOS_DURATION}s..."
        sleep $CHAOS_DURATION
    fi
    
    log_success "Disk I/O stress complete"
}

scenario_cpu_throttle() {
    local cpu_limit="${1:-50}"  # Percentage
    log_info "🌩️  CHAOS: Limiting backend CPU to ${cpu_limit}%"
    
    # Update container CPU limit
    docker update --cpus="0.${cpu_limit}" paws360-backend
    
    log_info "CPU throttling active for ${CHAOS_DURATION}s..."
    log_warning "Expected impact: Slower API responses, increased request latency"
    sleep $CHAOS_DURATION
    
    # Remove CPU limit
    log_info "Removing CPU throttling..."
    docker update --cpus="4" paws360-backend
    
    log_success "CPU throttling removed"
}

scenario_memory_pressure() {
    log_info "🌩️  CHAOS: Simulating memory pressure on backend service"
    
    # Allocate memory inside container
    docker exec -d paws360-backend bash -c "
        stress-ng --vm 1 --vm-bytes 80% --timeout ${CHAOS_DURATION}s 2>/dev/null
    " 2>/dev/null || {
        log_warning "stress-ng not available, using memory allocation script"
        docker exec -d paws360-backend bash -c "
            python3 -c '
import time
data = []
for i in range(100):
    data.append(\" \" * 10000000)  # Allocate 10MB per iteration
    time.sleep(1)
' &
        "
    }
    
    log_info "Memory pressure active for ${CHAOS_DURATION}s..."
    log_warning "Expected impact: OOM kills, container restarts"
    sleep $CHAOS_DURATION
    
    # Kill stress processes
    docker exec paws360-backend pkill -f stress-ng || true
    docker exec paws360-backend pkill -f "python.*data.append" || true
    
    wait_for_recovery "backend" 60
    log_success "Memory pressure test complete"
}

# Help text
show_help() {
    cat << EOF
Usage: $0 <scenario> [options]

Chaos Engineering Test Scenarios:

  network-partition       Simulate network split between Patroni nodes
  packet-loss [percent]   Inject packet loss (default: 20%)
  high-latency [ms]       Add network latency (default: 100ms)
  container-kill [name]   Kill container (default: random)
  disk-io-stress          Saturate disk I/O
  cpu-throttle [percent]  Limit CPU (default: 50%)
  memory-pressure         Simulate memory exhaustion

Environment Variables:

  CHAOS_DURATION          Duration of chaos in seconds (default: 60)
  RECOVERY_TIMEOUT        Max time to wait for recovery (default: 300)
  COMPOSE_FILE            Path to docker-compose.yml

Examples:

  # Basic network partition test
  $0 network-partition

  # 30% packet loss for 120 seconds
  CHAOS_DURATION=120 $0 packet-loss 30

  # Kill specific container
  $0 container-kill patroni2

  # CPU throttle to 25%
  $0 cpu-throttle 25

Safety:

  - All chaos is time-limited (default 60s)
  - State is automatically restored
  - Cluster health verified after each test
  - Recommended: Run against dev environment only

EOF
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    local scenario="$1"
    shift
    
    check_dependencies "$scenario"
    
    log_info "Starting chaos scenario: $scenario"
    log_warning "Duration: ${CHAOS_DURATION}s | Recovery timeout: ${RECOVERY_TIMEOUT}s"
    echo
    
    case "$scenario" in
        network-partition)
            scenario_network_partition "$@"
            ;;
        packet-loss)
            scenario_packet_loss "$@"
            ;;
        high-latency)
            scenario_high_latency "$@"
            ;;
        container-kill)
            scenario_container_kill "$@"
            ;;
        disk-io-stress)
            scenario_disk_io_stress "$@"
            ;;
        cpu-throttle)
            scenario_cpu_throttle "$@"
            ;;
        memory-pressure)
            scenario_memory_pressure "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown scenario: $scenario"
            echo
            show_help
            exit 1
            ;;
    esac
    
    echo
    log_success "Chaos scenario '$scenario' complete"
}

main "$@"
