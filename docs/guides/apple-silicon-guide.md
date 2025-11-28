# Apple Silicon (M1/M2/M3) Cross-Compilation Guide

Complete guide for developing PAWS360 on Apple Silicon Macs with ARM64 architecture.

## Table of Contents

- [Overview](#overview)
- [Architecture Challenges](#architecture-challenges)
- [Docker Desktop Configuration](#docker-desktop-configuration)
- [Multi-Architecture Builds](#multi-architecture-builds)
- [Rosetta 2 Emulation](#rosetta-2-emulation)
- [Performance Optimization](#performance-optimization)
- [Native ARM Images](#native-arm-images)
- [Troubleshooting](#troubleshooting)

---

## Overview

Apple Silicon (ARM64/aarch64) requires special consideration for Docker development targeting AMD64 servers.

### Architecture Matrix

| Component | Dev (Apple Silicon) | Production (Typical) | Strategy |
|-----------|---------------------|----------------------|----------|
| **Host CPU** | ARM64 (M1/M2/M3) | AMD64 (x86_64) | Cross-compile or emulate |
| **Base Images** | Multi-arch (ARM+AMD) | AMD64 only | Use multi-arch images |
| **PostgreSQL** | Native ARM ✅ | AMD64 | Multi-arch image |
| **Redis** | Native ARM ✅ | AMD64 | Multi-arch image |
| **etcd** | Native ARM ✅ | AMD64 | Multi-arch image |
| **Spring Boot** | Native ARM ✅ | AMD64 | Build for both |
| **Next.js** | Native ARM ✅ | AMD64 | Build for both |

---

## Architecture Challenges

### Problem 1: Platform Mismatch

```bash
# On Apple Silicon (ARM64)
docker build -t paws360-backend .

# Image built for: linux/arm64
# Production server expects: linux/amd64
# Result: ❌ "exec format error" on deployment
```

### Problem 2: Slow Emulation

```bash
# Force AMD64 build on ARM64 (via QEMU emulation)
docker build --platform linux/amd64 -t paws360-backend .

# Performance: 5-10x slower than native ARM build
# Maven build: ~12 minutes (vs 2 minutes native)
```

### Problem 3: Image Availability

```bash
# Some images missing ARM64 variant
docker pull someimage:latest
# Error: no matching manifest for linux/arm64
```

---

## Docker Desktop Configuration

### Recommended Settings

```json
{
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "20GB"
    }
  },
  "experimental": true,
  "features": {
    "buildkit": true
  },
  "containerd": true,
  "filesharingDirectories": [
    "/Users",
    "/Volumes",
    "/private",
    "/tmp"
  ],
  "memoryMiB": 16384,
  "cpus": 8,
  "diskSizeMiB": 102400,
  "useVirtualizationFramework": true,
  "useVirtualizationFrameworkRosetta": true,
  "useVirtualizationFrameworkVirtioFS": true
}
```

**Key settings**:
- `useVirtualizationFramework`: Enables Apple Virtualization.framework (faster than HyperKit)
- `useVirtualizationFrameworkRosetta`: Enables Rosetta 2 for AMD64 emulation (2x faster than QEMU)
- `useVirtualizationFrameworkVirtioFS`: Faster file sharing (5-10x vs gRPC-FUSE)
- `memoryMiB`: 16 GB (50-75% of system RAM)
- `cpus`: 8 (50-75% of cores)

### Enable Rosetta 2 Emulation

```bash
# Verify Rosetta 2 enabled in Docker Desktop
docker buildx inspect default | grep "Platforms"
# Platforms: linux/arm64, linux/amd64, linux/riscv64, linux/ppc64le, ...

# If linux/amd64 missing, install Rosetta 2
softwareupdate --install-rosetta --agree-to-license

# Restart Docker Desktop
# Settings → Features in Development → Use Rosetta ✅
```

---

## Multi-Architecture Builds

### Strategy 1: Build for Native ARM64 (Development)

**Use native ARM images for fast local development.**

```yaml
# docker-compose.yml (development)
services:
  patroni1:
    # Use multi-arch image (auto-selects ARM64 on M1/M2)
    image: postgres:15-alpine
    # No platform specified → defaults to host architecture
```

```bash
# Build backend for ARM64 (native, fast)
docker build -t paws360-backend:arm64 .

# Startup time: 45s (native ARM execution)
make dev-up
```

**Pros**:
- Fast builds (2-3 minutes for backend)
- Fast startup (no emulation overhead)
- Low CPU usage

**Cons**:
- Not production-representative
- May miss AMD64-specific bugs

### Strategy 2: Build for AMD64 (Production Parity)

**Use AMD64 images via Rosetta 2 for production parity.**

```yaml
# docker-compose.yml (production-parity mode)
services:
  patroni1:
    image: postgres:15-alpine
    platform: linux/amd64  # Force AMD64 even on ARM host
```

```bash
# Build backend for AMD64 (emulated, slower)
docker build --platform linux/amd64 -t paws360-backend:amd64 .

# Startup time: 65s (+45% overhead from Rosetta emulation)
make dev-up
```

**Pros**:
- Production-representative
- Catches AMD64-specific bugs
- Same image for dev and prod

**Cons**:
- Slower builds (5-8 minutes for backend)
- Slower startup (~30-45% overhead)
- Higher CPU usage

### Strategy 3: Multi-Platform Build (CI/CD)

**Build for both ARM64 and AMD64 simultaneously.**

```bash
# Create multi-platform builder
docker buildx create --name multiplatform --driver docker-container --use
docker buildx inspect --bootstrap

# Build for both platforms and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/your-org/paws360-backend:latest \
  --push \
  .

# Image manifest includes both architectures
docker manifest inspect ghcr.io/your-org/paws360-backend:latest
```

**Pros**:
- One image works on both ARM and AMD64
- Future-proof (ARM servers growing)
- Efficient CI/CD

**Cons**:
- Slower builds (builds twice)
- Requires push to registry (can't use locally)

---

## Rosetta 2 Emulation

### Performance Comparison

| Task | Native ARM64 | Rosetta 2 (AMD64) | QEMU (AMD64) |
|------|--------------|-------------------|--------------|
| Backend build (Maven) | 125s | 215s (+72%) | 650s (+420%) |
| Frontend build (npm) | 65s | 95s (+46%) | 280s (+331%) |
| PostgreSQL queries | 100% | 92% (-8%) | 45% (-55%) |
| Redis operations | 100% | 95% (-5%) | 60% (-40%) |
| Container startup | 45s | 65s (+44%) | 120s (+167%) |

**Verdict**: Rosetta 2 provides ~2-3x better performance than QEMU for AMD64 emulation.

### Enable Rosetta 2 Globally

```bash
# Add to docker-compose.yml (top-level)
x-common-platform: &common-platform
  platform: linux/amd64

services:
  backend:
    <<: *common-platform
    # ...
  
  frontend:
    <<: *common-platform
    # ...
  
  patroni1:
    <<: *common-platform
    # ...
```

### Verify Rosetta 2 Usage

```bash
# Check if Rosetta 2 is being used (not QEMU)
docker run --rm --platform linux/amd64 alpine uname -m
# x86_64 (via Rosetta 2 ✅)

# Check Docker Desktop settings
# Features in Development → "Use Rosetta for x86/amd64 emulation on Apple Silicon" ✅

# Verify in Activity Monitor (macOS)
# Look for "com.docker.backend" process
# CPU usage should be ~30-50% lower with Rosetta vs QEMU
```

---

## Performance Optimization

### 1. Use Native ARM Images (Development)

```dockerfile
# Dockerfile.backend (multi-stage build)
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-21 AS builder

# Build uses host platform (ARM64 on M1/M2) → fast!
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src/ src/
RUN mvn package -DskipTests

# Runtime can be ARM or AMD64
FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

**Build speedup**: 3-5x faster for native ARM builds.

### 2. Enable BuildKit Caching

```bash
# Add to docker-compose.yml or Dockerfile
# DOCKER_BUILDKIT=1 (enabled by default in Docker Desktop 4.0+)

# Use cache mounts for Maven/npm
# Dockerfile.backend
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

# Cache Maven dependencies
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline

# Build with cached dependencies
RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests
```

**Build speedup**: 2-3x faster on subsequent builds (cache hit).

### 3. Use Smaller Base Images

```dockerfile
# ❌ Slow: Full JDK (700 MB)
FROM eclipse-temurin:21

# ✅ Fast: JRE Alpine (180 MB)
FROM eclipse-temurin:21-jre-alpine

# ✅ Fastest: Distroless (120 MB)
FROM gcr.io/distroless/java21-debian12
```

**Pull time**: 3-5x faster for Alpine/distroless images.

### 4. Optimize File Sharing (VirtioFS)

```bash
# Enable VirtioFS in Docker Desktop
# Settings → General → "Use VirtioFS" ✅

# Verify VirtioFS active
docker run --rm -v $(pwd):/data alpine dd if=/dev/zero of=/data/testfile bs=1M count=100
# ~800 MB/s with VirtioFS
# ~200 MB/s with gRPC-FUSE
```

### 5. Reduce Memory Pressure

```bash
# Limit Docker memory (leave headroom for macOS)
# Docker Desktop Settings → Resources
# Memory: 12 GB (on 16 GB Mac) or 16 GB (on 32 GB Mac)

# Reduce PostgreSQL shared_buffers on Apple Silicon
# docker-compose.patroni.yml
services:
  patroni1:
    environment:
      PATRONI_POSTGRESQL_PARAMETERS_SHARED_BUFFERS: "512MB"  # Default: 1GB
      PATRONI_POSTGRESQL_PARAMETERS_EFFECTIVE_CACHE_SIZE: "2GB"  # Default: 4GB
```

---

## Native ARM Images

### PostgreSQL (Official)

```yaml
services:
  patroni1:
    image: postgres:15-alpine  # Multi-arch (ARM64 + AMD64)
    # Auto-selects ARM64 on M1/M2 → native performance ✅
```

### Redis (Official)

```yaml
services:
  redis-master:
    image: redis:7-alpine  # Multi-arch (ARM64 + AMD64)
    # Auto-selects ARM64 → native performance ✅
```

### etcd (Official)

```yaml
services:
  etcd1:
    image: quay.io/coreos/etcd:v3.5.11  # Multi-arch (ARM64 + AMD64)
    # Auto-selects ARM64 → native performance ✅
```

### Spring Boot (Custom Build)

```dockerfile
# Dockerfile.backend (multi-arch support)
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-21 AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src/ src/
RUN mvn package -DskipTests

# Runtime: Use matching architecture
FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

### Next.js (Custom Build)

```dockerfile
# Dockerfile.frontend (multi-arch support)
FROM --platform=$BUILDPLATFORM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Runtime: Use matching architecture
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
CMD ["npm", "start"]
```

---

## Troubleshooting

### "exec format error"

**Cause**: Running AMD64 binary on ARM64 without emulation.

**Solution**:
```bash
# Option 1: Enable Rosetta 2 in Docker Desktop
# Settings → Features in Development → Use Rosetta ✅

# Option 2: Explicitly set platform
docker run --platform linux/amd64 paws360-backend:latest

# Option 3: Rebuild for ARM64
docker build -t paws360-backend:arm64 .
docker run paws360-backend:arm64
```

### "no matching manifest for linux/arm64"

**Cause**: Image not available for ARM64 architecture.

**Solution**:
```bash
# Check available platforms
docker manifest inspect postgres:15-alpine | grep "architecture"
# "architecture": "arm64" ✅
# "architecture": "amd64" ✅

# If ARM64 missing, force AMD64 with Rosetta
docker pull --platform linux/amd64 some-image:latest
```

### Slow builds on Apple Silicon

**Symptoms**: Maven/npm builds taking 10+ minutes.

**Solution**:
```bash
# 1. Use native ARM64 builds (don't force --platform)
docker build -t backend .  # No --platform flag!

# 2. Enable BuildKit cache
export DOCKER_BUILDKIT=1

# 3. Use cache mounts in Dockerfile
RUN --mount=type=cache,target=/root/.m2 mvn package

# 4. Verify not using QEMU
docker buildx inspect default | grep "Platforms"
# Should NOT show "qemu" in driver name
```

### High CPU usage (Docker Desktop)

**Cause**: Emulation overhead or inefficient builds.

**Solution**:
```bash
# 1. Use native ARM images (not AMD64)
# Remove all "platform: linux/amd64" from docker-compose.yml

# 2. Limit Docker CPUs
# Docker Desktop → Resources → CPUs: 6 (leave 2 for macOS)

# 3. Check for runaway containers
docker stats
# Look for containers using >200% CPU

# 4. Rebuild with native architecture
docker-compose build --no-cache
```

### "port already in use" (AirPlay)

**Cause**: macOS AirPlay Receiver uses port 5000 (conflicts with some services).

**Solution**:
```bash
# Disable AirPlay Receiver
# System Settings → General → AirDrop & Handoff → AirPlay Receiver: Off

# Or change service port in docker-compose.yml
services:
  some-service:
    ports:
      - "5001:5000"  # Use 5001 instead of 5000
```

### VirtioFS not working

**Symptoms**: File sharing very slow (~50 MB/s).

**Solution**:
```bash
# 1. Enable VirtioFS in Docker Desktop
# Settings → General → "VirtioFS" ✅

# 2. Enable Virtualization Framework
# Settings → General → "Use the new Virtualization framework" ✅

# 3. Restart Docker Desktop completely
# Menu Bar → Docker → Quit Docker Desktop
# Re-open Docker Desktop

# 4. Verify VirtioFS active
docker run --rm -v $(pwd):/test alpine sh -c "dd if=/dev/zero of=/test/file bs=1M count=100 && rm /test/file"
# ~800 MB/s = VirtioFS ✅
# ~200 MB/s = gRPC-FUSE ❌
```

---

## Quick Reference

```bash
# === Check Architecture ===
uname -m
# arm64 (Apple Silicon M1/M2/M3)

docker version --format '{{.Server.Arch}}'
# arm64 (Docker running on ARM)

# === Build Strategies ===
# Native ARM (fast, dev only)
docker build -t backend .

# AMD64 via Rosetta (slower, prod-parity)
docker build --platform linux/amd64 -t backend .

# Multi-platform (CI/CD)
docker buildx build --platform linux/amd64,linux/arm64 -t backend --push .

# === Enable Rosetta 2 ===
# Docker Desktop → Settings → Features in Development
# ✅ Use Rosetta for x86/amd64 emulation on Apple Silicon

# === Performance Optimization ===
# 1. Use native ARM images (no --platform flag)
# 2. Enable VirtioFS (Settings → General)
# 3. Use BuildKit cache mounts
# 4. Limit memory (12-16 GB for Docker)
# 5. Limit CPUs (6-8 for Docker, leave 2 for macOS)

# === Troubleshooting ===
docker system prune -a  # Clean up everything
docker buildx prune -a  # Clean build cache
# Restart Docker Desktop
```

**Development recommendation**: Use native ARM64 images for 3-5x faster builds. Force AMD64 only for final pre-deployment testing.

---

## Related Documentation

- [Podman Compatibility](podman-compatibility.md)
- [WSL2 Optimization](wsl2-optimization.md)
- [Platform Compatibility Matrix](../reference/platform-compatibility.md)
- [Docker Performance Tuning](../operations/performance-tuning.md)
