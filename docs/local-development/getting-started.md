# Getting Started with Local Development

**Feature**: 001-local-dev-parity  
**Last Updated**: 2025-11-27

## Quick Start (5 Minutes)

```bash
# 1. Clone repository (if not already done)
git clone https://github.com/ZackHawkins/PAWS360.git
cd PAWS360

# 2. Validate your system meets requirements
make -f Makefile.dev validate-system

# 3. Initial setup (one-time)
make -f Makefile.dev dev-setup

# 4. Start the full HA stack
make -f Makefile.dev dev-up

# 5. Verify everything is healthy
make -f Makefile.dev health
```

You now have a production-parity environment running locally! 🎉

## What Just Happened?

You started:
- **3-node etcd cluster** (distributed configuration store)
- **3-node Patroni/PostgreSQL HA cluster** (with automatic failover)
- **Redis Sentinel** (master + 2 replicas + 3 sentinels)
- **Application services** (backend + frontend, if configured)

## Daily Workflow

### Starting Your Day

```bash
# Start environment
make -f Makefile.dev dev-up

# Check health
make -f Makefile.dev health

# View logs
make -f Makefile.dev logs
```

### During Development

```bash
# After changing backend code
make -f Makefile.dev dev-rebuild-backend

# After changing frontend code
make -f Makefile.dev dev-rebuild-frontend

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f patroni1
```

### Testing HA Failover

```bash
# Simulate Patroni leader failure
make -f Makefile.dev test-failover

# Expected: Failover completes in ≤60 seconds
```

### End of Day

```bash
# Option 1: Stop environment (keep data)
make -f Makefile.dev dev-down

# Option 2: Pause environment (fastest resume next time)
make -f Makefile.dev dev-pause
```

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| PostgreSQL (leader) | `localhost:5432` | Database connections |
| Patroni API | `http://localhost:8008` | Cluster management |
| Redis | `localhost:6379` | Cache/sessions |
| Redis Sentinel | `localhost:26379` | Failover monitoring |
| etcd | `http://localhost:2379` | Configuration store |
| Backend API | `http://localhost:8080` | REST API |
| Frontend | `http://localhost:3000` | Web UI |

## System Requirements

### Minimum Hardware
- **RAM**: 16GB (for full HA stack)
- **CPU**: 4 cores
- **Disk**: 40GB free space

### Software Prerequisites
- **Docker**: 20.10.0+ or **Podman**: 4.0+
- **Docker Compose**: 2.0+ (or Podman Compose 1.0+)
- **OS**: Linux, macOS, or Windows WSL2

### Validation
```bash
make -f Makefile.dev validate-system
```

## Troubleshooting

### "Port already in use"
```bash
# Check which ports are in use
scripts/validate-ports.sh

# Option 1: Stop conflicting service
# Option 2: Modify ports in .env.local
```

### "Insufficient RAM"
```bash
# Use fast mode (single instances)
make -f Makefile.dev dev-up-fast

# Or increase Docker Desktop memory allocation (macOS/Windows)
```

### "Services won't start"
```bash
# Check Docker is running
docker info

# Check logs for specific service
docker-compose logs patroni1

# Full reset (CAUTION: deletes all data)
make -f Makefile.dev dev-reset
```

### "Environment slow after sleep/hibernate"
```bash
# Clock skew detection
scripts/recover-from-sleep.sh

# Or restart environment
make -f Makefile.dev dev-restart
```

## Advanced Usage

### Fast Development Mode

For rapid iteration, use fast mode (50% faster startup, single instances):

```bash
make -f Makefile.dev dev-up-fast
```

**Trade-off**: No HA features, but perfect for development iterations.

### Pause/Resume (Resource Saving)

```bash
# Pause (frees 90% RAM while preserving state)
make -f Makefile.dev dev-pause

# Resume in <5 seconds
make -f Makefile.dev dev-resume
```

### Database Seeding

```bash
# Load sample data
make -f Makefile.dev dev-seed
```

Create seed data in `database/seeds/local-dev-data.sql`.

### Inspecting Infrastructure

```bash
# Check etcd cluster
curl http://localhost:2379/health | jq

# Check Patroni cluster
curl http://localhost:8008/patroni | jq

# Check Redis replication
docker exec paws360-redis-master redis-cli -a <password> INFO replication
```

## Next Steps

- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [HA Failover Testing](failover-testing.md) - Simulate and validate failover
- [Development Workflow](../guides/development-workflow.md) - Hot-reload, debugging
- [Local CI/CD](../ci-cd/local-ci-execution.md) - Test pipelines locally

## Testing Framework (Optional)

### bats-core Installation

**bats-core** is a testing framework for Bash scripts used in our test suite.

#### Linux (Ubuntu/Debian)
```bash
# Install from package manager
sudo apt-get install -y bats

# Or install latest from GitHub
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local

# Verify installation
bats --version
```

#### macOS
```bash
# Install via Homebrew
brew install bats-core

# Verify installation
bats --version
```

#### Manual Installation (All Platforms)
```bash
# Clone the repository
git clone https://github.com/bats-core/bats-core.git ~/bats-core

# Add to PATH in your shell profile (.bashrc, .zshrc, etc.)
export PATH="$HOME/bats-core/bin:$PATH"

# Verify installation
bats --version
```

### Running Tests
```bash
# Run integration tests
bats tests/integration/test_etcd_cluster.sh
bats tests/integration/test_patroni_ha.sh

# Run all tests
bats tests/integration/*.sh
```

## Getting Help

1. Check health status: `make -f Makefile.dev health`
2. Review logs: `make -f Makefile.dev logs`
3. Consult [Troubleshooting Guide](troubleshooting.md)
4. File issue in JIRA with logs and error messages
