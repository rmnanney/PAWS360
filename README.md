# PAWS360 🐾

```
   ____   ____    _    _   _____  _____  _____
  |  _ \ / __ \  | |  | | / ____||_   _||  __ \
  | |_) | |  | | | |  | || |       | |  | |  | |
  |  _ <| |  | | | |  | || |       | |  | |  | |
  | |_) | |__| | | |__| || |____  _| |_ | |__| |
  |____/ \____/   \____/  \_____||_____||_____/

  STUDENT SUCCESS PLATFORM
```

---

## 🎯 **WHAT IS PAWS360?**

**PAWS360** = Student Success Platform for Universities

```
🎓 STUDENTS → 📊 SUCCESS → 🎯 GRADUATION
```

- **Helps students succeed** in college
- **Tracks grades, attendance, alerts**
- **Connects students with advisors**
- **Manages courses and enrollments**

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

## 🛠️ **WHAT WE USE** (Tech Stack)

### **FRONTEND** (What Users See)
```
🌐 WEBSITES
├── AdminLTE Dashboard  → Admin interface (jQuery)
├── Admin UI           → Modern interface (Astro)
└── Student Page       → Student interface (React)
```

### **BACKEND** (The Brain)
```
⚙️ SERVERS
├── Spring Boot       → Main server (Java)
├── PostgreSQL        → Database (stores data)
├── Redis            → Fast memory cache
└── JIRA MCP         → Project management (AI)
```

### **INFRASTRUCTURE** (How It Runs)
```
🚀 DEPLOYMENT
├── Docker           → Container packaging
├── Ansible          → Server setup automation
└── Scripts          → Helper commands
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
🌐 http://localhost:8080  → Main app
📊 http://localhost:3000  → Admin dashboard
🤖 http://localhost:3001  → JIRA tools
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

## 🎮 **WHAT CAN YOU DO?**

### **👨‍💻 As a Developer:**

| **I Want To...** | **Command** | **What It Does** |
|------------------|-------------|------------------|
| **Start coding** | `./dev-helper.sh deploy-local-dev` | Setup everything locally |
| **Run tests** | `./exhaustive-test-suite.sh` | Check if code works |
| **Work with JIRA** | `cd docs/jira-mcp && source setup_jira_env.sh` | AI project management |
| **See all services** | `./paws360-services.sh start` | Start all parts |

### **🔧 Common Tasks:**

- **Add new feature** → Look in `specs/` folder for plans
- **Fix bug** → Run tests first, then change code
- **Deploy to server** → Use Ansible in `infrastructure/`
- **Write documentation** → Add to `docs/` folder

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
**Import the PAWS360 API collection for comprehensive API testing:**

1. **Download/Import Collection:**
   - File: `PAWS360_Admin_API.postman_collection.json`
   - Contains all admin API endpoints with pre-configured requests

2. **Team Workspace (if available):**
   - Join the PAWS360 Postman team workspace for shared collections
   - URL: [Team workspace URL - contact team lead for access]

3. **Environment Setup:**
   - Create a Postman environment with your local dev settings
   - Base URL: `http://localhost:8080/api`
   - Include authentication tokens as needed

4. **Quick Test:**
   - Import the collection
   - Set environment variables
   - Run the "Health Check" request to verify API connectivity

**[📖 Postman Collection Guide](PAWS360_Admin_API.postman_collection.json)**

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

## ⚡ **QUICK COMMANDS** (Cheat Sheet)

```bash
# Most used commands:
./dev-helper.sh deploy-local-dev     # Setup everything
./paws360-services.sh start          # Start services
./exhaustive-test-suite.sh           # Run all tests
cd docs/jira-mcp && source setup_jira_env.sh  # JIRA setup
```

---

## 🎉 **WELCOME TO THE TEAM!**

**PAWS360 helps students succeed** - and now you're part of that mission!

**Remember:** Everyone starts somewhere. Ask questions. Break things (in test environments). Learn together.

**🚀 Ready to start?** Run `./dev-helper.sh deploy-local-dev` and let's build something amazing!

---

*Made with ❤️ for new engineers joining the workforce*## �📁 Repository Structure

This repository has been organized following best practices. See [`docs/README.md`](docs/README.md) for detailed file categorization and structure.

### Quick Navigation
- 📚 **Documentation**: [`docs/`](docs/)
- 🔧 **Scripts**: [`scripts/`](scripts/)
- ⚙️ **Configuration**: [`config/`](config/)
- 📦 **Assets**: [`assets/`](assets/)
- 🏗️ **Infrastructure**: [`infrastructure/`](infrastructure/)
- 📋 **Specifications**: [`specs/`](specs/)

### 🏗️ Infrastructure Quick Access
- **🚀 Ansible Automation**: [`infrastructure/ansible/`](infrastructure/ansible/)
  - **[Local Development Setup](infrastructure/ansible/README-NEW.md)** - Get started in seconds
  - **[Deployment Guide](infrastructure/ansible/DEPLOYMENT.md)** - Complete infrastructure docs
  - **[Development Helper](infrastructure/ansible/dev-helper.sh)** - Easy command shortcuts
- **🐳 Docker Services**: [`infrastructure/docker/`](infrastructure/docker/)
- **📊 Monitoring**: [`infrastructure/monitoring/`](infrastructure/monitoring/)mprehensive project management and development platform for PAWS360, featuring JIRA integration, modern web interfaces, and complete infrastructure automation.

## � **New Team Members - Start Here!**

**Welcome to PAWS360!** If you're new to the team, please start with our comprehensive **[Onboarding Guide](docs/onboarding.md)** which provides:
- Complete development environment setup (WSL/Ubuntu)
- Platform architecture overview with diagrams
- Service catalog and quick start commands
- Role-based guidance for your position
- Success metrics and next steps

**[📖 Start Your Onboarding Journey →](docs/onboarding.md)**

## 🎯 What Do You Want to Do?

| I Want to... | Quick Start | Documentation |
|-------------|-------------|---------------|
| **🚀 Start Developing** | `cd infrastructure/ansible && ./dev-helper.sh deploy-local-dev` | [Local Dev Guide](infrastructure/ansible/README-NEW.md) |
| **🏗️ Deploy Infrastructure** | `cd infrastructure/ansible && ./dev-helper.sh test` | [Infrastructure Guide](infrastructure/ansible/DEPLOYMENT.md) |
| **🤖 Use JIRA Integration** | `cd docs/jira-mcp && source setup_jira_env.sh` | [JIRA MCP Guide](docs/jira-mcp/README.md) |
| **🧪 Run Tests** | `./scripts/testing/exhaustive-test-suite.sh` | [Testing Guide](docs/testing/README.md) |
| **📚 Learn the Platform** | Read the docs below | [Services Overview](docs/services-overview.md) |

---

## 🎯 Quick Start Guide

Choose your path based on what you want to accomplish:

### 🚀 **Just Want to Develop?**
**Get a complete development environment in 30 seconds:**
```bash
cd infrastructure/ansible
./dev-helper.sh deploy-local-dev
```
**[📖 Local Development Guide →](infrastructure/ansible/README-NEW.md)**

### 🏗️ **Need Full Infrastructure?**
**Deploy complete PAWS360 platform:**
```bash
cd infrastructure/ansible
./dev-helper.sh test              # Validate everything works
./dev-helper.sh deploy-demo       # Demo deployment
ansible-playbook site.yml         # Full production deployment
```
**[📖 Infrastructure Guide →](infrastructure/ansible/DEPLOYMENT.md)**

### 🤖 **Working with JIRA?**
**AI-powered project management:**
```bash
cd docs/jira-mcp
source setup_jira_env.sh
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```
**[📖 JIRA MCP Guide →](docs/jira-mcp/README.md)**

### 🧪 **Testing Everything?**
```bash
./scripts/testing/exhaustive-test-suite.sh  # Full test suite
cd infrastructure/ansible && ./dev-helper.sh test  # Infrastructure tests
```
**[📖 Testing Guide →](docs/testing/README.md)**

## �📁 Repository Structure

This repository has been organized following best practices. See [`docs/README.md`](docs/README.md) for detailed file categorization and structure.

### Quick Navigation
- 📚 **Documentation**: [`docs/`](docs/)
- 🔧 **Scripts**: [`scripts/`](scripts/)
- ⚙️ **Configuration**: [`config/`](config/)
- 📦 **Assets**: [`assets/`](assets/)
- 🏗️ **Infrastructure**: [`infrastructure/`](infrastructure/)
- 📋 **Specifications**: [`specs/`](specs/)

## 🎯 Key Components

### 📊 **Complete Services Overview**
**🎉 Your comprehensive platform catalog** - All 13+ services in one place:

- **JIRA MCP Server**: AI-powered project management automation
- **AdminLTE Dashboard**: Modern responsive admin interface
- **Admin UI**: Astro-based alternative interface
- **Mock Services**: Development backend (Auth, Data, Analytics)
- **Docker Infrastructure**: Containerized deployment with 8 services
- **Ansible Automation**: Infrastructure provisioning and scaling
- **Monitoring Stack**: Prometheus + Grafana dashboards
- **25+ Automation Scripts**: Setup, testing, and utility scripts

**[📖 View Complete Services Catalog](docs/services-overview.md)**

### JIRA MCP Server
A Model Context Protocol (MCP) server for seamless JIRA integration:

- **Project Import**: Import complete project data from JIRA
- **Work Item Export**: Bulk export with proper field mapping
- **Advanced Search**: JQL-based work item search
- **Real-time Updates**: Immediate synchronization
- **Secure Authentication**: API key-based with rate limiting

### Web Interfaces
- **AdminLTE Dashboard**: Modern responsive admin interface (jQuery-based, no client router)
- **Admin UI**: Alternative Astro-based implementation (Astro file-based routing)
- **Student Page**: React-based interface planned (React Router needed - see specs/001-transform-the-student/)
- **Mock Services**: Development backend services

### Routing Architecture
**Current State:**
- **AdminLTE Dashboard**: Static pages with jQuery navigation (no SPA router)
- **Admin UI (Astro)**: File-based routing with Astro's built-in router
- **Student Interface**: React Router planned for SPA functionality (per Zenith's requirements)

**Note**: The student-facing interface will require React Router implementation for single-page application behavior as specified in the transform-the-student feature requirements.

### Infrastructure
- **Docker**: Containerized deployment
- **Ansible**: Infrastructure automation
- **CI/CD**: Automated testing and deployment pipelines

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Node.js 18+
- Docker & Docker Compose
- JIRA API access (for JIRA features)

### Environment Setup
```bash
# 1. Clone repository
git clone <repository-url>
cd PAWS360ProjectPlan

# 2. Set up environment configuration
cp .env.example.local .env
# Edit .env with your local settings

# 3. Validate configuration
./scripts/utilities/validate-env.sh

# 4. Install dependencies
pip install -e .
npm install

# 5. Start services
./scripts/setup/paws360-services.sh start
```

### Configuration
The project uses environment-based configuration:

- **`.env.example`** - Complete configuration template
- **`.env.example.local`** - Local development settings
- **`.env.example.dev`** - Development server settings
- **`.env.example.prod`** - Production settings

See [`docs/guides/environment-configuration-guide.md`](docs/guides/environment-configuration-guide.md) for detailed configuration instructions.

## 📊 Project Statistics

- **Total Files**: 124 organized files
- **Documentation**: 33 files across 4 categories
- **Scripts**: 25 automation scripts
- **Test Coverage**: Comprehensive test suites
- **Infrastructure**: Docker + Ansible automation

## 🛠️ Development

### 🚀 **Quick Commands**
```bash
# Infrastructure
cd infrastructure/ansible && ./dev-helper.sh deploy-local-dev  # Local dev environment
cd infrastructure/ansible && ./dev-helper.sh test              # Test infrastructure

# JIRA Operations
./scripts/jira/csv_to_jira.py --help                           # JIRA import/export

# Services
./scripts/setup/start-adminlte.sh                             # Start AdminLTE
./scripts/setup/paws360-services.sh start                     # Start all services

# Testing
./scripts/testing/exhaustive-test-suite.sh                    # Full test suite
pytest                                                        # Python tests
```

### 📜 **Available Scripts**
- **Setup Scripts**: [`scripts/setup/`](scripts/setup/) - Environment and service setup
- **Testing Scripts**: [`scripts/testing/`](scripts/testing/) - Comprehensive testing
- **JIRA Scripts**: [`scripts/jira/`](scripts/jira/) - JIRA integration tools
- **Utility Scripts**: [`scripts/utilities/`](scripts/utilities/) - Helper utilities

### 🧪 **Testing**
```bash
# Run all tests
./scripts/testing/exhaustive-test-suite.sh

# API testing
./scripts/utilities/test_paws360_apis.sh

# Constitution compliance
./scripts/testing/test-constitution-compliance.sh

# Infrastructure testing
cd infrastructure/ansible && ./dev-helper.sh test
```

## � Project Management

### TODO Tracking
Track all project tasks and progress in [`TODO.md`](TODO.md):
- ✅ Completed tasks
- 🔄 In progress work
- ⏳ Planned tasks
- 📊 Progress tracking

### JIRA Integration
Complete JIRA MCP Server implementation for project management:
- **User Story**: [`specs/jira-mcp-server-user-story.md`](specs/jira-mcp-server-user-story.md)
- **Integration Guide**: [`docs/guides/jira-integration-guide.md`](docs/guides/jira-integration-guide.md)
- **Scripts**: `scripts/jira/` directory

## 🤖 JIRA MCP Server

**🚀 Production-Ready AI-Powered JIRA Integration**

The JIRA MCP Server enables seamless integration between AI assistants and JIRA for automated project management:

### Quick Access
- 📖 **[Complete Documentation](docs/jira-mcp/README.md)** - Full team guide
- 🛠️ **[Team Setup Guide](docs/jira-mcp/TEAM_SETUP_GUIDE.md)** - 5-minute setup
- 📋 **[Quick Reference](docs/jira-mcp/QUICK_REFERENCE_CARD.md)** - Essential commands
- 🔧 **[MCP Examples](docs/jira-mcp/mcp_examples.json)** - Sample interactions
- ⚙️ **[Setup Script](docs/jira-mcp/setup_jira_env.sh)** - Environment configuration

### Key Features
- ✅ **Create Stories**: AI-powered story generation with templates
- ✅ **Search & Filter**: Advanced JQL-based work item search
- ✅ **Bulk Operations**: Efficiently manage multiple issues
- ✅ **Sprint Management**: Complete sprint planning and tracking
- ✅ **Team Assignment**: Automated team and user assignments
- ✅ **Real-time Sync**: Immediate JIRA synchronization

### Get Started (2 minutes)
```bash
# 1. Set your JIRA credentials
cp docs/jira-mcp/setup_jira_env.sh .
nano setup_jira_env.sh  # Add your API token

# 2. Start the server
source setup_jira_env.sh
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve

# 3. Use with Claude Desktop or VS Code
# Follow: docs/jira-mcp/TEAM_SETUP_GUIDE.md
```

**🎯 Try it now:** "Create a JIRA story for implementing user authentication"

## 📚 Documentation

### 📖 **Essential Reading**
- **� Documentation Index**: [`docs/INDEX.md`](docs/INDEX.md) - Complete documentation catalog
- **�📊 Services Overview**: [`docs/services-overview.md`](docs/services-overview.md) - Complete platform catalog
- **🏗️ Infrastructure Guide**: [`infrastructure/ansible/README-NEW.md`](infrastructure/ansible/README-NEW.md) - Development setup
- **🤖 JIRA MCP Server**: [`docs/jira-mcp/README.md`](docs/jira-mcp/README.md) - AI-powered project management

### 🛠️ **Setup & Configuration**
- **Environment Configuration**: [`docs/guides/environment-configuration-guide.md`](docs/guides/environment-configuration-guide.md)
- **WSL/Ubuntu Setup**: [`docs/onboarding.md`](docs/onboarding.md)
- **Infrastructure Deployment**: [`infrastructure/ansible/DEPLOYMENT.md`](infrastructure/ansible/DEPLOYMENT.md)

### 🔧 **Development Guides**
- **API Testing**: [`docs/api/API_TESTING_README.md`](docs/api/API_TESTING_README.md)
- **JIRA Integration**: [`docs/guides/jira-integration-guide.md`](docs/guides/jira-integration-guide.md)
- **Testing Framework**: [`docs/testing/README.md`](docs/testing/README.md)
- **Deployment**: [`docs/deployment/`](docs/deployment/)

### 📋 **Project Management**
- **TODO Tracking**: [`TODO.md`](TODO.md) - All project tasks and progress
- **Project Structure**: [`docs/README.md`](docs/README.md) - File organization guide
- **Specifications**: [`specs/`](specs/) - Feature specifications and requirements

### 🎯 **Key Specifications**
- **Student Interface**: [`specs/001-transform-the-student/`](specs/001-transform-the-student/) - Student-facing React interface
- **JIRA Integration**: [`specs/002-let-s-create/`](specs/002-let-s-create/) - MCP server implementation
- **Platform Updates**: [`specs/003-update-paws360-project/`](specs/003-update-paws360-project/) - Core platform updates
- **Authentication**: [`specs/004-create-uwm-authentication/`](specs/004-create-uwm-authentication/) - UWM auth system
- **JIRA User Story**: [`specs/jira-mcp-server-user-story.md`](specs/jira-mcp-server-user-story.md) - MCP server requirements

## ✅ Key Achievements

- **🤖 AI-Powered JIRA Integration**: Complete MCP server for automated project management
- **🏗️ Production-Ready Infrastructure**: Ansible automation with local development support
- **🌐 Modern Web Interfaces**: AdminLTE dashboard, Astro UI, and React planning
- **📊 Comprehensive Testing**: Automated test suites and validation
- **📚 Complete Documentation**: Organized docs with easy navigation
- **🚀 Quick Setup**: Get developing in seconds with local infrastructure

## 🤝 Contributing

1. Review [`docs/README.md`](docs/README.md) for structure guidelines
2. Follow established coding standards
3. Write tests for new functionality
4. Update documentation as needed
5. Ensure all tests pass

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
*Repository reorganized: September 21, 2025*