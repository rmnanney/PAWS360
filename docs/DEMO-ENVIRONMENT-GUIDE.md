# PAWS360 Demo Environment - Complete Setup and Testing Guide

**Version**: 2.0  
**Created**: November 2024  
**Status**: Production Ready  
**Constitutional Compliance**: ✅ Article V (Test-Driven Infrastructure) + Article VIIa (Monitoring Discovery and Integration)

## 🎯 Overview

This guide provides comprehensive instructions for setting up, testing, and executing the PAWS360 demo environment. The implementation includes automated demo data management, health validation, and end-to-end flow testing to ensure successful demonstrations.

## 📋 Demo Infrastructure Components

### Core Services
- **Spring Boot Backend** (Port 8081): Authentication, API, and data services
- **Next.js Frontend** (Port 3000): Student portal and user interface
- **PostgreSQL Database** (Port 5432): Demo data and user management
- **Demo Data Service**: Automated data reset and validation
- **Health Monitoring**: Comprehensive system health checks

### New Demo Management Features
- **Automated Data Reset**: Reset to baseline state between demos
- **Health Validation**: 21-point validation system
- **Demo Startup Script**: One-command environment initialization
- **Constitutional Compliance**: Full testing and monitoring infrastructure

## 🚀 Quick Start Guide

### Prerequisites
- Docker and Docker Compose
- Java 21+
- Node.js 18+
- PostgreSQL (or Docker)
- Git

### One-Command Demo Launch
```bash
# Complete demo environment startup
cd /home/ryan/repos/PAWS360
./scripts/start-demo.sh

# Alternative: Development mode with hot reload
./scripts/start-demo.sh --dev

# Reset data before starting
./scripts/start-demo.sh --reset
```

### Manual Setup (Alternative)
```bash
# 1. Start database
docker run -d \
  --name paws360-postgres \
  -e POSTGRES_DB=paws360 \
  -e POSTGRES_USER=paws360_app \
  -e POSTGRES_PASSWORD=paws360_password \
  -p 5432:5432 \
  -v ./database/enhanced_demo_seed_data.sql:/docker-entrypoint-initdb.d/01-seed.sql:ro \
  postgres:15-alpine

# 2. Start backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=demo

# 3. Start frontend (separate terminal)
npm install && npm run dev
```

## 🔑 Demo Credentials

All demo accounts use the password **`password123`**

| Role | Email | Description |
|------|-------|-------------|
| **Administrator** | `admin@uwm.edu` | Full system access, admin dashboard |
| **Primary Student** | `john.smith@uwm.edu` | Computer Science student, main demo account |
| **Demo Student** | `demo.student@uwm.edu` | Simple demo account for quick testing |
| **Test Student** | `emily.johnson@uwm.edu` | Psychology student, secondary demo account |
| **Professor** | `jane.professor@uwm.edu` | Faculty access for instructor features |

## 🎬 Demo Execution Flow

### Phase 1: Environment Validation (5 minutes)
```bash
# Quick validation
./scripts/validate-demo.sh --quick

# Comprehensive validation
./scripts/validate-demo.sh --deep

# Get validation in JSON format
./scripts/validate-demo.sh --json
```

**Expected Results:**
- ✅ All infrastructure checks pass
- ✅ Demo data validation successful
- ✅ Authentication endpoints responding
- ✅ 95%+ validation success rate

### Phase 2: Student Portal Demonstration (10 minutes)

1. **Navigate to Frontend**
   ```
   URL: http://localhost:3000
   Expected: Automatic redirect to /login
   ```

2. **Student Authentication**
   ```
   Email: john.smith@uwm.edu
   Password: password123
   Expected: Redirect to /homepage with welcome message
   ```

3. **Dashboard Navigation**
   - Verify student profile information
   - Navigate between different sections
   - Confirm session persistence
   - Test logout functionality

4. **Data Consistency Check**
   ```bash
   # Verify student data via API
   curl -X POST http://localhost:8081/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"john.smith@uwm.edu","password":"password123"}'
   ```

### Phase 3: Administrative Access (10 minutes)

1. **Admin Authentication**
   ```
   Email: admin@uwm.edu
   Password: password123
   Expected: Admin dashboard access
   ```

2. **Student Data Verification**
   - Search for student "John Smith"
   - Verify data matches portal information
   - Check academic records consistency
   - Validate demographics and contact info

3. **Cross-System Validation**
   ```bash
   # Check data consistency via demo API
   curl http://localhost:8081/demo/validate
   
   # Get demo status
   curl http://localhost:8081/demo/status
   ```

### Phase 4: Single Sign-On Demonstration (5 minutes)

1. **Session Persistence Test**
   - Login as student in one tab
   - Open admin view in another tab
   - Verify no re-authentication required
   - Test session sharing across modules

2. **Session Management**
   ```bash
   # Check active sessions
   curl http://localhost:8081/health/sessions
   
   # Validate session health
   curl http://localhost:8081/health/authentication
   ```

## 🔧 Demo Management Operations

### Data Reset and Initialization
```bash
# API-based reset (preferred)
curl -X POST http://localhost:8081/demo/reset

# Database-level reset
psql -h localhost -U paws360_app -d paws360 -f database/demo_reset.sql
psql -h localhost -U paws360_app -d paws360 -f database/enhanced_demo_seed_data.sql

# Full environment reset
./scripts/start-demo.sh --reset
```

### Health Monitoring
```bash
# System health check
curl http://localhost:8081/health/status

# Demo readiness check
curl http://localhost:8081/demo/ready

# Database health
curl http://localhost:8081/health/database

# Frontend connectivity
curl http://localhost:3000
```

### Performance Validation
```bash
# Backend response time
time curl http://localhost:8081/health/ping

# Frontend load time
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000
```

## 🧪 Complete Demo Flow Testing

### Test Scenario 1: Clean Environment to Operational
```bash
# 1. Start from clean state
docker stop paws360-postgres && docker rm paws360-postgres
pkill -f "spring-boot" || true
pkill -f "next" || true

# 2. Run automated startup
./scripts/start-demo.sh

# 3. Validate environment
./scripts/validate-demo.sh --deep

# 4. Expected results:
# - All services running within 5 minutes
# - 100% validation success rate
# - Demo credentials working
# - Data consistency verified
```

### Test Scenario 2: Demo Data Reset and Repeatability
```bash
# 1. Corrupt demo data (simulate usage)
curl -X POST http://localhost:8081/auth/login \
  -d '{"email":"john.smith@uwm.edu","password":"wrongpassword"}'

# 2. Reset demo data
curl -X POST http://localhost:8081/demo/reset

# 3. Validate reset
curl http://localhost:8081/demo/validate

# 4. Test fresh login
curl -X POST http://localhost:8081/auth/login \
  -d '{"email":"john.smith@uwm.edu","password":"password123"}'
```

### Test Scenario 3: Multi-User Concurrent Access
```bash
# 1. Login as admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@uwm.edu","password":"password123"}' | \
  grep -o '"token":"[^"]*' | cut -d'"' -f4)

# 2. Login as student
STUDENT_TOKEN=$(curl -s -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john.smith@uwm.edu","password":"password123"}' | \
  grep -o '"token":"[^"]*' | cut -d'"' -f4)

# 3. Verify concurrent access
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8081/user/profile

curl -H "Authorization: Bearer $STUDENT_TOKEN" \
  http://localhost:8081/user/profile

# 4. Check session management
curl http://localhost:8081/health/sessions
```

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### Services Won't Start
```bash
# Check port conflicts
sudo lsof -i :3000 -i :8081 -i :5432

# Check Docker status
docker ps
docker logs paws360-postgres

# Check application logs
tail -f backend.log frontend.log
```

#### Database Connection Issues
```bash
# Verify database is running
docker exec paws360-postgres pg_isready -U paws360_app -d paws360

# Check demo data
docker exec paws360-postgres psql -U paws360_app -d paws360 \
  -c "SELECT email, role FROM users WHERE email LIKE '%@uwm.edu';"

# Reset database
docker restart paws360-postgres
```

#### Authentication Problems
```bash
# Test login endpoint
curl -v -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john.smith@uwm.edu","password":"password123"}'

# Check CORS settings
curl -H "Origin: http://localhost:3000" \
  -I http://localhost:8081/auth/login

# Verify user accounts
curl http://localhost:8081/demo/accounts
```

#### Frontend Issues
```bash
# Check frontend logs
docker logs paws360-frontend || tail -f frontend.log

# Verify API connectivity
curl http://localhost:3000/api/health

# Check environment variables
env | grep -E "(NEXT_|API_)"
```

### Emergency Recovery Procedures

#### Demo Failure During Presentation
1. **Quick Recovery**
   ```bash
   # Reset everything quickly
   ./scripts/start-demo.sh --reset
   ```

2. **Fallback Screenshots**
   - Use pre-validated screenshots from `docs/demo-screenshots/`
   - Reference recorded demo video for visual backup

3. **Manual Demonstration**
   ```bash
   # Show data consistency via direct queries
   docker exec paws360-postgres psql -U paws360_app -d paws360 \
     -c "SELECT firstname, lastname, email, role FROM users WHERE email = 'john.smith@uwm.edu';"
   ```

#### Complete Environment Failure
1. **Local Database Reset**
   ```bash
   docker stop paws360-postgres
   docker run --rm -d --name paws360-recovery \
     -e POSTGRES_DB=paws360 \
     -e POSTGRES_USER=paws360_app \
     -e POSTGRES_PASSWORD=paws360_password \
     -p 5433:5432 postgres:15-alpine
   ```

2. **Alternative Demo Environment**
   ```bash
   # Use CI environment as backup
   docker-compose -f docker-compose.ci.yml up -d
   ```

## 📊 Success Criteria Validation

### Automated Validation Checklist
- [ ] Environment starts in <15 minutes
- [ ] All health checks pass (21/21)
- [ ] Demo accounts authenticate successfully
- [ ] Data consistency between portal and admin view
- [ ] SSO works with <5 second navigation
- [ ] Session persists for 30+ minutes
- [ ] Reset operation completes successfully
- [ ] 95%+ user interactions work without errors

### Manual Validation Checklist
- [ ] Student can log in and see dashboard
- [ ] Admin can log in and search students
- [ ] Data matches between student view and admin view
- [ ] Navigation works without re-authentication
- [ ] All demo credentials work as expected
- [ ] Error handling provides user-friendly messages
- [ ] Performance meets demo requirements (<2s page loads)

## 📈 Performance Benchmarks

### Expected Performance Metrics
- **Backend Response Time**: <200ms for health checks
- **Frontend Load Time**: <2s for initial page load
- **Authentication**: <1s for login processing
- **Database Queries**: <100ms for user lookups
- **Demo Data Reset**: <30s for complete reset

### Monitoring Integration
```bash
# Check constitutional compliance monitoring
curl http://localhost:9090/api/v1/query?query=paws360_frontend_web_vital

# Verify monitoring stack
docker ps | grep -E "(prometheus|grafana|alertmanager)"

# Access monitoring dashboards
# Grafana: http://localhost:3001/d/paws360-frontend
# Prometheus: http://localhost:9090
```

## 🔐 Security Considerations

### Demo Environment Security
- All demo passwords are consistent (`password123`)
- No real user data in demo environment
- Database is isolated and containerized
- Session tokens have appropriate expiration
- CORS configured for demo origins only

### Production Considerations
- Change all demo passwords before production
- Use environment-specific configuration
- Enable proper SSL/TLS certificates
- Configure production database credentials
- Review and update CORS origins

## 📚 Additional Resources

### Documentation Links
- [Constitutional Compliance Report](docs/constitutional-compliance/CONSTITUTIONAL-COMPLIANCE-ACHIEVEMENT.md)
- [Task Implementation Summary](T055-IMPLEMENTATION-SUMMARY.md)
- [Performance Testing Results](T058-PERFORMANCE-COMPLETION-REPORT.md)
- [Security Testing Results](T059-SECURITY-COMPLETION-REPORT.md)

### API Documentation
- Backend API: `http://localhost:8081/swagger-ui/` (if enabled)
- Demo Management: `http://localhost:8081/demo/info`
- Health Endpoints: `http://localhost:8081/health/`

### Support Contacts
- **Technical Issues**: Development team
- **Demo Script Questions**: Product team
- **Emergency Support**: On-call engineer

---

**Demo Environment Version**: 2.0  
**Last Updated**: November 2024  
**Constitutional Compliance**: Fully Achieved (Article V + Article VIIa)  
**Status**: Production Ready for Demonstration