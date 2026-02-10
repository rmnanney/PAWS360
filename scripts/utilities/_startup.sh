#!/bin/bash
# PAWS360 Comprehensive Startup Script
# Run from: /home/ryan/repos/PAWS360ProjectPlan
# Usage: ./_startup.sh

set -e  # Exit on any error

echo "🚀 PAWS360 Comprehensive Startup Procedure"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Environment verification
echo "Step 1: Comprehensive Environment Verification"
echo "==============================================="

# Check Python 3.10+
print_status "Checking Python 3.10+..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$PYTHON_MAJOR" -gt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 10 ]); then
        print_success "Python $PYTHON_VERSION found"
    else
        print_error "Python 3.10+ required. Current: $PYTHON_VERSION"
        print_status "Installing Python 3.11..."
        sudo apt update && sudo apt install -y python3.11 python3.11-venv python3-pip
    fi
else
    print_error "Python3 not found"
    print_status "Installing Python 3.11..."
    sudo apt update && sudo apt install -y python3.11 python3.11-venv python3-pip
fi

# Check Node.js 16+
print_status "Checking Node.js 16+..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 16 ]; then
        print_success "Node.js $(node --version) found"
    else
        print_error "Node.js 16+ required. Current: $(node --version)"
        print_status "Installing Node.js 18..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    print_error "Node.js not found"
    print_status "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm not found"
    print_status "Installing npm..."
    sudo apt install -y npm
else
    print_success "npm $(npm --version) found"
fi

# Check Java 21 (for Spring Boot services)
print_status "Checking Java 21..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java --version 2>&1 | head -n1 | grep -oP '\d+')
    if [ "$JAVA_VERSION" -ge 21 ]; then
        print_success "Java $JAVA_VERSION found"
    else
        print_error "Java 21+ required. Current: $JAVA_VERSION"
        print_status "Installing OpenJDK 21..."
        sudo apt install -y openjdk-21-jdk
    fi
else
    print_error "Java not found"
    print_status "Installing OpenJDK 21..."
    sudo apt install -y openjdk-21-jdk
fi

# Check Docker (optional but recommended)
print_status "Checking Docker..."
if command -v docker &> /dev/null; then
    print_success "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') found"
    DOCKER_AVAILABLE=true
else
    print_warning "Docker not found - containerized deployment will not be available"
    DOCKER_AVAILABLE=false
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    print_success "Docker Compose found"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    print_success "Docker Compose V2 found"
else
    print_warning "Docker Compose not found - containerized deployment will not be available"
fi

print_success "Environment verification complete"

# Step 2: Python dependencies setup
echo ""
echo "Step 2: Python Dependencies Setup"
echo "=================================="

print_status "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_success "Virtual environment already exists"
fi

print_status "Activating virtual environment and installing dependencies..."
source venv/bin/activate

if [ -f "pyproject.toml" ]; then
    if command -v pip &> /dev/null; then
        pip install --upgrade pip
        pip install -e .
        print_success "Python dependencies installed from pyproject.toml"
    else
        print_error "pip not found"
        exit 1
    fi
else
    print_warning "pyproject.toml not found - skipping Python dependencies"
fi

# Step 3: Node.js dependencies setup
echo ""
echo "Step 3: Node.js Dependencies Setup"
echo "==================================="

# Install root-level dependencies (if any)
if [ -f "package.json" ] && [ -f "package-lock.json" ]; then
    print_status "Installing root-level Node.js dependencies..."
    npm install
    print_success "Root-level dependencies installed"
elif [ -f "package.json" ]; then
    print_status "Installing root-level Node.js dependencies..."
    npm install
    print_success "Root-level dependencies installed"
fi

# Install mock-services dependencies
if [ -d "mock-services" ] && [ -f "mock-services/package.json" ]; then
    print_status "Installing mock-services dependencies..."
    cd mock-services
    npm install
    cd ..
    print_success "Mock-services dependencies installed"
fi

# Install admin-dashboard dependencies
if [ -d "admin-dashboard" ] && [ -f "admin-dashboard/package.json" ]; then
    print_status "Installing admin-dashboard dependencies..."
    cd admin-dashboard
    npm install
    cd ..
    print_success "Admin-dashboard dependencies installed"
fi

# Install admin-ui dependencies (if exists)
if [ -d "admin-ui" ] && [ -f "admin-ui/package.json" ]; then
    print_status "Installing admin-ui dependencies..."
    cd admin-ui
    npm install
    cd ..
    print_success "Admin-ui dependencies installed"
fi

# Step 4: Build frontend assets
echo ""
echo "Step 4: Frontend Assets Build"
echo "=============================="

# Build admin-dashboard
if [ -d "admin-dashboard" ]; then
    print_status "Building admin-dashboard..."
    cd admin-dashboard
    npm run build
    cd ..
    print_success "Admin-dashboard built successfully"
fi

# Build admin-ui (if exists)
if [ -d "admin-ui" ]; then
    print_status "Building admin-ui..."
    cd admin-ui
    if npm run build 2>/dev/null; then
        print_success "Admin-ui built successfully"
    else
        print_warning "Admin-ui build failed or no build script - skipping"
    fi
    cd ..
fi

# Step 5: Database setup (if using local PostgreSQL)
echo ""
echo "Step 5: Database Setup"
echo "======================="

if command -v psql &> /dev/null; then
    print_status "PostgreSQL client found"
    print_warning "Note: Ensure PostgreSQL server is running for full functionality"
    print_status "Database configuration will be handled by services at runtime"
else
    print_warning "PostgreSQL client not found - database functionality may be limited"
fi

# Step 6: Service startup options
echo ""
echo "Step 6: Service Startup Options"
echo "==============================="

print_success "All installation requirements satisfied!"
echo ""
echo "Choose your startup method:"
echo ""
echo "1. 🐳 Docker Compose (Full production stack)"
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "   docker-compose up -d"
else
    echo "   (Docker not available)"
fi
echo ""
echo "2. � Mock Services (Development)"
echo "   ./paws360-services.sh start"
echo ""
echo "3. 🖥️  Admin Dashboard Only (Frontend)"
echo "   cd admin-dashboard && npm run dev"
echo ""
echo "4. 📊 Individual Services"
echo "   ./paws360-services.sh start auth     # Port 8081"
echo "   ./paws360-services.sh start data     # Port 8082"
echo "   ./paws360-services.sh start analytics # Port 8083"
echo "   ./paws360-services.sh start ui       # Port 8080"
echo ""
echo "5. 🧪 Test All Services"
echo "   ./paws360-services.sh test"
echo ""

# Optional: Auto-start services
read -p "Would you like to start the mock services now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_status "Starting PAWS360 mock services..."
    if [ -f "./paws360-services.sh" ]; then
        ./paws360-services.sh start
    else
        print_error "paws360-services.sh not found"
    fi
fi

echo ""
echo "🎉 PAWS360 setup complete!"
echo ""
echo "📋 Service URLs (when running):"
echo "   AdminLTE Dashboard:    http://localhost:8080"
echo "   AdminLTE Themes:       http://localhost:8080/themes/v4/"
echo "   Auth Service:          http://localhost:8081"
echo "   Data Service:          http://localhost:8082"
echo "   Analytics Service:     http://localhost:8083"
echo "   Admin Dashboard Dev:   http://localhost:3001"
echo ""
echo "🛑 To stop services:"
echo "   ./paws360-services.sh stop"
echo ""
echo "📊 Check status:"
echo "   ./paws360-services.sh status"
echo ""
echo "🧪 Test endpoints:"
echo "   ./paws360-services.sh test"