# PAWS360 Environment Configuration Guide

## 📋 Overview

This guide explains how to use the PAWS360 project's environment configuration system. The project uses `.env` files to manage configuration across different environments (local development, development server, and production).

## 🗂️ Configuration Files

### Base Configuration Template
- **`.env.example`** - Complete template with all available configuration options
- Copy this file to `.env` and customize for your environment

### Environment-Specific Templates
- **`.env.example.local`** - Optimized for local development with Docker
- **`.env.example.dev`** - For shared development server environment
- **`.env.example.prod`** - Production-ready configuration template

## 🚀 Quick Start

### For Local Development
```bash
# 1. Copy the local development template
cp .env.example.local .env

# 2. Edit with your local settings
nano .env

# 3. Start your services
./scripts/setup/paws360-services.sh start
```

### For Development Server
```bash
# 1. Copy the development template
cp .env.example.dev .env

# 2. Configure with development server settings
nano .env

# 3. Deploy to development environment
```

### For Production
```bash
# 1. Copy the production template
cp .env.example.prod .env

# 2. Configure with production settings (be careful!)
nano .env

# 3. Deploy to production
```

## ⚙️ Configuration Categories

### 🔐 Authentication & Security
```bash
# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRATION=24

# SAML Authentication (Azure AD)
SAML_ENTITY_ID=https://paws360.university.edu
SAML_IDP_METADATA_URL=https://login.microsoftonline.com/your-tenant-id/federationmetadata/2007-06/federationmetadata.xml
```

### 🗄️ Database Configuration
```bash
# PostgreSQL Settings
DB_HOST=localhost
DB_PORT=5432
DB_NAME=paws360
DB_USERNAME=paws360_user
DB_PASSWORD=your_secure_password
DB_SSL_MODE=require
```

### 🎫 JIRA Integration
```bash
# JIRA MCP Server Settings
JIRA_URL=https://paw360.atlassian.net
JIRA_PROJECT_KEY=PGB
JIRA_EMAIL=your-email@domain.com
JIRA_API_KEY=your_jira_api_token
```

### 📧 Email Configuration
```bash
# SMTP Settings
SMTP_HOST=smtp.university.edu
SMTP_PORT=587
SMTP_USERNAME=notifications@paws360.university.edu
SMTP_PASSWORD=your_smtp_password
```

### 🔄 External Services
```bash
# Service URLs
ANALYTICS_URL=http://localhost:8083
DATA_URL=http://localhost:8082
AUTH_URL=http://localhost:8081
UI_URL=http://localhost:8080
```

## 🔒 Security Best Practices

### Never Commit Sensitive Data
- `.env` files are automatically ignored by `.gitignore`
- Use strong, unique passwords for each environment
- Rotate API keys and tokens regularly
- Use different credentials for each environment

### Environment-Specific Credentials
```bash
# ❌ Don't do this
DB_PASSWORD=password

# ✅ Do this instead
# Local: DB_PASSWORD=dev_password_123
# Dev: DB_PASSWORD=dev_server_password
# Prod: DB_PASSWORD=prod_strong_password
```

### File Permissions
```bash
# Set restrictive permissions on .env files
chmod 600 .env
```

## 🛠️ Environment-Specific Settings

### Local Development
- **Debug Mode**: Enabled
- **Database**: Local PostgreSQL via Docker
- **Services**: All services run locally
- **Logging**: Verbose logging for debugging
- **Security**: Relaxed for development speed

### Development Server
- **Debug Mode**: Enabled
- **Database**: Shared development database
- **Services**: Containerized services
- **Logging**: Info level logging
- **Security**: Development-appropriate security

### Production
- **Debug Mode**: Disabled
- **Database**: Production database cluster
- **Services**: Highly available production services
- **Logging**: Warning+ level logging
- **Security**: Maximum security settings

## 🔧 Configuration Validation

### Check Your Configuration
```bash
# Validate .env file syntax
python -c "import os; [print(f'{k}={v}') for k, v in os.environ.items() if k.startswith(('APP_', 'DB_', 'JIRA_'))]"
```

### Required Variables by Environment

#### All Environments
- `APP_ENV`
- `APP_DEBUG`
- `DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`
- `JIRA_URL`, `JIRA_PROJECT_KEY`, `JIRA_EMAIL`, `JIRA_API_KEY`

#### Production Only
- `JWT_SECRET` (strong, random key)
- `ENCRYPTION_KEY` (32-character key)
- All SAML configuration
- All SMTP configuration

## 🚨 Common Issues & Solutions

### Missing Environment Variables
```bash
# Check if variables are loaded
echo $JIRA_API_KEY

# Source your .env file
source .env
```

### Database Connection Issues
```bash
# Test database connection
psql -h $DB_HOST -U $DB_USERNAME -d $DB_NAME

# Check SSL settings for production
# DB_SSL_MODE=require for production
```

### JIRA Authentication Problems
```bash
# Verify JIRA credentials
curl -H "Authorization: Bearer $JIRA_API_KEY" \
     -H "Content-Type: application/json" \
     $JIRA_URL/rest/api/3/myself
```

### Permission Issues
```bash
# Fix .env file permissions
chmod 600 .env

# Check file ownership
ls -la .env
```

## 📊 Environment Comparison

| Setting | Local | Development | Production |
|---------|-------|-------------|------------|
| Debug Mode | ✅ Enabled | ✅ Enabled | ❌ Disabled |
| Database SSL | ❌ Disabled | ✅ Required | ✅ Required |
| Log Level | DEBUG | INFO | WARNING |
| Cache TTL | 5 min | 30 min | 1 hour |
| Rate Limit | 1000/min | 500/min | 100/min |
| File Upload Size | 50MB | 25MB | 10MB |

## 🔄 Migration from Old Config

### If You Have Existing Config Files
1. **Backup** your current configuration
2. **Copy** the appropriate `.env.example.*` template
3. **Migrate** values from old config to new `.env` file
4. **Update** your application code to use environment variables
5. **Test** thoroughly in each environment

### Update Application Code
```python
# Old way
config = {
    'database_url': 'hardcoded_value'
}

# New way
import os
config = {
    'database_url': os.getenv('DATABASE_URL')
}
```

## 📚 Additional Resources

- **JIRA Integration Guide**: `docs/guides/jira-integration-guide.md`
- **API Testing Guide**: `docs/api/API_TESTING_README.md`
- **Deployment Guide**: `docs/deployment/`
- **Security Guidelines**: Check with your security team

## 🆘 Support

### Getting Help
1. Check this guide first
2. Review the appropriate `.env.example.*` template
3. Check existing issues in the project
4. Contact the development team

### Reporting Issues
- Include your environment (local/dev/prod)
- Specify which service is having issues
- Include relevant error messages
- Don't include sensitive credential information

---

**Last Updated:** September 19, 2025
**Version:** 1.0.0