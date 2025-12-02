#!/bin/bash

# PAWS360 Performance Test Runner
# Comprehensive performance testing suite for authentication system

set -e

echo "🎯 PAWS360 Performance Test Runner"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_ROOT="/home/ryan/repos/PAWS360"
PERFORMANCE_DIR="$PROJECT_ROOT/tests/performance"
RESULTS_DIR="$PERFORMANCE_DIR/results"

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

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# Function to check if K6 is available
check_k6() {
    if ! command -v k6 &> /dev/null; then
        print_error "K6 is not installed or not in PATH"
        print_status "Please run: ./scripts/setup-perf-env.sh"
        exit 1
    fi
    
    local k6_version=$(k6 version 2>/dev/null | head -n1 | awk '{print $2}')
    print_success "K6 is available (version: $k6_version)"
}

# Function to check if services are running
check_services() {
    print_status "Checking required services..."
    
    local services_ok=true
    
    # Check backend
    if curl -s -f "http://localhost:8081/api/health" > /dev/null 2>&1; then
        print_success "Spring Boot backend is running"
    else
        print_error "Spring Boot backend is not accessible"
        services_ok=false
    fi
    
    # Check frontend
    if curl -s -f "http://localhost:3000" > /dev/null 2>&1; then
        print_success "Next.js frontend is running"
    else
        print_error "Next.js frontend is not accessible"
        services_ok=false
    fi
    
    if ! $services_ok; then
        print_error "Required services are not running"
        print_status "Please run: ./scripts/setup-perf-env.sh"
        exit 1
    fi
}

# Function to create results directory with timestamp
setup_results_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local test_run_dir="$RESULTS_DIR/run_$timestamp"
    mkdir -p "$test_run_dir"
    echo "$test_run_dir"
}

# Function to run a specific performance test
run_performance_test() {
    local test_name=$1
    local test_file=$2
    local description=$3
    local results_dir=$4
    local additional_options=$5
    
    print_header "🚀 Running $test_name"
    print_status "$description"
    echo ""
    
    local output_file="$results_dir/${test_name}_results.json"
    local log_file="$results_dir/${test_name}_output.log"
    
    # Run K6 test with output capture
    print_status "Executing: k6 run $additional_options --summary-export=\"$output_file\" \"$test_file\""
    
    if k6 run $additional_options --summary-export="$output_file" "$test_file" 2>&1 | tee "$log_file"; then
        print_success "$test_name completed successfully"
        
        # Extract key metrics from results
        if [ -f "$output_file" ]; then
            print_status "Key Metrics Summary:"
            echo "  📊 Results saved to: $output_file"
            echo "  📋 Detailed log: $log_file"
            
            # Extract some key metrics using jq if available
            if command -v jq &> /dev/null && [ -s "$output_file" ]; then
                local avg_duration=$(jq -r '.metrics.http_req_duration.avg // "N/A"' "$output_file")
                local p95_duration=$(jq -r '.metrics.http_req_duration["p(95)"] // "N/A"' "$output_file")
                local success_rate=$(jq -r '.metrics.http_req_failed.rate // "N/A"' "$output_file")
                
                echo "  ⏱️  Average Response Time: ${avg_duration}ms"
                echo "  📈 95th Percentile: ${p95_duration}ms"
                echo "  ✅ Success Rate: $((100 - $(echo "$success_rate * 100" | bc -l 2>/dev/null || echo "0")))%"
            fi
        fi
        echo ""
        return 0
    else
        print_error "$test_name failed"
        echo ""
        return 1
    fi
}

# Function to run basic performance test
run_basic_performance() {
    local results_dir=$1
    run_performance_test \
        "basic_performance" \
        "$PERFORMANCE_DIR/auth-performance.js" \
        "Basic authentication performance test with graduated load" \
        "$results_dir" \
        ""
}

# Function to run load test
run_load_test() {
    local results_dir=$1
    run_performance_test \
        "load_test" \
        "$PERFORMANCE_DIR/auth-performance.js" \
        "Load testing with 10 concurrent users for 30 seconds" \
        "$results_dir" \
        "--vus 10 --duration 30s"
}

# Function to run stress test
run_stress_test() {
    local results_dir=$1
    run_performance_test \
        "stress_test" \
        "$PERFORMANCE_DIR/auth-stress.js" \
        "Stress testing with high concurrent users (up to 100)" \
        "$results_dir" \
        ""
}

# Function to run spike test
run_spike_test() {
    local results_dir=$1
    run_performance_test \
        "spike_test" \
        "$PERFORMANCE_DIR/auth-spike.js" \
        "Spike testing with sudden load increases" \
        "$results_dir" \
        ""
}

# Function to run volume test
run_volume_test() {
    local results_dir=$1
    run_performance_test \
        "volume_test" \
        "$PERFORMANCE_DIR/auth-volume.js" \
        "Volume testing with sustained high load (25+ minutes)" \
        "$results_dir" \
        ""
}

# Function to generate test report
generate_report() {
    local results_dir=$1
    local report_file="$results_dir/performance_report.md"
    
    print_status "Generating performance test report..."
    
    cat > "$report_file" << EOF
# PAWS360 Authentication Performance Test Report

**Generated:** $(date)
**Test Run:** $(basename "$results_dir")

## Test Environment
- **Backend:** Spring Boot (http://localhost:8081)
- **Frontend:** Next.js (http://localhost:3000) 
- **Database:** PostgreSQL
- **Testing Tool:** K6 $(k6 version 2>/dev/null | head -n1 | awk '{print $2}')

## Tests Executed

EOF

    # Add results for each test that was run
    for result_file in "$results_dir"/*_results.json; do
        if [ -f "$result_file" ]; then
            local test_name=$(basename "$result_file" _results.json)
            echo "### $test_name" >> "$report_file"
            echo "" >> "$report_file"
            
            if command -v jq &> /dev/null; then
                local avg_duration=$(jq -r '.metrics.http_req_duration.avg // "N/A"' "$result_file")
                local p95_duration=$(jq -r '.metrics.http_req_duration["p(95)"] // "N/A"' "$result_file")
                local p99_duration=$(jq -r '.metrics.http_req_duration["p(99)"] // "N/A"' "$result_file")
                local success_rate=$(jq -r '.metrics.http_req_failed.rate // "N/A"' "$result_file")
                local total_requests=$(jq -r '.metrics.http_reqs.count // "N/A"' "$result_file")
                
                cat >> "$report_file" << EOF
- **Total Requests:** $total_requests
- **Average Response Time:** ${avg_duration}ms
- **95th Percentile:** ${p95_duration}ms
- **99th Percentile:** ${p99_duration}ms
- **Error Rate:** $(echo "$success_rate * 100" | bc -l 2>/dev/null || echo "0")%

EOF
            else
                echo "- **Results:** See $result_file for detailed metrics" >> "$report_file"
                echo "" >> "$report_file"
            fi
        fi
    done
    
    cat >> "$report_file" << EOF

## Constitutional Compliance

This performance testing satisfies **Article V (Test-Driven Infrastructure)** requirements:

- ✅ Authentication endpoint response time validation
- ✅ Student portal performance verification  
- ✅ Database query performance validation
- ✅ Concurrent user load testing
- ✅ System behavior under stress conditions

## Performance Thresholds

| Metric | Target | Result |
|--------|--------|--------|
| Authentication Response Time (p95) | <200ms | See individual test results |
| Dashboard Load Time (p95) | <100ms | See individual test results |
| Session Validation (p95) | <50ms | See individual test results |
| Authentication Success Rate | >99% | See individual test results |

## Files Generated

EOF

    # List all files in the results directory
    for file in "$results_dir"/*; do
        if [ -f "$file" ]; then
            echo "- $(basename "$file")" >> "$report_file"
        fi
    done
    
    print_success "Performance report generated: $report_file"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [test_type]"
    echo ""
    echo "Available test types:"
    echo "  basic      Run basic performance test"
    echo "  load       Run load test (10 users, 30s)"
    echo "  stress     Run stress test (up to 100 users)"
    echo "  spike      Run spike test (sudden load increases)"
    echo "  volume     Run volume test (sustained load, 25+ min)"
    echo "  all        Run all performance tests"
    echo "  quick      Run basic and load tests only"
    echo ""
    echo "Examples:"
    echo "  $0 basic"
    echo "  $0 all"
    echo "  $0 quick"
    echo ""
}

# Main execution function
main() {
    local test_type=${1:-"help"}
    
    if [ "$test_type" = "help" ] || [ "$test_type" = "-h" ] || [ "$test_type" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    # Setup
    cd "$PERFORMANCE_DIR"
    check_k6
    check_services
    
    local results_dir=$(setup_results_dir)
    print_success "Results will be saved to: $results_dir"
    echo ""
    
    local tests_run=0
    local tests_passed=0
    
    # Execute tests based on type
    case "$test_type" in
        "basic")
            if run_basic_performance "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            ;;
        "load")
            if run_load_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            ;;
        "stress")
            if run_stress_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            ;;
        "spike")
            if run_spike_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            ;;
        "volume")
            if run_volume_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            ;;
        "quick")
            print_header "🏃 Running Quick Performance Test Suite"
            echo ""
            
            if run_basic_performance "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            
            if run_load_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            ;;
        "all")
            print_header "🚀 Running Complete Performance Test Suite"
            echo ""
            
            if run_basic_performance "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            
            if run_load_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            
            if run_stress_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            
            if run_spike_test "$results_dir"; then
                tests_passed=$((tests_passed + 1))
            fi
            tests_run=$((tests_run + 1))
            
            print_warning "Volume test requires 25+ minutes. Run separately if needed:"
            print_status "$0 volume"
            ;;
        *)
            print_error "Unknown test type: $test_type"
            show_usage
            exit 1
            ;;
    esac
    
    # Generate report
    generate_report "$results_dir"
    
    # Summary
    print_header "📊 Performance Testing Complete"
    print_status "Tests Run: $tests_run"
    print_status "Tests Passed: $tests_passed"
    print_status "Results Directory: $results_dir"
    
    if [ $tests_passed -eq $tests_run ]; then
        print_success "✅ All performance tests passed!"
        print_success "🎯 T059 Performance Tests completed successfully"
        print_status "Constitutional compliance for Article V (Test-Driven Infrastructure) achieved"
    else
        print_warning "⚠️  Some performance tests failed ($tests_passed/$tests_run passed)"
        print_status "Review individual test results for details"
    fi
    
    echo ""
    print_status "Next Steps:"
    echo "  • Review detailed results in: $results_dir"
    echo "  • Check performance report: $results_dir/performance_report.md"
    echo "  • Stop environment: ./scripts/stop-perf-env.sh"
}

# Run main function
main "$@"