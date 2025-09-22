# PAWS360 Ansible Infrastructure Guide

## 🚀 Quick Start

### Local Development (Recommended)
Get started immediately with no external dependencies:

```bash
# Deploy local development environment
./dev-helper.sh deploy-local-dev

# Test everything works
./dev-helper.sh test
```

### What You Get
- ✅ Complete PAWS360 development environment
- ✅ No external role dependencies
- ✅ Works with Ansible defaults only
- ✅ Local directory structure created
- ✅ Configuration files generated
- ✅ Service endpoints documented

## 📋 Playbooks Overview

| Playbook | Purpose | Dependencies | Use Case |
|----------|---------|--------------|----------|
| `local-dev.yml` | Local development setup | None | Getting started, development |
| `deploy-demo.yml` | Demo deployment | None | Show capabilities, testing |
| `site.yml` | Production deployment | External roles | Production environments |
| `rolling-update.yml` | Zero-downtime updates | External roles | Production maintenance |
| `scale.yml` | Horizontal scaling | External roles | Production scaling |

## 🛠️ Development Tools

### Helper Script
```bash
./dev-helper.sh help              # Show all commands
./dev-helper.sh test              # Run comprehensive tests
./dev-helper.sh deploy-local-dev  # Setup local development
./dev-helper.sh status            # Check deployment status
./dev-helper.sh logs <service>    # View service logs
```

### Direct Ansible Commands
```bash
# Local development
ansible-playbook local-dev.yml

# With tags for selective execution
ansible-playbook local-dev.yml --tags services,config
ansible-playbook local-dev.yml --tags status
ansible-playbook local-dev.yml --tags clean

# Testing
ansible-playbook --syntax-check local-dev.yml
ansible-playbook local-dev.yml --check
```

## 📁 Local Development Environment

When you run `local-dev.yml`, it creates:

```
~/paws360-dev/
├── config/
│   └── development.ini      # Configuration file
├── logs/                    # Log directory
├── data/                    # Data storage
├── services/                # Service files
└── deployment-summary.md    # Deployment report
```

## 🔧 Configuration

### Default Variables (No Setup Required)
```yaml
adminlte_user: "adminlte"
adminlte_version: "4.0.0-rc4"
java_version: "21"
auth_service_port: 8081
data_service_port: 8082
analytics_service_port: 8083
adminlte_ui_port: 80
```

### Production Variables
For production deployments, set these variables:
- `auth_service_jar_url`: URL to auth service JAR
- `data_service_jar_url`: URL to data service JAR
- `analytics_service_jar_url`: URL to analytics service JAR
- `postgresql_database`: Database name
- `use_ssl`: Enable SSL (true/false)

## 🧪 Testing

### Run All Tests
```bash
./dev-helper.sh test
# Output: All tests passed! ✅
```

### Individual Test Types
- **Syntax**: Validates YAML structure
- **Inventory**: Checks host configuration
- **Idempotency**: Ensures safe re-runs
- **Fresh Start**: Tests clean deployments

## 🚀 Production Deployment

### Prerequisites
```bash
# Install external roles
ansible-galaxy install -r requirements.yml

# Setup inventory
# Edit inventories/production/hosts
```

### Deploy
```bash
# Full deployment
ansible-playbook site.yml -i inventories/production

# Rolling update
ansible-playbook rolling-update.yml -i inventories/production

# Scale services
ansible-playbook scale.yml -i inventories/production -e "scale_factor=3"
```

## 📖 Advanced Usage

### Playbook Tags
Use tags to run specific parts of playbooks:

```bash
# Deploy only services
ansible-playbook local-dev.yml --tags services

# Setup infrastructure only
ansible-playbook local-dev.yml --tags setup,database,cache

# Run health checks
ansible-playbook local-dev.yml --tags health
```

### Available Tags
- `setup`: Directory creation, prerequisites
- `database`: PostgreSQL configuration
- `cache`: Redis setup
- `services`: All microservices
- `auth`, `data`, `analytics`, `ui`: Individual services
- `security`: Security configuration
- `monitoring`: Monitoring setup
- `config`: Configuration file generation
- `status`: Show current status
- `clean`: Clean up environment

### Debugging
```bash
# Verbose output
ansible-playbook local-dev.yml -vvv

# Dry run (see what would change)
ansible-playbook local-dev.yml --check

# Syntax check only
ansible-playbook --syntax-check local-dev.yml
```

## 🔒 Security & Compliance

- **FERPA Compliant**: Education data protection
- **RBAC**: 5-tier role hierarchy
- **Audit Logging**: Comprehensive tracking
- **No External Dependencies**: Local dev is secure by default

## 🐛 Troubleshooting

### Common Issues

**"Role not found"**
```bash
ansible-galaxy install -r requirements.yml
```

**Permission errors**
```bash
ansible-playbook site.yml --become
```

**Variable undefined**
- Use `local-dev.yml` for defaults
- Check `group_vars/` for production

### Getting Help
```bash
./dev-helper.sh help
ansible-playbook --help
```

## 📚 Additional Documentation

- `DEPLOYMENT.md`: Comprehensive deployment guide
- `test-playbooks.sh`: Testing framework details
- `dev-helper.sh`: Development tools reference

---

**🎯 Start Here**: Run `./dev-helper.sh deploy-local-dev` to get your PAWS360 development environment ready in seconds!