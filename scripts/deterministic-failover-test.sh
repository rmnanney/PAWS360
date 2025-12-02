#!/usr/bin/env bash
#
# deterministic-failover-test.sh - Zero-data-loss failover validation
#
# Tests that Patroni failover maintains data integrity by:
# 1. Taking database snapshot
# 2. Seeding known test data
# 3. Triggering failover
# 4. Validating all data present after failover
#
# Exit codes:
#   0 - Failover succeeded with zero data loss
#   1 - Failover failed or data loss detected
#   2 - Pre-flight checks failed

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PATRONI_PORTS=(8008 8009 8010)
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-paws360}"
FAILOVER_TIMEOUT=90
TEST_DATA_ROWS=1000

# Test state
ORIGINAL_LEADER=""
NEW_LEADER=""
SNAPSHOT_TIMESTAMP=""

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

log_step() {
    echo
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
}

# Pre-flight checks
check_prerequisites() {
    log_step "STEP 1: Pre-flight Checks"
    
    # Check containers running
    local required_containers=("patroni1" "patroni2" "patroni3" "etcd1")
    for container in "${required_containers[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "paws360-${container}"; then
            log_error "Container paws360-${container} is not running"
            return 2
        fi
        log_success "Container paws360-${container} running"
    done
    
    # Check Patroni cluster has exactly one leader
    local leader_count=0
    local replica_count=0
    
    for port in "${PATRONI_PORTS[@]}"; do
        local role=$(curl -sf http://localhost:${port}/patroni 2>/dev/null | grep -o '"role":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
        
        if [ "$role" = "master" ]; then
            leader_count=$((leader_count + 1))
            if [ -z "$ORIGINAL_LEADER" ]; then
                # Determine which node based on port
                case $port in
                    8008) ORIGINAL_LEADER="patroni1" ;;
                    8009) ORIGINAL_LEADER="patroni2" ;;
                    8010) ORIGINAL_LEADER="patroni3" ;;
                esac
            fi
        elif [ "$role" = "replica" ]; then
            replica_count=$((replica_count + 1))
        fi
    done
    
    if [ $leader_count -ne 1 ]; then
        log_error "Expected exactly 1 leader, found $leader_count"
        return 2
    fi
    
    if [ $replica_count -lt 1 ]; then
        log_error "Expected at least 1 replica, found $replica_count"
        return 2
    fi
    
    log_success "Patroni cluster healthy (1 leader, $replica_count replicas)"
    log_info "Original leader: $ORIGINAL_LEADER"
    
    return 0
}

# Create test data
seed_test_data() {
    log_step "STEP 2: Seeding Test Data"
    
    log_info "Creating test table: failover_test_data..."
    docker exec paws360-${ORIGINAL_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} <<EOF
DROP TABLE IF EXISTS failover_test_data;
CREATE TABLE failover_test_data (
    id SERIAL PRIMARY KEY,
    test_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
EOF
    
    log_info "Inserting $TEST_DATA_ROWS test records..."
    docker exec paws360-${ORIGINAL_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} <<EOF
INSERT INTO failover_test_data (test_value)
SELECT 'test_record_' || generate_series(1, $TEST_DATA_ROWS);
EOF
    
    # Get row count before failover
    local row_count=$(docker exec paws360-${ORIGINAL_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c \
        "SELECT COUNT(*) FROM failover_test_data;")
    row_count=$(echo $row_count | tr -d ' ')
    
    if [ "$row_count" -ne "$TEST_DATA_ROWS" ]; then
        log_error "Expected $TEST_DATA_ROWS rows, found $row_count"
        return 1
    fi
    
    log_success "Seeded $row_count test records"
    
    # Calculate checksum
    local checksum=$(docker exec paws360-${ORIGINAL_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c \
        "SELECT md5(string_agg(test_value, '' ORDER BY id)) FROM failover_test_data;")
    checksum=$(echo $checksum | tr -d ' ')
    
    log_info "Data checksum: $checksum"
    echo "$checksum" > /tmp/paws360_failover_checksum.txt
    
    return 0
}

# Trigger failover
trigger_failover() {
    log_step "STEP 3: Triggering Failover"
    
    log_info "Current leader: $ORIGINAL_LEADER"
    log_warning "Pausing leader container to simulate failure..."
    
    local start_time=$(date +%s)
    docker pause paws360-${ORIGINAL_LEADER}
    
    log_info "Waiting for new leader election (timeout: ${FAILOVER_TIMEOUT}s)..."
    
    local elected=false
    local elapsed=0
    
    while [ $elapsed -lt $FAILOVER_TIMEOUT ]; do
        for port in "${PATRONI_PORTS[@]}"; do
            # Skip the paused leader's port
            case $port in
                8008) local node="patroni1" ;;
                8009) local node="patroni2" ;;
                8010) local node="patroni3" ;;
            esac
            
            if [ "$node" = "$ORIGINAL_LEADER" ]; then
                continue
            fi
            
            local role=$(curl -sf http://localhost:${port}/patroni 2>/dev/null | grep -o '"role":"master"' | head -1 | cut -d'"' -f4 || echo "")
            
            if [ "$role" = "master" ]; then
                NEW_LEADER="$node"
                elected=true
                break 2
            fi
        done
        
        sleep 1
        elapsed=$(($(date +%s) - start_time))
        
        if [ $((elapsed % 10)) -eq 0 ]; then
            log_info "  Still waiting... (${elapsed}s elapsed)"
        fi
    done
    
    if [ "$elected" = false ]; then
        log_error "No new leader elected within ${FAILOVER_TIMEOUT}s"
        # Resume original leader
        docker unpause paws360-${ORIGINAL_LEADER}
        return 1
    fi
    
    log_success "New leader elected: $NEW_LEADER (failover time: ${elapsed}s)"
    
    # Resume original leader
    log_info "Resuming original leader $ORIGINAL_LEADER..."
    docker unpause paws360-${ORIGINAL_LEADER}
    
    # Wait for it to join as replica
    sleep 5
    
    local resumed_role=$(docker exec paws360-${ORIGINAL_LEADER} curl -sf http://localhost:8008/patroni 2>/dev/null | grep -o '"role":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    
    if [ "$resumed_role" = "replica" ]; then
        log_success "$ORIGINAL_LEADER rejoined cluster as replica"
    else
        log_warning "$ORIGINAL_LEADER role: $resumed_role (expected: replica)"
    fi
    
    # Record metrics
    echo "$elapsed" > /tmp/paws360_failover_time.txt
    
    return 0
}

# Validate data integrity
validate_data_integrity() {
    log_step "STEP 4: Validating Data Integrity"
    
    log_info "Checking data on new leader: $NEW_LEADER"
    
    # Wait for replication lag to settle
    log_info "Waiting for replication lag to settle..."
    sleep 3
    
    # Check row count
    local row_count=$(docker exec paws360-${NEW_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c \
        "SELECT COUNT(*) FROM failover_test_data;")
    row_count=$(echo $row_count | tr -d ' ')
    
    if [ "$row_count" -ne "$TEST_DATA_ROWS" ]; then
        log_error "DATA LOSS DETECTED!"
        log_error "Expected: $TEST_DATA_ROWS rows"
        log_error "Found:    $row_count rows"
        log_error "Missing:  $((TEST_DATA_ROWS - row_count)) rows"
        return 1
    fi
    
    log_success "Row count verified: $row_count/$TEST_DATA_ROWS ✓"
    
    # Validate checksum
    local new_checksum=$(docker exec paws360-${NEW_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c \
        "SELECT md5(string_agg(test_value, '' ORDER BY id)) FROM failover_test_data;")
    new_checksum=$(echo $new_checksum | tr -d ' ')
    
    local original_checksum=$(cat /tmp/paws360_failover_checksum.txt)
    
    if [ "$new_checksum" != "$original_checksum" ]; then
        log_error "DATA CORRUPTION DETECTED!"
        log_error "Original checksum: $original_checksum"
        log_error "New checksum:      $new_checksum"
        return 1
    fi
    
    log_success "Data checksum verified: $new_checksum ✓"
    
    # Check all replicas
    log_info "Validating data on all replicas..."
    
    for port in "${PATRONI_PORTS[@]}"; do
        case $port in
            8008) local node="patroni1" ;;
            8009) local node="patroni2" ;;
            8010) local node="patroni3" ;;
        esac
        
        local replica_count=$(docker exec paws360-${node} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c \
            "SELECT COUNT(*) FROM failover_test_data;" 2>/dev/null || echo "0")
        replica_count=$(echo $replica_count | tr -d ' ')
        
        if [ "$replica_count" -eq "$TEST_DATA_ROWS" ]; then
            log_success "$node: $replica_count rows ✓"
        else
            log_warning "$node: $replica_count rows (expected $TEST_DATA_ROWS)"
        fi
    done
    
    return 0
}

# Cleanup test data
cleanup_test_data() {
    log_step "STEP 5: Cleanup"
    
    log_info "Removing test data..."
    docker exec paws360-${NEW_LEADER:-$ORIGINAL_LEADER} psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} <<EOF
DROP TABLE IF EXISTS failover_test_data;
EOF
    
    rm -f /tmp/paws360_failover_checksum.txt /tmp/paws360_failover_time.txt
    
    log_success "Cleanup complete"
}

# Generate report
generate_report() {
    local exit_code=$1
    
    log_step "FAILOVER TEST REPORT"
    
    echo "┌─────────────────────────────────────────────────┐"
    echo "│         Deterministic Failover Test            │"
    echo "├─────────────────────────────────────────────────┤"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "│ ${GREEN}Status:          ✅ PASSED (Zero Data Loss)${NC}     │"
    else
        echo -e "│ ${RED}Status:          ❌ FAILED${NC}                     │"
    fi
    
    echo "├─────────────────────────────────────────────────┤"
    echo "│ Original Leader: $ORIGINAL_LEADER                        │"
    echo "│ New Leader:      ${NEW_LEADER:-N/A}                        │"
    
    if [ -f /tmp/paws360_failover_time.txt ]; then
        local failover_time=$(cat /tmp/paws360_failover_time.txt)
        echo "│ Failover Time:   ${failover_time}s                           │"
        
        if [ $failover_time -le 30 ]; then
            echo -e "│ ${GREEN}Performance:     Excellent (<30s)${NC}              │"
        elif [ $failover_time -le 60 ]; then
            echo -e "│ ${YELLOW}Performance:     Good (<60s)${NC}                   │"
        else
            echo -e "│ ${RED}Performance:     Needs Improvement (>60s)${NC}      │"
        fi
    fi
    
    echo "│ Test Data Rows:  $TEST_DATA_ROWS                        │"
    echo "└─────────────────────────────────────────────────┘"
    echo
    
    if [ $exit_code -eq 0 ]; then
        log_success "Failover completed successfully with zero data loss!"
        log_info "Cluster automatically recovered and data integrity verified."
    else
        log_error "Failover test failed. Review logs above for details."
    fi
}

# Main execution
main() {
    echo
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   PAWS360 Deterministic Failover Test                    ║"
    echo "║   Zero-Data-Loss Validation                              ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo
    
    local exit_code=0
    
    # Run test sequence
    if ! check_prerequisites; then
        exit_code=2
    elif ! seed_test_data; then
        exit_code=1
    elif ! trigger_failover; then
        exit_code=1
    elif ! validate_data_integrity; then
        exit_code=1
    fi
    
    # Always cleanup
    cleanup_test_data || true
    
    # Generate report
    generate_report $exit_code
    
    exit $exit_code
}

# Trap errors
trap 'log_error "Test failed unexpectedly"; cleanup_test_data; exit 1' ERR

main "$@"
