# PAWS360 Configuration Management

## 🎯 **Overview**

This directory contains the centralized configuration management system for the PAWS360 project ecosystem. It provides a unified way to manage configuration across all repositories and services.

## 📁 **Directory Structure**

```
config/
├── central/           # Master configuration files
│   └── .env.central   # Central configuration template
├── environments/      # Environment-specific overrides
│   ├── development.env
│   ├── staging.env
│   └── production.env
├── services/          # Service-specific configurations
│   ├── jira-mcp.env
│   ├── student-frontend.env
│   └── admin-dashboard.env
└── repositories/      # Repository-specific settings
    ├── main.env
    ├── student-frontend.env
    └── admin-dashboard.env

scripts/config/
├── generate-env.sh    # Generate environment configs
├── validate-config.sh # Validate configuration files
├── deploy-config.sh   # Deploy configurations
└── health-check.sh    # System health check
```

## 🚀 **Quick Start**

### **1. Set Up Central Configuration**

```bash
# Copy the central configuration template
cp config/central/.env.central .env

# Edit with your actual values
nano .env
```

### **2. Generate Environment Configurations**

```bash
# Generate development configuration
./scripts/config/generate-env.sh development

# Generate staging configuration
./scripts/config/generate-env.sh staging

# Generate production configuration
./scripts/config/generate-env.sh production
```

### **3. Validate Configuration**

```bash
# Validate all configurations
./scripts/config/health-check.sh

# Validate specific environment
./scripts/config/validate-config.sh .env.development
```

### **4. Deploy Configuration**

```bash
# Deploy to local environment
./scripts/config/deploy-config.sh development local

# Deploy to Docker
./scripts/config/deploy-config.sh production docker

# Deploy to Kubernetes
./scripts/config/deploy-config.sh production kubernetes
```

## ⚙️ **Configuration Files**

### **Central Configuration (`.env.central`)**

The master configuration file containing all variables used across the ecosystem:

- **Global Settings**: Environment, version, domain
- **Database**: PostgreSQL connection settings
- **Authentication**: JWT, SAML, security settings
- **JIRA Integration**: API credentials and settings
- **External Services**: Redis, email, analytics
- **Feature Flags**: Enable/disable features

### **Environment Overrides**

Environment-specific files that override central settings:

- **`development.env`**: Debug mode, local services
- **`staging.env`**: Testing environment settings
- **`production.env`**: Production security and performance

### **Service Configurations**

Service-specific configuration files:

- **`jira-mcp.env`**: JIRA MCP Server settings
- **`student-frontend.env`**: React frontend configuration
- **`admin-dashboard.env`**: Admin interface settings

## 🔧 **Scripts**

### **`generate-env.sh`**
Generates environment-specific `.env` files by combining central configuration with environment overrides.

```bash
./scripts/config/generate-env.sh [environment] [output_dir]
```

### **`validate-config.sh`**
Validates configuration files for completeness and security.

```bash
./scripts/config/validate-config.sh [config_file]
```

### **`deploy-config.sh`**
Deploys configuration to different targets (local, Docker, Kubernetes).

```bash
./scripts/config/deploy-config.sh [environment] [target]
```

### **`health-check.sh`**
Performs comprehensive health checks on the configuration system.

```bash
./scripts/config/health-check.sh
```

## 🔐 **Security Best Practices**

### **Secrets Management**

1. **Never commit secrets** to version control
2. **Use environment variables** for sensitive data
3. **Rotate secrets regularly** (recommended: monthly)
4. **Use different secrets** per environment

### **Required Secrets**

The following variables must be set in your environment:

```bash
# Database
DB_PASSWORD=your_secure_db_password

# Authentication
JWT_SECRET=your_jwt_secret_key
ENCRYPTION_KEY=your_encryption_key

# JIRA Integration
JIRA_EMAIL=your_jira_email
JIRA_API_KEY=your_jira_api_token

# SAML Authentication
SAML_IDP_METADATA_URL=your_saml_metadata_url

# Redis
REDIS_PASSWORD=your_redis_password

# Email
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
```

## 🌍 **Multi-Repository Setup**

### **Repository Structure**

The PAWS360 ecosystem includes:

1. **Main Repository** (`PAWS360ProjectPlan`)
   - Central configuration management
   - JIRA MCP Server
   - Backend services

2. **Student Frontend** (`paws360-student-frontend`)
   - React-based student interface
   - Course management UI

3. **Admin Dashboard** (`paws360-admin-dashboard`)
   - Administrative interface
   - Reporting and analytics

### **Configuration Synchronization**

Use GitHub Actions to automatically sync configurations:

```yaml
# .github/workflows/sync-config.yml
name: Sync Configuration
on:
  push:
    paths:
      - 'config/central/**'
      - 'config/environments/**'
```

## 📊 **Monitoring & Maintenance**

### **Regular Tasks**

- **Daily**: Run health checks
- **Weekly**: Review access logs
- **Monthly**: Rotate secrets
- **Quarterly**: Audit configuration changes

### **Health Checks**

```bash
# Run daily health check
./scripts/config/health-check.sh

# Check specific service
./scripts/config/validate-config.sh config/services/jira-mcp.env
```

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Configuration Not Found**
```bash
# Check if central config exists
ls -la config/central/.env.central

# Regenerate configuration
./scripts/config/generate-env.sh development
```

#### **Validation Errors**
```bash
# Check validation output
./scripts/config/validate-config.sh .env.development

# Fix missing variables in .env file
nano .env
```

#### **Permission Errors**
```bash
# Make scripts executable
chmod +x scripts/config/*.sh

# Check file permissions
ls -la scripts/config/
```

### **Debug Mode**

Enable debug logging for troubleshooting:

```bash
# In your .env file
LOG_LEVEL=DEBUG
APP_DEBUG=true
```

## 📚 **Documentation**

- **[Central Configuration System](CENTRALIZED_CONFIGURATION_SYSTEM.md)**: Complete system documentation
- **[JIRA MCP Implementation](../docs/JIRA_MCP_COMPLETE_IMPLEMENTATION.md)**: JIRA integration details
- **[Security Guide](../docs/security/secrets-management.md)**: Security best practices
- **[Deployment Guide](../docs/deployment/configuration-deployment.md)**: Deployment procedures

## 🤝 **Contributing**

### **Adding New Configuration**

1. **Update central config**: Add to `config/central/.env.central`
2. **Add environment overrides**: Update `config/environments/*.env`
3. **Update validation**: Modify `scripts/config/validate-config.sh`
4. **Test changes**: Run `./scripts/config/health-check.sh`
5. **Update documentation**: Update this README

### **Adding New Environment**

1. **Create environment file**: `config/environments/new-env.env`
2. **Update scripts**: Modify generation and validation scripts
3. **Test deployment**: `./scripts/config/deploy-config.sh new-env local`

## 📞 **Support**

- **Issues**: Create GitHub issues with `configuration` label
- **Discussions**: Use project discussions for questions
- **Documentation**: Check docs/ directory for detailed guides

---

**Last Updated**: September 20, 2025
**Version**: 1.0.0
**Status**: ✅ **IMPLEMENTATION COMPLETE**