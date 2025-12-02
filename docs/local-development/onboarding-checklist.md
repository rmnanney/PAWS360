# Developer Onboarding Checklist

Complete guide for new developers joining the PAWS360 project. Follow this checklist to get your local development environment fully operational.

## Overview

| Phase | Duration | Description |
|-------|----------|-------------|
| [Prerequisites](#phase-1-prerequisites) | 15-30 min | Install required tools |
| [Repository Setup](#phase-2-repository-setup) | 5-10 min | Clone and configure |
| [Environment Startup](#phase-3-environment-startup) | 5-15 min | Start all services |
| [Validation](#phase-4-validation) | 10-15 min | Verify everything works |
| [Development Workflow](#phase-5-development-workflow) | Ongoing | Learn daily commands |

**Total Estimated Time**: 45-90 minutes (depending on internet speed and existing tools)

---

## Phase 1: Prerequisites

### 1.1 System Requirements

- [ ] **Operating System**: Verify you're running a supported OS
  - Linux (Ubuntu 20.04+, Fedora 35+, Debian 11+)
  - macOS 12+ (Monterey or newer)
  - Windows 11 with WSL2

- [ ] **Hardware**: Confirm minimum specifications
  - RAM: 16GB minimum (8GB with `--lite` mode)
  - CPU: 4 cores minimum
  - Disk: 40GB free space (20GB with `--lite` mode)
  - Network: Stable internet connection for image pulls

### 1.2 Container Runtime

Choose ONE of the following:

#### Option A: Docker (Recommended)

- [ ] Install Docker Engine 20.10+
  ```bash
  # Ubuntu/Debian
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
  # Log out and back in for group changes
  
  # macOS
  brew install --cask docker
  # Or download from docker.com
  ```

- [ ] Install Docker Compose 2.x
  ```bash
  # Usually included with Docker Desktop
  # Verify:
  docker compose version
  ```

- [ ] Verify Docker installation
  ```bash
  docker --version    # Should be 20.10+
  docker run hello-world
  ```

#### Option B: Podman (Alternative)

- [ ] Install Podman 4.0+
  ```bash
  # Ubuntu
  sudo apt install podman podman-compose
  
  # Fedora
  sudo dnf install podman podman-compose
  
  # macOS
  brew install podman podman-compose
  ```

- [ ] Configure Docker compatibility
  ```bash
  # Add to ~/.bashrc or ~/.zshrc
  alias docker=podman
  alias docker-compose=podman-compose
  ```

- [ ] Verify Podman installation
  ```bash
  podman --version    # Should be 4.0+
  podman run hello-world
  ```

### 1.3 Development Tools

- [ ] **Git**: Version 2.30+
  ```bash
  git --version
  # Install if needed:
  sudo apt install git  # Ubuntu
  brew install git      # macOS
  ```

- [ ] **Node.js**: Version 20 LTS
  ```bash
  node --version  # Should be v20.x
  # Install via nvm (recommended):
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
  nvm install 20
  nvm use 20
  ```

- [ ] **Java JDK**: Version 21
  ```bash
  java --version  # Should be 21.x
  # Install via SDKMAN (recommended):
  curl -s "https://get.sdkman.io" | bash
  sdk install java 21-tem
  ```

- [ ] **Make**: Build automation
  ```bash
  make --version
  # Install if needed:
  sudo apt install make  # Ubuntu
  # Included on macOS
  ```

### 1.4 Optional Tools (Highly Recommended)

- [ ] **psql**: PostgreSQL client for database access
  ```bash
  sudo apt install postgresql-client  # Ubuntu
  brew install libpq                   # macOS
  ```

- [ ] **jq**: JSON processing
  ```bash
  sudo apt install jq  # Ubuntu
  brew install jq      # macOS
  ```

- [ ] **curl**: HTTP client (usually pre-installed)
  ```bash
  curl --version
  ```

### 1.5 IDE Setup

- [ ] **VS Code** (Recommended)
  - [ ] Install VS Code
  - [ ] Install recommended extensions:
    ```bash
    code --install-extension ms-azuretools.vscode-docker
    code --install-extension vscjava.vscode-java-pack
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
    code --install-extension bradlc.vscode-tailwindcss
    ```

- [ ] **IntelliJ IDEA** (Alternative for Java)
  - [ ] Enable Spring Boot support
  - [ ] Configure JDK 21

---

## Phase 2: Repository Setup

### 2.1 Clone Repository

- [ ] Clone the PAWS360 repository
  ```bash
  git clone https://github.com/ZackHawkins/PAWS360.git
  cd PAWS360
  ```

- [ ] Checkout the development branch
  ```bash
  git checkout 001-local-dev-parity
  # Or main branch for stable version:
  git checkout main
  ```

### 2.2 Configure Environment

- [ ] Create local environment file
  ```bash
  cp config/dev.env .env
  ```

- [ ] Review and customize settings (if needed)
  ```bash
  # Edit .env to customize:
  # - Database credentials
  # - Port mappings
  # - Feature flags
  cat .env
  ```

### 2.3 Verify Repository Structure

- [ ] Confirm key files exist
  ```bash
  ls -la docker-compose.yml Makefile.dev config/dev.env
  ```

- [ ] Check documentation is accessible
  ```bash
  ls docs/local-development/
  ```

---

## Phase 3: Environment Startup

### 3.1 Quick Start (Automated)

- [ ] Run the quickstart script
  ```bash
  ./docs/quickstart.sh
  ```

  The script will:
  - Validate prerequisites
  - Pull required images
  - Start all services
  - Run health checks
  - Display access URLs

- [ ] If quickstart fails, try with flags:
  ```bash
  # Skip prerequisite checks (if you know they're met)
  ./docs/quickstart.sh --skip-prereqs
  
  # Start lite mode (reduced resources)
  ./docs/quickstart.sh --lite
  
  # Clean start (remove existing data)
  ./docs/quickstart.sh --clean
  ```

### 3.2 Manual Start (Alternative)

If you prefer manual control:

- [ ] Pull images
  ```bash
  make dev-pull
  ```

- [ ] Start infrastructure
  ```bash
  make dev-infra
  ```

- [ ] Wait for infrastructure health
  ```bash
  make dev-wait-healthy
  ```

- [ ] Start application services
  ```bash
  make dev-up
  ```

### 3.3 First-Time Database Setup

- [ ] Initialize the database schema
  ```bash
  make dev-migrate
  ```

- [ ] Load seed data (optional)
  ```bash
  make dev-seed
  ```

---

## Phase 4: Validation

### 4.1 Service Health Checks

- [ ] Check all containers are running
  ```bash
  make dev-status
  # Or: docker compose ps
  ```
  
  Expected: All services showing "Up" status

- [ ] Verify health endpoints
  ```bash
  # Backend health
  curl http://localhost:8080/actuator/health
  
  # Frontend
  curl -I http://localhost:3000
  ```

### 4.2 Database Validation

- [ ] Connect to PostgreSQL
  ```bash
  make dev-psql
  # Or: psql -h localhost -U paws360 -d paws360
  ```

- [ ] Verify tables exist
  ```sql
  \dt
  -- Should list application tables
  ```

- [ ] Check Patroni cluster status (full mode)
  ```bash
  make patroni-status
  ```

### 4.3 Application Access

- [ ] Open frontend in browser
  - URL: http://localhost:3000
  - Expected: Login page or dashboard

- [ ] Test API endpoint
  ```bash
  curl http://localhost:8080/actuator/info
  ```

### 4.4 Run Test Suite

- [ ] Run backend tests
  ```bash
  make test-backend
  ```

- [ ] Run frontend tests
  ```bash
  make test-frontend
  ```

- [ ] Run integration tests
  ```bash
  make test-integration
  ```

---

## Phase 5: Development Workflow

### 5.1 Daily Commands

| Command | Purpose |
|---------|---------|
| `make dev-up` | Start all services |
| `make dev-down` | Stop all services |
| `make dev-restart` | Restart all services |
| `make dev-logs` | View all logs |
| `make dev-logs-f` | Follow logs (real-time) |
| `make dev-status` | Check container status |

### 5.2 Database Commands

| Command | Purpose |
|---------|---------|
| `make dev-psql` | PostgreSQL shell |
| `make dev-migrate` | Run migrations |
| `make dev-seed` | Load seed data |
| `make dev-reset` | Reset database (destructive) |
| `make dev-backup` | Backup database |
| `make dev-restore` | Restore from backup |

### 5.3 Testing Commands

| Command | Purpose |
|---------|---------|
| `make test` | Run all tests |
| `make test-backend` | Backend unit tests |
| `make test-frontend` | Frontend unit tests |
| `make test-integration` | Integration tests |
| `make test-failover` | HA failover test |

### 5.4 Troubleshooting Commands

| Command | Purpose |
|---------|---------|
| `make dev-logs SERVICE=backend` | Logs for specific service |
| `make dev-shell SERVICE=backend` | Shell into container |
| `make dev-restart SERVICE=backend` | Restart specific service |
| `make doctor` | Diagnose environment issues |
| `make dev-clean` | Clean up resources |

---

## Troubleshooting

### Common Issues

#### Port Already in Use

```bash
# Find what's using the port
lsof -i :5432  # Or whatever port

# Kill the process
kill -9 <PID>

# Or change port in .env
POSTGRES_PORT=5433
```

#### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

#### Out of Memory

```bash
# Use lite mode
make dev-down
./docs/quickstart.sh --lite

# Or increase Docker memory allocation
# Docker Desktop: Settings > Resources > Memory
```

#### Database Connection Refused

```bash
# Check if postgres is running
docker compose ps postgres

# Check logs
docker compose logs postgres

# Wait longer for startup
make dev-wait-healthy
```

#### Images Not Pulling

```bash
# Check Docker Hub rate limits
docker login

# Try pulling individually
docker pull postgres:15-alpine
```

---

## Getting Help

### Documentation

- [Local Development README](./README.md)
- [Troubleshooting Guide](./troubleshooting.md)
- [Makefile Reference](../reference/makefile-targets.md)
- [Architecture Overview](../architecture/ha-stack.md)

### Team Contacts

- **Slack Channel**: #paws360-dev
- **Tech Lead**: [Team Lead Name]
- **DevOps Support**: [DevOps Contact]

### External Resources

- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Patroni Documentation](https://patroni.readthedocs.io/)
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/)
- [Next.js Documentation](https://nextjs.org/docs)

---

## Completion Checklist

Before considering your setup complete, verify:

- [ ] All Phase 1 prerequisites installed
- [ ] Repository cloned and configured
- [ ] All services start successfully
- [ ] Frontend accessible at http://localhost:3000
- [ ] Backend API responding at http://localhost:8080
- [ ] Database connection working
- [ ] Test suite passing
- [ ] Familiar with daily workflow commands

**Congratulations!** You're ready to start developing on PAWS360! 🎉

---

## Next Steps

1. **Read the Architecture Documentation**
   - [HA Stack Design](../architecture/ha-stack.md)
   - [Testing Strategy](../architecture/testing-strategy.md)

2. **Set Up Your IDE**
   - Import Java project into IDE
   - Configure ESLint/Prettier for frontend

3. **Pick Up Your First Task**
   - Check JIRA board for available tasks
   - Review coding standards in team wiki

4. **Attend Team Standup**
   - Introduce yourself
   - Ask questions!
