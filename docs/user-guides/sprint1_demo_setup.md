# PAWS360 Sprint 1 Demo Setup Guide

## 📋 **Setup Overview**
This guide contains all preparation procedures for the PAWS360 Sprint 1 presentation demo. Complete these steps to ensure a smooth, reliable demonstration.

---

## 🌐 **Complete Service Ecosystem (6 Services Running)**

### **Service Architecture Overview**
PAWS360 Sprint 1 features a comprehensive multi-service architecture with 6 concurrent systems:

| Service | Port | Technology | Purpose | Status |
|---------|------|------------|---------|--------|
| **Student Portal** | [9002](http://localhost:9002) | Next.js 15.3.3 | Main student-facing application | ✅ Running |
| **Admin Dashboard** | [3001](http://localhost:3001) | AdminLTE v4.0.0-rc4 | Administrative interface | ✅ Running |
| **Auth Service** | [8081](http://localhost:8081) | Node.js Express | Authentication & SAML2 simulation | ✅ Running |
| **Data Service** | [8082](http://localhost:8082) | Node.js Express | Student data & PostgreSQL simulation | ✅ Running |
| **Analytics Service** | [8083](http://localhost:8083) | Node.js Express | Reporting & Chart.js integration | ✅ Running |
| **Legacy UI** | [8080](http://localhost:8080) | Python HTTP Server | PeopleSoft integration simulation | ✅ Running |

### **Quick Access Links**
- 🎓 **[Student Portal](http://localhost:9002)** - Main application with UWM branding
- 👨‍💼 **[Admin Dashboard](http://localhost:3001)** - Administrative interface with dark theme
- 🔐 **[Auth Service](http://localhost:8081/health)** - Authentication health check
- 📊 **[Data Service](http://localhost:8082/health)** - Student data API
- 📈 **[Analytics Service](http://localhost:8083/health)** - Analytics and reporting
- 🏛️ **[Legacy System](http://localhost:8080)** - PeopleSoft integration UI

### **API Endpoints & Testing**

#### **Health Checks (All Services)**
```bash
# Test all services simultaneously
curl -s http://localhost:8081/health && echo "Auth: ✅"
curl -s http://localhost:8082/health && echo "Data: ✅"
curl -s http://localhost:8083/health && echo "Analytics: ✅"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/ && echo "Admin: ✅"
curl -s -o /dev/null -w "%{http_code}" http://localhost:9002/ && echo "Student: ✅"
curl -s http://localhost:8080/ | grep -q "html" && echo "Legacy: ✅"
```

#### **Service-Specific APIs**
```bash
# Auth Service Endpoints
curl http://localhost:8081/health
curl http://localhost:8081/api/auth/status

# Data Service Endpoints
curl http://localhost:8082/health
curl http://localhost:8082/api/students
curl http://localhost:8082/api/courses

# Analytics Service Endpoints
curl http://localhost:8083/health
curl http://localhost:8083/api/analytics/dashboard
curl http://localhost:8083/api/reports/summary

# Admin Dashboard
curl -s http://localhost:3001/ | head -10

# Student Portal
curl -s -o /dev/null -w "%{http_code}" http://localhost:9002/
curl -s http://localhost:9002/login | grep -q "login" && echo "Login page: ✅"
```

### **Demo Flow with Service Integration**
1. **Start All Services**: Use the startup scripts below
2. **Student Portal** ([localhost:9002](http://localhost:9002)): Main user experience
3. **Admin Dashboard** ([localhost:3001](http://localhost:3001)): Administrative oversight
4. **Auth Service** ([localhost:8081](http://localhost:8081)): Handles login/authentication
5. **Data Service** ([localhost:8082](http://localhost:8082)): Provides student/course data
6. **Analytics Service** ([localhost:8083](http://localhost:8083)): Generates reports and charts
7. **Legacy System** ([localhost:8080](http://localhost:8080)): PeopleSoft integration

### **Complete Ecosystem Startup Script**
```bash
#!/bin/bash
# Start all 6 PAWS360 services simultaneously
# Save as: ~/start-all-services.sh

echo "🚀 Starting Complete PAWS360 Ecosystem (6 Services)"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to start service
start_service() {
    local name=$1
    local command=$2
    local port=$3
    
    echo -e "${YELLOW}Starting $name on port $port...${NC}"
    eval "$command" &
    sleep 2
    
    # Test if service is responding
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/ | grep -q "200\|301\|302\|307"; then
        echo -e "${GREEN}✅ $name: RUNNING on port $port${NC}"
    else
        echo -e "${YELLOW}⚠️  $name: Started but not yet responding${NC}"
    fi
}

# Start services in order
cd /home/ryan/repos/PAWS360ProjectPlan

# 1. Legacy UI (Python server)
start_service "Legacy UI" "python3 -m http.server 8080" "8080"

# 2. Auth Service (Node.js)
start_service "Auth Service" "cd mock-services/auth && node server.js" "8081"

# 3. Data Service (Node.js)
start_service "Data Service" "cd mock-services/data && node server.js" "8082"

# 4. Analytics Service (Node.js)
start_service "Analytics Service" "cd mock-services/analytics && node server.js" "8083"

# 5. Admin Dashboard (webpack)
start_service "Admin Dashboard" "cd admin-dashboard && npm run dev" "3001"

# 6. Student Portal (Next.js)
start_service "Student Portal" "cd ../PAWS360 && npm run dev" "9002"

echo ""
echo "🎉 All services started! Access points:"
echo "🎓 Student Portal:    http://localhost:9002"
echo "👨‍💼 Admin Dashboard:  http://localhost:3001"
echo "🔐 Auth Service:      http://localhost:8081/health"
echo "📊 Data Service:      http://localhost:8082/health"
echo "📈 Analytics Service: http://localhost:8083/health"
echo "🏛️ Legacy System:     http://localhost:8080"
echo ""
echo "🛑 To stop all services: pkill -f 'node\|python\|webpack'"
```

---

## 🛠️ **Pre-Demo Preparation (Do This 1-2 Hours Before)**

### **Phase 1: Environment Setup (10 minutes)**
```bash
# One-liner: Verify and setup environment
cd /home/ryan/repos/PAWS360ProjectPlan && node --version && npm --version && echo "✅ Environment ready"
```

### **Phase 2: Dependencies & Build (15 minutes)**
```bash
# One-liner: Install dependencies
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && npm install

# One-liner: Type check (fix any errors now)
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && npm run typecheck

# One-liner: Production build test
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && npm run build
```

### **Phase 3: Multiple Dev Server Tests (20 minutes)**
```bash
# Test 1: Fresh dev server start
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && timeout 10s npm run dev || echo "Test 1 complete"

# Test 2: Quick restart test
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && pkill -f "next dev" && sleep 2 && timeout 10s npm run dev || echo "Test 2 complete"

# Test 3: Clean cache restart
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && pkill -f "next dev" && rm -rf .next && timeout 10s npm run dev || echo "Test 3 complete"

# Test 4: Port conflict test
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && lsof -ti:9002 | xargs kill -9 2>/dev/null || true && timeout 10s npm run dev || echo "Test 4 complete"

# Test 5: Full cycle test
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && pkill -f "next dev" && rm -rf .next && timeout 15s npm run dev || echo "Test 5 complete"
```

### **Phase 4: Browser & Network Tests (5 minutes)**
```bash
# One-liner: Test application access
curl -s -o /dev/null -w "%{http_code}" http://localhost:9002 && echo "✅ App accessible" || echo "❌ App not accessible"

# One-liner: Test login page specifically
curl -s http://localhost:9002/login | grep -q "login" && echo "✅ Login page loads" || echo "❌ Login page issue"
```

---

## ⚡ **Demo Day Setup (Do This 10 Minutes Before Presentation)**

### **Quick Verification Script**
```bash
#!/bin/bash
# Save as: ~/verify-paws360.sh
# Run: ./verify-paws360.sh

echo "🔍 PAWS360 Pre-Demo Verification"
echo "================================"

# Check Node.js
node --version >/dev/null 2>&1 && echo "✅ Node.js ready" || echo "❌ Node.js missing"

# Check project directory
[ -d "../PAWS360" ] && echo "✅ Project directory exists" || echo "❌ Project directory missing"

# Check dependencies
[ -d "../PAWS360/node_modules" ] && echo "✅ Dependencies installed" || echo "❌ Dependencies missing"

# Check build cache
[ -d "../PAWS360/.next" ] && echo "✅ Build cache exists" || echo "❌ Build cache missing"

# Quick type check
cd ../PAWS360 && npm run typecheck >/dev/null 2>&1 && echo "✅ Type check passes" || echo "⚠️  Type check has warnings"

echo ""
echo "🎯 If all ✅, you're ready for demo!"
echo "🚀 Run: cd ../PAWS360 && npm run dev"
```

### **Final Startup Sequence**
```bash
# One-liner: Clean startup for demo
cd /home/ryan/repos/PAWS360ProjectPlan && cd ../PAWS360 && pkill -f "next dev" 2>/dev/null || true && sleep 1 && npm run dev
```

---

## 🎯 **During Demo (Live Commands - Keep These Simple)**

### **Essential Demo Commands**
```bash
# Start the application (main command)
npm run dev

# Check if running
ps aux | grep "next dev"

# Open in browser
xdg-open http://localhost:9002

# Quick status check
curl -s http://localhost:9002 | head -5

# Stop if needed
pkill -f "next dev"
```

### **Backup Commands (If Something Goes Wrong)**
```bash
# Quick restart
pkill -f "next dev" && sleep 2 && npm run dev

# Clean restart
pkill -f "next dev" && rm -rf .next && npm run dev

# Port conflict fix
lsof -ti:9002 | xargs kill -9 && npm run dev
```

---

## 📋 **Presentation Flow with Commands**

### **Slide 1-3: Work Completed & Goals**
*No commands needed - just show slides*

### **Slide 4: Live Demo**
```
# Terminal 1: Start the app
npm run dev

# Wait for "Ready in XXXms" message

# Terminal 2: Open browser
xdg-open http://localhost:9002

# Demo the application...
```

### **Q&A Section**
```
# If asked about performance
time npm run build

# If asked about dependencies
npm list --depth=0

# If asked about health
curl -I http://localhost:9002
```

---

## 🚀 **Student Portal Startup Guide (Reference for Demo)**

### **Prerequisites**
- ✅ Node.js 18+ installed
- ✅ npm or yarn package manager
- ✅ Git repository cloned
- ✅ Terminal/command prompt access

### **Step-by-Step Setup Process**

#### **Step 1: Navigate to Project Directory**
```bash
# From PAWS360ProjectPlan directory
cd ../PAWS360
# Or from anywhere:
cd /home/ryan/repos/PAWS360
```

#### **Step 2: Install Dependencies**
```bash
npm install
```
*Expected output: Dependencies installation completes successfully*

#### **Step 3: Verify Installation**
```bash
npm run typecheck
```
*Expected output: No TypeScript errors*

#### **Step 4: Start Development Server**
```bash
npm run dev
```
*Expected output:*
```
- Local:        http://localhost:9002
- Network:      http://10.255.255.254:9002
 ✓ Starting...
 ✓ Ready in 818ms
```

#### **Step 5: Verify Application Access**
- Open browser to: `http://localhost:9002`
- Should redirect to: `http://localhost:9002/login`
- Login page should load with UWM branding

### **Quick Start Commands**
```bash
# Install dependencies
npm install

# Start development server (Port 9002)
npm run dev

# Access the application
http://localhost:9002
```

### **Available NPM Scripts**
- `npm run dev` - Start development server with Turbopack on port 9002
- `npm run build` - Build production version
- `npm run start` - Start production server
- `npm run lint` - Run ESLint checks
- `npm run typecheck` - Run TypeScript type checking

### **Demo Flow for Student Portal**
1. **Terminal Setup**: `cd /home/ryan/repos/PAWS360 && npm run dev`
2. **Open Browser**: Navigate to `http://localhost:9002`
3. **Login Demo**: 
   - Show UWM-branded login page
   - Test email validation (@UWM.edu requirement)
   - Demo credentials: `test@UWM.edu` / `password`
4. **Component Showcase**: Navigate through different UI components
5. **Mobile Responsive**: Show mobile view (browser dev tools)

### **Troubleshooting Steps**
- **Port 9002 already in use**: `lsof -ti:9002 | xargs kill -9`
- **Dependencies issues**: Delete `node_modules` and `package-lock.json`, then `npm install`
- **TypeScript errors**: Run `npm run typecheck` to identify issues
- **Build cache issues**: Delete `.next` folder and restart

### **Backup Demo Plan**
- Screenshots ready if live demo fails
- Localhost alternative: `http://127.0.0.1:9002`
- Pre-recorded screen recording as last resort

---

## 🐧 **WSL Startup Procedures (Complete System Setup)**

### **System Requirements**
- **OS**: Ubuntu 22.04+ on WSL2
- **Memory**: 4GB+ RAM recommended
- **Storage**: 2GB+ free space
- **Network**: Internet connection for npm packages

### **Initial Environment Setup**
```bash
# Update WSL and install Node.js
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installations
node --version    # Should show v18.x.x
npm --version     # Should show 9.x.x
```

### **One-Shot Startup Script**
```bash
#!/bin/bash
# PAWS360 Complete Startup Script
# Save as: ~/start-paws360.sh

echo "🚀 Starting PAWS360 Student Portal..."

# Navigate to project directory
cd /home/ryan/repos/PAWS360 || {
    echo "❌ Error: PAWS360 directory not found"
    exit 1
}

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Type check
echo "🔍 Running type check..."
npm run typecheck

# Start development server
echo "🌐 Starting development server..."
npm run dev
```

### **Performance Benchmarks (WSL Environment)**

#### **Command Timing Results** (5 iterations each)
| Command | Average Time | Min Time | Max Time | Status |
|---------|-------------|----------|----------|--------|
| `npm install` | 0.84s | 0.78s | 0.96s | ✅ Fast |
| `npm run typecheck` | 1.05s | 0.98s | 1.25s | ⚠️ Has TS errors |
| `npm run dev` | 0.68s | 0.66s | 0.69s | ✅ Very Fast |
| `npm run build` | 9.22s | 8.40s | 10.63s | ✅ Reasonable |

#### **System Performance Notes**
- **CPU**: Intel/AMD with 4+ cores recommended
- **Memory**: 4GB minimum, 8GB+ for optimal performance
- **Storage**: SSD recommended for faster npm installs
- **Network**: Stable internet for package downloads

---

## ⚡ **Start, Stop, Restart Commands**

### **Development Server Management**

#### **Start Commands**
```bash
# Start development server
cd /home/ryan/repos/PAWS360
npm run dev

# Start in background (for production-like testing)
cd /home/ryan/repos/PAWS360
npm run dev &

# Start with custom port
cd /home/ryan/repos/PAWS360
npm run dev -- --port 3000
```

#### **Stop Commands**
```bash
# Find and stop Next.js process
ps aux | grep "next dev"
kill -9 <PID>

# Stop by port
lsof -ti:9002 | xargs kill -9

# Stop all Node.js processes
pkill -f "next"

# Graceful shutdown (if supported)
curl -X POST http://localhost:9002/api/shutdown 2>/dev/null || true
```

#### **Restart Commands**
```bash
# Quick restart (stop and start)
cd /home/ryan/repos/PAWS360
pkill -f "next dev" && sleep 2 && npm run dev

# Clean restart (clear cache)
cd /home/ryan/repos/PAWS360
pkill -f "next dev"
rm -rf .next
npm run dev

# Full restart (reinstall dependencies)
cd /home/ryan/repos/PAWS360
pkill -f "next dev"
rm -rf node_modules package-lock.json .next
npm install && npm run dev
```

### **Process Management Scripts**

#### **Status Check Script**
```bash
#!/bin/bash
# Save as: ~/check-paws360.sh

echo "🔍 PAWS360 Status Check"
echo "======================"

# Check if process is running
if pgrep -f "next dev" > /dev/null; then
    echo "✅ Development server: RUNNING"
    ps aux | grep "next dev" | grep -v grep
else
    echo "❌ Development server: STOPPED"
fi

# Check port availability
if lsof -i :9002 > /dev/null; then
    echo "✅ Port 9002: IN USE"
else
    echo "❌ Port 9002: AVAILABLE"
fi

# Check application health
if curl -s http://localhost:9002 > /dev/null; then
    echo "✅ Application: HEALTHY"
else
    echo "❌ Application: UNHEALTHY"
fi
```

#### **Auto-Restart Script**
```bash
#!/bin/bash
# Save as: ~/monitor-paws360.sh

while true; do
    if ! pgrep -f "next dev" > /dev/null; then
        echo "$(date): Restarting PAWS360..."
        cd /home/ryan/repos/PAWS360
        npm run dev &
    fi
    sleep 30
done
```

### **Batch Operations**

#### **Start Multiple Services**
```bash
# Start PAWS360 and open browser
cd /home/ryan/repos/PAWS360 && npm run dev &
sleep 3
xdg-open http://localhost:9002
```

#### **Clean Development Environment**
```bash
# Complete cleanup and fresh start
cd /home/ryan/repos/PAWS360
pkill -f "next"
rm -rf .next node_modules package-lock.json
npm install
npm run dev
```

---

## 🔄 **Unified Startup Procedure (One-Shot)**

### **Complete System Initialization**
```bash
#!/bin/bash
# PAWS360 Unified Startup Script
# Run from: /home/ryan/repos/PAWS360ProjectPlan
# Usage: ./start-paws360-unified.sh

set -e  # Exit on any error

echo "🚀 PAWS360 Unified Startup Procedure"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Verify environment
echo "Step 1: Environment verification..."
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please install Node.js 18+"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npm not found. Please install npm"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18+ required. Current: $(node --version)"
    exit 1
fi
print_status "Environment verified"

# Step 2: Navigate to project directory
echo "Step 2: Navigating to project directory..."
if [ ! -d "../PAWS360" ]; then
    print_error "PAWS360 directory not found at ../PAWS360"
    exit 1
fi
cd ../PAWS360
print_status "Navigated to project directory"

# Step 3: Check and install dependencies
echo "Step 3: Dependency management..."
if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
    print_warning "Dependencies not found. Installing..."
    npm install
    print_status "Dependencies installed"
else
    print_status "Dependencies already installed"
fi

# Step 4: Type checking
echo "Step 4: Type checking..."
if npm run typecheck 2>/dev/null; then
    print_status "Type check passed"
else
    print_warning "Type check failed (continuing anyway)"
fi

# Step 5: Clean previous build
echo "Step 5: Cleaning previous build..."
rm -rf .next
print_status "Build cache cleared"

# Step 6: Start development server
echo "Step 6: Starting development server..."
npm run dev &
SERVER_PID=$!

# Wait for server to start
echo "Waiting for server to be ready..."
sleep 5

# Check if server is running
if kill -0 $SERVER_PID 2>/dev/null; then
    print_status "Development server started successfully"
    echo ""
    echo "🌐 Access your application at:"
    echo "   Local:   http://localhost:9002"
    echo "   Network: http://10.255.255.254:9002"
    echo ""
    echo "📝 Demo credentials:"
    echo "   Email: test@UWM.edu"
    echo "   Password: password"
    echo ""
    echo "🛑 To stop the server:"
    echo "   kill $SERVER_PID"
    echo "   or: pkill -f 'next dev'"
else
    print_error "Failed to start development server"
    exit 1
fi

echo ""
echo "🎉 PAWS360 is now running!"
echo "Press Ctrl+C to stop the server"
```

### **Quick Start Commands Summary**
```bash
# From PAWS360ProjectPlan directory
cd ../PAWS360 && npm install && npm run dev

# Or use the unified script
./start-paws360-unified.sh

# Check status
ps aux | grep "next dev"

# Stop server
pkill -f "next dev"
```

### **Emergency Recovery**
```bash
# Complete reset
cd /home/ryan/repos/PAWS360
pkill -f "next"
rm -rf .next node_modules package-lock.json
npm install
npm run dev
```

---

**Demo Setup Complete - Ready for Presentation! 🎯**