# Quickstart Guide: Repository Unification

**Date**: November 6, 2024  
**Phase**: Phase 1 - Design & Architecture  
**Spec**: [001-unify-repos](./spec.md)  
**Time Required**: <30 minutes total setup

## 🚀 Quick Demo Launch

### One-Command Demo Startup
```bash
# Complete demo environment launch
cd /home/ryan/repos/PAWS360 && docker-compose up -d
```

**What This Does:**
- Launches PostgreSQL database with seed data
- Starts Spring Boot backend (port 8081) 
- Starts Next.js frontend (port 3000)
- Configures networking between services
- **Demo ready in <5 minutes**

## 📋 Prerequisites

### ✅ System Requirements (Verified)
- ✅ **Docker**: 24.x.x (Available)
- ✅ **Docker Compose**: 2.x.x (Available)
- ✅ **Java**: 21.0.8 (Ready)
- ✅ **Maven**: 3.9.11 (Ready)
- ✅ **Node.js**: 18.20.8 (Ready)
- ✅ **Repository**: All dependencies resolved

## 🎬 Demo Execution Flows

### Complete Demo Setup (Recommended)
```bash
# Full environment with monitoring
cd /home/ryan/repos/PAWS360

# Start all services
docker-compose -f docker-compose.yml up -d

# Verify services are running  
docker-compose ps

# View logs (optional)
docker-compose logs -f frontend backend database

# Demo ready at:
# Frontend: http://localhost:3000
# Backend API: http://localhost:8081
# Database: localhost:5432 (internal only)
```

### Development Mode Setup
```bash
# For active development with hot reload
cd /home/ryan/repos/PAWS360

# Start infrastructure only
docker-compose up -d database

# Run backend locally (terminal 1)
./mvnw spring-boot:run -Dspring-boot.run.profiles=development

# Run frontend locally (terminal 2) 
npm run dev

# Services running at:
# Frontend: http://localhost:3000 (hot reload)
# Backend: http://localhost:8081 (Spring DevTools)
# Database: docker container
```

### Health Verification
```bash
# Check backend health (NEW - to be implemented)
curl http://localhost:8081/health

# Expected response: {"status":"UP","components":{...}}

# Check database connectivity
docker-compose exec database psql -U paws360_app -d paws360 -c "SELECT COUNT(*) FROM users;"

# Verify frontend accessibility
curl -I http://localhost:3000
```

### Access Points
1. **Student Portal**: http://localhost:3000
2. **Backend API**: http://localhost:8081/login (REST endpoints)
3. **Database**: Internal container networking only

## 🔑 Demo User Accounts

### Pre-configured Demo Credentials (Based on Existing Data)

| Role | Email | Password | Access Level |
|------|-------|----------|--------------|
| Student | `demo.student@uwm.edu` | `student123` | Student Portal + Academic Records |
| Faculty | `demo.faculty@uwm.edu` | `faculty123` | Course Management + Student View |
| Staff | `demo.staff@uwm.edu` | `staff123` | Administrative Functions |
| Admin | `demo.admin@uwm.edu` | `admin123` | Full System Access |

> **Note**: These accounts are configured for the existing authentication system that validates `@uwm.edu` email format. The backend `LoginService.java` already handles BCrypt password validation and session token generation.

## 🎯 Demo Flow Walkthrough

### Phase 1: Authentication & Student Experience (10 minutes)
1. **Access Application** → Navigate to http://localhost:3000
2. **Login Page** → Should redirect automatically to `/login`
3. **Authentication** → Use `demo.student@uwm.edu` / `student123`
4. **Success Validation** → Should redirect to `/homepage` with welcome message
5. **Session Persistence** → Verify localStorage contains `authToken`
6. **Navigation Test** → Navigate between pages, confirm no re-auth required

### Phase 2: Multi-Role Demonstration (10 minutes)  
1. **Logout** → Clear session and return to login
2. **Faculty Login** → Use `demo.faculty@uwm.edu` / `faculty123`
3. **Role Verification** → Confirm different role context in UI
4. **Admin Access** → Test `demo.admin@uwm.edu` / `admin123`
5. **Data Consistency** → Verify backend returns appropriate role-based data

### Phase 3: System Integration Validation (10 minutes)
1. **API Health** → Check `http://localhost:8081/health` (to be implemented)
2. **Service Status** → Verify all containers running (`docker-compose ps`)
3. **Database Query** → Validate user data via direct database access
4. **Error Handling** → Test invalid credentials, confirm proper error messages
5. **Session Management** → Verify session timeout and renewal behavior

## 🐛 Troubleshooting

### Services Won't Start
```bash
# Check port conflicts
netstat -tulpn | grep -E ':(3000|8081|5432)'
sudo lsof -i :3000 -i :8081 -i :5432

# Check container logs
docker-compose logs backend frontend database

# Kill conflicting processes if needed
sudo kill -9 <PID>
```

### Database Connection Issues
```bash
# Reset database with existing seed data
docker-compose exec database psql -U paws360_app -d paws360 -f /docker-entrypoint-initdb.d/paws360_seed_data.sql

# Verify demo accounts exist  
docker-compose exec database psql -U paws360_app -d paws360 -c "SELECT email, role FROM users WHERE email LIKE 'demo.%@uwm.edu';"

# Check database connection from backend
docker-compose logs backend | grep -i "database\|connection\|postgresql"
```

### Authentication Problems  
```bash
# Test login endpoint manually
curl -X POST http://localhost:8081/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo.student@uwm.edu","password":"student123"}' \
  -v

# Verify CORS settings (if needed)
curl -H "Origin: http://localhost:3000" -i http://localhost:8081/login

# Check session token generation
docker-compose exec database psql -U paws360_app -d paws360 -c "SELECT session_token, session_expiration FROM users WHERE email = 'demo.student@uwm.edu';"
```

### Frontend Connection Issues
```bash
# Check frontend logs  
docker-compose logs frontend

# Verify frontend can reach backend
docker-compose exec frontend ping backend
docker-compose exec frontend curl http://backend:8081/health

# Check API configuration in frontend
docker-compose exec frontend env | grep API
```

## 🔄 Demo Data Management

### Reset Demo Data (Idempotent)
```bash
# Complete data reset (recommended)
cd /home/ryan/repos/PAWS360

# Method 1: Quick reset (maintains containers)
docker-compose restart database
docker-compose exec database psql -U paws360_app -d paws360 -f /docker-entrypoint-initdb.d/paws360_seed_data.sql

# Method 2: Full environment reset  
docker-compose down -v && docker-compose up -d

# Method 3: Selective user reset
docker-compose exec database psql -U paws360_app -d paws360 -c "
UPDATE users SET 
  session_token = NULL,
  session_expiration = NULL,
  failed_attempts = 0,
  account_locked = false
WHERE email LIKE 'demo.%@uwm.edu';
"
```

### Backup Current State
```bash
# Save current data state
docker-compose exec database pg_dump -U paws360_app paws360 > demo-backup-$(date +%Y%m%d-%H%M%S).sql

# Restore from backup
cat demo-backup-YYYYMMDD-HHMMSS.sql | docker-compose exec -T database psql -U paws360_app -d paws360
```

## Automation (Ansible)

### Idempotent Setup
```bash
# Run automation playbook
ansible-playbook -i inventory/demo infrastructure/ansible/demo-setup.yml

# Verify idempotency (should report OK/unchanged)
ansible-playbook -i inventory/demo infrastructure/ansible/demo-setup.yml --check
```

### Automation Health Check
```bash
# Check automation status
ansible-playbook -i inventory/demo infrastructure/ansible/health-check.yml

# Expected output: All tasks OK, no failures
```

## Success Criteria Checklist

- [ ] **SC-001**: Demo preparation + both flows completed in <30 minutes
- [ ] **SC-002**: 95%+ interactions complete without visible errors  
- [ ] **SC-003**: 100% demo account authentication success on first attempt
- [ ] **SC-004**: 100% field-level data consistency between student portal and admin view
- [ ] **SC-005**: No code changes required during demo execution
- [ ] **SC-006**: SSO works - single login grants access to both modules in <5 seconds
- [ ] **SC-007**: Authentication session valid for 30+ minutes without re-auth
- [ ] **SC-008**: Running setup automation twice results in 100% OK status
- [ ] **SC-009**: Clean rebuild to operational in <15 minutes via automation

## Emergency Contacts & Fallbacks

### If Demo Environment Fails
1. **Screenshot Backup**: Use pre-validated screenshots from `docs/demo-screenshots/`
2. **Video Walkthrough**: Reference recorded demo in `docs/demo-video.mp4`
3. **Manual Override**: Direct database queries to show data consistency

### If SSO Fails
1. **Individual Logins**: Demonstrate each module separately with explicit login
2. **Credential Consistency**: Emphasize same accounts work across modules
3. **Architecture Explanation**: Show session sharing concept with diagrams

### Point of Contact
- **Technical Issues**: [Team Lead/DevOps contact]
- **Demo Script**: [Product/Demo contact] 
- **Fallback Authority**: [Stakeholder/Decision maker]

---

**Last Updated**: 2025-11-06  
**Next Review**: Post-demo feedback session  
**Version**: 1.0 (Initial demo-ready release)