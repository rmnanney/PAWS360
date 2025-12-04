# 📦 PAWS360 - Package Contents

Thank you for testing PAWS360! This zip package contains everything you need to run the application.

## 📄 Quick Reference

| Document | Purpose |
|----------|---------|
| **QUICKSTART.md** | ⚡ Start here! Get running in 3 commands |
| **SETUP_FROM_SCRATCH.md** | 📚 Detailed installation guide |
| **TESTING_CHECKLIST.md** | ✅ Verify all features work correctly |
| **README_PACKAGE.md** | 📖 This file - overview of package contents |

## 🚀 Getting Started

### Fastest Path

1. Extract this zip file
2. Open a terminal in the extracted folder
3. Run: `./scripts/setup/setup-from-scratch.sh`
4. Run: `./scripts/setup/start-app.sh`
5. Open browser to: http://localhost:3000
6. Login: `test@uwm.edu` / `password`

### What's Included

```
PAWS360/
├── QUICKSTART.md                    # Quick start guide
├── SETUP_FROM_SCRATCH.md           # Complete setup instructions
├── TESTING_CHECKLIST.md            # Feature testing checklist
├── README_PACKAGE.md               # This file
├── .env                            # Pre-configured environment
├── scripts/
│   └── setup/
│       ├── setup-from-scratch.sh   # Auto-install all dependencies
│       ├── start-app.sh            # Start all services
│       ├── stop-app.sh             # Stop all services
│       └── health-check.sh         # Verify services are running
├── database/
│   ├── setup_database.sh           # Initialize database
│   ├── paws360_database_ddl.sql    # Database schema
│   └── paws360_seed_data.sql       # Test data
├── src/                            # Spring Boot backend source
├── app/                            # Next.js frontend source
└── docs/                           # Additional documentation
```

## 🎯 What You're Testing

PAWS360 is a student information system portal with:

- **Authentication** - Secure login system
- **Academic Records** - GPA, transcript, grades
- **Course Management** - Browse courses, view schedules
- **Enrollment** - Registration dates and planning
- **Student Services** - Holds, tasks, quick links
- **Modern UI** - Dark mode, responsive design

## 🔧 System Requirements

### Minimum
- **OS**: Ubuntu 20.04+, macOS 11+, or Windows 10+ (with WSL2)
- **RAM**: 8GB
- **Disk**: 20GB free space
- **Internet**: Required for initial setup

### Will Be Installed Automatically
- Java 21 (OpenJDK)
- Node.js 20.x
- Maven 3.x
- Docker & Docker Compose
- PostgreSQL 15 (via Docker)

## 🧪 Testing Workflow

1. **Setup** (10-15 minutes)
   - Run automated setup script
   - Verify all dependencies installed
   - Database initialized with test data

2. **Start Services** (2-3 minutes)
   - Backend starts on port 8086
   - Frontend starts on port 3000
   - Database running in Docker

3. **Test Features** (30-60 minutes)
   - Follow TESTING_CHECKLIST.md
   - Check each feature systematically
   - Document any issues found

4. **Report Results**
   - Complete checklist
   - Note any failures or unexpected behavior
   - Provide feedback

## 🎓 Test Account

Pre-configured test account:

```
Email:    test@uwm.edu
Password: password
Role:     Student
```

This account has:
- Basic profile information
- Sample academic data
- Access to all student features

## 📊 Expected Behavior

### Working Features
✅ Login/Logout
✅ Homepage navigation
✅ Academic records display
✅ Enrollment dates display
✅ Holds & Tasks display (empty state)
✅ Dark mode toggle
✅ Responsive design
✅ All page navigation

### Known Limitations
⚠️ Course search may show "unavailable" (database schema mismatch)
⚠️ Some academic data may be placeholder/sample data
⚠️ Limited to test user data only

## 🆘 Help & Troubleshooting

### Quick Checks

```bash
# Are services running?
./scripts/setup/health-check.sh

# View logs
tail -f /tmp/paws360-logs/backend.log
tail -f /tmp/paws360-logs/frontend.log

# Restart everything
./scripts/setup/stop-app.sh
./scripts/setup/start-app.sh
```

### Common Issues

**Port conflicts**
- Run: `./scripts/setup/stop-app.sh`
- Kill any lingering processes
- Restart services

**Database connection fails**
- Check: `docker ps | grep paws360-postgres`
- Restart: `docker start paws360-postgres`

**Dependencies missing**
- Re-run: `./scripts/setup/setup-from-scratch.sh`
- Check installation logs for errors

**Frontend won't start**
- Delete: `rm -rf node_modules package-lock.json`
- Reinstall: `npm install`

## 📝 Feedback

When reporting issues, please include:

1. **Environment**
   - OS and version
   - Available RAM
   - Docker version

2. **Steps to Reproduce**
   - What you did
   - What you expected
   - What actually happened

3. **Logs**
   - Backend: `/tmp/paws360-logs/backend.log`
   - Frontend: `/tmp/paws360-logs/frontend.log`
   - Browser console (F12)

4. **Screenshots**
   - Error messages
   - Unexpected behavior
   - UI issues

## ✅ Success Criteria

The test is successful if:

- ✅ All services start without errors
- ✅ Login works with test credentials
- ✅ All pages are accessible from navigation
- ✅ No critical errors in console/logs
- ✅ UI is usable and responsive
- ✅ Dark mode works correctly

## 🎉 Thank You!

Your testing helps ensure PAWS360 is ready for production deployment.

**Questions or Issues?**
- Check SETUP_FROM_SCRATCH.md for detailed troubleshooting
- Review logs in `/tmp/paws360-logs/`
- Document issues in TESTING_CHECKLIST.md

---

**Package Version**: Master (December 2025)
**Prepared By**: Development Team
**Contact**: [Your contact information]
