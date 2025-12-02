# Platform Compatibility Matrix

Comprehensive compatibility matrix for running PAWS360 across different platforms and container runtimes.

## Quick Reference

| Platform | Docker | Podman | Status | Performance | Notes |
|----------|--------|--------|--------|-------------|-------|
| **Linux (x86_64)** | ✅ Full | ✅ Full | Production | 100% baseline | Recommended for production |
| **Linux (ARM64)** | ✅ Full | ✅ Full | Production | 95-100% | Growing cloud adoption (AWS Graviton) |
| **macOS (Intel)** | ✅ Full | ⚠️ Limited | Development | 80-90% | Docker Desktop recommended |
| **macOS (Apple Silicon)** | ✅ Full | ⚠️ Limited | Development | 85-95% | Use Rosetta 2 for AMD64 |
| **Windows (Docker Desktop)** | ✅ Full | ❌ No | Development | 70-80% | Use WSL2 backend |
| **Windows (WSL2 Native)** | ✅ Full | ✅ Full | Development | 80-95% | Keep code in Linux FS |
| **Windows (Native)** | ⚠️ Limited | ⚠️ Limited | Not recommended | 50-60% | Windows containers only |

---

## Detailed Compatibility

### Linux (x86_64 / AMD64)

**Best for**: Production servers, CI/CD, development

| Component | Docker 20.10+ | Docker 24+ | Podman 4.x | Podman 5.x |
|-----------|---------------|------------|------------|------------|
| Compose files (v2/v3) | ✅ | ✅ | ✅ | ✅ |
| Volume mounts | ✅ | ✅ | ✅ | ✅ |
| Named volumes | ✅ | ✅ | ✅ | ✅ |
| Bridge networking | ✅ | ✅ | ✅ | ✅ |
| Host networking | ✅ | ✅ | ✅ | ✅ |
| BuildKit | ✅ | ✅ | ⚠️ Limited | ✅ |
| Swarm mode | ✅ | ✅ | ❌ | ❌ |
| Kubernetes YAML | ❌ | ❌ | ✅ | ✅ |
| Rootless mode | ⚠️ Experimental | ✅ | ✅ | ✅ |
| Systemd integration | Via dockerd | Via dockerd | ✅ Native | ✅ Native |

**Installation**:
```bash
# Docker Engine
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker

# Podman
sudo apt-get install podman podman-compose  # Debian/Ubuntu
sudo dnf install podman podman-compose      # Fedora/RHEL
```

**Performance**: Baseline (100%)

**Known Issues**: None

---

### Linux (ARM64 / aarch64)

**Best for**: AWS Graviton, Raspberry Pi, ARM servers

| Component | Docker 20.10+ | Docker 24+ | Podman 4.x | Podman 5.x |
|-----------|---------------|------------|------------|------------|
| All features | ✅ | ✅ | ✅ | ✅ |
| AMD64 emulation (QEMU) | ✅ | ✅ | ✅ | ✅ |
| Multi-arch builds | ✅ | ✅ | ✅ | ✅ |

**Multi-arch image support**:
- PostgreSQL 15+: ✅ ARM64 + AMD64
- Redis 7+: ✅ ARM64 + AMD64
- etcd 3.5+: ✅ ARM64 + AMD64
- Spring Boot (custom): ✅ Build for both
- Next.js (custom): ✅ Build for both

**Installation**:
```bash
# Same as x86_64
curl -fsSL https://get.docker.com | sh

# Install QEMU for AMD64 emulation
sudo apt-get install qemu-user-static binfmt-support
```

**Performance**: 95-100% (native ARM), 20-40% (AMD64 via QEMU)

**Known Issues**:
- Some images missing ARM64 variants (force AMD64 with `--platform`)
- QEMU emulation slow for AMD64 images

---

### macOS (Intel x86_64)

**Best for**: Development on older Macs

| Component | Docker Desktop | Podman Machine | Native (No VM) |
|-----------|----------------|----------------|----------------|
| Compose files | ✅ | ✅ | ❌ |
| Volume mounts | ✅ | ✅ | ❌ |
| Host networking | ❌ (VM limitation) | ❌ | ❌ |
| BuildKit | ✅ | ⚠️ Limited | ❌ |
| GUI | ✅ | ❌ | ❌ |
| Performance | 80-90% | 70-80% | N/A |

**Installation**:
```bash
# Docker Desktop (recommended)
# Download from https://www.docker.com/products/docker-desktop/

# Podman (alternative)
brew install podman
podman machine init --cpus 4 --memory 8192
podman machine start
```

**Recommended Settings** (Docker Desktop):
- Memory: 12-16 GB
- CPUs: 6-8
- Disk: 100 GB
- VirtioFS: ✅ Enabled (5-10x faster file sharing)

**Performance**: 80-90% of Linux

**Known Issues**:
- File sharing slow without VirtioFS
- `host.docker.internal` required to access macOS services
- No true host networking (use port forwarding)

---

### macOS (Apple Silicon M1/M2/M3)

**Best for**: Development on modern Macs

| Component | Docker Desktop | Docker + Rosetta 2 | Podman Machine |
|-----------|----------------|-------------------|----------------|
| ARM64 images | ✅ Native | ✅ Native | ✅ Native |
| AMD64 images | ⚠️ QEMU (slow) | ✅ Rosetta (fast) | ⚠️ QEMU (slow) |
| Multi-arch builds | ✅ | ✅ | ⚠️ Limited |
| Performance (ARM64) | 95-100% | 95-100% | 85-95% |
| Performance (AMD64) | 20-40% | 70-85% | 20-40% |

**Installation**:
```bash
# Docker Desktop (recommended)
# Download from https://www.docker.com/products/docker-desktop/

# Enable Rosetta 2 (2-3x faster than QEMU for AMD64)
softwareupdate --install-rosetta
# Docker Desktop → Settings → Features → Use Rosetta ✅

# Podman (alternative, less mature on macOS)
brew install podman
podman machine init --cpus 4 --memory 8192
podman machine start
```

**Development Strategies**:

1. **Native ARM64** (fast, development):
   ```yaml
   # No platform specified → uses ARM64
   services:
     backend:
       build: .
   ```
   Build time: 2-3 minutes ✅

2. **AMD64 via Rosetta 2** (slower, prod-parity):
   ```yaml
   services:
     backend:
       build:
         context: .
         platform: linux/amd64
   ```
   Build time: 5-7 minutes ⚠️

3. **Multi-platform** (CI/CD):
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 -t backend --push .
   ```
   Build time: 8-12 minutes

**Performance**: 85-95% (native ARM), 70-85% (AMD64 via Rosetta 2)

**Known Issues**:
- AirPlay Receiver conflicts with port 5000 (disable in System Settings)
- Some images missing ARM64 variants
- QEMU emulation slow without Rosetta 2

---

### Windows (Docker Desktop)

**Best for**: Windows developers, simplicity

| Component | WSL2 Backend | Hyper-V Backend | Windows Containers |
|-----------|--------------|-----------------|-------------------|
| Linux containers | ✅ | ✅ | ❌ |
| Windows containers | ❌ | ❌ | ✅ |
| Compose files | ✅ | ✅ | ⚠️ Limited |
| Volume mounts | ✅ | ✅ | ✅ |
| Host networking | ❌ (VM) | ❌ (VM) | ✅ |
| Performance | 80-95% | 60-75% | 90-100% |

**Installation**:
```powershell
# Download Docker Desktop
# https://www.docker.com/products/docker-desktop/

# Enable WSL2 backend (recommended)
# Docker Desktop → Settings → General → Use WSL2 based engine ✅

# Enable specific WSL2 distros
# Docker Desktop → Settings → Resources → WSL Integration → Enable Ubuntu ✅
```

**Recommended Settings**:
- Backend: WSL2 (not Hyper-V)
- Memory: 12-16 GB
- CPUs: 6-8
- File sharing: Use WSL2 filesystem (\\wsl$\Ubuntu\home\user\)

**Performance**: 80-95% (WSL2 backend), 60-75% (Hyper-V backend)

**Known Issues**:
- Slow if code on Windows FS (C:\) instead of WSL2 FS (/home/)
- Requires Windows Pro/Enterprise for Hyper-V backend
- WSL2 memory not released automatically (requires `wsl --shutdown`)

---

### Windows (WSL2 Native Docker)

**Best for**: Windows developers, performance, no Docker Desktop license

| Component | Docker Engine | Podman |
|-----------|---------------|--------|
| Linux containers | ✅ | ✅ |
| Compose files | ✅ | ✅ |
| Volume mounts | ✅ | ✅ |
| Rootless mode | ⚠️ Experimental | ✅ |
| Systemd | ✅ (WSL 0.67.6+) | ✅ |
| Performance | 80-95% | 80-95% |

**Installation**:
```bash
# Inside WSL2 Ubuntu
# Install Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Enable systemd (required)
sudo nano /etc/wsl.conf
[boot]
systemd=true

# Restart WSL2
exit
wsl --shutdown  # From PowerShell
wsl

# Start Docker
sudo systemctl enable --now docker

# Or install Podman
sudo apt-get install podman podman-compose
```

**Performance**: 80-95% (if code in Linux FS), 30-50% (if code in Windows FS)

**Critical Rule**: Keep code in `/home/user/`, NOT `/mnt/c/`

**Known Issues**:
- Must enable systemd in WSL2
- File permissions issues on Windows FS (/mnt/c/)
- DNS resolution slow (use custom DNS)

---

### Windows (Native Windows Containers)

**Best for**: Windows-only workloads (not PAWS360)

| Component | Support | Notes |
|-----------|---------|-------|
| Linux containers | ❌ | Requires WSL2/Hyper-V |
| Windows containers | ✅ | Different base images |
| PAWS360 support | ❌ | PAWS360 uses Linux containers |

**Not recommended for PAWS360**. Use WSL2 or Docker Desktop with WSL2 backend instead.

---

## Container Runtime Comparison

### Docker vs Podman

| Feature | Docker | Podman |
|---------|--------|--------|
| **Daemon** | Required (dockerd) | Daemonless |
| **Root requirement** | docker group or root | True rootless |
| **Security** | Daemon runs as root | No privileged process |
| **API compatibility** | Docker API | Docker-compatible API |
| **Compose** | docker-compose | podman-compose |
| **Swarm** | ✅ | ❌ |
| **Kubernetes YAML** | ❌ | ✅ Native support |
| **Systemd integration** | Via daemon | Native (no daemon) |
| **Memory overhead** | 100-200 MB (daemon) | 10-30 MB |
| **Performance** | Baseline | 95-100% |

**Recommendation**: Docker for production (mature, widely supported), Podman for rootless/security-focused environments.

---

## Platform-Specific Optimization

### Linux

```bash
# Optimize for production
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w net.core.somaxconn=65535
echo 'fs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Use overlay2 storage driver (fastest)
cat /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
```

### macOS

```bash
# Enable VirtioFS (5-10x faster file sharing)
# Docker Desktop → Settings → General → VirtioFS ✅

# On Apple Silicon: Enable Rosetta 2
# Settings → Features → Use Rosetta for x86/amd64 emulation ✅

# Increase memory (Docker Desktop)
# Settings → Resources → Memory: 16 GB
```

### Windows WSL2

```ini
# C:\Users\YourUsername\.wslconfig
[wsl2]
memory=16GB
processors=8
swap=16GB
localhostForwarding=true
networkingMode=mirrored  # WSL 2.0+ only
```

```bash
# Inside WSL2: Keep code in Linux FS
cd /home/user/repos/PAWS360  # ✅ Fast (3 GB/s)
# NOT: /mnt/c/Users/.../PAWS360  # ❌ Slow (200 MB/s)
```

---

## Testing Checklist

Use this checklist to verify PAWS360 works on your platform:

```bash
# 1. Check container runtime
docker --version || podman --version

# 2. Check architecture
docker version --format '{{.Server.Arch}}'
# Expected: amd64 (Intel/AMD) or arm64 (Apple Silicon/ARM)

# 3. Clone repository
git clone https://github.com/your-org/PAWS360.git
cd PAWS360

# 4. Start environment
make dev-up

# 5. Wait for health
make wait-healthy

# 6. Verify services
curl http://localhost:8080/api/health  # Backend
curl http://localhost:3000             # Frontend
curl http://localhost:8008/patroni     # Patroni

# 7. Run tests
make test-failover        # Patroni failover test
make test-zero-data-loss  # Data integrity test

# 8. Check performance
time make dev-up  # Should be <90s on most platforms
```

**Expected startup times**:
- Linux (native): 45-50s
- macOS (Intel): 60-70s
- macOS (Apple Silicon, ARM64): 50-60s
- macOS (Apple Silicon, AMD64): 70-85s
- Windows (WSL2): 55-70s
- Windows (Docker Desktop): 70-90s

---

## Troubleshooting by Platform

### Linux

```bash
# Issue: Permission denied
sudo usermod -aG docker $USER
newgrp docker

# Issue: Docker daemon not starting
sudo systemctl start docker
sudo systemctl status docker

# Issue: Storage driver issues
sudo rm -rf /var/lib/docker
sudo systemctl restart docker
```

### macOS

```bash
# Issue: Slow file sharing
# Enable VirtioFS in Docker Desktop settings

# Issue: Port conflicts (AirPlay port 5000)
# System Settings → General → AirDrop & Handoff → AirPlay Receiver: Off

# Issue: Out of memory
# Docker Desktop → Settings → Resources → Memory: Increase to 16 GB
```

### Windows (WSL2)

```powershell
# Issue: WSL2 not starting
wsl --update
wsl --shutdown
wsl

# Issue: Docker in WSL2 not found
# Inside WSL2:
sudo systemctl start docker

# Issue: Slow performance
# Move code from /mnt/c/ to /home/user/
```

---

## Quick Reference

| Platform | Command to Start PAWS360 | Expected Startup Time |
|----------|--------------------------|---------------------|
| Linux (Docker) | `make dev-up` | 45-50s |
| Linux (Podman) | `make dev-up` | 48-55s |
| macOS (Docker Desktop) | `make dev-up` | 60-85s |
| macOS (Podman) | `podman-compose up -d` | 70-90s |
| Windows (Docker Desktop) | `make dev-up` | 70-90s |
| Windows (WSL2 Docker) | `make dev-up` | 55-70s |
| Windows (WSL2 Podman) | `podman-compose up -d` | 60-80s |

**Performance ranking** (fastest to slowest):
1. Linux native (100%)
2. Linux ARM64 (95-100%)
3. WSL2 (Linux FS) (80-95%)
4. macOS (VirtioFS + Rosetta) (85-95%)
5. macOS (Intel) (80-90%)
6. WSL2 (Windows FS) (30-50%)

---

## Related Documentation

- [Podman Compatibility Guide](../guides/podman-compatibility.md)
- [WSL2 Optimization Guide](../guides/wsl2-optimization.md)
- [Apple Silicon Cross-Compilation](../guides/apple-silicon-guide.md)
- [Performance Tuning](../operations/performance-tuning.md)
