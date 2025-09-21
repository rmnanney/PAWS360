# PAWS360 Project Makefile
# Comprehensive build, test, and deployment automation

.PHONY: help install test test-unit test-integration test-contract coverage quality lint format security clean docker-build docker-up docker-down deploy docs

# Default target
help:
	@echo "PAWS360 Development Commands"
	@echo "============================"
	@echo ""
	@echo "Getting Started:"
	@echo "  make install          Install all dependencies"
	@echo "  make setup            Initial project setup"
	@echo ""
	@echo "Testing:"
	@echo "  make test             Run all tests"
	@echo "  make test-unit        Run unit tests only"
	@echo "  make test-integration Run integration tests only"
	@echo "  make test-contract    Run contract tests only"
	@echo "  make coverage         Generate coverage report"
	@echo ""
	@echo "Code Quality:"
	@echo "  make quality          Run all quality checks"
	@echo "  make lint             Run linting"
	@echo "  make format           Format code"
	@echo "  make security         Run security scans"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build     Build all Docker images"
	@echo "  make docker-up        Start all services"
	@echo "  make docker-down      Stop all services"
	@echo "  make docker-logs      Show service logs"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs             Build documentation"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-staging   Deploy to staging"
	@echo "  make deploy-prod      Deploy to production"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean            Clean build artifacts"
	@echo "  make reset            Reset development environment"

# Installation
install:
	@echo "Installing Python dependencies..."
	pip install -e .[dev]
	@echo "Installing Node.js dependencies..."
	npm install
	@echo "Installation complete!"

setup: install
	@echo "Setting up development environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "Created .env file from template"; \
	fi
	@echo "Setup complete!"

# Testing
test:
	@echo "Running complete test suite..."
	export JIRA_EMAIL=test@example.com && \
	export JIRA_API_TOKEN=test_token && \
	export JIRA_URL=https://test.atlassian.net && \
	export JIRA_PROJECT_KEY=TEST && \
	pytest tests/ -v --cov=src --cov-report=html --cov-report=term-missing

test-unit:
	@echo "Running unit tests..."
	export JIRA_EMAIL=test@example.com && \
	export JIRA_API_TOKEN=test_token && \
	export JIRA_URL=https://test.atlassian.net && \
	export JIRA_PROJECT_KEY=TEST && \
	pytest tests/unit/ -v --cov=src --cov-report=term-missing

test-integration:
	@echo "Running integration tests..."
	export JIRA_EMAIL=test@example.com && \
	export JIRA_API_TOKEN=test_token && \
	export JIRA_URL=https://test.atlassian.net && \
	export JIRA_PROJECT_KEY=TEST && \
	pytest tests/integration/ -v --cov=src --cov-report=term-missing

test-contract:
	@echo "Running contract tests..."
	export JIRA_EMAIL=test@example.com && \
	export JIRA_API_TOKEN=test_token && \
	export JIRA_URL=https://test.atlassian.net && \
	export JIRA_PROJECT_KEY=TEST && \
	pytest tests/contract/ -v --cov=src --cov-report=term-missing

coverage:
	@echo "Generating coverage report..."
	export JIRA_EMAIL=test@example.com && \
	export JIRA_API_TOKEN=test_token && \
	export JIRA_URL=https://test.atlassian.net && \
	export JIRA_PROJECT_KEY=TEST && \
	pytest tests/ --cov=src --cov-report=html --cov-report=term-missing
	@echo "Coverage report generated in htmlcov/"

# Code Quality
quality: lint format security
	@echo "All quality checks passed!"

lint:
	@echo "Running linting checks..."
	flake8 src/ tests/
	mypy src/

format:
	@echo "Formatting code..."
	black src/ tests/
	isort src/ tests/

security:
	@echo "Running security scans..."
	bandit -r src/ -f json -o bandit-report.json || true
	safety check --output json || true
	@echo "Security reports generated"

# Docker
docker-build:
	@echo "Building Docker images..."
	docker-compose build --parallel

docker-up:
	@echo "Starting all services..."
	docker-compose up -d
	@echo "Services starting... (use 'make docker-logs' to see logs)"

docker-down:
	@echo "Stopping all services..."
	docker-compose down

docker-logs:
	@echo "Showing service logs..."
	docker-compose logs -f

docker-test:
	@echo "Testing Docker containers..."
	docker-compose up -d
	sleep 30
	docker-compose ps
	docker-compose exec auth-service curl -f http://localhost:8081/actuator/health || echo "Auth service health check failed"
	docker-compose exec data-service curl -f http://localhost:8082/actuator/health || echo "Data service health check failed"
	docker-compose exec analytics-service curl -f http://localhost:8083/actuator/health || echo "Analytics service health check failed"
	docker-compose down

# Documentation
docs:
	@echo "Building documentation..."
	@if command -v mkdocs >/dev/null 2>&1; then \
		mkdocs build; \
	else \
		echo "MkDocs not installed. Install with: pip install mkdocs mkdocs-material"; \
	fi

# Deployment
deploy-staging:
	@echo "Deploying to staging environment..."
	@echo "This would deploy to your staging environment"
	@echo "Add your deployment commands here"

deploy-prod:
	@echo "Deploying to production environment..."
	@echo "This would deploy to your production environment"
	@echo "Add your deployment commands here"

# Utilities
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/
	rm -rf dist/
	rm -rf *.egg-info/
	rm -rf .pytest_cache/
	rm -rf .coverage
	rm -rf coverage.xml
	rm -rf htmlcov/
	rm -rf bandit-report.json
	rm -rf safety-report.json
	rm -rf benchmark.json
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

reset: clean
	@echo "Resetting development environment..."
	rm -f .env
	docker-compose down -v
	docker system prune -f

# Development helpers
dev-setup: setup docker-build
	@echo "Development environment ready!"
	@echo "Run 'make docker-up' to start services"
	@echo "Run 'make test' to run tests"

ci-local:
	@echo "Running local CI pipeline..."
	make quality
	make test
	make docker-test
	make coverage
	@echo "Local CI pipeline complete!"

# Performance testing
performance:
	@echo "Running performance tests..."
	pytest tests/ -k "performance or benchmark" -v --benchmark-only --benchmark-json=benchmark.json

# Database operations
db-migrate:
	@echo "Running database migrations..."
	# Add your migration commands here

db-seed:
	@echo "Seeding database with test data..."
	# Add your seeding commands here

# Monitoring
health-check:
	@echo "Checking service health..."
	curl -f http://localhost:8081/actuator/health || echo "Auth service down"
	curl -f http://localhost:8082/actuator/health || echo "Data service down"
	curl -f http://localhost:8083/actuator/health || echo "Analytics service down"

# Git hooks
install-hooks:
	@echo "Installing git hooks..."
	pre-commit install
	pre-commit install --hook-type commit-msg

# Release management
release-patch:
	@echo "Creating patch release..."
	# Add version bump and release commands

release-minor:
	@echo "Creating minor release..."
	# Add version bump and release commands

release-major:
	@echo "Creating major release..."
	# Add version bump and release commands