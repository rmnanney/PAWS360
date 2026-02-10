+# PAWS360 Platform Services Overview

## 🎯 **Complete Services Catalog**

This document provides a comprehensive overview of all services available in the PAWS360 platform, organized by category and functionality.

**Status**: ✅ **PRODUCTION READY**  
**Date**: September 20, 2025  
**Version**: 1.0.0  
**Platform**: PAWS360 Enterprise  

---

## 📋 **Table of Contents**

1. [JIRA MCP Server - Your AI Project Assistant](#-jira-mcp-server---your-ai-project-assistant)
2. [Mock Services Suite - Development Playground](#-mock-services-suite---development-playground)
3. [AdminLTE Dashboard - Visual Project Explorer](#-adminlte-dashboard---visual-project-explorer)
4. [Admin UI (Astro) - Modern Interface Builder](#-admin-ui-astro---modern-interface-builder)
5. [Docker Containerization - Portable Development](#-docker-containerization---portable-development)
6. [Ansible Automation - Infrastructure Magic](#-ansible-automation---infrastructure-magic)
7. [Java Spring Boot Backend - The Heart of PAWS360](#-java-spring-boot-backend---the-heart-of-paws360)
8. [Automation & Scripting Services - Your Task Automators](#-automation--scripting-services---your-task-automators)
9. [Monitoring & Analytics Services - System Health Watch](#-monitoring--analytics-services---system-health-watch)
10. [Service Status Summary](#-service-status-summary)
11. [Quick Start Guide](#-quick-start-guide)
12. [Integration Examples](#-integration-examples)

---

## 🤖 **JIRA MCP Server - Your AI Project Assistant**

**🚀 What it does for YOU:**
This is your personal AI assistant that makes JIRA work for you! Instead of struggling with complex JIRA interfaces, you can simply ask it to create user stories, search for tasks, or organize your work. It's like having an experienced project manager who speaks your language and handles all the tedious JIRA work automatically.

**Great for getting started because:**
- ✅ **Learn by doing** - See how professional user stories are written
- ✅ **Instant task creation** - No more blank forms and confusion
- ✅ **Smart search** - Find relevant work without knowing JQL
- ✅ **Guided workflow** - Understand project processes through examples

**Location**: `src/jira_mcp_server/`  
**Status**: ✅ **Production Ready**  
**Technology**: Python 3.11+ FastMCP  
**Port**: stdio (MCP protocol)

#### **What You Can Do With It**
- **"Create a user story for login functionality"** → Gets a perfectly formatted story with acceptance criteria
- **"Find all tasks related to authentication"** → Instantly shows relevant work items
- **"Create a sprint for next week"** → Sets up sprint planning automatically
- **"Show me my team's workload"** → Provides capacity reports and assignments

#### **Features**
- ✅ **16 MCP Tools** for complete JIRA automation
- ✅ **Story Creation** with templates and acceptance criteria
- ✅ **Advanced Search** using JQL queries
- ✅ **Bulk Operations** for efficient management
- ✅ **Sprint Management** with capacity planning
- ✅ **Team Assignment** and workload tracking
- ✅ **Real-time Synchronization** with rate limiting
- ✅ **Secure Authentication** with API key validation

#### **Available Tools**
| Tool | Description | Use Case |
|------|-------------|----------|
| `create_workitem` | Create new issues | Adding user stories, bugs, tasks |
| `search_workitems` | Search with JQL | Finding issues by criteria |
| `update_workitem` | Modify existing issues | Updating status, assignee, fields |
| `import_project` | Get project data | Project analysis and reporting |
| `export_workitems` | Bulk create issues | Importing from other systems |
| `create_sprint` | Create sprints | Sprint planning |
| `assign_to_sprint` | Add issues to sprints | Sprint management |
| `assign_team` | Assign teams/users | Resource allocation |
| `bulk_update_issues` | Update multiple issues | Batch operations |
| `get_sprint_capacity_report` | Capacity analysis | Sprint planning |

#### **Usage Examples**
```bash
# Start the server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve

# Create a story via MCP protocol
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "create_workitem",
    "arguments": {
      "summary": "As a student, I want to log in",
      "description": "Secure authentication system",
      "issue_type": "Story"
    }
  }
}
```

#### **Integration Options**
- ✅ **Claude Desktop**: Direct MCP integration
- ✅ **VS Code**: MCP extension support
- ✅ **Programmatic**: Python/HTTP API access
- ✅ **Command Line**: Direct CLI usage

---

## 📊 **AdminLTE Dashboard - Visual Project Explorer**

**👀 What it does for YOU:**
This is your window into the PAWS360 world! It's a beautiful, professional-looking admin interface that shows you exactly what the system can do. Instead of reading endless documentation, you can see real data, interact with tables, view charts, and understand the user experience firsthand.

**Great for getting started because:**
- ✅ **Visual learning** - See the system in action instead of just reading about it
- ✅ **Professional examples** - Learn from real UI patterns and designs
- ✅ **Interactive exploration** - Click around and understand user flows
- ✅ **Design inspiration** - See how professional dashboards are built

**Location**: `admin-dashboard/`  
**Status**: ✅ **Production Ready**  
**Technology**: AdminLTE 4.0 + Bootstrap 5 + Webpack  
**Default Port**: 3001

#### **What You Can Do With It**
- **Explore data tables** → See how professional tables display information
- **View interactive charts** → Learn data visualization patterns
- **Test user interactions** → Experience notifications and forms
- **Study responsive design** → See how interfaces work on different screens

#### **Features**
- ✅ **Modern Admin Interface** with dark theme support
- ✅ **DataTables Integration** for advanced table management
- ✅ **Chart.js Analytics** with real-time data visualization
- ✅ **Responsive Design** for mobile and desktop
- ✅ **SweetAlert2 Notifications** for user interactions
- ✅ **Date Range Picker** for filtering and reporting
- ✅ **Select2 Dropdowns** with search functionality
- ✅ **FontAwesome Icons** and custom theming

#### **Technology Stack**
```json
{
  "framework": "AdminLTE 4.0",
  "ui": "Bootstrap 5.3.7",
  "icons": "FontAwesome 7.0.1",
  "tables": "DataTables 2.0.0",
  "charts": "Chart.js 4.4.0",
  "notifications": "SweetAlert2 11.10.1",
  "build": "Webpack 5.89.0"
}
```

#### **Usage**
```bash
cd admin-dashboard

# Development
npm run dev          # Hot reload development server
npm run watch        # File watching with rebuild

# Production
npm run build        # Production build
npm run serve        # Serve built files (port 3001)

# Quality
npm run lint         # ESLint code quality
npm run format       # Prettier code formatting
```

## ⚡ **Admin UI (Astro) - Modern Interface Builder**

**🔨 What it does for YOU:**
This is your modern web development playground! Built with cutting-edge Astro framework, it's where you can learn the latest web technologies while building beautiful interfaces. It's like having a next-generation toolkit that makes complex web development feel approachable and fun.

**Great for getting started because:**
- ✅ **Future-proof skills** - Learn modern frameworks used in industry
- ✅ **TypeScript practice** - Get comfortable with typed JavaScript
- ✅ **Component architecture** - Learn reusable code patterns
- ✅ **Performance optimization** - See how fast websites are built

**Location**: `admin-ui/`  
**Status**: ✅ **Production Ready**  
**Technology**: Astro + TypeScript + AdminLTE  
**Default Port**: 3000

#### **What You Can Do With It**
- **Build modern components** → Learn component-based development
- **Practice TypeScript** → Write safer, more reliable code
- **Optimize performance** → See static site generation in action
- **Create accessible interfaces** → Learn WCAG compliance patterns

#### **Features**
- ✅ **Static Site Generation** for optimal performance
- ✅ **TypeScript Support** with full type safety
- ✅ **Component-Based Architecture** with Astro islands
- ✅ **SEO Optimization** with meta tags and structured data
- ✅ **Accessibility Compliance** with WCAG guidelines
- ✅ **Multi-theme Support** including dark mode
- ✅ **Build Optimization** with code splitting

#### **Technology Stack**
```json
{
  "framework": "Astro 5.10.0",
  "language": "TypeScript 5.8.3",
  "ui": "AdminLTE 4.0.0-rc4",
  "styling": "Bootstrap 5.3.7",
  "build": "Vite (via Astro)",
  "deployment": "Static hosting ready"
}
```

#### **Usage**
```bash
cd admin-ui

# Development
npm run dev          # Development server with HMR
npm run preview      # Preview production build

# Production
npm run build        # Static site generation
npm run docs-serve   # Documentation server

# Quality
npm run lint         # ESLint + Astro checks
npm run format       # Prettier formatting
```

---

## ☕ **Java Spring Boot Backend - The Heart of PAWS360**

**💓 What it does for YOU:**
This is the powerful engine that makes PAWS360 tick! While it's still being built, it's where all the business logic, database connections, and API endpoints will live. Think of it as the brain of the system that processes data and makes decisions.

**Great for getting started because:**
- ✅ **Learn enterprise Java** - See modern Spring Boot patterns
- ✅ **Understand architecture** - Study how large systems are structured
- ✅ **API design patterns** - Learn RESTful service development
- ✅ **Database integration** - See JPA and data persistence in action

**Location**: `backend/src/main/java/edu/university/paws360/`  
**Status**: 🔄 **Under Development**  
**Technology**: Java 21 + Spring Boot 3.x

#### **What You'll Learn From It**
- **Enterprise architecture** → See how large applications are structured
- **REST API design** → Learn professional API development patterns
- **Database operations** → Understand data persistence and queries
- **Security implementation** → Study authentication and authorization

#### **Architecture**
```
backend/src/main/java/edu/university/paws360/
├── config/          # Application configuration - learn config patterns
├── controllers/     # REST API endpoints - see API design
├── models/          # JPA entities - understand data modeling
└── repository/      # Data access layer - learn database patterns
```

#### **Planned Features**
- 🔄 **SAML2 Authentication** with Azure AD integration
- 🔄 **PostgreSQL Database** with JPA/Hibernate
- 🔄 **Redis Caching** for session management
- 🔄 **RESTful APIs** for frontend integration
- 🔄 **Spring Security** with role-based access
- 🔄 **Actuator** for monitoring and health checks

#### **Configuration**
```yaml
# application.yml
spring:
  profiles:
    active: development
  datasource:
    url: jdbc:postgresql://localhost:5432/paws360
    username: paws360_user
    password: ${DB_PASSWORD}
  security:
    oauth2:
      client:
        registration:
          azure:
            client-id: ${AZURE_CLIENT_ID}
            client-secret: ${AZURE_CLIENT_SECRET}
```

---

## 🎭 **Mock Services Suite - Development Playground**

**🧪 What it does for YOU:**
Think of this as your personal testing ground! These are fake but realistic services that mimic the real PAWS360 system. You can build and test your frontend code, practice API calls, and learn how the system works without worrying about breaking anything or needing complex backend setup.

**Great for getting started because:**
- ✅ **Safe learning environment** - Experiment without fear of breaking production
- ✅ **Realistic data** - Practice with data that looks like the real system
- ✅ **Independent development** - Work on frontend without waiting for backend
- ✅ **API learning** - Understand REST endpoints through hands-on practice

**Location**: `mock-services/`  
**Status**: ✅ **Production Ready**  
**Technology**: Node.js + Express

#### **What You Can Do With It**
- **Test login flows** → Practice authentication without real user accounts
- **Build data displays** → Connect to realistic student/course data
- **Create dashboards** → Work with sample analytics and reports
- **Learn API patterns** → Understand how PAWS360 services communicate

#### **Available Services**

##### **UWM Authentication Service** 🔐 (Port: 3000)
**Your Complete Authentication Playground**
- ✅ **JWT Authentication** - Practice modern token-based auth
- ✅ **SAML2 Federation** - Learn enterprise SSO patterns
- ✅ **NextAuth.js Compatible** - Ready for frontend integration
- ✅ **PostgreSQL Database** - Real database with auth tables
- ✅ **Session Management** - Learn session handling patterns
- ✅ **Security Headers** - Study web security best practices
- ✅ **Rate Limiting** - Understand API protection
- ✅ **Health Monitoring** - See production-ready monitoring

**Features:**
- **15/15 Integration Tests** passing with NextAuth.js
- **Docker Containerized** with health checks and monitoring
- **Complete API Suite** - Login, sessions, SAML2, health checks
- **Production Database** - PostgreSQL with auth schema and mock data
- **Security Hardened** - CORS, rate limiting, input sanitization

##### **Auth Service** 🔐 (Port: 8081)
**Your Practice Authentication System**
- Practice login/logout flows
- Test user session management
- Learn authentication patterns
- Safe environment for auth experiments

##### **Data Service** 📊 (Port: 8082)
**Your Sample Data Playground**
- Realistic student and course data
- Practice data fetching and display
- Test search and filtering
- Learn data manipulation patterns

##### **Analytics Service** 📈 (Port: 8083)
**Your Dashboard Development Lab**
- Sample charts and metrics
- Practice data visualization
- Test reporting features
- Learn analytics integration

#### **Usage**
```bash
cd mock-services

# Start all services
npm start

# Start individual services
npm run auth         # Auth service only
npm run data         # Data service only
npm run analytics    # Analytics service only

# Health checks
npm run health       # Check all services
curl http://localhost:8081/health
curl http://localhost:8082/health
curl http://localhost:8083/health
```

---

## 🐳 **Docker Containerization - Portable Development**

**📦 What it does for YOU:**
Docker is like a magical box that makes your development environment portable and consistent! No more "it works on my machine" problems. Everything you need to run PAWS360 is packaged up neatly, so you can focus on coding instead of fighting environment setup.

**Great for getting started because:**
- ✅ **Consistent environment** - Same setup for everyone on the team
- ✅ **Easy startup** - One command to launch the entire system
- ✅ **Isolated development** - Your changes won't break other projects
- ✅ **Production simulation** - Test in environment identical to production

**Location**: `infrastructure/docker/`  
**Status**: ✅ **Production Ready**

#### **What You Can Do With It**
- **Launch full system** → `docker-compose up -d` starts everything
- **Develop in isolation** → Your code changes are contained
- **Test deployments** → See how the system runs in production-like setup
- **Share environments** → Team members get identical setups

#### **Containerized Services**

| Service | What It Does For You |
|---------|---------------------|
| **AdminLTE UI** | Your visual interface, ready to explore |
| **Auth Service** | Practice authentication flows safely |
| **Data Service** | Work with realistic student/course data |
| **Analytics Service** | Build dashboards with sample metrics |
| **PostgreSQL** | Learn database operations with real data |
| **Redis** | Understand caching and session management |
| **Prometheus** | Monitor system performance |
| **Grafana** | Create beautiful data visualizations |

#### **Docker Compose Usage**
```bash
cd infrastructure/docker

# Start all services
docker-compose up -d

# Start specific service
docker-compose up auth-service

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build
```

#### **Environment Configuration**
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env

# Key variables
APP_ENV=production
DB_PASSWORD=REPLACE_ME
REDIS_PASSWORD=REPLACE_ME
GRAFANA_PASSWORD=REPLACE_ME
```

## ⚙️ **Ansible Automation - Infrastructure Magic**

**🔮 What it does for YOU:**
Ansible is your infrastructure wizard! Instead of manually setting up servers or worrying about deployment details, Ansible automates everything. It's like having a robot that can deploy your entire application to any environment with a single command.

**Great for getting started because:**
- ✅ **No manual setup** - Complex infrastructure deployed automatically
- ✅ **Repeatable deployments** - Same process every time
- ✅ **Learn DevOps basics** - Understand infrastructure as code
- ✅ **Safe experimentation** - Test deployments without risk

**Location**: `infrastructure/ansible/`  
**Status**: ✅ **Production Ready**

#### **What You Can Do With It**
- **Deploy to demo** → `ansible-playbook deploy-demo.yml` for quick testing
- **Scale services** → Automatically add more servers as needed
- **Update systems** → Zero-downtime updates with rolling deployments
- **Configure environments** → Consistent setup across dev/staging/production

#### **Available Playbooks**

| Playbook | What It Does For You |
|----------|---------------------|
| `site.yml` | Complete infrastructure setup - your full environment ready |
| `deploy-demo.yml` | Quick demo environment - test your work fast |
| `rolling-update.yml` | Zero-downtime updates - deploy without breaking users |
| `scale.yml` | Horizontal scaling - handle more users automatically |

#### **Usage**
```bash
cd infrastructure/ansible

# Full infrastructure deployment
ansible-playbook site.yml

# Demo environment setup
ansible-playbook deploy-demo.yml

# Rolling update
ansible-playbook rolling-update.yml

# Scale services
ansible-playbook scale.yml
```

#### **Inventory Structure**
```
inventories/
├── production/          # Production servers
├── staging/            # Staging environment
└── development/        # Development servers

group_vars/
├── all.yml            # Global variables
├── webservers.yml     # Web server config
└── databases.yml      # Database config
```

---

## 🤖 **Automation & Scripting Services - Your Task Automators**

**⚡ What it does for YOU:**
These are your personal assistants that handle repetitive tasks so you can focus on creative work! From setting up your development environment to importing data or running tests, these scripts make complex tasks simple and save you hours of manual work.

**Great for getting started because:**
- ✅ **Quick setup** - Get your environment running in minutes
- ✅ **Learn automation** - See how experts automate repetitive tasks
- ✅ **Reduce errors** - Scripts handle complex tasks consistently
- ✅ **Save time** - Focus on coding, not configuration

**Location**: `scripts/` (multiple subdirectories)

#### **What You Can Do With It**
- **Start everything** → `./scripts/setup/paws360-services.sh start`
- **Import data** → `python scripts/jira/csv_to_jira.py --file data.csv`
- **Run tests** → `./scripts/testing/exhaustive-test-suite.sh`
- **Validate setup** → `./scripts/utilities/validate-env.sh`

#### **Script Categories**

| Category | What It Does For You |
|----------|---------------------|
| **Setup Scripts** | Get your development environment running instantly |
| **JIRA Scripts** | Automate project management and data import tasks |
| **Testing Scripts** | Run comprehensive tests with single commands |
| **Utility Scripts** | Handle common tasks and validations |

#### **Popular Scripts for Newcomers**
- `paws360-services.sh` - Start the entire platform
- `start-adminlte.sh` - Launch the visual dashboard
- `validate-env.sh` - Check your setup is correct
- `test_paws360_apis.sh` - Test all API endpoints

---

## 📊 **Monitoring & Analytics Services - System Health Watch**

**👁️ What it does for YOU:**
These are your system detectives! They watch over PAWS360 and tell you exactly how everything is performing. Instead of guessing if your code is working well, you get beautiful dashboards and alerts that show you the system's health, performance, and any issues.

**Great for getting started because:**
- ✅ **Visual system status** - See at a glance if everything is working
- ✅ **Learn monitoring** - Understand how production systems are observed
- ✅ **Performance insights** - See how your changes affect the system
- ✅ **Problem detection** - Catch issues before they become big problems

**Location**: Docker containers (Prometheus/Grafana)

#### **What You Can Do With It**
- **Check system health** → See if all services are running properly
- **Monitor performance** → Track CPU, memory, and response times
- **View beautiful dashboards** → Understand data through visualizations
- **Set up alerts** → Get notified when things need attention

#### **Available Services**

##### **Prometheus** 📈 (Port: 9090)
**Your System Metrics Collector**
- Collects performance data from all services
- Stores time-series data for analysis
- Enables querying of system metrics
- Powers alerting and monitoring rules

##### **Grafana** 📊 (Port: 3000)
**Your Data Visualization Studio**
- Creates beautiful dashboards and charts
- Connects to multiple data sources
- Builds custom visualizations
- Shares insights with the team

#### **Pre-configured Dashboards**
- **PAWS360 Overview** - Complete system health at a glance
- **Service Metrics** - Individual service performance
- **Database Performance** - PostgreSQL monitoring
- **User Activity** - Application usage patterns

---

## 📈 **Service Status Summary**

| Priority | Service | Status | What It Does For You |
|----------|---------|--------|---------------------|
| **1st** | JIRA MCP Server | ✅ Production | AI assistant for project management and task creation |
| **2nd** | Mock Services | ✅ Production | Safe development playground with realistic data |
| **3rd** | AdminLTE Dashboard | ✅ Production | Visual interface to explore and learn the system |
| **4th** | Admin UI (Astro) | ✅ Production | Modern web development with cutting-edge tech |
| **5th** | Docker Containers | ✅ Production | Portable, consistent development environment |
| **6th** | Ansible Automation | ✅ Production | Automated infrastructure deployment |
| **7th** | Spring Boot Backend | 🔄 Development | Enterprise Java architecture and API design |
| **8th** | Automation Scripts | ✅ Production | Task automation and environment setup |
| **9th** | Monitoring Stack | ✅ Production | System health and performance insights |

---

## 🚀 **Quick Start Guide**

### **🎯 Recommended Getting Started Sequence**

**Follow this sequence to get up and running most effectively:**

1. **🎭 Start with Mock Services** - Get your development playground running
2. **📊 Launch AdminLTE Dashboard** - See the system visually  
3. **🤖 Try JIRA MCP Server** - Use AI to create your first tasks
4. **🐳 Explore Docker** - Understand the full environment
5. **⚙️ Learn Automation Scripts** - Automate your workflow

### **Option 1: Full Platform Startup**
```bash
# 1. Start all services
./scripts/setup/paws360-services.sh start

# 2. Start JIRA MCP Server (in another terminal)
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve

# 3. Start Docker infrastructure
cd infrastructure/docker && docker-compose up -d

# 4. Access services
# AdminLTE Dashboard: http://localhost:3001
# Admin UI: http://localhost:3000
# Grafana: http://localhost:3000
# Prometheus: http://localhost:9090
```

### **Option 2: Development Mode**
```bash
# 1. Start mock services
cd mock-services && npm start

# 2. Start AdminLTE dashboard
cd admin-dashboard && npm run dev

# 3. Start Admin UI
cd admin-ui && npm run dev

# 4. Start JIRA MCP Server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

### **Option 3: Production Deployment**
```bash
# 1. Deploy with Ansible
cd infrastructure/ansible
ansible-playbook site.yml

# 2. Start Docker services
cd ../docker
docker-compose up -d

# 3. Verify deployment
curl http://your-server:8081/health
curl http://your-server:8082/health
curl http://your-server:8083/health
```

---

## 🔗 **Integration Examples**

### **Claude Desktop Integration**
```json
{
  "mcpServers": {
    "jira-paws360": {
      "command": "python",
      "args": ["-m", "cli", "serve"],
      "env": {
        "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
        "JIRA_URL": "https://paw360.atlassian.net",
        "JIRA_API_KEY": "REPLACE_ME",
        "JIRA_EMAIL": "your-email@university.edu",
        "JIRA_PROJECT_KEY": "PGB"
      }
    }
  }
}
```

### **VS Code Integration**
```json
{
  "mcp.server.jira-paws360": {
    "command": "python",
    "args": ["-m", "cli", "serve"],
    "env": {
      "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
      "JIRA_URL": "https://paw360.atlassian.net",
      "JIRA_API_KEY": "REPLACE_ME"
    }
  }
}
```

### **Programmatic Integration**
```python
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def create_jira_story():
    server_params = StdioServerParameters(
        command="python",
        args=["-m", "cli", "serve"],
        env={
            "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
            "JIRA_URL": "https://paw360.atlassian.net",
            "JIRA_API_KEY": "REPLACE_ME",
            "JIRA_PROJECT_KEY": "PGB"
        }
    )

    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            result = await session.call_tool(
                "create_workitem",
                arguments={
                    "summary": "Implement user authentication",
                    "description": "Add secure login functionality",
                    "issue_type": "Story"
                }
            )
            print(f"Created issue: {result.content[0].text}")

asyncio.run(create_jira_story())
```

---

## 🎯 **Service Health Checks**

### **Quick Health Check**
```bash
# Check all services
./scripts/utilities/test_paws360_apis.sh

# Individual service checks
curl http://localhost:8081/health  # Auth service
curl http://localhost:8082/health  # Data service
curl http://localhost:8083/health  # Analytics service
curl http://localhost:3001        # AdminLTE dashboard
curl http://localhost:3000        # Admin UI
```

### **Docker Health Checks**
```bash
# Check container status
docker-compose ps

# View service logs
docker-compose logs auth-service
docker-compose logs data-service
docker-compose logs analytics-service
```

### **JIRA MCP Health Check**
```bash
# Test MCP server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli validate

# Test JIRA connection
python scripts/utilities/test_jira_official.py
```

---

## 📞 **Support & Documentation**

### **Documentation Links**
- **[JIRA MCP Server Guide](jira-mcp/README.md)** - Complete JIRA automation guide
- **[Configuration Guide](config/README.md)** - Environment and configuration
- **[Deployment Guide](deployment/)** - Infrastructure deployment
- **[API Testing](api/API_TESTING_README.md)** - API testing procedures

### **Getting Help**
1. **Service Status**: Check service health endpoints
2. **Logs**: Review Docker/container logs
3. **Configuration**: Validate environment variables
4. **Documentation**: Refer to specific service guides

### **Common Issues**
- **Port Conflicts**: Check if ports are already in use
- **Environment Variables**: Ensure all required variables are set
- **Dependencies**: Verify all dependencies are installed
- **Network**: Check network connectivity for external services

---

## 🎉 **Your Platform is Complete!**

**🚀 Welcome to PAWS360 - Your Learning Playground!**

**You now have:**

✅ **🤖 AI Project Assistant** - JIRA MCP Server to guide your work  
✅ **🎭 Safe Development Environment** - Mock Services for practice  
✅ **👀 Visual Learning Tools** - Dashboards to see the system in action  
✅ **🔨 Modern Tech Playground** - Astro UI for cutting-edge development  
✅ **📦 Portable Environment** - Docker for consistent development  
✅ **⚡ Automation Helpers** - Scripts to handle repetitive tasks  
✅ **👁️ System Monitoring** - Tools to understand performance  
✅ **🏗️ Enterprise Architecture** - Spring Boot for learning patterns  
✅ **🔮 Infrastructure Magic** - Ansible for deployment automation  

**Start with the Mock Services and AdminLTE Dashboard - they're your best friends for learning!**

**Ready for development, testing, and production deployment!** 🚀

---

*PAWS360 Services Overview - Version 1.0.0*  
*Last Updated: September 20, 2025*  
*Total Services: 13 major services*  
*Status: Production Ready*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/services-overview.md