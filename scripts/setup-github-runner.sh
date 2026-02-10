#!/bin/bash
set -euo pipefail

# GitHub Actions Runner Setup Script for PAWS360
# Repository: rmnanney/PAWS360
# Platform: Linux x64

RUNNER_VERSION="2.329.0"
RUNNER_HASH="194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d"
REPO_URL="https://github.com/rmnanney/PAWS360"

echo "=== GitHub Actions Runner Setup for PAWS360 ==="
echo

# Check for registration token
if [ -z "${RUNNER_TOKEN:-}" ]; then
    echo "❌ Error: RUNNER_TOKEN environment variable not set"
    echo
    echo "To get a token:"
    echo "  1. Go to: https://github.com/rmnanney/PAWS360/settings/actions/runners/new"
    echo "  2. Copy the token from the --token parameter"
    echo "  3. Run this script with: RUNNER_TOKEN='your-token' $0"
    echo
    exit 1
fi

# Create runner directory
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
echo "📁 Creating runner directory: $RUNNER_DIR"
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download runner package
RUNNER_FILE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_FILE}"

if [ ! -f "$RUNNER_FILE" ]; then
    echo "⬇️  Downloading runner package..."
    curl -o "$RUNNER_FILE" -L "$DOWNLOAD_URL"
else
    echo "✓ Runner package already downloaded"
fi

# Validate hash
echo "🔐 Validating package hash..."
echo "${RUNNER_HASH}  ${RUNNER_FILE}" | shasum -a 256 -c

# Extract if not already extracted
if [ ! -f "config.sh" ]; then
    echo "📦 Extracting runner package..."
    tar xzf "./$RUNNER_FILE"
else
    echo "✓ Runner already extracted"
fi

# Configure runner
echo "⚙️  Configuring runner..."
./config.sh \
    --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$(hostname)-paws360" \
    --labels "linux,x64" \
    --work _work \
    --unattended

echo
echo "✅ Runner configured successfully!"
echo

# Install as service
read -p "Install runner as a systemd service? (recommended) [Y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo "🔧 Installing runner service..."
    sudo ./svc.sh install
    sudo ./svc.sh start
    echo "✅ Runner service installed and started"
    echo
    echo "Check status with: sudo ./svc.sh status"
    echo "View logs with: sudo journalctl -u actions.runner.rmnanney-PAWS360.* -f"
else
    echo "⚠️  Skipping service installation"
    echo "To run manually: ./run.sh"
fi

echo
echo "=== Setup Complete ==="
echo
echo "Verify runner is online at:"
echo "  https://github.com/rmnanney/PAWS360/settings/actions/runners"
echo
echo "Test with a workflow:"
echo "  gh workflow run constitutional-self-check.yml"
echo

# Install dependencies prompt
echo "📋 Required dependencies for PAWS360 workflows:"
echo "  - Docker (for container builds)"
echo "  - Node.js 20+ (for frontend builds)"
echo "  - Java 21 (for backend builds)"
echo "  - Git"
echo "  - GitHub CLI (gh)"
echo "  - Ansible"
echo "  - Terraform"
echo
read -p "Install dependencies now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Installing dependencies..."
    
    # Update package list
    sudo apt-get update
    
    # Install essentials
    sudo apt-get install -y git curl wget jq
    
    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$(whoami)"
        echo "⚠️  Log out and back in for Docker permissions to take effect"
    fi
    
    # Install Node.js 20
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js 20..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install Java 21
    if ! command -v java &> /dev/null; then
        echo "Installing Java 21..."
        sudo apt-get install -y openjdk-21-jdk
    fi
    
    # Install GitHub CLI
    if ! command -v gh &> /dev/null; then
        echo "Installing GitHub CLI..."
        sudo apt-get install -y gh
    fi
    
    # Install Ansible
    if ! command -v ansible &> /dev/null; then
        echo "Installing Ansible..."
        sudo apt-get install -y ansible
    fi
    
    # Install Terraform
    if ! command -v terraform &> /dev/null; then
        echo "Installing Terraform..."
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update && sudo apt-get install -y terraform
    fi
    
    echo "✅ Dependencies installed"
fi

echo
echo "🎉 All done! Runner is ready to accept jobs."
