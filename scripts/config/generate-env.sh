#!/bin/bash
# Generate environment-specific .env files from central configuration

set -e

ENVIRONMENT=${1:-development}
OUTPUT_DIR=${2:-.}

echo "Generating configuration for environment: $ENVIRONMENT"

# Load central configuration
if [ ! -f "config/central/.env.central" ]; then
    echo "Error: config/central/.env.central not found"
    exit 1
fi

# Load environment-specific configuration
ENV_FILE="config/environments/${ENVIRONMENT}.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE not found"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate final configuration
cat "config/central/.env.central" "$ENV_FILE" > "${OUTPUT_DIR}/.env.${ENVIRONMENT}"

echo "Configuration generated: ${OUTPUT_DIR}/.env.${ENVIRONMENT}"