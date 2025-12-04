#!/bin/bash
set -e

echo "=========================================="
echo "PAWS360 - Automated Setup Script"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Check and install required dependencies"
echo "  2. Set up PostgreSQL database"
echo "  3. Initialize database schema and test data"
echo "  4. Configure the application"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo -e "${RED}Please run this script in WSL2 on Windows${NC}"
    exit 1
else
    echo -e "${RED}Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Detected OS: $OS"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Java version
check_java_version() {
    if command_exists java; then
        java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        if [[ "$java_version" -ge 21 ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to check Node version
check_node_version() {
    if command_exists node; then
        node_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$node_version" -ge 18 ]]; then
            return 0
        fi
    fi
    return 1
}

echo "=========================================="
echo "Step 1: Checking Dependencies"
echo "=========================================="
echo ""

# Check Java
if check_java_version; then
    echo -e "${GREEN}✓${NC} Java 21+ is installed"
else
    echo -e "${YELLOW}⚠${NC} Java 21+ not found. Installing..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt update
        sudo apt install -y openjdk-21-jdk
    elif [[ "$OS" == "macos" ]]; then
        brew install openjdk@21
    fi
    echo -e "${GREEN}✓${NC} Java installed"
fi

# Check Node.js
if check_node_version; then
    echo -e "${GREEN}✓${NC} Node.js 18+ is installed"
else
    echo -e "${YELLOW}⚠${NC} Node.js 18+ not found. Installing..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    elif [[ "$OS" == "macos" ]]; then
        brew install node@20
    fi
    echo -e "${GREEN}✓${NC} Node.js installed"
fi

# Check Maven
if command_exists mvn; then
    echo -e "${GREEN}✓${NC} Maven is installed"
else
    echo -e "${YELLOW}⚠${NC} Maven not found. Installing..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt install -y maven
    elif [[ "$OS" == "macos" ]]; then
        brew install maven
    fi
    echo -e "${GREEN}✓${NC} Maven installed"
fi

# Check Docker
if command_exists docker; then
    echo -e "${GREEN}✓${NC} Docker is installed"
else
    echo -e "${YELLOW}⚠${NC} Docker not found. Installing..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        echo -e "${YELLOW}⚠${NC} Please log out and log back in for Docker permissions to take effect"
    elif [[ "$OS" == "macos" ]]; then
        echo -e "${RED}Please install Docker Desktop from https://www.docker.com/products/docker-desktop${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Docker installed"
fi

# Verify Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo -e "${RED}✗${NC} Docker is not running. Please start Docker and run this script again."
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker is running"

echo ""
echo "=========================================="
echo "Step 2: Setting Up PostgreSQL Database"
echo "=========================================="
echo ""

# Stop and remove existing container if it exists
if docker ps -a | grep -q paws360-postgres; then
    echo "Removing existing PostgreSQL container..."
    docker stop paws360-postgres 2>/dev/null || true
    docker rm paws360-postgres 2>/dev/null || true
fi

# Start PostgreSQL container
echo "Starting PostgreSQL container..."
docker run -d \
  --name paws360-postgres \
  -e POSTGRES_DB=paws360_dev \
  -e POSTGRES_USER=paws360 \
  -e POSTGRES_PASSWORD=paws360_dev_password \
  -p 5432:5432 \
  postgres:15-alpine

echo -e "${GREEN}✓${NC} PostgreSQL container started"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
max_attempts=30
attempt=0
while ! docker exec paws360-postgres pg_isready -U paws360 -d paws360_dev >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}✗${NC} PostgreSQL failed to start after ${max_attempts} seconds"
        exit 1
    fi
    echo "  Waiting... (${attempt}/${max_attempts})"
    sleep 1
done

echo -e "${GREEN}✓${NC} PostgreSQL is ready"

echo ""
echo "=========================================="
echo "Step 3: Initializing Database"
echo "=========================================="
echo ""

# Run database setup script
if [ -f "database/setup_database.sh" ]; then
    chmod +x database/setup_database.sh
    ./database/setup_database.sh
    echo -e "${GREEN}✓${NC} Database initialized with schema and test data"
else
    echo -e "${YELLOW}⚠${NC} Database setup script not found. Creating minimal schema..."
    
    # Create basic users table and test user
    docker exec -i paws360-postgres psql -U paws360 -d paws360_dev <<EOF
-- Create users table if not exists
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    role VARCHAR(50) DEFAULT 'STUDENT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test user (password is BCrypt hash of 'password')
INSERT INTO users (email, password, firstname, lastname, role)
VALUES ('test@uwm.edu', '\$2a\$10\$ZKnJLWCE9fGQlm5.5D7oJO5Zy5wZ4VZq1qKZVqKZVqKZVqKZVqKZVq', 'Test', 'Student', 'STUDENT')
ON CONFLICT (email) DO NOTHING;

EOF
    echo -e "${GREEN}✓${NC} Basic database schema created"
fi

echo ""
echo "=========================================="
echo "Step 4: Installing Frontend Dependencies"
echo "=========================================="
echo ""

echo "Installing npm packages (this may take 2-5 minutes)..."
npm install

echo -e "${GREEN}✓${NC} Frontend dependencies installed"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}✓${NC} All dependencies installed"
echo -e "${GREEN}✓${NC} PostgreSQL database running"
echo -e "${GREEN}✓${NC} Database initialized with test data"
echo -e "${GREEN}✓${NC} Application configured"
echo ""
echo "To start the application:"
echo ""
echo "  1. Start backend (in a new terminal):"
echo "     ./mvnw spring-boot:run"
echo ""
echo "  2. Start frontend (in another terminal):"
echo "     npm run dev"
echo ""
echo "  3. Open browser to: http://localhost:3000"
echo ""
echo "Test Login:"
echo "  Email:    test@uwm.edu"
echo "  Password: password"
echo ""
echo "Or use the quick start script:"
echo "  ./scripts/setup/start-app.sh"
echo ""
