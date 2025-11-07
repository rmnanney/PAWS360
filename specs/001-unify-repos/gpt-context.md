---
title: "PAWS360 Repository Unification - GPT Context"
last_updated: "2025-11-06"
owner: "PAWS360 Development Team"
jira_ticket: "SCRUM-70"
services: ["spring-boot", "nextjs", "postgresql", "docker-compose"]
dependencies: ["authentication", "sso", "demo-data"]
constitutional_article: "Article II - GPT-Specific Context Management"
ai_agent_instructions:
  - "Always verify both Spring Boot and Next.js services are running before testing"
  - "Use 'docker-compose up -d' for local development environment setup"
  - "Check application.properties for Spring Boot configuration"
  - "Verify Next.js builds with 'npm run build' before deployment"
  - "Common issue: Port conflicts - Spring Boot (8080), Next.js (3000), PostgreSQL (5432)"
  - "SSO integration requires proper CORS configuration in both applications"
emergency_contacts: ["development-team@paws360.com"]
---

# PAWS360 Repository Unification - GPT Context

## Implementation Overview
This context file provides comprehensive implementation details for SCRUM-70: Repository Unification Demo Feature. The goal is to create a seamless demonstration of unified PAWS360 Student Portal and Admin View with shared authentication and database.

## Technology Stack
- **Backend**: Spring Boot 3.5.x (Java 21)
- **Frontend**: Next.js (TypeScript)
- **Database**: PostgreSQL
- **Authentication**: BCrypt + SSO integration
- **Infrastructure**: Docker Compose, Ansible
- **Styling**: React, Tailwind CSS

## Current Configuration

### Spring Boot Service
- **Port**: 8080
- **Config File**: `src/main/resources/application.properties`
- **Main Class**: `com.uwm.paws360.Paws360Application`
- **Database**: PostgreSQL connection via JPA
- **Authentication**: BCrypt password hashing

### Next.js Service
- **Port**: 3000
- **Config Files**: `next.config.ts`, `tailwind.config.ts`
- **Entry Point**: `app/page.tsx`
- **API Routes**: Not yet implemented
- **Styling**: Tailwind CSS with component library

### Database Service
- **Type**: PostgreSQL
- **Schema**: `db/schema.sql`
- **Seed Data**: `db/seed.sql`
- **Connection**: Spring Boot JPA configuration

## Implementation Tasks

### Phase 1: Setup and Foundation (T001-T006)
```bash
# Initialize project structure
mkdir -p .specify/memory
mkdir -p specs/001-unify-repos

# Set up Docker Compose environment
docker-compose up -d postgres
docker-compose up -d spring-boot
docker-compose up -d nextjs
```

### Phase 2: Foundational Components (T007-T014)
```bash
# Database setup
psql -h localhost -U paws360_user -d paws360_db -f db/schema.sql
psql -h localhost -U paws360_user -d paws360_db -f db/seed.sql

# Spring Boot configuration
# Edit application.properties for database connection
# Configure BCrypt for password hashing
# Set up CORS for Next.js integration
```

### Phase 3: User Story Implementation (T015-T054)

#### Student Portal (T015-T031)
```bash
# Next.js student portal setup
cd app/
npm install
npm run dev

# Key components to verify:
# - app/login/page.tsx (authentication)
# - app/homepage/page.tsx (main interface)
# - app/components/login-form.tsx (login functionality)
```

#### Admin View (T032-T048)
```bash
# Spring Boot admin endpoints
./mvnw spring-boot:run

# Verify endpoints:
# - /api/admin/dashboard
# - /api/admin/users
# - /api/auth/login
```

#### Integration Testing (T049-T054)
```bash
# SSO flow testing
curl -X POST localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo_user","password":"demo_pass"}'

# Cross-service communication
# Verify Next.js can authenticate via Spring Boot API
```

## Common Operations

### Development Environment Setup
```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps
curl http://localhost:8080/actuator/health
curl http://localhost:3000/api/health

# View logs
docker-compose logs -f spring-boot
docker-compose logs -f nextjs
```

### Database Operations
```bash
# Connect to database
docker exec -it paws360_postgres psql -U paws360_user -d paws360_db

# Reset database
docker-compose down -v
docker-compose up -d postgres
# Re-run schema.sql and seed.sql
```

### Build and Test
```bash
# Spring Boot build
./mvnw clean package
./mvnw test

# Next.js build
npm run build
npm run test
npm run lint
```

## Troubleshooting Guide

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check what's using ports
   lsof -i :3000
   lsof -i :8080
   lsof -i :5432
   
   # Kill conflicting processes
   kill -9 <PID>
   ```

2. **Database Connection Issues**
   ```bash
   # Verify PostgreSQL is running
   docker-compose ps postgres
   
   # Check connection string in application.properties
   # Default: jdbc:postgresql://localhost:5432/paws360_db
   ```

3. **CORS Issues Between Services**
   ```bash
   # Add to Spring Boot application.properties:
   # spring.web.cors.allowed-origins=http://localhost:3000
   # spring.web.cors.allowed-methods=GET,POST,PUT,DELETE,OPTIONS
   ```

4. **Authentication Flow Problems**
   ```bash
   # Verify BCrypt configuration
   # Check user exists in database
   # Validate JWT token generation (if applicable)
   ```

5. **Build Failures**
   ```bash
   # Spring Boot build issues
   ./mvnw clean install -U
   
   # Next.js build issues
   rm -rf node_modules package-lock.json
   npm install
   ```

## Testing Requirements (Constitutional Article V)

### Unit Tests Required
- Spring Boot authentication service tests
- Next.js component tests (login-form, navigation)
- Database model tests
- Password hashing/validation tests

### Integration Tests Required
- SSO authentication flow end-to-end
- Cross-service API communication
- Database transaction integrity
- Session management across services

### Performance Tests Required
- Authentication endpoint response time (<200ms)
- Page load performance for student portal
- Database query performance
- Concurrent user handling

### Security Tests Required
- Password hashing validation
- SQL injection prevention
- XSS protection in Next.js components
- CORS configuration validation

## Monitoring Requirements (Constitutional Article VIIa)

### Metrics to Collect
- Spring Boot: Actuator endpoints (/actuator/metrics, /actuator/health)
- Next.js: Response times, error rates
- PostgreSQL: Connection pool, query performance
- Authentication: Login success/failure rates

### Dashboard Requirements
- Service health status dashboard
- Authentication metrics dashboard
- Performance monitoring dashboard
- Error rate tracking

## AI Agent Best Practices

1. **Always verify service dependencies first**
   - Check PostgreSQL is running before Spring Boot
   - Check Spring Boot is healthy before testing authentication
   - Verify both services before integration testing

2. **Use consistent error handling**
   - Check HTTP status codes for API responses
   - Validate database connections before operations
   - Handle service startup timeouts gracefully

3. **Follow constitutional requirements**
   - All work must reference SCRUM-70
   - Test-first development approach mandatory
   - Document all changes and configurations

4. **Emergency procedures**
   - If services fail: `docker-compose restart`
   - If database corrupted: Reset with schema.sql + seed.sql
   - If authentication breaks: Verify BCrypt configuration and user data

## Context File Updates Required
- Update after any configuration changes
- Update after adding new endpoints or components
- Update after infrastructure changes
- Must be kept synchronized with actual implementation

## JIRA Integration
- **Ticket**: SCRUM-70
- **Status Updates**: Update JIRA with progress on each task completion
- **Blocking Issues**: Report any constitutional compliance issues in JIRA
- **Acceptance Criteria**: Must be validated before marking complete

## Constitutional Compliance Status
- **Article I (JIRA-First)**: ✅ SCRUM-70 established
- **Article II (Context Management)**: ✅ This gpt-context.md file
- **Article V (Test-Driven Infrastructure)**: ⚠️  Test tasks need to be added to tasks.md
- **Article VIIa (Monitoring Discovery)**: ⚠️  Monitoring tasks need to be added
- **Other Articles**: Need validation during implementation

**Last Context Update**: 2025-11-06
**Next Required Update**: When implementation begins or configuration changes