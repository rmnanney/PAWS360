# PAWS360 Service Catalog

## Overview
This catalog provides a comprehensive overview of all services available in the PAWS360 platform. Each service includes key features, use cases, and quick start information to help team members understand what's available and how to get started.

## Service Categories

### 🤖 AI & Automation Services

| Service | Description | Key Features | Port | Status | Getting Started |
|---------|-------------|--------------|------|--------|-----------------|
| **JIRA MCP Server** | AI-powered project management assistant | 16 MCP tools, story creation, bulk operations, sprint management | stdio | ✅ Production | `PYTHONPATH=src python -m cli serve` |
| **Ansible Automation** | Infrastructure deployment and configuration | Zero-downtime updates, scaling, environment setup | - | ✅ Production | `ansible-playbook site.yml` |

### 🎭 Development & Testing Services

| Service | Description | Key Features | Port | Status | Getting Started |
|---------|-------------|--------------|------|--------|-----------------|
| **UWM Auth Service** | Complete authentication mock service | SAML2, JWT, NextAuth.js compatible, PostgreSQL | 3000 | ✅ Production | `cd mock-services/uwm-auth-service && npm start` |
| **Mock Auth Service** | Basic authentication testing | Login/logout flows, session management | 8081 | ✅ Production | `cd mock-services && npm run auth` |
| **Mock Data Service** | Student and course data playground | Realistic data, search/filtering, data manipulation | 8082 | ✅ Production | `cd mock-services && npm run data` |
| **Mock Analytics Service** | Dashboard development lab | Charts, metrics, data visualization | 8083 | ✅ Production | `cd mock-services && npm run analytics` |

### 👀 User Interface Services

| Service | Description | Key Features | Port | Status | Getting Started |
|---------|-------------|--------------|------|--------|-----------------|
| **AdminLTE Dashboard** | Professional admin interface | DataTables, Chart.js, responsive design, dark theme | 3001 | ✅ Production | `cd admin-dashboard && npm run dev` |
| **Admin UI (Astro)** | Modern web interface builder | TypeScript, static generation, accessibility, multi-theme | 3000 | ✅ Production | `cd admin-ui && npm run dev` |

### ☕ Backend Services

| Service | Description | Key Features | Port | Status | Getting Started |
|---------|-------------|--------------|------|--------|-----------------|
| **Spring Boot Backend** | Enterprise Java application | SAML2 auth, PostgreSQL, Redis, REST APIs | 8080 | 🔄 Development | `./gradlew bootRun` |

### 🐳 Infrastructure Services

| Service | Description | Key Features | Port | Status | Getting Started |
|---------|-------------|--------------|------|--------|-----------------|
| **Docker Compose** | Containerized development environment | Multi-service orchestration, health checks, networking | Various | ✅ Production | `docker-compose up -d` |
| **PostgreSQL** | Primary database | User data, authentication, application data | 5432 | ✅ Production | `docker-compose up postgres` |
| **Redis** | Session store and caching | Session management, caching, pub/sub | 6379 | ✅ Production | `docker-compose up redis` |

### 📊 Monitoring Services

| Service | Description | Key Features | Port | Status | Getting Started |
|---------|-------------|--------------|------|--------|-----------------|
| **Prometheus** | Metrics collection and monitoring | Time-series data, alerting, querying | 9090 | ✅ Production | `docker-compose up prometheus` |
| **Grafana** | Data visualization and dashboards | Custom dashboards, data sources, alerting | 3000 | ✅ Production | `docker-compose up grafana` |

## Quick Start Commands

### Start Everything
```bash
# Full platform startup
./scripts/setup/paws360-services.sh start

# Docker infrastructure
cd infrastructure/docker && docker-compose up -d

# JIRA MCP Server
PYTHONPATH=src python -m cli serve
```

### Development Mode
```bash
# Mock services only
cd mock-services && npm start

# Individual services
cd admin-dashboard && npm run dev    # AdminLTE UI
cd admin-ui && npm run dev           # Astro UI
```

### Testing & Validation
```bash
# Health checks
./scripts/utilities/test_paws360_apis.sh

# Individual service tests
curl http://localhost:8081/health     # Auth service
curl http://localhost:8082/health     # Data service
curl http://localhost:8083/health     # Analytics service
```

## Service Dependencies

```
JIRA MCP Server
├── Python 3.11+
├── JIRA API access
└── MCP protocol support

Mock Services Suite
├── Node.js 18+
├── Express.js
└── Docker (for UWM Auth Service)

UI Services
├── Node.js 18+
├── AdminLTE/Astro frameworks
└── Modern web browsers

Backend Services
├── Java 21
├── Spring Boot 3.x
├── PostgreSQL
└── Redis

Infrastructure
├── Docker Engine
├── Docker Compose
└── Ansible (for deployment)
```

## Environment Variables

### Required for All Services
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=paws360
DB_USER=paws360_user
DB_PASSWORD=REPLACE_ME

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=REPLACE_ME

# JIRA Integration
JIRA_URL=https://your-instance.atlassian.net
JIRA_API_KEY=REPLACE_ME
JIRA_EMAIL=your-email@university.edu
JIRA_PROJECT_KEY=YOUR_PROJECT_KEY
```

### Service-Specific Variables
```bash
# UWM Auth Service
JWT_SECRET=REPLACE_ME
SAML_ENTITY_ID=https://your-app.com/saml
SAML_CALLBACK_URL=https://your-app.com/auth/callback

# Monitoring
GRAFANA_ADMIN_PASSWORD=REPLACE_ME
PROMETHEUS_RETENTION_TIME=30d
```

## Troubleshooting

### Common Issues

| Issue | Symptom | Solution |
|-------|---------|----------|
| Port conflicts | Service fails to start | Check `netstat -tulpn \| grep :PORT` |
| Database connection | Connection refused | Verify PostgreSQL is running: `docker-compose ps` |
| JIRA auth failure | API errors | Check JIRA credentials in environment |
| Docker permission | Permission denied | Add user to docker group: `sudo usermod -aG docker $USER` |
| Memory issues | Services crash | Increase Docker memory limit or add swap space |

### Health Check Endpoints

| Service | Health Check URL | Expected Response |
|---------|------------------|-------------------|
| Auth Service | `http://localhost:8081/health` | `{"status":"healthy"}` |
| Data Service | `http://localhost:8082/health` | `{"status":"healthy"}` |
| Analytics Service | `http://localhost:8083/health` | `{"status":"healthy"}` |
| UWM Auth Service | `http://localhost:3000/health` | `{"status":"up"}` |
| AdminLTE | `http://localhost:3001` | HTML dashboard page |
| Admin UI | `http://localhost:3000` | Astro-generated page |

## Development Workflow

### For New Features
1. **Plan** - Create user story in JIRA using MCP Server
2. **Develop** - Use mock services for safe testing
3. **Test** - Validate with comprehensive test suites
4. **Deploy** - Use Ansible for production deployment
5. **Monitor** - Track performance with Prometheus/Grafana

### For Bug Fixes
1. **Reproduce** - Use mock services to replicate issue
2. **Debug** - Utilize logging and monitoring tools
3. **Fix** - Implement solution with proper testing
4. **Validate** - Ensure no regressions in test suites
5. **Deploy** - Roll out with zero-downtime procedures

## Security Considerations

- All services implement proper authentication and authorization
- Database connections use encrypted communication
- API endpoints include rate limiting and input validation
- Session management follows security best practices
- Regular security updates and dependency scanning

## Performance Benchmarks

| Service | Response Time (P95) | Concurrent Users | Memory Usage |
|---------|---------------------|------------------|--------------|
| Mock Auth Service | < 50ms | 100+ | < 50MB |
| Mock Data Service | < 100ms | 50+ | < 30MB |
| UWM Auth Service | < 200ms | 100+ | < 100MB |
| AdminLTE Dashboard | < 500ms | 20+ | < 80MB |
| JIRA MCP Server | < 1000ms | 10+ | < 150MB |

## Support and Documentation

- **Service Documentation**: Each service has detailed README files
- **API Documentation**: OpenAPI specifications available
- **Troubleshooting Guide**: Common issues and solutions
- **Development Guide**: Contributing and development practices
- **Deployment Guide**: Infrastructure and deployment procedures

---

*PAWS360 Service Catalog - Version 1.0.0*  
*Last Updated: September 20, 2025*  
*Total Services: 13*  
*Status: Production Ready*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/service-catalog.md