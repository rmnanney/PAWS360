# PAWS360 — quickstart (Group 7)

This README section contains the minimal, copy/paste steps to get PAWS360 running locally with the Student Frontend included.

## Quick start — 3 commands

1) Prepare the environment (Ansible helper)

```bash
cd infrastructure/ansible
./dev-helper.sh deploy-local-dev
```

2) Start services via Docker Compose (includes the Student Frontend)

```bash
cd infrastructure/docker
docker compose up -d
```

3) Open these URLs in your browser

- AdminLTE Dashboard: http://localhost:8080
- Student Frontend (Next.js): http://localhost:9002
- Auth service (mock/uwm): http://localhost:8084 or http://localhost:3000 (if configured)
- Mock Auth API: http://localhost:8081
- Mock Data API: http://localhost:8082
- Mock Analytics API: http://localhost:8083

If you prefer running the Student Frontend locally instead of via Docker Compose, checkout the feature branch and run it from `./frontend`:

```bash
# from repo root
git checkout feat/SCRUM-7-create-login-page
cd frontend
npm install
npm run dev -p 9002
# then visit: http://localhost:9002
```

## Health checks (quick)

```bash
curl http://localhost:8080/
curl http://localhost:9002/_next/static/ || true
curl http://localhost:8081/health
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health
```

## Notes and recommendations
- The compose service `student-frontend` mounts `./frontend` from the repo root and exposes port 9002. Ensure the `frontend/` folder is present (this repo already contains it).
- The current compose dev flow runs the Next dev server inside the container. For faster, more reproducible startup we can add a Dockerfile in `frontend/` that builds a production image and serves static output.
- If you see a Docker permission/daemon error, run `docker info` and ensure your user can access the Docker daemon or use `sudo`.

## Postman collection
- Import `PAWS360_Admin_API.postman_collection.json` from the repo root to exercise APIs. Set `base_url` to `http://localhost:8080` (or the service port you want to target).

---

## 📁 **PROJECT FOLDERS** (What's Where)

```
PAWS360ProjectPlan/
├── 📚 docs/           → Instructions & guides
├── 🔧 scripts/        → Helper commands
├── 🐳 infrastructure/ → Docker & server setup
├── 📋 specs/          → What to build (plans)
├── 🎨 frontend/       → Websites (React, Astro)
├── ⚙️ backend/        → Server code (Java)
├── 🧪 tests/          → Test files
└── 📦 assets/         → Images & data files
```

---

## 🎮 **WHAT CAN GROUP 7 DO?** (Your Toolkit)

### **👨‍💻 For Developers:**

| **Task** | **Command** | **What It Does** |
|----------|-------------|------------------|
| **🚀 Start Everything** | `./scripts/setup/paws360-services.sh start` | Launch all services |
| **🧪 Run All Tests** | `./scripts/testing/exhaustive-test-suite.sh` | Validate everything works |
| **🔧 Setup Local Dev** | `cd infrastructure/ansible && ./dev-helper.sh deploy-local-dev` | Complete environment setup |
| **📊 Test APIs** | Import `PAWS360_Admin_API.postman_collection.json` | Test all endpoints |
| **🗄️ Database Access** | Check `database/` folder | SQL scripts & docs |
| **🎓 Run Student Frontend** | `git checkout feat/SCRUM-7-create-login-page && npm run dev` | Next.js student app (port 9002) |

### **🔧 Development Workflow:**

1. **📥 Pull Latest Code** → `git pull origin main`
2. **🚀 Start Services** → `./scripts/setup/paws360-services.sh start`  
3. **✅ Run Tests** → `./scripts/testing/exhaustive-test-suite.sh`
4. **🎓 Start Student Frontend** → `git checkout feat/SCRUM-7-create-login-page && npm run dev`
5. **💻 Code Changes** → Edit files, test locally
6. **🔄 Commit & Push** → `git add . && git commit -m "..." && git push`

---

## 🆘 **WHEN STUCK** (Help!)

### **📖 Documentation:**
- `docs/onboarding.md` → New team member guide
- `infrastructure/ansible/README-NEW.md` → Setup help
- `docs/services-overview.md` → What each part does
- `NEW_ENGINEER_CHECKLIST.md` → Track your progress
- `PROGRAMMING_BASICS.md` → What coding is

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

**[📖 Complete API Documentation](docs/api/API_TESTING_README.md)**

### **👥 Team Help:**
- **Slack/Teams** → Ask questions
- **Code Reviews** → Get feedback on changes
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
├── � specs/                   → Feature specifications
├── ⚙️ config/                  → Environment configurations
├── 🗄️ database/                → SQL scripts and DB docs
└── 📦 assets/                  → Static files and resources
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
- **[� API Testing with Postman](docs/api/API_TESTING_README.md)** - API documentation

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
