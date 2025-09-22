# PAWS360 Ansible Infrastructure Guide

## Overview
This directory contains Ansible playbooks for deploying the PAWS360 AdminLTE dashboard with Spring Boot microservices.

## Quick Start

### Local Development (Recommended for Getting Started)
```bash
# Deploy local development environment (works with defaults only)
./dev-helper.sh deploy-local-dev

# Or directly with ansible-playbook
ansible-playbook local-dev.yml
```

### Demo Environment
```bash
# Test everything works
./dev-helper.sh test

# Deploy demo environment
./dev-helper.sh deploy-demo
```

### Production Deployment
```bash
# Full production deployment (requires external roles)
ansible-playbook site.yml

# Rolling update
ansible-playbook rolling-update.yml

# Scale services
ansible-playbook scale.yml -e "scale_factor=2"
```

## Playbooks

### `local-dev.yml` - Local Development (Defaults Only)
**Purpose**: Sets up a complete development environment using only Ansible built-in modules and default settings.

**Features**:
- ✅ No external dependencies required
- ✅ Works with Ansible defaults only
- ✅ Creates local directory structure
- ✅ Simulates all services for development
- ✅ Generates configuration files

**Usage**:
```bash
ansible-playbook local-dev.yml
# Or with dev-helper
./dev-helper.sh deploy-local-dev
```

**Tags**:
- `setup` - Create directories and basic setup
- `database` - Database configuration tasks
- `cache` - Redis/cache setup tasks
- `services` - Service deployment tasks
- `auth` - Authentication service specific
- `data` - Data service specific
- `analytics` - Analytics service specific
- `ui` - AdminLTE UI specific
- `security` - Security configuration
- `monitoring` - Monitoring setup
- `health` - Health check tasks
- `config` - Configuration file generation
- `summary` - Summary and status output
- `status` - Show current status
- `clean` - Clean up development environment

**Examples**:
```bash
# Deploy only services
ansible-playbook local-dev.yml --tags services

# Setup database only
ansible-playbook local-dev.yml --tags database

# Show status
ansible-playbook local-dev.yml --tags status

# Clean environment
ansible-playbook local-dev.yml --tags clean
```

### `deploy-demo.yml` - Demo Environment
**Purpose**: Demonstration deployment that shows the full PAWS360 system capabilities.

**Features**:
- Simulation of complete deployment
- User story tracking (16 stories, 127 points)
- Comprehensive status reporting
- No actual service deployment

### `site.yml` - Production Deployment
**Purpose**: Full production deployment with all services and infrastructure.

**Requirements**:
- External Ansible roles (see requirements.yml)
- Proper inventory configuration
- System administrator privileges

**Variables**:
- `adminlte_user` (default: 'adminlte') - System user for services
- `rolling_update_batch` (default: '25%') - Batch size for updates
- `use_ssl` (default: false) - Enable SSL certificates

### `rolling-update.yml` - Zero-Downtime Updates
**Purpose**: Perform rolling updates with health checks and automatic rollback.

### `scale.yml` - Horizontal Scaling
**Purpose**: Scale services horizontally.

**Variables**:
- `scale_factor` (default: 2) - Scaling multiplier

## Variables and Configuration

### Default Variables (No Configuration Required)
The `local-dev.yml` playbook uses these sensible defaults:

```yaml
adminlte_user: "adminlte"
adminlte_version: "4.0.0-rc4"
java_version: "21"
auth_service_port: 8081
data_service_port: 8082
analytics_service_port: 8083
adminlte_ui_port: 80
postgres_version: "15"
redis_version: "7"
```

### Production Variables
For production deployments, configure these in `group_vars/` or via `-e`:

```yaml
# Service Configuration
auth_service_jar_url: "https://example.com/auth-service.jar"
data_service_jar_url: "https://example.com/data-service.jar"
analytics_service_jar_url: "https://example.com/analytics-service.jar"

# Database Configuration
postgresql_version: "15"
postgresql_database: "paws360_prod"
postgresql_user: "paws360_admin"

# Security
saml_keystore_file: "/path/to/keystore.jks"
use_ssl: true

# Infrastructure
rolling_update_batch: "25%"
```

## Development Workflow

### 1. Local Development Setup
```bash
# Create local development environment
./dev-helper.sh deploy-local-dev

# Check status
./dev-helper.sh status

# View logs (when real services are running)
./dev-helper.sh logs auth-service
```

### 2. Testing
```bash
# Run all tests
./dev-helper.sh test

# Test specific components
./dev-helper.sh test-syntax
./dev-helper.sh test-idempotency
```

### 3. Development Iteration
```bash
# Clean and redeploy
ansible-playbook local-dev.yml --tags clean
ansible-playbook local-dev.yml

# Deploy specific components
ansible-playbook local-dev.yml --tags services,config
```

### 4. Production Deployment
```bash
# Install external roles
ansible-galaxy install -r requirements.yml

# Deploy to production
ansible-playbook site.yml -i inventories/production
```

## Directory Structure Created

The `local-dev.yml` playbook creates this structure in `~/paws360-dev/`:

```
paws360-dev/
├── config/
│   └── development.ini      # Development configuration
├── logs/                    # Log files directory
├── data/                    # Data storage directory
├── services/                # Service-specific files
└── deployment-summary.md    # Deployment report
```

## Troubleshooting

### Common Issues

**"Role not found" errors**:
```bash
# Install required external roles
ansible-galaxy install -r requirements.yml
```

**Permission denied**:
```bash
# Use sudo for production deployments
ansible-playbook site.yml --become
```

**Variable undefined**:
- Use `local-dev.yml` for defaults-only development
- Define variables in `group_vars/` for production

### Debug Mode
```bash
# Verbose output
ansible-playbook local-dev.yml -vvv

# Check syntax only
ansible-playbook --syntax-check local-dev.yml

# Dry run
ansible-playbook local-dev.yml --check
```

## Development Helper Script

The `dev-helper.sh` script provides shortcuts for common tasks:

```bash
./dev-helper.sh help              # Show all commands
./dev-helper.sh test              # Run all tests
./dev-helper.sh deploy-local-dev  # Deploy local dev environment
./dev-helper.sh status            # Show deployment status
./dev-helper.sh logs auth-service # View service logs
./dev-helper.sh clean             # Clean up artifacts
```

## Security Notes

- Local development uses simulated security
- Production deployments require proper SSL/TLS
- FERPA compliance enabled in all configurations
- RBAC system initialized with 5-tier hierarchy
- Audit logging configured for compliance

## Next Steps

1. **Start Developing**: Use `local-dev.yml` to set up your environment
2. **Add Real Services**: Replace simulated services with actual implementations
3. **Configure Production**: Set up inventory and variables for production deployment
4. **Scale**: Use `scale.yml` for horizontal scaling when needed