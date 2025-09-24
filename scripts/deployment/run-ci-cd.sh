#!/bin/bash

# PAWS360 Local CI/CD Pipeline Runner
# Run the complete CI/CD pipeline locally

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PYTHON_VERSION="3.10"
NODE_VERSION="18"
JAVA_VERSION="21"

echo -e "${BLUE}🚀 PAWS360 Local CI/CD Pipeline${NC}"
echo "=================================="

# Function to print status
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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check Python
    if ! command -v python${PYTHON_VERSION} &> /dev/null; then
        print_error "Python ${PYTHON_VERSION} not found"
        exit 1
    fi

    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found"
        exit 1
    fi

# Check Java
if ! command -v java &> /dev/null; then
    print_warning "Java not found - Java-related checks will be skipped"
else
    print_success "Java found"
fi    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found - Docker tests will be skipped"
    fi

    print_success "Prerequisites check passed"
}

# Setup environment
setup_environment() {
    print_status "Setting up environment..."

    # Create test environment file
    cat > .env.test << EOF
JIRA_EMAIL=test@example.com
JIRA_API_TOKEN=test_token
JIRA_URL=https://test.atlassian.net
JIRA_PROJECT_KEY=TEST
DATABASE_URL=postgresql://postgres:test_password@localhost:5432/test_db
REDIS_URL=redis://localhost:6379
SECRET_KEY=test_secret_key_for_ci_cd_pipeline
EOF

    # Export environment variables
    export JIRA_EMAIL=test@example.com
    export JIRA_API_TOKEN=test_token
    export JIRA_URL=https://test.atlassian.net
    export JIRA_PROJECT_KEY=TEST
    export DATABASE_URL=postgresql://postgres:test_password@localhost:5432/test_db
    export REDIS_URL=redis://localhost:6379
    export SECRET_KEY=test_secret_key_for_ci_cd_pipeline

    print_success "Environment setup complete"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."

    # Python dependencies
    python${PYTHON_VERSION} -m pip install --upgrade pip
    pip install -e .[dev]

    # Node.js dependencies
    npm install

    print_success "Dependencies installed"
}

# Code quality checks
run_quality_checks() {
    print_status "Running code quality checks..."

    # Code formatting check
    echo "Checking code formatting..."
    black --check --diff src/ tests/ || {
        print_warning "Code formatting issues found. Run 'make format' to fix"
    }

    # Import sorting check
    echo "Checking import sorting..."
    isort --check-only --diff src/ tests/ || {
        print_warning "Import sorting issues found. Run 'make format' to fix"
    }

    # Linting
    echo "Running linting..."
    flake8 src/ tests/ || {
        print_warning "Linting issues found"
    }

    # Type checking
    echo "Running type checking..."
    mypy src/ || {
        print_warning "Type checking issues found"
    }

    print_success "Code quality checks completed"
}

# Security scanning
run_security_scans() {
    print_status "Running security scans..."

    # Bandit security scan
    echo "Running Bandit security scan..."
    bandit -r src/ -f json -o bandit-report.json || {
        print_warning "Bandit security scan completed with issues"
    }

    # Safety dependency check
    echo "Running Safety dependency check..."
    safety check --output json || {
        print_warning "Safety dependency check completed with issues"
    }

    print_success "Security scans completed"
}

# Unit tests
run_unit_tests() {
    print_status "Running unit tests..."

    pytest tests/unit/ -v --cov=src --cov-report=term-missing --cov-report=xml || {
        print_error "Unit tests failed"
        return 1
    }

    print_success "Unit tests passed"
}

# Integration tests
run_integration_tests() {
    print_status "Running integration tests..."

    # Start test services if Docker is available
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        print_status "Starting test services..."
        docker-compose -f docker-compose.test.yml up -d postgres redis || {
            print_warning "Could not start test services, running without them"
        }
        sleep 10
    fi

    pytest tests/integration/ -v --cov=src --cov-report=term-missing --cov-report=xml || {
        print_error "Integration tests failed"
        return 1
    }

    print_success "Integration tests passed"
}

# Contract tests
run_contract_tests() {
    print_status "Running contract tests..."

    pytest tests/contract/ -v --cov=src --cov-report=term-missing --cov-report=xml || {
        print_error "Contract tests failed"
        return 1
    }

    print_success "Contract tests passed"
}

# Docker tests
run_docker_tests() {
    print_status "Running Docker tests..."

    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        print_warning "Docker not available, skipping Docker tests"
        return 0
    fi

    # Build images
    docker-compose build --parallel || {
        print_error "Docker build failed"
        return 1
    }

    # Test containers
    docker-compose up -d || {
        print_error "Docker services failed to start"
        return 1
    }

    sleep 30

    # Health checks
    docker-compose ps

    # Check service health
    if curl -f http://localhost:8081/actuator/health &> /dev/null; then
        print_success "Auth service health check passed"
    else
        print_warning "Auth service health check failed"
    fi

    if curl -f http://localhost:8082/actuator/health &> /dev/null; then
        print_success "Data service health check passed"
    else
        print_warning "Data service health check failed"
    fi

    if curl -f http://localhost:8083/actuator/health &> /dev/null; then
        print_success "Analytics service health check passed"
    else
        print_warning "Analytics service health check failed"
    fi

    # Cleanup
    docker-compose down

    print_success "Docker tests completed"
}

# Performance tests
run_performance_tests() {
    print_status "Running performance tests..."

    pytest tests/ -k "performance or benchmark" -v --benchmark-only --benchmark-json=benchmark.json || {
        print_warning "Performance tests completed (some may have failed)"
    }

    print_success "Performance tests completed"
}

# Generate coverage report
generate_coverage_report() {
    print_status "Generating coverage report..."

    # Combine coverage data
    coverage combine || true
    coverage html || true
    coverage report --fail-under=70 || {
        print_warning "Coverage below 70% threshold"
    }

    print_success "Coverage report generated"
}

# Main pipeline execution
main() {
    local start_time=$(date +%s)
    local failed_steps=()

    echo "Starting CI/CD pipeline at $(date)"
    echo ""

    # Step 1: Prerequisites
    if ! check_prerequisites; then
        failed_steps+=("prerequisites")
    fi

    # Step 2: Environment setup
    if ! setup_environment; then
        failed_steps+=("environment")
    fi

    # Step 3: Dependencies
    if ! install_dependencies; then
        failed_steps+=("dependencies")
    fi

    # Step 4: Quality checks
    if ! run_quality_checks; then
        failed_steps+=("quality")
    fi

    # Step 5: Security scans
    if ! run_security_scans; then
        failed_steps+=("security")
    fi

    # Step 6: Unit tests
    if ! run_unit_tests; then
        failed_steps+=("unit_tests")
    fi

    # Step 7: Integration tests
    if ! run_integration_tests; then
        failed_steps+=("integration_tests")
    fi

    # Step 8: Contract tests
    if ! run_contract_tests; then
        failed_steps+=("contract_tests")
    fi

    # Step 9: Docker tests
    if ! run_docker_tests; then
        failed_steps+=("docker_tests")
    fi

    # Step 10: Performance tests
    if ! run_performance_tests; then
        failed_steps+=("performance_tests")
    fi

    # Step 11: Coverage report
    if ! generate_coverage_report; then
        failed_steps+=("coverage")
    fi

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo "=================================="
    echo -e "${BLUE}CI/CD Pipeline Results${NC}"
    echo "=================================="

    if [ ${#failed_steps[@]} -eq 0 ]; then
        print_success "🎉 All pipeline steps passed!"
        echo "Duration: ${duration} seconds"
        echo ""
        echo "Coverage report: htmlcov/index.html"
        echo "Security reports: bandit-report.json"
        echo "Performance results: benchmark.json"
    else
        print_error "❌ Pipeline completed with failures"
        echo "Failed steps: ${failed_steps[*]}"
        echo "Duration: ${duration} seconds"
        echo ""
        echo "Check the logs above for details"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    "quality")
        check_prerequisites
        setup_environment
        install_dependencies
        run_quality_checks
        ;;
    "security")
        check_prerequisites
        setup_environment
        install_dependencies
        run_security_scans
        ;;
    "test")
        check_prerequisites
        setup_environment
        install_dependencies
        run_unit_tests
        run_integration_tests
        run_contract_tests
        ;;
    "docker")
        run_docker_tests
        ;;
    "coverage")
        generate_coverage_report
        ;;
    "all"|*)
        main
        ;;
esac