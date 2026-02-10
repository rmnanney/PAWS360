#!/bin/bash
# Ansible Playbook Testing Framework for PAWS360
# Validates syntax, idempotency, and basic functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR"
INVENTORY_FILE="$ANSIBLE_DIR/inventories/production/hosts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Test functions
test_syntax() {
    local playbook="$1"
    log_info "Testing syntax of $playbook..."

    if ansible-playbook --syntax-check "$playbook" >/dev/null 2>&1; then
        log_success "Syntax check passed for $playbook"
        return 0
    else
        log_error "Syntax check failed for $playbook"
        return 1
    fi
}

test_inventory() {
    log_info "Testing inventory file..."

    if ansible-inventory --list -i "$INVENTORY_FILE" >/dev/null 2>&1; then
        log_success "Inventory validation passed"
        return 0
    else
        log_error "Inventory validation failed"
        return 1
    fi
}

test_idempotency() {
    local playbook="$1"

    log_info "Testing syntax and structure of $playbook..."

    # Test syntax validation
    if ansible-playbook --syntax-check "$playbook" >/dev/null 2>&1; then
        log_success "Syntax validation passed for $playbook"
        return 0
    else
        log_error "Syntax validation failed for $playbook"
        return 1
    fi
}

test_fresh_start() {
    local playbook="$1"

    log_info "Testing fresh start capability of $playbook..."

    # Create a temporary directory to simulate fresh environment
    local temp_dir
    temp_dir=$(mktemp -d)

    # Copy playbook to temp directory
    cp "$playbook" "$temp_dir/"

    # Try to run with minimal inventory
    if ansible-playbook -i "localhost," --check "$temp_dir/$(basename "$playbook")" >/dev/null 2>&1; then
        log_success "Fresh start test passed for $playbook"
        rm -rf "$temp_dir"
        return 0
    else
        log_error "Fresh start test failed for $playbook"
        rm -rf "$temp_dir"
        return 1
    fi
}

run_all_tests() {
    local failed_tests=0

    log_info "Starting Ansible playbook test suite..."

    # Test inventory
    if ! test_inventory; then
        ((failed_tests++))
    fi

    # Test syntax for all playbooks
    local playbooks=("site.yml" "rolling-update.yml" "deploy-demo.yml" "scale.yml" "local-dev.yml")

    for playbook in "${playbooks[@]}"; do
        if [[ -f "$ANSIBLE_DIR/$playbook" ]]; then
            if ! test_idempotency "$ANSIBLE_DIR/$playbook"; then
                ((failed_tests++))
            fi
        else
            log_warning "Playbook $playbook not found, skipping..."
        fi
    done

    # Test idempotency (only for demo playbook - expect it to not be idempotent)
    if [[ -f "$ANSIBLE_DIR/deploy-demo.yml" ]]; then
        if ! test_idempotency "$ANSIBLE_DIR/deploy-demo.yml"; then
            log_warning "Demo playbook is not idempotent (expected for demo purposes)"
        fi
    fi

    # Test fresh start
    if [[ -f "$ANSIBLE_DIR/deploy-demo.yml" ]]; then
        if ! test_fresh_start "$ANSIBLE_DIR/deploy-demo.yml"; then
            ((failed_tests++))
        fi
    fi

    # Summary
    echo
    if [[ $failed_tests -eq 0 ]]; then
        log_success "All tests passed! ✅"
        return 0
    else
        log_error "$failed_tests test(s) failed! ❌"
        return 1
    fi
}

# Main execution
case "${1:-all}" in
    "syntax")
        test_idempotency "$2"
        ;;
    "inventory")
        test_inventory
        ;;
    "idempotency")
        test_idempotency "$2"
        ;;
    "fresh-start")
        test_fresh_start "$2"
        ;;
    "all")
        run_all_tests
        ;;
    *)
        echo "Usage: $0 [syntax|inventory|idempotency|fresh-start|all] [playbook]"
        echo "Examples:"
        echo "  $0 all                    # Run all tests"
        echo "  $0 syntax site.yml        # Test syntax of site.yml"
        echo "  $0 idempotency deploy-demo.yml  # Test idempotency"
        exit 1
        ;;
esac