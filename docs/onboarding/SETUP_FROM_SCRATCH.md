# PAWS360 - Complete Setup Guide (From Scratch)

This guide will help you set up and run PAWS360 on a fresh machine with no existing dependencies.

## Prerequisites

You'll need a machine running:
- **Ubuntu 20.04+** / **Debian 11+** / **macOS 11+** / **Windows 10+ with WSL2**
- At least **8GB RAM** and **20GB free disk space**
- Internet connection

## Quick Start (Automated)

We've provided scripts to automate the entire setup process:

```bash
# 1. Extract the zip file
unzip paws360-master.zip
cd PAWS360

# 2. Run the setup script (will install all dependencies)
chmod +x scripts/setup/setup-from-scratch.sh
./scripts/setup/setup-from-scratch.sh

# 3. Start the application
./scripts/setup/start-app.sh
```

The application will be available at:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8086

**Test Login Credentials**:
- Email: `test@uwm.edu`
- Password: `password`

---

## Manual Setup (Step by Step)

If you prefer to install dependencies manually or the automated script fails, follow these steps:

### Step 1: Install Core Dependencies

#### On Ubuntu/Debian:
```bash
# Update package list
sudo apt update

# Install Java 21
sudo apt install -y openjdk-21-jdk

# Install Node.js 20 and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install -y docker-compose-plugin

# Install Maven
sudo apt install -y maven

# Install Git (if not present)
sudo apt install -y git
```

#### On macOS:
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install openjdk@21
brew install node@20
brew install maven
brew install --cask docker

# Start Docker Desktop
open -a Docker
```

#### On Windows (WSL2):
1. Install WSL2 following [Microsoft's guide](https://docs.microsoft.com/windows/wsl/install)
2. Install Ubuntu 22.04 from Microsoft Store
3. Open Ubuntu terminal and follow Ubuntu instructions above

### Step 2: Verify Installations

```bash
# Check Java version (should be 21.x)
java -version

# Check Node version (should be 20.x)
node -v

# Check npm version
npm -v

# Check Maven version
mvn -v

# Check Docker
docker --version
docker compose version
```

### Step 3: Start PostgreSQL Database

```bash
# Start PostgreSQL in Docker
docker run -d \
  --name paws360-postgres \
  -e POSTGRES_DB=paws360_dev \
  -e POSTGRES_USER=paws360 \
   -e POSTGRES_PASSWORD=<REPLACE_ME_PASSWORD> \
  -p 5432:5432 \
  postgres:15-alpine

# Wait for PostgreSQL to be ready
sleep 5
```

### Step 4: Initialize Database

```bash
# Navigate to project directory
cd /path/to/PAWS360

# Run database setup script
chmod +x database/setup_database.sh
./database/setup_database.sh
```

This will:
- Create all required tables
- Insert sample data
- Create a test student user

### Step 5: Configure Backend

The `.env` file is already configured for local development with these settings:
- Database: `localhost:5432/paws360_dev`
- Backend port: `8086`
- CORS: Allows `http://localhost:3000`

No changes needed unless you want to customize ports.

### Step 6: Start Backend

```bash
# Build and start Spring Boot backend
./mvnw spring-boot:run
```

The backend will start on `http://localhost:8086`

**Wait for this message**: `Started Paws360Application in X seconds`

### Step 7: Install Frontend Dependencies

Open a **new terminal** window:

```bash
cd /path/to/PAWS360

# Install npm dependencies
npm install
```

This may take 2-5 minutes depending on your internet connection.

### Step 8: Start Frontend

```bash
# Start Next.js development server
npm run dev
```

The frontend will start on `http://localhost:3000`

### Step 9: Access the Application

1. Open your browser to: **http://localhost:3000**
2. You should see the PAWS360 login page
3. Login with:
   - **Email**: `test@uwm.edu`
   - **Password**: `password`

---

## Test User Details

After database initialization, you'll have this test user:

| Field | Value |
|-------|-------|
| Email | test@uwm.edu |
| Password | password |
| Role | Student |
| Student ID | 1 |
| Name | Test Student |

---

## Common Issues & Troubleshooting

### Issue: "Port 8086 already in use"

```bash
# Find and kill process using port 8086
lsof -ti:8086 | xargs kill -9
```

### Issue: "Port 3000 already in use"

```bash
# Find and kill process using port 3000
lsof -ti:3000 | xargs kill -9
```

### Issue: "Port 5432 already in use"

```bash
# Stop existing PostgreSQL container
docker stop paws360-postgres
docker rm paws360-postgres
```

### Issue: Backend fails with "Connection refused"

Make sure PostgreSQL is running:
```bash
docker ps | grep paws360-postgres
```

If not running, restart it:
```bash
docker start paws360-postgres
```

### Issue: Frontend shows "Network Error"

1. Check if backend is running: `curl http://localhost:8086/actuator/health`
2. If not responding, restart backend: `./mvnw spring-boot:run`
3. Check CORS settings in `.env` file

### Issue: Database connection fails

Check database credentials in `.env`:
```bash
cat .env | grep POSTGRES
```

Should show:
- `SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/paws360_dev`
- `SPRING_DATASOURCE_USERNAME=paws360`
- `SPRING_DATASOURCE_PASSWORD=REPLACE_ME`

### Issue: "Module not found" errors in frontend

```bash
# Clear npm cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Issue: Maven build fails

```bash
# Clean and rebuild
./mvnw clean install
```

---

## Stopping the Application

To stop all services:

```bash
# Stop frontend (Ctrl+C in frontend terminal)

# Stop backend (Ctrl+C in backend terminal)

# Stop and remove database
docker stop paws360-postgres
docker rm paws360-postgres
```

---

## Quick Reference

### Start Everything (After Initial Setup)

```bash
# Terminal 1: Start database (if not running)
docker start paws360-postgres || docker run -d --name paws360-postgres -e POSTGRES_DB=paws360_dev -e POSTGRES_USER=paws360 -e POSTGRES_PASSWORD=<REPLACE_ME_PASSWORD> -p 5432:5432 postgres:15-alpine

# Terminal 2: Start backend
./mvnw spring-boot:run

# Terminal 3: Start frontend
npm run dev
```

### URLs
- Frontend: http://localhost:3000
- Backend API: http://localhost:8086
- Health Check: http://localhost:8086/actuator/health

### Test Credentials
- Email: `test@uwm.edu`
- Password: `<TEST_PASSWORD>`

---

## Need Help?

If you encounter issues not covered here:

1. Check application logs in the terminal windows
2. Check Docker logs: `docker logs paws360-postgres`
3. Verify all services are running:
   - Database: `docker ps | grep paws360-postgres`
   - Backend: `curl http://localhost:8086/actuator/health`
   - Frontend: `curl http://localhost:3000`

---

## Next Steps

Once the application is running:

1. **Explore Features**: Navigate through the student portal
2. **Test Functionality**: Try different pages (Academic, Courses, Holds & Tasks, etc.)
3. **Check Dark Mode**: Toggle dark mode in the header
4. **Review Data**: The test user has sample schedule and academic data

For development or customization, see:
- `docs/` - Additional documentation
- `README.md` - Project overview
- `.github/copilot-instructions.md` - Development guidelines
