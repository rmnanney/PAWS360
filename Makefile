# PAWS360 CI/CD Makefile
# Common commands for development, testing, and deployment

.PHONY: help build test clean docker-build docker-push deploy-staging deploy-prod

# Default target
help:
	@echo "PAWS360 CI/CD Commands:"
	@echo ""
	@echo "Development:"
	@echo "  make build          - Build the application"
	@echo "  make test           - Run all tests"
	@echo "  make clean          - Clean build artifacts"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build   - Build Docker image"
	@echo "  make docker-push    - Push Docker image to registry"
	@echo "  make docker-run     - Run application in Docker"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-staging - Deploy to staging environment"
	@echo "  make deploy-prod    - Deploy to production environment"
	@echo ""
	@echo "CI/CD:"
	@echo "  make ci             - Run full CI pipeline locally"
	@echo "  make lint           - Run code quality checks"
	@echo "  make security-scan  - Run security vulnerability scan"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate     - Run database migrations"
	@echo "  make db-seed        - Seed database with test data"
	@echo ""
	@echo "Monitoring:"
	@echo "  make logs           - Show application logs"
	@echo "  make health         - Check application health"
	@echo "  make metrics        - Show application metrics"

# Development commands
build:
	@echo "🔨 Building PAWS360 application..."
	./scripts/ci-cd/build.sh

test:
	@echo "🧪 Running PAWS360 test suite..."
	./scripts/ci-cd/test.sh

clean:
	@echo "🧹 Cleaning build artifacts..."
	mvn clean
	rm -rf target/
	rm -rf .mvn/wrapper/maven-wrapper.jar
	docker system prune -f

lint:
	@echo "🔍 Running code quality checks..."
	mvn checkstyle:check
	mvn spotbugs:check

# Docker commands
docker-build:
	@echo "🐳 Building Docker image..."
	docker build -f infrastructure/docker/Dockerfile -t paws360-app:latest .

docker-push:
	@echo "📤 Pushing Docker image..."
	docker tag paws360-app:latest ghcr.io/$(shell git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/'):latest
	docker push ghcr.io/$(shell git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/'):latest

docker-run:
	@echo "🚀 Running application in Docker..."
	docker run -p 8080:8080 --env-file .env paws360-app:latest

# Deployment commands
deploy-staging:
	@echo "🚀 Deploying to staging environment..."
	./scripts/ci-cd/deploy.sh staging $(shell git rev-parse --abbrev-ref HEAD)

deploy-prod:
	@echo "🚀 Deploying to production environment..."
	./scripts/ci-cd/deploy.sh production $(shell git rev-parse --abbrev-ref HEAD)

# CI/CD commands
ci: clean build test lint security-scan
	@echo "✅ CI pipeline completed successfully!"

security-scan:
	@echo "🔒 Running security vulnerability scan..."
	mvn org.owasp:dependency-check-maven:check
	docker run --rm -v $(PWD):/src aquasecurity/trivy:0.40.0 fs /src

# Database commands
db-migrate:
	@echo "🗄️ Running database migrations..."
	mvn flyway:migrate

db-seed:
	@echo "🌱 Seeding database with test data..."
	mvn exec:java -Dexec.mainClass="com.paws360.DatabaseSeeder"

# Monitoring commands
logs:
	@echo "📋 Showing application logs..."
	docker-compose -f infrastructure/docker/docker-compose.yml logs -f paws360-app

health:
	@echo "❤️ Checking application health..."
	curl -f http://localhost:8080/actuator/health || echo "Application is not healthy"

metrics:
	@echo "📊 Showing application metrics..."
	curl -f http://localhost:8080/actuator/metrics || echo "Metrics endpoint not available"

# Utility commands
setup:
	@echo "⚙️ Setting up development environment..."
	cp .env.example .env
	@echo "Please update .env with your configuration values"

update-deps:
	@echo "📦 Updating dependencies..."
	mvn versions:use-latest-versions
	mvn versions:commit

# Development server
dev:
	@echo "🚀 Starting development server..."
	mvn spring-boot:run

dev-docker:
	@echo "🐳 Starting development environment with Docker..."
	cd infrastructure/docker && docker-compose up -d

stop-dev:
	@echo "🛑 Stopping development environment..."
	cd infrastructure/docker && docker-compose down

# Testing helpers
test-unit:
	@echo "🧪 Running unit tests only..."
	mvn test -Dtest="*Test" -DfailIfNoTests=false

test-integration:
	@echo "🔗 Running integration tests only..."
	mvn test -Dtest="*IT" -DfailIfNoTests=false

test-coverage:
	@echo "📈 Generating test coverage report..."
	mvn jacoco:report
	@echo "Coverage report available at: target/site/jacoco/index.html"

# Quality gates
quality-gate: lint test security-scan
	@echo "✅ All quality gates passed!"

# Emergency commands
rollback-staging:
	@echo "🔄 Rolling back staging deployment..."
	cd infrastructure/docker && docker-compose -f docker-compose.staging.yml down
	cd infrastructure/docker && docker-compose -f docker-compose.staging.yml up -d

rollback-prod:
	@echo "🔄 Rolling back production deployment..."
	cd infrastructure/docker && docker-compose -f docker-compose.prod.yml down
	cd infrastructure/docker && docker-compose -f docker-compose.prod.yml up -d

# Information commands
info:
	@echo "ℹ️ PAWS360 Project Information:"
	@echo "=============================="
	@echo "Version: $(shell mvn help:evaluate -Dexpression=project.version -q -DforceStdout)"
	@echo "Java Version: $(shell java -version 2>&1 | head -n 1)"
	@echo "Maven Version: $(shell mvn --version | head -n 1 | cut -d' ' -f3)"
	@echo "Docker Version: $(shell docker --version)"
	@echo "Git Branch: $(shell git rev-parse --abbrev-ref HEAD)"
	@echo "Git Commit: $(shell git rev-parse --short HEAD)"
	@echo "Build Date: $(shell date)"

# Help for specific commands
help-%:
	@echo "Help for '$*':"
	@grep -A5 -B1 "^$*:" Makefile | sed 's/^# //' | head -n10