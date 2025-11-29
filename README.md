# PAWS360 — quickstart (Group 7)

This README section contains the minimal, copy/paste steps to get PAWS360 running locally with the Student Frontend included.

## 🚀 Quick Start (Automated)

**New!** Use the automated quickstart script for a complete HA environment setup:

```bash
# One-command setup with full validation
./docs/quickstart.sh
```

The script will:
- ✓ Validate prerequisites (Docker, memory, ports)
- ✓ Pull all required images
- ✓ Start the full HA stack (PostgreSQL cluster, Redis Sentinel, etc.)
- ✓ Run health checks
- ✓ Display access URLs

**Options:**
```bash
./docs/quickstart.sh --lite      # Minimal setup (single PostgreSQL, no HA)
./docs/quickstart.sh --skip-pull # Skip image pulling (faster if cached)
./docs/quickstart.sh --clean     # Fresh start, remove existing volumes
./docs/quickstart.sh --help      # Show all options
```

**Access URLs (after setup):**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- Health Check: http://localhost:8080/actuator/health

📚 **Documentation:**
- [Developer Onboarding Checklist](docs/local-development/onboarding-checklist.md)
- [Makefile Target Reference](docs/reference/makefile-targets.md)
- [HA Architecture Guide](docs/architecture/ha-stack.md)
- [CI/CD Dashboard (monitoring)](monitoring/ci-cd-dashboard/README.md) → Live CI/CD metrics and historical trends (published to GitHub Pages when enabled)

---

## Quick start — 3 commands (Legacy)

1) Prepare the environment (Ansible helper)

```bash
cd infrastructure/ansible
./dev-helper.sh deploy-local-dev
```

2) Start services via Docker Compose (includes the Student Frontend)

**Note**: Use `docker compose` (not `docker-compose` or `docker composer`)

```bash
cd infrastructure/docker
docker compose up -d
```

3) Open these URLs in your browser

- AdminLTE Dashboard: http://localhost:8080
- Student Frontend (Next.js): http://localhost:9002
- Auth Service + Mock Auth API: http://localhost:8081
- Data Service + Mock Data API: http://localhost:8082
- Analytics Service + Mock Analytics API: http://localhost:8083
- UWM Auth Service: http://localhost:3000 (if configured)

If you prefer running the Student Frontend locally instead of via Docker Compose, run it from the `./frontend` directory:

```bash
# from repo root
cd frontend
npm install
npm run dev  # Runs on port 9002
>>>>>>> master
# then visit: http://localhost:9002
```

## Health checks (quick)

**Note**: These health checks will only work after services are fully configured and running.

```bash
# Check what's actually running first
docker compose ps

# Then test connectivity (may return connection errors until JAR files are provided)
curl http://localhost:8080/ || echo "AdminLTE UI not accessible"
curl http://localhost:9002/_next/static/ || echo "Frontend not running"
curl http://localhost:8081/health || echo "Auth service not accessible" 
curl http://localhost:8082/actuator/health || echo "Data service not accessible"
curl http://localhost:8083/actuator/health || echo "Analytics service not accessible"

# Database should be accessible
psql -h localhost -p 5432 -U paws360 -d paws360_dev -c "SELECT 1;" || echo "Database connection failed"
```

## Notes and recommendations
- **Docker Compose Setup Required**: Services need JAR files and proper configuration to run fully. PostgreSQL and Redis will start successfully.
- The compose service `student-frontend` mounts `./frontend` from the repo root and exposes port 9002. Ensure the `frontend/` folder is present (this repo already contains it).
- **Spring Boot Services**: Auth, Data, and Analytics services require compiled JAR files in `infrastructure/docker/services/` to start properly.
- **First-time Setup**: You may need to install `docker-compose-plugin` for modern Docker Compose support: `sudo apt install docker-compose-plugin`
- If you see a Docker permission/daemon error, run `docker info` and ensure your user can access the Docker daemon or use `sudo`.

NOTE: The repository's SSO end-to-end test artifacts (Playwright) have been retired due to maintenance and CI flakiness. See `docs/SSO-RETIREMENT.md` for details on how these tests were handled and how to temporarily re-enable them if necessary.

## Postman collection
- Import `PAWS360_Admin_API.postman_collection.json` from the repo root to exercise APIs. Set `base_url` to `http://localhost:8080` (or the service port you want to target).

---

## 📁 **PROJECT FOLDERS** (What's Where)

```
PAWS360/
├── 📚 docs/           → Documentation & guides
├── 🔧 scripts/        → Automation scripts
├── 🐳 infrastructure/ → Docker & Ansible deployment
├── 📋 specs/          → Feature specifications (if present)
├── 🎨 frontend/       → Next.js Student Portal
├── 🎨 app/            → Shared React components
├── ⚙️ config/         → Environment configurations
├── 🗄️ database/       → SQL scripts & DB documentation
├── ⚙️ src/            → Backend code (Java/Spring Boot)
└── 📊 PAWS360_Admin_API.postman_collection.json → Complete API collection
```

---

## 🎮 **WHAT CAN GROUP 7 DO?** (Your Toolkit)

### **👨‍💻 For Developers:**

| **Task** | **Command** | **What It Does** |
|----------|-------------|------------------|
| **🚀 Start Everything** | `./scripts/setup/paws360-services.sh start` | Launch all services |
| **🧪 Run All Tests** | `./scripts/testing/exhaustive-test-suite.sh` | Validate everything works |
| **🔧 Setup Local Dev** | `cd infrastructure/ansible && ./dev-helper.sh deploy-local-dev` | Complete environment setup |
| **✍️ Enforce commit message format** | `git config --local commit.template .gitmessage && make setup-hooks` | Use the commit template and install repo hooks (commit-msg enforces JIRA key) |
| **📊 Test APIs** | Import `PAWS360_Admin_API.postman_collection.json` | Test all endpoints |
| **🗄️ Database Access** | Check `database/` folder | SQL scripts & docs |
| **🎓 Run Student Frontend** | `cd frontend && npm run dev` | Next.js student app (port 9002) |

### **🔧 Development Workflow:**

1. **📥 Pull Latest Code** → `git pull origin master`
2. **🚀 Start Services** → `./scripts/setup/paws360-services.sh start`  
3. **✅ Run Tests** → `./scripts/testing/exhaustive-test-suite.sh`
4. **🎓 Start Student Frontend** → `cd frontend && npm run dev`
5. **💻 Code Changes** → Edit files, test locally
6. **🔄 Commit & Push** → `git add . && git commit -m "..." && git push`

---

## 🆘 **WHEN STUCK** (Help!)

### **📖 Documentation:**
- `docs/onboarding.md` → New team member guide
- `infrastructure/ansible/README-NEW.md` → Setup help
- `docs/services-overview.md` → What each part does
- `developer-onboarding.md` → Complete development guide
- `TODO.md` → Current tasks and progress

### 🧪 **Testing:**
```bash
# Test everything works
./scripts/testing/exhaustive-test-suite.sh

# Test just the APIs
./scripts/utilities/test_paws360_apis.sh
```

### **🧪 API Testing with Postman:**
**📋 Complete PAWS360 Admin API Collection Available!**

**📦 Import the comprehensive PAWS360 API collection:**

```bash
# Collection Location
./PAWS360_Admin_API.postman_collection.json
```

**🚀 Quick Setup:**

1. **📥 Import Collection:**
   - Open Postman
   - Click "Import" → "Upload Files"
   - Select `PAWS360_Admin_API.postman_collection.json` from project root
   - Collection includes 50+ endpoints with pre-configured requests

2. **⚙️ Environment Variables:**
   - `base_url`: `http://localhost:8080` (or your server URL)
   - `jwt_token`: Set after authentication (auto-populated)
   - `student_id`: `123456` (test student)
   - `course_id`: `1` (test course)
   - `alert_id`: `1` (test alert)

3. **🔐 Authentication Flow:**
   - Run "Login via SAML2" request first
   - JWT token automatically saved to environment
   - All subsequent requests use bearer token auth

4. **✅ Quick Test:**
   - Start services: `./scripts/setup/paws360-services.sh start`
   - Import collection and set environment
   - Run "Health Check" → "Get System Status" to verify connectivity
   - Explore Authentication → Student Management → Analytics folders

**📋 API Categories in Collection:**
- 🔐 **Authentication**: SAML2, JWT, session management
- 👨‍🎓 **Student Management**: CRUD operations, bulk imports
- 📊 **Analytics**: Performance metrics, success tracking
- 📚 **Course Administration**: Course management, enrollments
- 🚨 **Alert Management**: Early warning system, notifications
- ⚙️ **System Administration**: Health checks, configuration

**🌐 Available APIs (Currently Running):**
- **[� AdminLTE Dashboard](http://localhost:8080)** - Main admin interface (Bootstrap/jQuery)
- **[� UWM Auth Service API](http://localhost:3000/api)** - Production authentication service
- **[� Mock Auth API](http://localhost:8081/auth)** - Development authentication endpoint
- **[📊 Mock Data API](http://localhost:8082/data)** - Student records & course management  
- **[� Mock Analytics API](http://localhost:8083/analytics)** - Performance metrics & reporting

**[📖 Complete API Documentation](docs/API_TESTING_README.md)**

### **👥 Team Help:**
- **Slack/Teams** → Ask questions
- **Code Reviews** → Get feedback on changes
 - **Commit message policy** → Use `.gitmessage` as the template and run `make setup-hooks` to install the `commit-msg` hook which enforces a JIRA key (e.g., SCRUM-84) in the commit message.
- **Mentor** → Find someone to pair with

---

## 📈 **LEARNING PATH** (Grow as Engineer)

```
🌱 NEW ENGINEER
    ↓
📚 Learn the basics (this README)
    ↓
🛠️ Setup development environment
    ↓
🐛 Fix small bugs
    ↓
✨ Add small features
    ↓
🏗️ Build bigger features
    ↓
🚀 Deploy to production
    ↓
👨‍🏫 Help other new engineers
    ↓
🧑‍💼 Senior Engineer
```

### **📚 What to Learn:**
- **Git** → Version control (save code history)
- **Docker** → Container technology
- **APIs** → How systems talk to each other
- **Databases** → How data is stored
- **Testing** → Making sure code works

---

## 🎯 **YOUR FIRST TASKS**

### **Week 1:**
- [ ] Setup development environment
- [ ] Run all tests (they should pass)
- [ ] Read `docs/onboarding.md`
- [ ] Say "hello" in team chat

### **Week 2:**
- [ ] Fix a small bug
- [ ] Add a small feature
- [ ] Write a test
- [ ] Get code review

### **Week 3:**
- [ ] Deploy to staging server
- [ ] Help another new engineer
- [ ] Learn about our JIRA integration

---

## ⚡ **GROUP 7 QUICK COMMANDS** (Copy & Paste)

```bash
# 🚀 ESSENTIAL COMMANDS (Most Used)
./scripts/setup/paws360-services.sh start         # Start all services
./scripts/testing/exhaustive-test-suite.sh        # Test everything
cd infrastructure/ansible && ./dev-helper.sh deploy-local-dev  # Setup dev environment

# 🔍 HEALTH CHECKS  
curl http://localhost:8080/                       # AdminLTE Dashboard
curl http://localhost:3000/health                 # UWM Auth Service
curl http://localhost:8081/health                 # Mock Auth API  
curl http://localhost:8082/health                 # Mock Data API
curl http://localhost:8083/health                 # Mock Analytics API

# 📊 USEFUL UTILITIES
./scripts/utilities/test_paws360_apis.sh          # Test all APIs
./scripts/utilities/validate-env.sh               # Check configuration
```

---

## 🎉 **WELCOME TO GROUP 7!**

**🎯 Mission: Help students succeed in university**

You now have a **complete student success platform** with:
- ✅ **Live Services**: AdminLTE admin dashboard, UWM auth service, mock APIs
- ✅ **Database**: PostgreSQL with student records (Docker)
- ✅ **Testing**: Automated test suites
- ✅ **Documentation**: Complete guides and references
- ✅ **APIs**: 50+ endpoints for all functionality (Postman collection)

**🚀 Ready to start?** Run `./scripts/setup/paws360-services.sh start` and build something amazing!

---

*Built by Group 7 for student success* 🎓

---

*Made with ❤️ for Group 7 engineers building student success*

---

## 📁 **Project Structure** (What's Where)

```
PAWS360/
├── 📚 docs/                    → Complete documentation
├── 🔧 scripts/                 → Automation and setup scripts  
├── 🐳 infrastructure/          → Docker & Ansible deployment
├──  specs/                   → Feature specifications
├── ⚙️ config/                  → Environment configurations
├── 🗄️ database/                → SQL scripts and DB docs
├── 🎨 frontend/                → Next.js Student Portal
├── 🎨 app/                     → Shared React components
├── ⚙️ src/                     → Backend code (Spring Boot)
└── 📊 PAWS360_Admin_API.postman_collection.json → API collection
```

### 🚀 **Quick Access Links**
- **[📖 Full Documentation](docs/)** - Complete guides and references
- **[🏗️ Infrastructure Setup](infrastructure/ansible/README-NEW.md)** - Local development  
- **[🤖 JIRA Integration](docs/jira-mcp/README.md)** - AI project management
- **[🧪 Testing Guide](docs/testing/README.md)** - Test everything
- **[📊 Services Overview](docs/services-overview.md)** - All platform services

---

## � **Documentation & Resources**

### 🎯 **For Group 7 Team Members**
- **[📖 Complete Documentation Index](docs/INDEX.md)** - All guides in one place
- **[🏗️ Infrastructure Setup Guide](infrastructure/ansible/README-NEW.md)** - Local development
- **[📊 Services Overview](docs/services-overview.md)** - All platform components  
- **[🧪 Testing Guide](docs/testing/README.md)** - How to test everything
- **[📊 API Testing with Postman](docs/API_TESTING_README.md)** - API documentation

### 📋 **Project Management**  
- **[✅ TODO Tracking](TODO.md)** - Current tasks and progress
- **[📋 Specifications](specs/)** - Feature requirements and plans
- **[🤖 JIRA Integration](docs/jira-mcp/README.md)** - AI-powered project management

---

## 🤝 **Contributing to PAWS360**

1. **📖 Read**: Review documentation and understand the platform
2. **🧪 Test**: Run tests to ensure everything works  
3. **💻 Code**: Follow established patterns and best practices
4. **� Document**: Update docs for any new functionality
5. **✅ Verify**: Ensure all tests pass before submitting

---

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Repository reorganized for Group 7: September 21, 2025*
