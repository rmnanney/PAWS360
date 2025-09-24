# WSL/Ubuntu Development Environment Setup Guide

## Overview
This guide provides comprehensive setup instructions for new PAWS360 team members to configure their development environment on Windows Subsystem for Linux (WSL) with Ubuntu. The setup includes all necessary tools, configurations, and security measures for productive development work.

## Prerequisites
- Windows 10 version 2004 or higher (Build 19041 or higher)
- Windows 11
- Administrator access to install WSL
- At least 8GB RAM available
- 20GB free disk space

## Phase 1: WSL Installation and Configuration

### Step 1: Enable WSL Feature
```powershell
# Open PowerShell as Administrator and run:
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### Step 2: Install WSL2
```powershell
# Download and install the WSL2 kernel update:
# https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi

# Set WSL2 as default version:
wsl --set-default-version 2
```

### Step 3: Install Ubuntu Distribution
```powershell
# Install Ubuntu 22.04 LTS (or latest LTS):
wsl --install -d Ubuntu-22.04

# Alternative: List available distributions first
wsl --list --online
wsl --install -d Ubuntu-22.04
```

### Step 4: Initial Ubuntu Setup
```bash
# Launch Ubuntu and complete initial setup:
# - Create username: pawsdev (recommended)
# - Create password: [secure password]
# - Confirm password

# Update system packages:
sudo apt update && sudo apt upgrade -y
```

## Phase 2: Development Tools Installation

### Step 5: Install Essential Build Tools
```bash
# Install build essentials and development tools:
sudo apt install -y build-essential curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Python development tools:
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install Node.js 18+ and npm:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Java 21 (Amazon Corretto):
wget -O- https://apt.corretto.aws/corretto.key | sudo apt-key add -
sudo add-apt-repository 'deb https://apt.corretto.aws stable main'
sudo apt-get update
sudo apt-get install -y java-21-amazon-corretto-jdk

# Install Docker and Docker Compose:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group:
sudo usermod -aG docker $USER
```

### Step 6: Install Development IDEs and Tools
```bash
# Install Visual Studio Code:
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

# Install additional development tools:
sudo apt install -y vim neovim tmux htop tree jq httpie postgresql-client redis-tools

# Install development libraries:
sudo apt install -y libssl-dev libffi-dev libxml2-dev libxslt-dev libpq-dev
```

## Phase 3: SSH Key Configuration

### Step 7: Generate SSH Keys
```bash
# Generate SSH key pair:
ssh-keygen -t ed25519 -C "your.email@uwm.edu" -f ~/.ssh/id_ed25519

# Add SSH key to ssh-agent:
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key for GitHub/GitLab:
cat ~/.ssh/id_ed25519.pub
```

### Step 8: Configure SSH for Git Services
```bash
# Create SSH config file:
cat > ~/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
EOF

# Set proper permissions:
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## Phase 4: Git Configuration

### Step 9: Configure Git
```bash
# Set global Git configuration:
git config --global user.name "Your Full Name"
git config --global user.email "your.email@uwm.edu"
git config --global init.defaultBranch main
git config --global pull.rebase false

# Configure Git to use SSH:
git config --global url."git@github.com:".insteadOf "https://github.com/"
git config --global url."git@gitlab.com:".insteadOf "https://gitlab.com/"

# Set up Git credential helper (optional):
git config --global credential.helper store
```

## Phase 5: Project Setup

### Step 10: Clone PAWS360 Repository
```bash
# Create projects directory:
mkdir -p ~/projects
cd ~/projects

# Clone the repository:
git clone git@github.com:UWM-PAWS360/paws360-project-plan.git
cd paws360-project-plan
```

### Step 11: Install Project Dependencies
```bash
# Install Node.js dependencies for frontend:
cd admin-ui
npm install

cd ../admin-dashboard
npm install

# Install Python dependencies:
cd ..
pip3 install -r requirements.txt

# Install Java/Gradle wrapper (if needed):
# ./gradlew wrapper --gradle-version=8.5
```

### Step 12: Database Setup
```bash
# Install PostgreSQL locally (optional for development):
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL service:
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create development database:
sudo -u postgres createuser --createdb --superuser $USER
createdb paws360_dev
```

## Phase 6: Environment Configuration

### Step 13: Configure Environment Variables
```bash
# Create environment configuration:
cat > ~/.bashrc_paws360 << 'EOF'
# PAWS360 Development Environment
export PAWS360_HOME="$HOME/projects/paws360-project-plan"
export PATH="$PAWS360_HOME/scripts:$PATH"
export NODE_ENV="development"
export JAVA_HOME="/usr/lib/jvm/java-21-amazon-corretto"
export PATH="$JAVA_HOME/bin:$PATH"

# Docker environment
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Python virtual environment
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Development aliases
alias paws="cd $PAWS360_HOME"
alias start-services="cd $PAWS360_HOME && docker-compose up -d"
alias stop-services="cd $PAWS360_HOME && docker-compose down"
alias logs="cd $PAWS360_HOME && docker-compose logs -f"
EOF

# Source the configuration:
echo "source ~/.bashrc_paws360" >> ~/.bashrc
source ~/.bashrc
```

### Step 14: Configure Development Tools
```bash
# Configure Vim/Neovim (optional):
cat > ~/.vimrc << 'EOF'
syntax on
set number
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set background=dark
EOF

# Configure tmux (optional):
cat > ~/.tmux.conf << 'EOF'
# Set prefix to Ctrl-a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse mode
set -g mouse on

# Set base index to 1
set -g base-index 1
setw -g pane-base-index 1
EOF
```

## Phase 7: Testing and Validation

### Step 15: Test Development Environment
```bash
# Test basic tools:
node --version
npm --version
python3 --version
java --version
docker --version
git --version

# Test Docker functionality:
docker run hello-world

# Test project setup:
cd $PAWS360_HOME
npm test  # If available
python3 -m pytest  # If available

# Test database connection:
psql -d paws360_dev -c "SELECT version();"
```

### Step 16: Configure VS Code Integration
```bash
# Install VS Code extensions (from within VS Code):
# - Remote-WSL
# - Python
# - JavaScript and TypeScript Nightly
# - Docker
# - GitLens
# - ESLint
# - Prettier

# Configure VS Code settings for WSL:
cat > ~/.vscode/settings.json << 'EOF'
{
  "python.defaultInterpreterPath": "python3",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "files.eol": "\n",
  "git.autofetch": true,
  "terminal.integrated.shell.linux": "/bin/bash"
}
EOF
```

## Phase 8: Security and Best Practices

### Step 17: Security Hardening
```bash
# Update system regularly:
sudo apt update && sudo apt upgrade -y

# Configure firewall (UFW):
sudo apt install -y ufw
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 3000  # Development ports as needed

# Install security tools:
sudo apt install -y fail2ban clamav

# Configure fail2ban for SSH protection:
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Step 18: Backup and Recovery
```bash
# Create backup script:
cat > ~/backup-dev-env.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup SSH keys
cp -r ~/.ssh "$BACKUP_DIR/"

# Backup Git configuration
cp ~/.gitconfig "$BACKUP_DIR/"

# Backup VS Code settings
cp -r ~/.vscode "$BACKUP_DIR/"

# Backup environment configuration
cp ~/.bashrc_paws360 "$BACKUP_DIR/"

echo "Backup created in: $BACKUP_DIR"
EOF

chmod +x ~/backup-dev-env.sh
```

## Troubleshooting

### Common Issues and Solutions

**WSL Network Issues:**
```bash
# Restart WSL networking:
sudo service networking restart
# Or restart WSL entirely:
wsl --shutdown
wsl
```

**Docker Permission Issues:**
```bash
# Re-add user to docker group:
sudo usermod -aG docker $USER
# Restart WSL session
```

**SSH Key Issues:**
```bash
# Test SSH connection:
ssh -T git@github.com
# If issues, regenerate keys and update GitHub/GitLab
```

**Performance Issues:**
```bash
# Check WSL version:
wsl -l -v
# Update WSL kernel if needed
# Allocate more RAM in .wslconfig (Windows side)
```

## Next Steps

1. **Join Team Communication:** Request access to Slack, Microsoft Teams, or project communication channels
2. **Access Documentation:** Review project documentation in `$PAWS360_HOME/docs/`
3. **Onboarding Session:** Schedule pair programming session with team lead
4. **First Task:** Start with a small, well-defined task from the project backlog
5. **Code Review:** Submit first pull request and participate in code review process

## Support

- **Team Lead:** [Team Lead Name] - [contact]
- **DevOps Support:** [DevOps Contact] - [contact]
- **Documentation:** `$PAWS360_HOME/docs/` and project wiki
- **Issue Tracking:** Create GitHub issues for environment problems

---

*This guide ensures consistent development environments across the PAWS360 team and follows security best practices for university development work.*