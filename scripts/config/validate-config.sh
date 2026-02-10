#!/bin/bash
# Validate configuration files for completeness and security

set -e

CONFIG_FILE=${1:-.env}

echo "Validating configuration: $CONFIG_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found"
    exit 1
fi

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
    "your_secure_password_here"
    "your_jwt_secret_key_here"
    "your_api_token_here"
    "your_saml_metadata_url"
)

for placeholder in "${PLACEHOLDER_VARS[@]}"; do
    if grep -q "$placeholder" "$CONFIG_FILE"; then
        echo "WARNING: Placeholder value found: $placeholder"
    fi
done

echo "Configuration validation passed"