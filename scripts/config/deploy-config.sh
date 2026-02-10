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
        if [ -f "docker-compose.yml" ]; then
            docker-compose --env-file ".env.${ENVIRONMENT}" up -d
        else
            echo "Warning: docker-compose.yml not found"
        fi
        ;;
    kubernetes)
        # Deploy to Kubernetes
        if command -v kubectl &> /dev/null; then
            kubectl create configmap paws360-config \
                --from-env-file=".env.${ENVIRONMENT}" \
                --namespace=paws360 --dry-run=client -o yaml | kubectl apply -f -
        else
            echo "Warning: kubectl not found"
        fi
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac

echo "Configuration deployed successfully"