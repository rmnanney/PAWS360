#!/bin/bash
# Comprehensive configuration health check

echo "=== PAWS360 Configuration Health Check ==="

# Check central configuration
if [ ! -f "config/central/.env.central" ]; then
    echo "❌ Central configuration missing"
    exit 1
fi

echo "✅ Central configuration found"

# Validate all environments
for env in development staging production; do
    echo "Checking $env environment..."
    if [ ! -f "config/environments/${env}.env" ]; then
        echo "❌ $env environment configuration missing"
        exit 1
    fi

    # Generate and validate configuration
    ./scripts/config/generate-env.sh "$env" /tmp
    ./scripts/config/validate-config.sh "/tmp/.env.${env}" || exit 1
    echo "✅ $env environment validated"
done

# Check service configurations
for service in jira-mcp student-frontend admin-dashboard; do
    if [ ! -f "config/services/${service}.env" ]; then
        echo "❌ $service service configuration missing"
        exit 1
    fi
    echo "✅ $service service configuration found"
done

# Check scripts
SCRIPTS=(
    "scripts/config/generate-env.sh"
    "scripts/config/validate-config.sh"
    "scripts/config/deploy-config.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        echo "❌ $script missing"
        exit 1
    fi
    if [ ! -x "$script" ]; then
        chmod +x "$script"
        echo "✅ Made $script executable"
    fi
done

echo "✅ All health checks passed"