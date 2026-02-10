# PAWS360 Installation Requirements & Setup Guide

## 📋 System Requirements

### Required Software
- **Python 3.10+** - For JIRA MCP server and data processing
- **Node.js 16+** (18+ recommended) - For frontend and mock services
- **Java 21+** - For Spring Boot backend services
- **npm** - Node.js package manager
- **pip** - Python package manager

### Optional but Recommended
- **Docker & Docker Compose** - For full containerized deployment
- **PostgreSQL** - For database functionality
- **Git** - For version control

## 🚀 Quick Start

### Option 1: Comprehensive Setup (Recommended)
```bash
# Run the comprehensive startup script
./_startup.sh
```

### Option 2: Manual Setup
Follow the step-by-step installation guide below.

## 📦 Detailed Installation Steps

### Step 1: System Dependencies

#### Ubuntu/Debian
```bash
# Update package list
sudo apt update

# Install Python 3.11+
sudo apt install -y python3.11 python3.11-venv python3-pip

# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Java 21+
sudo apt install -y openjdk-21-jdk

# Install additional tools
sudo apt install -y curl wget git postgresql-client
```

#### macOS (with Homebrew)
```bash
# Install Python 3.11+
brew install python@3.11

# Install Node.js 18+
brew install node@18

# Install Java 21+
brew install openjdk@21

# Install additional tools
brew install curl wget git postgresql
```

#### Windows (WSL2 Recommended)
```powershell
# Use WSL2 with Ubuntu, then follow Ubuntu/Debian instructions
wsl --install -d Ubuntu
```

### Step 2: Verify Installations

```bash
# Python 3.10+
python3 --version  # Should show 3.10 or higher

# Node.js 16+
node --version     # Should show v16 or higher
npm --version      # Should show version number

# Java 21+
java --version     # Should show version 21 or higher

# Optional: Docker
docker --version
docker-compose --version
```

### Step 3: Project Setup

```bash
# Clone or navigate to project directory
cd /home/ryan/repos/PAWS360ProjectPlan

# Make scripts executable
chmod +x *.sh
chmod +x scripts/*.sh

# Run comprehensive setup
./_startup.sh
```

## 🏗️ Project Components

### Python Components
- **JIRA MCP Server** (`pyproject.toml`)
  - Python 3.10+
  - Dependencies: mcp, requests, pydantic, python-jose, click, python-dotenv, structlog
  - Optional dev dependencies: pytest, black, flake8, mypy, pre-commit

### Node.js Components
- **Mock Services** (`mock-services/package.json`)
  - Node.js 16+
  - Express.js, CORS
  - Ports: 8081 (auth), 8082 (data), 8083 (analytics)

- **Admin Dashboard** (`admin-dashboard/package.json`)
  - Node.js 16+
  - AdminLTE 4.0.0-rc4, Bootstrap 5, Chart.js, DataTables
  - Webpack build system
  - Port: 3001 (dev), built files served via other services

- **Admin UI** (`admin-ui/package.json`)
  - AdminLTE theme files
  - Port: 8080 (production)

### Java Components
- **Spring Boot Services** (planned)
  - Java 21+
  - Spring Boot 3.x
  - PostgreSQL, Redis
  - SAML2 Authentication

### Docker Components (Optional)
- **Full Stack Deployment** (`docker-compose.yml`)
  - PostgreSQL, Redis
  - Prometheus, Grafana
  - Nginx reverse proxy
  - All services containerized

## 🌐 Service Architecture

| Service | Port | Technology | Purpose |
|---------|------|------------|---------|
| **AdminLTE UI** | 8080 | Nginx/Node.js | Main dashboard interface |
| **Auth Service** | 8081 | Node.js/Express | Authentication & authorization |
| **Data Service** | 8082 | Node.js/Express | Student/course data API |
| **Analytics Service** | 8083 | Node.js/Express | Analytics & reporting |
| **Admin Dashboard** | 3001 | Node.js/Webpack | Development dashboard |
| **PostgreSQL** | 5432/5433 | Docker | Primary/Read replica database |
| **Redis** | 6379 | Docker | Session store & caching |
| **Prometheus** | 9090 | Docker | Metrics collection |
| **Grafana** | 3000 | Docker | Dashboard visualization |

## 🚦 Startup Methods

### Method 1: Docker Compose (Full Production Stack)
```bash
# Requires Docker & Docker Compose
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Method 2: Mock Services (Development)
```bash
# Start all services
./paws360-services.sh start

# Start individual services
./paws360-services.sh start auth
./paws360-services.sh start data
./paws360-services.sh start analytics
./paws360-services.sh start ui

# Check status
./paws360-services.sh status

# Test endpoints
./paws360-services.sh test
```

### Method 3: Admin Dashboard Only
```bash
cd admin-dashboard
npm run dev
# Access at http://localhost:3001
```

## 🧪 Testing & Validation

### Health Checks
```bash
# Test all services
./paws360-services.sh test

# Individual health checks
curl http://localhost:8081/health
curl http://localhost:8082/health
curl http://localhost:8083/health
curl http://localhost:8080/
```

### Sample API Calls
```bash
# Authentication
curl -X POST http://localhost:8081/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Student data
curl http://localhost:8082/api/students

# Course data
curl http://localhost:8082/api/courses
```

## 🔧 Troubleshooting

### Common Issues

#### Python Issues
```bash
# Virtual environment issues
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -e .

# Permission issues
pip install --user -e .
```

#### Node.js Issues
```bash
# Clear npm cache
npm cache clean --force

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Port conflicts
lsof -ti:8080 | xargs kill -9
```

#### Java Issues
```bash
# Check Java version
java --version
echo $JAVA_HOME

# Set Java 21 if multiple versions
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

#### Docker Issues
```bash
# Check Docker status
sudo systemctl status docker

# Start Docker service
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

### Service-Specific Issues

#### Mock Services Won't Start
```bash
# Check Node.js version
node --version

# Check if ports are available
lsof -i :8081
lsof -i :8082
lsof -i :8083

# Check logs
./paws360-services.sh logs auth
```

#### Admin Dashboard Build Issues
```bash
cd admin-dashboard

# Clear build cache
npm run clean

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check for Sass issues
npm ls sass
npm ls sass-loader
```

## 📚 Additional Resources

- **Project Documentation**: `WELCOME-KIT.md`
- **File Structure Guide**: `FILE-STRUCTURE-GUIDE.md`
- **Quick Reference**: `QUICK-REFERENCE-CARD.md`
- **Service Management**: `PAWS360-SERVICES-README.md`
- **JIRA Integration**: `JIRA-IMPORT-HOWTO.md`

## 🆘 Getting Help

1. Check the troubleshooting section above
2. Review the relevant documentation files
3. Check service logs: `./paws360-services.sh logs <service>`
4. Verify all requirements are met: `./_startup.sh`
5. Test individual components in isolation

## 📝 Environment Variables

Create a `.env` file based on `.env.example`:

```bash
# JIRA Configuration
JIRA_URL=https://paw360.atlassian.net
JIRA_API_KEY=REPLACE_ME
JIRA_PROJECT_KEY=PGB

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=paws360
DB_USER=paws360_user
DB_PASSWORD=REPLACE_ME

# Application Configuration
NODE_ENV=development
JAVA_OPTS=-Xmx2g -Xms512m

# Security
JWT_SECRET=REPLACE_ME
ENCRYPTION_KEY=REPLACE_ME
```

---

**Last Updated**: September 19, 2025
**PAWS360 Version**: 1.0.0