# PAWS360 CI/CD Pipeline Documentation

## Table of Contents
1. [Overview](#overview)
2. [Pipeline Architecture](#pipeline-architecture)
3. [GitHub Actions Workflows](#github-actions-workflows)
4. [Docker Containerization](#docker-containerization)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Monitoring and Observability](#monitoring-and-observability)
7. [Security Scanning](#security-scanning)
8. [Deployment Procedures](#deployment-procedures)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Overview

The PAWS360 CI/CD pipeline provides automated build, test, security scanning, and deployment capabilities using GitHub Actions, Docker, and Kubernetes.

### Key Features
- ✅ Automated testing with >80% code coverage
- ✅ Multi-stage Docker builds for optimized images
- ✅ Security vulnerability scanning with Trivy
- ✅ Automated deployments to staging and production
- ✅ Health checks and service verification
- ✅ Prometheus metrics and Grafana dashboards
- ✅ Horizontal Pod Autoscaling (HPA)
- ✅ Zero-downtime rolling updates

## Pipeline Architecture

```
┌─────────────┐
│   Git Push  │
└──────┬──────┘
       │
       ├─────────────────────────────────────────┐
       │                                         │
       ▼                                         ▼
┌─────────────────┐                    ┌─────────────────┐
│  Test & Build   │                    │  Code Quality   │
│  - Unit Tests   │                    │  - Linting      │
│  - Integration  │                    │  - Coverage     │
│  - Package      │                    │  - Security     │
└────────┬────────┘                    └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Docker Build   │
│  - Multi-stage  │
│  - Optimize     │
│  - Push to GHCR │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  UI Tests    │   │  Security    │   │  E2E Tests   │
│  - Playwright│   │  - Trivy     │   │  - Postman   │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       └──────────────────┴──────────────────┘
                          │
       ┌──────────────────┴──────────────────┐
       │                                     │
       ▼                                     ▼
┌─────────────────┐                 ┌─────────────────┐
│  Deploy Staging │                 │  Deploy Prod    │
│  - Automatic    │                 │  - Manual Gate  │
│  - Health Check │                 │  - Blue/Green   │
└─────────────────┘                 └─────────────────┘
```

## GitHub Actions Workflows

### Main CI/CD Workflow (.github/workflows/ci-cd.yml)

The workflow consists of the following jobs:

#### 1. Test and Build
```yaml
- Checkout code
- Set up JDK 21
- Cache Maven dependencies
- Run unit and integration tests
- Generate JaCoCo coverage report
- Package application
- Upload artifacts
```

**Triggers:**
- Push to: `main`, `master`, `develop`, feature branches
- Pull requests to: `main`, `master`, `develop`

**Environment:**
- PostgreSQL 15
- Redis 7
- JDK 21 (Temurin)

#### 2. Docker Build
```yaml
- Download build artifacts
- Login to GitHub Container Registry
- Build multi-stage Docker image
- Push to GHCR with multiple tags
- Cache layers for faster builds
```

**Image Tags:**
- `latest` (main/master branch)
- `branch-name` (feature branches)
- `pr-number` (pull requests)
- `sha-<commit>` (specific commit)

#### 3. UI Tests
```yaml
- Set up Node.js 18
- Install Playwright
- Start application with docker-compose
- Run UI tests
- Upload test results and screenshots
```

#### 4. Security Scan
```yaml
- Run Trivy vulnerability scanner
- Check for CVEs in dependencies
- Scan container images
- Upload results to GitHub Security tab
```

#### 5. Deploy Staging
```yaml
- Automatic deployment on develop branch
- Health checks after deployment
- Smoke tests
```

#### 6. Deploy Production
```yaml
- Manual approval required
- Deploy to production on main/master
- Rolling update with zero downtime
- Automatic rollback on failure
```

## Docker Containerization

### Multi-Stage Dockerfile

The application uses a multi-stage Dockerfile for optimized builds:

**Stage 1: Build**
- Base: `maven:3.9.11-eclipse-temurin-21`
- Download dependencies (cached)
- Compile and package application
- Run tests (if enabled)

**Stage 2: Runtime**
- Base: `openjdk:21-jdk-slim`
- Install curl for health checks
- Create non-root user (`paws360`)
- Copy JAR from build stage
- Configure health checks
- Expose port 8080

**Best Practices:**
- ✅ Layer caching for dependencies
- ✅ Non-root user for security
- ✅ Minimal runtime image
- ✅ Health check configuration
- ✅ Multi-architecture support

### Building Locally

```bash
# Build image
docker build -f infrastructure/docker/Dockerfile -t paws360:latest .

# Run container
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=docker \
  -e DATABASE_URL=jdbc:postgresql://host:5432/paws360 \
  paws360:latest

# Check health
curl http://localhost:8080/actuator/health
```

### Docker Compose for CI

See `docker-compose.ci.yml` for the complete stack including:
- PAWS360 Application
- PostgreSQL Database
- Redis Cache

## Kubernetes Deployment

### Architecture Overview

```
┌──────────────────────────────────────────────┐
│                 Ingress                      │
│         (nginx-ingress-controller)           │
└─────────────────┬────────────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
         ▼                 ▼
┌──────────────┐  ┌──────────────┐
│ LoadBalancer │  │   Service    │
│   (External) │  │  (ClusterIP) │
└──────┬───────┘  └──────┬───────┘
       │                 │
       └────────┬────────┘
                │
    ┌───────────┴───────────┐
    │                       │
    ▼                       ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│  Pod 1  │  │  Pod 2  │  │  Pod 3  │
│ App     │  │  App    │  │  App    │
└────┬────┘  └────┬────┘  └────┬────┘
     │            │            │
     └────────────┴────────────┘
                  │
     ┌────────────┼────────────┐
     │                         │
     ▼                         ▼
┌──────────────┐        ┌──────────────┐
│  PostgreSQL  │        │    Redis     │
│ (StatefulSet)│        │(StatefulSet) │
└──────────────┘        └──────────────┘
```

### Kubernetes Resources

Located in `infrastructure/kubernetes/`:

1. **namespace.yaml** - Namespace isolation
2. **configmap.yaml** - Application configuration
3. **secrets.yaml** - Sensitive data (passwords, tokens)
4. **deployment.yaml** - Application deployment (3 replicas)
5. **service.yaml** - Service discovery
6. **ingress.yaml** - External access and TLS
7. **hpa.yaml** - Horizontal Pod Autoscaler
8. **rbac.yaml** - Role-Based Access Control
9. **resource-limits.yaml** - Resource quotas and limits
10. **postgres.yaml** - PostgreSQL StatefulSet
11. **redis.yaml** - Redis StatefulSet

### Deployment Script

Use the automated deployment script:

```bash
# Deploy to Kubernetes
./scripts/deploy-kubernetes.sh

# Or manually apply resources
kubectl apply -f infrastructure/kubernetes/namespace.yaml
kubectl apply -f infrastructure/kubernetes/rbac.yaml
kubectl apply -f infrastructure/kubernetes/configmap.yaml
kubectl apply -f infrastructure/kubernetes/secrets.yaml
kubectl apply -f infrastructure/kubernetes/postgres.yaml
kubectl apply -f infrastructure/kubernetes/redis.yaml
kubectl apply -f infrastructure/kubernetes/deployment.yaml
kubectl apply -f infrastructure/kubernetes/service.yaml
kubectl apply -f infrastructure/kubernetes/ingress.yaml
kubectl apply -f infrastructure/kubernetes/hpa.yaml
```

### Scaling

**Horizontal Pod Autoscaler (HPA):**
- Min replicas: 3
- Max replicas: 10
- Target CPU: 70%
- Target Memory: 80%

**Manual Scaling:**
```bash
# Scale to 5 replicas
kubectl scale deployment paws360-app --replicas=5 -n paws360

# Check HPA status
kubectl get hpa -n paws360
```

## Monitoring and Observability

### Health Endpoints

- **Liveness Probe:** `/actuator/health/liveness`
- **Readiness Probe:** `/actuator/health/readiness`
- **Full Health:** `/actuator/health`
- **Metrics:** `/actuator/prometheus`
- **Info:** `/actuator/info`

### Prometheus Metrics

The application exposes metrics at `/actuator/prometheus`:

- HTTP request rates and latencies
- JVM memory and GC metrics
- Database connection pool stats
- Custom business metrics
- Thread pool statistics

### Grafana Dashboards

Import `infrastructure/kubernetes/monitoring/grafana-dashboard.json`:

**Panels:**
1. Request Rate
2. Response Time (p95, p99)
3. Memory Usage
4. CPU Usage
5. Service Health
6. Pod Replicas
7. Error Rate
8. Database Connections

### Alerts

Configured in `prometheus-rules.yaml`:

- High error rate (>5% 5xx responses)
- High response time (p95 > 2s)
- Pod down for >2 minutes
- High memory usage (>90%)
- High CPU usage (>90%)
- Database connection errors
- Low pod replicas (<2)

## Security Scanning

### Trivy Vulnerability Scanner

**Automated Scanning:**
- Runs on every PR and push
- Scans filesystem and container images
- Reports to GitHub Security tab
- Blocks deployment on critical vulnerabilities

**Manual Scanning:**
```bash
# Scan project files
trivy fs .

# Scan Docker image
trivy image ghcr.io/zackhawkins/paws360:latest

# Scan with specific severity
trivy image --severity HIGH,CRITICAL paws360:latest
```

### Dependency Scanning

Maven dependency check runs during build:

```bash
# Run dependency check
mvn dependency-check:check

# View report
open target/dependency-check-report.html
```

### Security Best Practices

- ✅ Non-root container user
- ✅ Read-only root filesystem (where possible)
- ✅ Security scanning in CI/CD
- ✅ Secrets management with Kubernetes Secrets
- ✅ TLS/SSL for all external communication
- ✅ Network policies for pod communication
- ✅ RBAC for access control
- ✅ Regular dependency updates

## Deployment Procedures

### Staging Deployment

**Automatic on `develop` branch:**

1. Code merged to `develop`
2. CI/CD pipeline runs
3. All tests pass
4. Security scan passes
5. Automatic deployment to staging
6. Health checks verify deployment
7. Smoke tests run

### Production Deployment

**Manual approval required:**

1. Code merged to `main/master`
2. CI/CD pipeline runs
3. All quality gates pass
4. Manual approval in GitHub Actions
5. Rolling update to production
6. Health checks at each step
7. Automatic rollback on failure

**Rollback Procedure:**

```bash
# View deployment history
kubectl rollout history deployment/paws360-app -n paws360

# Rollback to previous version
kubectl rollout undo deployment/paws360-app -n paws360

# Rollback to specific revision
kubectl rollout undo deployment/paws360-app --to-revision=3 -n paws360
```

### Blue/Green Deployment

For zero-downtime deployments:

1. Deploy new version (green) alongside current (blue)
2. Run smoke tests on green
3. Switch traffic to green
4. Monitor for issues
5. Keep blue for quick rollback
6. Decommission blue after verification

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Issue:** Maven build fails
```bash
# Check logs
kubectl logs -f deployment/paws360-app -n paws360

# Debug locally
mvn clean install -X
```

#### 2. Container Crashes

**Issue:** Pods keep restarting
```bash
# Check pod status
kubectl get pods -n paws360

# View logs
kubectl logs <pod-name> -n paws360 --previous

# Describe pod for events
kubectl describe pod <pod-name> -n paws360
```

#### 3. Database Connection Issues

**Issue:** Can't connect to PostgreSQL
```bash
# Check database pod
kubectl get pod -l component=database -n paws360

# Test connection
kubectl exec -it <pod-name> -n paws360 -- psql -U paws360 -d paws360_prod

# Check service
kubectl get svc paws360-postgres -n paws360
```

#### 4. Health Check Failures

**Issue:** Health checks failing
```bash
# Port forward to pod
kubectl port-forward <pod-name> 8080:8080 -n paws360

# Check health endpoint
curl http://localhost:8080/actuator/health

# View detailed health
curl http://localhost:8080/actuator/health | jq
```

#### 5. Ingress Not Working

**Issue:** Cannot access application externally
```bash
# Check ingress
kubectl get ingress -n paws360

# Describe ingress
kubectl describe ingress paws360-ingress -n paws360

# Check ingress controller
kubectl get pods -n ingress-nginx
```

### Debugging Commands

```bash
# View all resources
kubectl get all -n paws360

# Check events
kubectl get events -n paws360 --sort-by='.lastTimestamp'

# View logs with labels
kubectl logs -l app=paws360 -n paws360 --tail=100

# Execute shell in pod
kubectl exec -it <pod-name> -n paws360 -- /bin/bash

# Port forward for debugging
kubectl port-forward svc/paws360-app 8080:8080 -n paws360

# View resource usage
kubectl top pods -n paws360
kubectl top nodes
```

## Best Practices

### Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/SCRUM-XX-description
   ```

2. **Make changes and test locally**
   ```bash
   mvn test
   docker build -t paws360:test .
   docker-compose up
   ```

3. **Commit and push**
   ```bash
   git add .
   git commit -m "SCRUM-XX: Description"
   git push origin feature/SCRUM-XX-description
   ```

4. **Create Pull Request**
   - CI/CD runs automatically
   - Review test results
   - Check security scan
   - Wait for approval

5. **Merge to develop**
   - Automatic staging deployment
   - Verify in staging environment

6. **Merge to main**
   - Request production deployment approval
   - Monitor deployment
   - Verify in production

### Code Quality

- ✅ Maintain >80% test coverage
- ✅ Follow Java coding standards
- ✅ Write meaningful commit messages
- ✅ Keep PRs small and focused
- ✅ Update documentation
- ✅ Fix security vulnerabilities
- ✅ Review dependency updates

### Infrastructure as Code

- ✅ Version control all configs
- ✅ Use declarative configurations
- ✅ Document all resources
- ✅ Test configurations locally
- ✅ Use namespaces for isolation
- ✅ Implement RBAC
- ✅ Regular backups

### Security

- ✅ Rotate secrets regularly
- ✅ Use least privilege access
- ✅ Enable audit logging
- ✅ Keep dependencies updated
- ✅ Scan for vulnerabilities
- ✅ Use TLS everywhere
- ✅ Implement network policies

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/reference/actuator/index.html)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Last Updated:** October 2025
**Version:** 1.0
**Maintained by:** PAWS360 DevOps Team
