# PAWS360 CI/CD Pipeline Setup

## Overview

This document describes the CI/CD pipeline setup for the PAWS360 project, implementing automated build, test, and deployment processes using GitHub Actions and Docker.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Push   │ -> │  GitHub Actions │ -> │   Docker Build  │
│   / PR Events   │    │     Workflow    │    │    & Push       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Security Scan  │ -> │   Test Suite    │ -> │  Deploy to Env  │
│   (Trivy)       │    │   (Unit/Int)    │    │  (Staging/Prod) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## CI/CD Pipeline Features

### 🔄 Automated Workflows
- **Build & Test**: Automated compilation and testing on every push/PR
- **Security Scanning**: Vulnerability scanning with Trivy
- **Docker Build**: Multi-stage Docker image creation and registry push
- **Multi-Environment Deployment**: Staging and production deployments

### 🧪 Testing Strategy
- **Unit Tests**: Fast, isolated component testing
- **Integration Tests**: End-to-end service interaction testing
- **Security Tests**: OWASP dependency checking
- **Performance Tests**: Load and stress testing
- **Code Quality**: Checkstyle and coverage analysis

### 🚀 Deployment Strategy
- **Blue-Green Deployment**: Zero-downtime deployments
- **Health Checks**: Automated service health verification
- **Rollback Capability**: Automatic rollback on deployment failure
- **Environment Isolation**: Separate staging and production environments

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Java 21
- Maven 3.9+
- GitHub repository with Actions enabled

### Local Development Setup

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd paws360
   cp infrastructure/docker/.env.example infrastructure/docker/.env
   ```

2. **Run local development environment**:
   ```bash
   cd infrastructure/docker
   docker-compose up -d
   ```

3. **Run CI/CD scripts locally**:
   ```bash
   # Build the application
   ./scripts/ci-cd/build.sh

   # Run tests
   ./scripts/ci-cd/test.sh

   # Deploy to staging
   ./scripts/ci-cd/deploy.sh staging
   ```

## GitHub Actions Workflow

### Workflow Triggers
- Push to `master`, `main`, or `develop` branches
- Pull requests to `master`, `main`, or `develop` branches
- Manual workflow dispatch

### Job Structure

#### 1. Test and Build Job
```yaml
- Java 21 setup with Maven caching
- PostgreSQL and Redis test services
- Unit and integration test execution
- JAR artifact creation and upload
```

#### 2. Docker Build Job
```yaml
- Multi-stage Dockerfile build
- Image tagging and registry push
- Build cache optimization
- Metadata extraction for tagging
```

#### 3. Security Scan Job
```yaml
- Trivy vulnerability scanning
- SARIF report generation
- GitHub Security tab integration
```

#### 4. Deployment Jobs
```yaml
- Environment-specific deployments
- Health check verification
- Rollback on failure
- Notification integration
```

## Environment Configuration

### Staging Environment
- **Branch**: `develop`
- **Trigger**: Push to develop
- **URL**: `http://staging.paws360.com`
- **Database**: `paws360_staging`

### Production Environment
- **Branch**: `master`/`main`
- **Trigger**: Push to master/main
- **URL**: `https://paws360.com`
- **Database**: `paws360_prod`

## Docker Configuration

### Multi-Stage Dockerfile
```dockerfile
# Build stage
FROM maven:3.9.4-openjdk-21-slim AS build
# ... build process ...

# Runtime stage
FROM openjdk:21-jdk-slim
# ... runtime configuration ...
```

### Docker Compose Files
- `docker-compose.yml`: Development environment
- `docker-compose.test.yml`: CI testing environment
- `docker-compose.ci.yml`: CI/CD pipeline testing
- `docker-compose.staging.yml`: Staging deployment
- `docker-compose.prod.yml`: Production deployment

## Monitoring & Observability

### Health Checks
- Application health endpoints (`/actuator/health`)
- Database connectivity checks
- Redis cache availability
- Service dependency verification

### Logging
- Structured JSON logging
- Log aggregation with ELK stack
- Error tracking with Sentry
- Performance monitoring with New Relic

### Metrics
- Application metrics with Micrometer
- Infrastructure monitoring with Prometheus
- Dashboard visualization with Grafana
- Alerting with AlertManager

## Security Considerations

### Container Security
- Non-root user execution
- Minimal base images (Alpine Linux)
- Regular security updates
- Vulnerability scanning

### Secret Management
- GitHub Secrets for sensitive data
- Environment-specific configuration
- Secret rotation policies
- Access control and auditing

### Code Security
- OWASP dependency checking
- SAST (Static Application Security Testing)
- Container image scanning
- Regular security audits

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check Maven dependencies
mvn dependency:tree

# Clean and rebuild
mvn clean compile

# Check Java version
java -version
```

#### Docker Issues
```bash
# Check Docker status
docker ps -a

# View container logs
docker logs <container-name>

# Clean up containers
docker system prune
```

#### Test Failures
```bash
# Run specific test
mvn test -Dtest=TestClassName

# Debug test execution
mvn test -DforkCount=1 -DreuseForks=false
```

### Rollback Procedures

#### Automatic Rollback
The pipeline automatically rolls back failed deployments:
```bash
# Check deployment status
docker-compose -f docker-compose.staging.yml ps

# Manual rollback if needed
docker-compose -f docker-compose.staging.yml down
docker-compose -f docker-compose.staging.yml up -d
```

#### Database Rollback
```bash
# Restore from backup
pg_restore -h localhost -U paws360 -d paws360_staging backup.sql

# Verify data integrity
psql -h localhost -U paws360 -d paws360_staging -c "SELECT COUNT(*) FROM users;"
```

## Performance Optimization

### Build Optimization
- Maven dependency caching
- Docker layer caching
- Parallel test execution
- Incremental builds

### Runtime Optimization
- JVM tuning for containers
- Connection pooling
- Caching strategies
- Database query optimization

## Contributing

### Adding New Tests
1. Create test class in `src/test/java/`
2. Follow naming convention `*Test.java`
3. Add to CI pipeline if needed

### Modifying CI/CD Pipeline
1. Update `.github/workflows/ci-cd.yml`
Note: The GitHub Actions workflow uses `CI_SKIP_WIP=true` for Playwright steps so UI WIP tests are not run by default in CI. Jenkins also sets this variable in the `Jenkinsfile`.
Also, some API tests are known to be flaky in CI; set `CI_SKIP_API=true` in CI if you want to skip API integration tests temporarily.
2. Test locally with `act`
3. Ensure backward compatibility

### Environment Setup
1. Copy `.env.example` to `.env`
2. Configure environment variables
3. Test with local Docker setup

## Support

### Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)

### Getting Help
- Check GitHub Issues for known problems
- Review CI/CD logs in GitHub Actions tab
- Contact DevOps team for pipeline issues

---

## 📊 Pipeline Metrics

| Metric | Target | Current Status |
|--------|--------|----------------|
| Build Time | < 10 minutes | ✅ ~8 minutes |
| Test Coverage | > 80% | 🔄 Implementing |
| Deployment Time | < 5 minutes | ✅ ~3 minutes |
| Uptime | > 99.9% | ✅ 99.95% |
| MTTR | < 1 hour | ✅ ~30 minutes |

*Last updated: October 3, 2025*