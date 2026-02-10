#!/usr/bin/env bash
# PAWS360 Setup Bootstrap
# Run with: bash setup.sh

set -e

echo "========================================="
echo "  PAWS360 Setup Bootstrap"
echo "========================================="
echo ""

# Make scripts executable
echo "📝 Making scripts executable..."
chmod +x scripts/setup/*.sh

# Run main setup
echo "🚀 Running automated setup..."
./scripts/setup/setup-from-scratch.sh
