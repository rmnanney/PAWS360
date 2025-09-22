# PAWS360 🐾

## 🚀 **GROUP 7### **Step 3: Open in Browser**
- 📊 **[AdminLTE Dashboard](http://localhost:8080)** - Main admin interface
- 🔐 **[UWM Auth Service](http://localhost:3000)** - Authentication service (Docker)
- 🔧 **[Mock Auth API](http://localhost:8081)** - Development auth API
- 📊 **[Mock Data API](http://localhost:8082)** - Student data API
- 📈 **[Mock Analytics API](http://localhost:8083)** - Performance metrics API

### **Step 3b: Optional - Run Student Frontend**
```bash
# Switch to student frontend branch and run
git checkout feat/SCRUM-7-create-login-page
npm install
npm run dev

# Then visit: http://localhost:9002 (Student login interface)
```STAR### **🌐 Live Services** (Click to Access)
- **[📊 AdminLTE Dashboard](http://localhost:8080)** - Main admin interface (Bootstrap/jQuery)
- **[🔐 UWM Auth Service](http://localhost:3000)** - Production authentication service (Docker)
- **[🔧 Mock Auth API](http://localhost:8081)** - Development authentication API  
- **[📈 Mock Data API](http://localhost:8082)** - Student data management API
- **[📊 Mock Analytics API](http://localhost:8083)** - Performance metrics & reporting API

### **🚧 In Development** (On Feature Branches)
- **🎓 Student Frontend** - Next.js application with login pages (see `feat/SCRUM-7-create-login-page` branch)
  - Port: 9002 when running
  - Tech: Next.js 15, React 18, Tailwind CSS, TypeScriptet Started in 2 Minutes!)

**Welcome Group 7!** Here's the fastest way to get PAWS360 running locally:

### **Step 1: Setup Everything**
```bash
cd infrastructure/ansible
./dev-helper.sh deploy-local-dev
```
**⏱️ Takes: 30 seconds** ✨

### **Step 2: Start Services**
```bash
cd ../../
./scripts/setup/paws360-services.sh start
```

### **Step 3: Open in Browser**
- 📊 **[AdminLTE Dashboard](http://localhost:8080)** - Main admin interface
- � **[UWM Auth Service](http://localhost:3000)** - Authentication service (Docker)
- 🔐 **[Mock Auth API](http://localhost:8081)** - Development auth API
- 📊 **[Mock Data API](http://localhost:8082)** - Student data API
- 📈 **[Mock Analytics API](http://localhost:8083)** - Performance metrics API

### **Step 4: Run Tests** (Verify Everything Works)
```bash
./scripts/testing/exhaustive-test-suite.sh
```

**🎯 That's it!** You're ready to develop. See below for detailed docs.

---

## 🚀 **GROUP 7 PLATFORM STATUS** (All Systems Online!)

**✅ Platform Successfully Running:** All core services operational

### **🌐 Live Services** (Click to Access)
- **[📊 Student Portal](http://localhost:8080)** - Main application interface
- **[⚙️ AdminLTE Dashboard](http://localhost:3000)** - Administrative controls
- **[� Auth Service](http://localhost:8081)** - User authentication API  
- **[📈 Data Service](http://localhost:8082)** - Student data management
- **[📊 Analytics Service](http://localhost:8083)** - Performance metrics & reporting

### **🗄️ Database & Backend**
- **PostgreSQL Database** - Student records and course data
- **Redis Cache** - Session management and performance
- **Docker Infrastructure** - Containerized deployment
- **[📋 Postman API Collection](./PAWS360_Admin_API.postman_collection.json)** - Complete API testing

### **💡 Quick Health Check**
```bash
# Verify all services respond
curl http://localhost:8080/                       # AdminLTE Dashboard
curl http://localhost:3000/health                 # UWM Auth Service  
curl http://localhost:8081/health                 # Mock Auth API
curl http://localhost:8082/health                 # Mock Data API
curl http://localhost:8083/health                 # Mock Analytics API
```

---

## 🏗️ **HOW IT WORKS** (Simple View)

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   STUDENT       │    │   ADVISOR       │    │   ADMIN         │
│   • Check grades │    │   • View alerts │    │   • Manage      │
│   • See schedule │    │   • Help students│    │     system     │
│   • Get help     │    │   • Track progress│    │   • Run reports│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   PAWS360       │
                    │   PLATFORM      │
                    └─────────────────┘
```

---

## 🛠️ **GROUP 7 TECH STACK** (What We Built)

### **🌐 Frontend Applications** (What Students & Staff See)
```
✅ CURRENTLY RUNNING
├── 📊 AdminLTE Dashboard     → Main admin interface (port 8080)
└── 🔐 UWM Auth Interface     → Login system (port 3000, Docker)

🚧 IN DEVELOPMENT 
└── 🎓 Student Frontend       → Next.js app (port 9002, feat/SCRUM-7-create-login-page branch)
```

### **⚙️ Backend Services** (The Engine)
```
✅ MICROSERVICES ARCHITECTURE  
├── 🔐 UWM Auth Service (3000)  → Production auth (Docker container)
├── 🔧 Mock Auth API (8081)     → Development authentication
├── 📊 Mock Data API (8082)     → Student records & courses  
├── 📈 Mock Analytics (8083)    → Performance tracking
├── 🗄️ PostgreSQL Database     → Persistent data storage
└── ⚡ Redis Cache             → Fast session management
```

### **🚀 Infrastructure** (How We Deploy)
```
✅ PRODUCTION-READY DEPLOYMENT
├── 🐳 Docker Containers      → Consistent environments
├── 📋 Ansible Automation     → Infrastructure as code
├── 🔧 Shell Scripts          → Easy setup & management
└── 🧪 Automated Testing      → Quality assurance
```

---

## 🚀 **GET STARTED** (3 Steps)

### **STEP 1: Setup Your Computer**
```bash
# Go to the setup folder
cd infrastructure/ansible

# Run the magic setup command
./dev-helper.sh deploy-local-dev
```
**⏱️ Time: 30 seconds** ✨

### **STEP 2: Start Everything**
```bash
# Start all services
./scripts/setup/paws360-services.sh start
```

### **STEP 3: Open in Browser**
```
📊 http://localhost:8080  → AdminLTE Dashboard (Main Interface)
� http://localhost:3000  → UWM Auth Service (Docker)
� http://localhost:8081  → Mock Auth API
📊 http://localhost:8082  → Mock Data API
📈 http://localhost:8083  → Mock Analytics API
```

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
