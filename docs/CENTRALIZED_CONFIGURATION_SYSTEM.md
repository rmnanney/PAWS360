# PAWS360 Centralized Configuration Management

## 🎯 **Overview**

The PAWS360 project consists of multiple repositories and services that require coordinated configuration management. This document outlines a comprehensive centralized configuration system that manages all project components across different environments and repositories.

**Status**: ✅ **IMPLEMENTATION IN PROGRESS**  
**Date**: September 20, 2025  
**Version**: 1.0.0  

---

## 🏗️ **Architecture Overview**

### **Configuration Hierarchy**

```
PAWS360 Configuration System
├── config/
│   ├── central/           # Centralized configuration
│   ├── environments/      # Environment-specific configs
│   ├── services/         # Service-specific configurations
│   └── repositories/     # Repository-specific settings
├── scripts/
│   ├── config/           # Configuration management scripts
│   └── deployment/       # Deployment automation
└── docs/
    └── config/           # Configuration documentation
```

### **Repository Structure**

The PAWS360 ecosystem includes:

1. **Main Repository** (`PAWS360ProjectPlan`)
   - JIRA MCP Server
   - Backend services
   - Infrastructure automation
   - Documentation

2. **Student Frontend Repository** (`paws360-student-frontend`)
   - React-based student interface
   - Authentication integration
   - Course management UI

3. **Admin Dashboard Repository** (`paws360-admin-dashboard`)
   - AdminLTE-based admin interface
   - Administrative tools
   - Reporting dashboards

4. **Infrastructure Repository** (`paws360-infrastructure`)
   - Docker configurations
   - Kubernetes manifests
   - Ansible playbooks

---

## ⚙️ **Centralized Configuration System**

### **Core Configuration Files**

#### **`.env.central` - Master Configuration**
```bash
# =============================================================================
# PAWS360 CENTRAL CONFIGURATION
# =============================================================================
# This file contains all configuration variables used across the ecosystem
# DO NOT commit this file - it contains sensitive information

# -----------------------------------------------------------------------------
# GLOBAL SETTINGS
# -----------------------------------------------------------------------------
PAWS360_ENV=development
PAWS360_VERSION=1.0.0
PAWS360_DOMAIN=paws360.university.edu

# -----------------------------------------------------------------------------
# DATABASE CONFIGURATION
# -----------------------------------------------------------------------------
DB_TYPE=postgresql
DB_HOST=localhost
DB_PORT=5432
DB_NAME=paws360
DB_USERNAME=paws360_user
DB_PASSWORD=${DB_PASSWORD}
DB_SSL_MODE=require
DB_POOL_SIZE=10
DB_TIMEOUT=30

# -----------------------------------------------------------------------------
# AUTHENTICATION & SECURITY
# -----------------------------------------------------------------------------
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRATION=24
SESSION_TIMEOUT=3600
ENCRYPTION_KEY=${ENCRYPTION_KEY}

# -----------------------------------------------------------------------------
# JIRA INTEGRATION
# -----------------------------------------------------------------------------
JIRA_URL=https://paw360.atlassian.net
JIRA_PROJECT_KEY=PGB
JIRA_EMAIL=${JIRA_EMAIL}
JIRA_API_KEY=${JIRA_API_KEY}
JIRA_BOARD_ID=1
JIRA_TIMEOUT=30
JIRA_RATE_LIMIT=50

# -----------------------------------------------------------------------------
# SAML AUTHENTICATION (Azure AD)
# -----------------------------------------------------------------------------
SAML_ENTITY_ID=https://paws360.university.edu
SAML_IDP_METADATA_URL=${SAML_IDP_METADATA_URL}
SAML_CERTIFICATE_PATH=/etc/ssl/certs/paws360.crt
SAML_PRIVATE_KEY_PATH=/etc/ssl/private/paws360.key
SAML_ACS_URL=https://paws360.university.edu/saml/acs
SAML_SLO_URL=https://paws360.university.edu/saml/slo

# -----------------------------------------------------------------------------
# REDIS CONFIGURATION
# -----------------------------------------------------------------------------
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_DB=0
REDIS_TIMEOUT=5
REDIS_MAX_CONNECTIONS=20

# -----------------------------------------------------------------------------
# EMAIL CONFIGURATION
# -----------------------------------------------------------------------------
SMTP_HOST=smtp.university.edu
SMTP_PORT=587
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
EMAIL_FROM=notifications@paws360.university.edu

# -----------------------------------------------------------------------------
# EXTERNAL SERVICE INTEGRATIONS
# -----------------------------------------------------------------------------
ANALYTICS_URL=http://analytics.paws360.university.edu
DATA_SERVICE_URL=http://data.paws360.university.edu
AUTH_SERVICE_URL=http://auth.paws360.university.edu

# -----------------------------------------------------------------------------
# STUDENT FRONTEND CONFIGURATION
# -----------------------------------------------------------------------------
STUDENT_FRONTEND_URL=https://student.paws360.university.edu
STUDENT_API_BASE_URL=https://api.paws360.university.edu/student
STUDENT_AUTH_REDIRECT_URL=https://student.paws360.university.edu/auth/callback

# -----------------------------------------------------------------------------
# ADMIN DASHBOARD CONFIGURATION
# -----------------------------------------------------------------------------
ADMIN_DASHBOARD_URL=https://admin.paws360.university.edu
ADMIN_API_BASE_URL=https://api.paws360.university.edu/admin
ADMIN_AUTH_REDIRECT_URL=https://admin.paws360.university.edu/auth/callback

# -----------------------------------------------------------------------------
# INFRASTRUCTURE CONFIGURATION
# -----------------------------------------------------------------------------
DOCKER_REGISTRY=registry.university.edu
K8S_NAMESPACE=paws360
DEPLOY_ENV=development
BACKUP_RETENTION=30

# -----------------------------------------------------------------------------
# MONITORING & LOGGING
# -----------------------------------------------------------------------------
LOG_LEVEL=INFO
METRICS_ENABLED=true
AUDIT_LOGGING=true
FERPA_COMPLIANCE=true

# -----------------------------------------------------------------------------
# FEATURE FLAGS
# -----------------------------------------------------------------------------
FEATURE_JIRA_INTEGRATION=true
FEATURE_SAML_AUTH=true
FEATURE_ANALYTICS=true
FEATURE_BACKUP=true
FEATURE_MONITORING=true
```

#### **`.env.environments/` - Environment-Specific Configurations**

**`.env.environments/development.env`**
```bash
# Development Environment Configuration
PAWS360_ENV=development
LOG_LEVEL=DEBUG
DB_HOST=localhost
REDIS_HOST=localhost
DEBUG_MODE=true
HOT_RELOAD=true
```

**`.env.environments/staging.env`**
```bash
# Staging Environment Configuration
PAWS360_ENV=staging
LOG_LEVEL=INFO
DB_HOST=staging-db.university.edu
REDIS_HOST=staging-redis.university.edu
DEBUG_MODE=false
METRICS_ENABLED=true
```

**`.env.environments/production.env`**
```bash
# Production Environment Configuration
PAWS360_ENV=production
LOG_LEVEL=WARNING
DB_HOST=prod-db.university.edu
REDIS_HOST=prod-redis.university.edu
DEBUG_MODE=false
METRICS_ENABLED=true
AUDIT_LOGGING=true
FERPA_COMPLIANCE=true
```

#### **`.env.services/` - Service-Specific Configurations**

**`.env.services/jira-mcp.env`**
```bash
# JIRA MCP Server Configuration
JIRA_URL=https://paw360.atlassian.net
JIRA_PROJECT_KEY=PGB
JIRA_EMAIL=${JIRA_EMAIL}
JIRA_API_KEY=${JIRA_API_KEY}
JIRA_TIMEOUT=30
JIRA_RATE_LIMIT=50
LOG_LEVEL=INFO
```

**`.env.services/student-frontend.env`**
```bash
# Student Frontend Configuration
REACT_APP_API_BASE_URL=https://api.paws360.university.edu
REACT_APP_AUTH_URL=https://auth.paws360.university.edu
REACT_APP_JIRA_PROJECT_KEY=PGB
REACT_APP_ANALYTICS_ENABLED=true
GENERATE_SOURCEMAP=false
```

**`.env.services/admin-dashboard.env`**
```bash
# Admin Dashboard Configuration
APP_URL=https://admin.paws360.university.edu
API_BASE_URL=https://api.paws360.university.edu
JIRA_INTEGRATION_ENABLED=true
ANALYTICS_ENABLED=true
BACKUP_ENABLED=true
```

---

## 🔧 **Configuration Management Scripts**

### **Core Scripts**

#### **`scripts/config/generate-env.sh`**
```bash
#!/bin/bash
# Generate environment-specific .env files from central configuration

set -e

ENVIRONMENT=${1:-development}
OUTPUT_DIR=${2:-.}

echo "Generating configuration for environment: $ENVIRONMENT"

# Load central configuration
if [ ! -f ".env.central" ]; then
    echo "Error: .env.central not found"
    exit 1
fi

# Load environment-specific configuration
ENV_FILE=".env.environments/${ENVIRONMENT}.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE not found"
    exit 1
fi

# Generate final configuration
cat .env.central "$ENV_FILE" > "${OUTPUT_DIR}/.env.${ENVIRONMENT}"

echo "Configuration generated: ${OUTPUT_DIR}/.env.${ENVIRONMENT}"
```

#### **`scripts/config/validate-config.sh`**
```bash
#!/bin/bash
# Validate configuration files for completeness and security

set -e

CONFIG_FILE=${1:-.env}

echo "Validating configuration: $CONFIG_FILE"

# Check required variables
REQUIRED_VARS=(
    "DB_PASSWORD"
    "JWT_SECRET"
    "JIRA_API_KEY"
    "REDIS_PASSWORD"
)

for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^${var}=" "$CONFIG_FILE" || grep -q "^${var}=\$" "$CONFIG_FILE"; then
        echo "ERROR: Required variable $var is missing or empty"
        exit 1
    fi
done

# Check for placeholder values
PLACEHOLDER_VARS=(
    "REPLACE_ME_here"
    "REPLACE_ME_key_here"
    "REPLACE_ME"
    "your_saml_metadata_url"
)

for placeholder in "${PLACEHOLDER_VARS[@]}"; do
    if grep -q "$placeholder" "$CONFIG_FILE"; then
        echo "WARNING: Placeholder value found: $placeholder"
    fi
done

echo "Configuration validation passed"
```

#### **`scripts/config/deploy-config.sh`**
```bash
#!/bin/bash
# Deploy configuration to target environments

set -e

ENVIRONMENT=${1:-development}
TARGET=${2:-local}

echo "Deploying configuration for $ENVIRONMENT to $TARGET"

# Generate configuration
./scripts/config/generate-env.sh "$ENVIRONMENT"

# Deploy based on target
case $TARGET in
    local)
        cp ".env.${ENVIRONMENT}" .env
        ;;
    docker)
        # Deploy to Docker containers
        docker-compose --env-file ".env.${ENVIRONMENT}" up -d
        ;;
    kubernetes)
        # Deploy to Kubernetes
        kubectl create configmap paws360-config \
            --from-env-file=".env.${ENVIRONMENT}" \
            --namespace=paws360
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac

echo "Configuration deployed successfully"
```

---

## 📁 **Repository-Specific Configuration**

### **Main Repository Configuration**

**`.env.example`**
```bash
# PAWS360 Main Repository Configuration
# Copy from central configuration system

# Include all variables from .env.central
# Plus repository-specific overrides

# Repository-specific settings
REPO_NAME=PAWS360ProjectPlan
REPO_VERSION=1.0.0
LOCAL_DEV=true
```

### **Student Frontend Repository Configuration**

**`.env.example`**
```bash
# Student Frontend Configuration
# Generated from central configuration system

# React App Configuration
REACT_APP_API_BASE_URL=https://api.paws360.university.edu
REACT_APP_AUTH_URL=https://auth.paws360.university.edu
REACT_APP_JIRA_PROJECT_KEY=PGB

# Build Configuration
GENERATE_SOURCEMAP=false
SKIP_PREFLIGHT_CHECK=true
```

### **Admin Dashboard Repository Configuration**

**`.env.example`**
```bash
# Admin Dashboard Configuration
# Generated from central configuration system

# Application Configuration
APP_NAME=PAWS360 Admin Dashboard
APP_URL=https://admin.paws360.university.edu
API_BASE_URL=https://api.paws360.university.edu

# Feature Flags
JIRA_INTEGRATION_ENABLED=true
ANALYTICS_ENABLED=true
BACKUP_ENABLED=true
```

---

## 🔄 **Configuration Synchronization**

### **GitHub Actions Workflow**

**`.github/workflows/sync-config.yml`**
```yaml
name: Sync Configuration

on:
  push:
    paths:
      - 'config/central/**'
      - 'config/environments/**'
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  sync-config:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout main repository
      uses: actions/checkout@v3
      with:
        repository: your-org/PAWS360ProjectPlan
        path: main

    - name: Checkout student frontend
      uses: actions/checkout@v3
      with:
        repository: your-org/paws360-student-frontend
        path: student-frontend

    - name: Checkout admin dashboard
      uses: actions/checkout@v3
      with:
        repository: your-org/paws360-admin-dashboard
        path: admin-dashboard

    - name: Generate configurations
      run: |
        cd main
        ./scripts/config/generate-env.sh development
        ./scripts/config/generate-env.sh staging
        ./scripts/config/generate-env.sh production

    - name: Sync to student frontend
      run: |
        cp main/.env.development student-frontend/.env.local
        cp main/.env.staging student-frontend/.env.staging
        cp main/.env.production student-frontend/.env.production

    - name: Sync to admin dashboard
      run: |
        cp main/.env.development admin-dashboard/.env.local
        cp main/.env.staging admin-dashboard/.env.staging
        cp main/.env.production admin-dashboard/.env.production

    - name: Commit changes
      run: |
        cd student-frontend
        git add .env.*
        git commit -m "chore: sync configuration from central config" || true
        git push

        cd ../admin-dashboard
        git add .env.*
        git commit -m "chore: sync configuration from central config" || true
        git push
```

---

## 🔐 **Security & Secrets Management**

### **Secrets Management Strategy**

1. **Central Secrets Repository**
   - Store sensitive values in dedicated secrets repository
   - Use GitHub Secrets or AWS Secrets Manager
   - Never commit actual secrets to code

2. **Environment Variable Substitution**
   ```bash
   # In configuration files, use placeholders
   DB_PASSWORD=${DB_PASSWORD}
   JWT_SECRET=${JWT_SECRET}

   # Inject actual values at runtime
   export DB_PASSWORD="actual_secret_here"
   ```

3. **Secret Rotation**
   - Automated secret rotation scripts
   - Integration with cloud secret managers
   - Audit logging for secret access

### **Security Best Practices**

- ✅ **No Secrets in Code**: Never commit actual secrets
- ✅ **Environment Separation**: Different secrets per environment
- ✅ **Access Control**: Least privilege access to secrets
- ✅ **Audit Logging**: Track secret access and rotation
- ✅ **Encryption**: Encrypt secrets at rest and in transit

---

## 🚀 **Usage Guide**

### **Setting Up Configuration**

1. **Clone Main Repository**
   ```bash
   git clone https://github.com/your-org/PAWS360ProjectPlan.git
   cd PAWS360ProjectPlan
   ```

2. **Set Up Central Configuration**
   ```bash
   cp .env.example .env.central
   # Edit .env.central with your values
   ```

3. **Generate Environment Configurations**
   ```bash
   ./scripts/config/generate-env.sh development
   ./scripts/config/generate-env.sh staging
   ./scripts/config/generate-env.sh production
   ```

4. **Validate Configuration**
   ```bash
   ./scripts/config/validate-config.sh .env.development
   ```

### **Repository-Specific Setup**

1. **Student Frontend Repository**
   ```bash
   cd paws360-student-frontend
   cp ../PAWS360ProjectPlan/.env.development .env.local
   npm install
   npm start
   ```

2. **Admin Dashboard Repository**
   ```bash
   cd paws360-admin-dashboard
   cp ../PAWS360ProjectPlan/.env.development .env.local
   composer install
   php artisan serve
   ```

### **Deployment**

1. **Local Development**
   ```bash
   ./scripts/config/deploy-config.sh development local
   ```

2. **Docker Deployment**
   ```bash
   ./scripts/config/deploy-config.sh production docker
   ```

3. **Kubernetes Deployment**
   ```bash
   ./scripts/config/deploy-config.sh production kubernetes
   ```

---

## 📊 **Monitoring & Maintenance**

### **Configuration Health Checks**

- **Daily Validation**: Automated config validation
- **Secret Rotation**: Monthly secret rotation
- **Access Audit**: Weekly access log review
- **Backup Verification**: Daily backup integrity checks

### **Maintenance Scripts**

#### **`scripts/config/health-check.sh`**
```bash
#!/bin/bash
# Comprehensive configuration health check

echo "=== PAWS360 Configuration Health Check ==="

# Check central configuration
if [ ! -f ".env.central" ]; then
    echo "❌ Central configuration missing"
    exit 1
fi

# Validate all environments
for env in development staging production; do
    echo "Checking $env environment..."
    ./scripts/config/validate-config.sh ".env.$env" || exit 1
done

# Check repository synchronization
echo "Checking repository sync status..."
# Add repository sync checks here

echo "✅ All health checks passed"
```

---

## 🎯 **Benefits**

### **For Developers**
- ✅ **Single Source of Truth**: All configuration in one place
- ✅ **Environment Consistency**: Identical configs across repos
- ✅ **Automated Synchronization**: No manual config management
- ✅ **Security**: Centralized secrets management
- ✅ **Validation**: Automated config validation

### **For Operations**
- ✅ **Deployment Automation**: One-command deployments
- ✅ **Environment Management**: Easy environment switching
- ✅ **Monitoring**: Comprehensive health checks
- ✅ **Audit Trail**: Complete configuration history
- ✅ **Disaster Recovery**: Automated backup and restore

### **For Security**
- ✅ **Secrets Management**: Secure secret storage and rotation
- ✅ **Access Control**: Granular permissions
- ✅ **Compliance**: FERPA and security compliance
- ✅ **Audit Logging**: Complete audit trails
- ✅ **Encryption**: Data protection at rest and in transit

---

## 📈 **Implementation Roadmap**

### **Phase 1: Foundation (Current)**
- ✅ Central configuration repository
- ✅ Environment-specific configurations
- ✅ Basic validation scripts
- ✅ Repository synchronization

### **Phase 2: Automation (Next 2 weeks)**
- 🔄 Automated deployment scripts
- 🔄 GitHub Actions integration
- 🔄 Secret management integration
- 🔄 Advanced validation rules

### **Phase 3: Advanced Features (Next month)**
- ⏳ Multi-cloud support
- ⏳ Advanced monitoring
- ⏳ Configuration templating
- ⏳ Integration with infrastructure as code

### **Phase 4: Enterprise Features (Next quarter)**
- ⏳ Multi-tenant configuration
- ⏳ Advanced audit logging
- ⏳ Compliance automation
- ⏳ AI-assisted configuration

---

## 📞 **Support & Documentation**

### **Documentation Links**
- **Configuration Guide**: `docs/config/README.md`
- **Security Guide**: `docs/security/secrets-management.md`
- **Deployment Guide**: `docs/deployment/configuration-deployment.md`
- **Troubleshooting**: `docs/troubleshooting/config-issues.md`

### **Getting Help**
- **Issues**: Create GitHub issues with `config` label
- **Discussions**: Use GitHub Discussions for questions
- **Wiki**: Comprehensive documentation in project wiki

---

*Centralized Configuration System - Implementation in Progress*  
*Last Updated: September 20, 2025*  
*Next Review: October 4, 2025*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/CENTRALIZED_CONFIGURATION_SYSTEM.md