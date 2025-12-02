# Container Runtime Hardening Guide

Comprehensive security hardening practices for PAWS360 container runtime configuration.

## Table of Contents

- [Overview](#overview)
- [Non-Root Users](#non-root-users)
- [Capability Drops](#capability-drops)
- [Resource Limits](#resource-limits)
- [Read-Only Filesystems](#read-only-filesystems)
- [Security Options](#security-options)
- [Network Hardening](#network-hardening)
- [Secrets Management](#secrets-management)
- [Image Security](#image-security)
- [Monitoring and Auditing](#monitoring-and-auditing)

## Overview

Runtime hardening reduces the attack surface and limits the impact of potential security breaches in containerized environments.

**Security Principles**:
- **Least Privilege**: Run with minimum required permissions
- **Defense in Depth**: Multiple layers of security controls
- **Immutability**: Prevent runtime modifications
- **Isolation**: Limit container access to host and other containers

## Non-Root Users

Running containers as non-root users prevents privilege escalation attacks.

### Dockerfile Implementation

```dockerfile
# Bad: Running as root (default)
FROM postgres:15
COPY app.jar /app.jar
CMD ["java", "-jar", "/app.jar"]

# Good: Create and use non-root user
FROM postgres:15

# Create non-root user with specific UID
RUN groupadd -r appuser --gid=1000 && \
    useradd -r -g appuser --uid=1000 --home-dir=/app --shell=/bin/bash appuser

# Set ownership of application files
COPY --chown=appuser:appuser app.jar /app/app.jar

# Switch to non-root user
USER appuser

WORKDIR /app
CMD ["java", "-jar", "app.jar"]
```

### Docker Compose Configuration

```yaml
services:
  backend:
    build: ./backend
    user: "1000:1000"  # UID:GID
    security_opt:
      - no-new-privileges:true  # Prevent privilege escalation
    
  patroni1:
    build: ./infrastructure/patroni
    user: postgres  # Use named user from image
    security_opt:
      - no-new-privileges:true
```

### Verification

```bash
# Check running user inside container
docker exec backend whoami
# Should output: appuser (not root)

# Check process UID
docker exec backend ps -eo user,pid,comm | head
# Should show non-root user
```

## Capability Drops

Linux capabilities divide root privileges into distinct units. Drop all except those explicitly needed.

### Drop All Capabilities

```yaml
# docker-compose.yml
services:
  backend:
    cap_drop:
      - ALL  # Drop all capabilities
    cap_add:
      - NET_BIND_SERVICE  # Only add what's needed (bind ports < 1024)
    
  redis:
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID
```

### Common Capabilities Reference

| Capability | Purpose | Risk if Not Dropped |
|------------|---------|---------------------|
| `CHOWN` | Change file ownership | Unauthorized file access |
| `DAC_OVERRIDE` | Bypass file permission checks | Read/modify any file |
| `SETUID/SETGID` | Change user/group ID | Privilege escalation |
| `NET_ADMIN` | Network administration | Network sniffing, spoofing |
| `SYS_ADMIN` | System administration | Mount filesystems, kernel access |
| `NET_BIND_SERVICE` | Bind ports < 1024 | Needed for HTTP/HTTPS (80/443) |

### Application-Specific Examples

```yaml
# PostgreSQL (Patroni)
patroni1:
  cap_drop:
    - ALL
  cap_add:
    - CHOWN      # PostgreSQL needs to manage file ownership
    - DAC_OVERRIDE  # Access data files
    - SETGID
    - SETUID
    - NET_BIND_SERVICE

# Redis
redis-master:
  cap_drop:
    - ALL
  cap_add:
    - SETGID
    - SETUID

# etcd (requires network binding)
etcd1:
  cap_drop:
    - ALL
  cap_add:
    - NET_BIND_SERVICE
    - CHOWN
    - SETGID
    - SETUID

# Application (minimal privileges)
backend:
  cap_drop:
    - ALL
  # No capabilities needed if running on port > 1024
```

## Resource Limits

Prevent resource exhaustion attacks and ensure fair resource allocation.

### Memory Limits

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G      # Hard limit
        reservations:
          memory: 1G      # Soft limit (guaranteed)
    
  patroni1:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G
    
  redis-master:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### CPU Limits

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2.0'     # Max 2 CPU cores
        reservations:
          cpus: '0.5'     # Guaranteed 0.5 cores
    
  patroni1:
    deploy:
      resources:
        limits:
          cpus: '4.0'
        reservations:
          cpus: '1.0'
```

### Process Limits (PIDs)

```yaml
services:
  backend:
    pids_limit: 200  # Max 200 processes
    
  patroni1:
    pids_limit: 500
```

### Ulimits (File Descriptors, etc.)

```yaml
services:
  backend:
    ulimits:
      nproc: 512      # Max number of processes
      nofile:
        soft: 1024    # Soft limit for open files
        hard: 2048    # Hard limit for open files
```

## Read-Only Filesystems

Mount root filesystem as read-only to prevent runtime modifications.

### Basic Implementation

```yaml
services:
  backend:
    read_only: true
    tmpfs:
      - /tmp          # Writable temporary storage
      - /var/tmp
    volumes:
      - app-logs:/app/logs:rw  # Writable volume for logs
```

### Application-Specific Configuration

```yaml
# PostgreSQL requires writable data directory
patroni1:
  read_only: true
  tmpfs:
    - /tmp
    - /var/tmp
    - /run
  volumes:
    - patroni1-data:/var/lib/postgresql/data:rw
    - ./infrastructure/patroni/patroni.yml:/etc/patroni/patroni.yml:ro

# Redis requires writable data directory
redis-master:
  read_only: true
  tmpfs:
    - /tmp
  volumes:
    - redis-data:/data:rw
    - ./infrastructure/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro

# Application with read-only root
backend:
  read_only: true
  tmpfs:
    - /tmp
    - /app/temp
  volumes:
    - backend-logs:/app/logs:rw
```

## Security Options

Additional security hardening via Docker security options.

### AppArmor

```yaml
services:
  backend:
    security_opt:
      - apparmor=docker-default  # Use Docker's default AppArmor profile
```

### Seccomp

```yaml
services:
  backend:
    security_opt:
      - seccomp=./security/seccomp-profile.json
```

**Example Seccomp Profile** (security/seccomp-profile.json):

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86", "SCMP_ARCH_X32"],
  "syscalls": [
    {
      "names": [
        "accept", "accept4", "access", "bind", "brk", "close", "connect",
        "dup", "dup2", "epoll_create", "epoll_ctl", "epoll_wait",
        "exit", "exit_group", "fcntl", "fstat", "futex", "getpid",
        "getsockname", "getsockopt", "listen", "mmap", "munmap",
        "open", "openat", "poll", "read", "readv", "recv", "recvfrom",
        "rt_sigaction", "rt_sigprocmask", "send", "sendto", "setsockopt",
        "shutdown", "socket", "stat", "write", "writev"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### No New Privileges

```yaml
services:
  backend:
    security_opt:
      - no-new-privileges:true  # Prevent privilege escalation via setuid
```

## Network Hardening

### Network Isolation

```yaml
services:
  backend:
    networks:
      - paws360-internal  # Isolated internal network
    # No published ports = not accessible from host
  
  frontend:
    networks:
      - paws360-internal
    ports:
      - "127.0.0.1:3000:3000"  # Bind only to localhost
  
  database:
    networks:
      - paws360-internal
    # No external access

networks:
  paws360-internal:
    driver: bridge
    internal: false  # Set to true for complete isolation (no internet)
```

### Disable Inter-Container Communication

```yaml
networks:
  paws360-internal:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"  # Disable ICC
```

### Port Binding Best Practices

```yaml
# Bad: Binds to all interfaces (0.0.0.0)
ports:
  - "5432:5432"

# Good: Binds only to localhost
ports:
  - "127.0.0.1:5432:5432"

# Best: No published ports (use docker exec or internal network)
# No ports section
```

## Secrets Management

Never store secrets in environment variables or Dockerfiles.

### Docker Secrets (Swarm Mode)

```yaml
services:
  backend:
    secrets:
      - db_password
      - jwt_secret
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      JWT_SECRET_FILE: /run/secrets/jwt_secret

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

### External Secrets (Vault, AWS Secrets Manager)

```bash
# Fetch secret at runtime from Vault
docker run \
  -e VAULT_ADDR=https://vault.example.com \
  -e VAULT_TOKEN=$(cat ~/.vault-token) \
  backend:latest
```

### Environment File Encryption

```bash
# Encrypt .env file with GPG
gpg --symmetric --cipher-algo AES256 .env

# Decrypt at runtime
gpg --decrypt .env.gpg > .env
docker-compose up -d
rm .env  # Remove plaintext
```

## Image Security

### Multi-Stage Builds

```dockerfile
# Stage 1: Build (includes build tools)
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# Stage 2: Runtime (minimal image)
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S appuser && adduser -S appuser -G appuser
USER appuser
WORKDIR /app
COPY --from=builder --chown=appuser:appuser /app/target/app.jar .
CMD ["java", "-jar", "app.jar"]
```

### Minimal Base Images

```dockerfile
# Bad: Large attack surface
FROM ubuntu:22.04

# Better: Smaller image
FROM debian:12-slim

# Best: Minimal distroless image
FROM gcr.io/distroless/java21-debian12:nonroot
COPY app.jar /app.jar
CMD ["app.jar"]
```

### Image Scanning

```bash
# Scan during build
docker build -t backend:latest .
trivy image --severity CRITICAL,HIGH backend:latest

# Fail build on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL backend:latest
```

## Monitoring and Auditing

### Enable Logging

```yaml
services:
  backend:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service,environment"
```

### Docker Bench Security

```bash
# Run Docker Bench for Security
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/lib/systemd:/usr/lib/systemd \
  -v /etc:/etc --label docker_bench_security \
  docker/docker-bench-security
```

### Audit Container Events

```bash
# Enable Docker audit logging
sudo auditctl -w /usr/bin/docker -k docker
sudo auditctl -w /var/lib/docker -k docker
sudo auditctl -w /etc/docker -k docker

# View audit logs
sudo ausearch -k docker
```

## Complete Hardened Example

```yaml
# docker-compose.hardened.yml
version: '3.9'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    image: paws360-backend:latest
    
    # User and privileges
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
      - apparmor=docker-default
    cap_drop:
      - ALL
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
    pids_limit: 200
    
    # Filesystem
    tmpfs:
      - /tmp
      - /app/temp
    volumes:
      - backend-logs:/app/logs:rw
      - ./config/application.yml:/app/config/application.yml:ro
    
    # Network
    networks:
      - paws360-internal
    ports:
      - "127.0.0.1:8080:8080"
    
    # Logging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s

networks:
  paws360-internal:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"

volumes:
  backend-logs:
```

## Verification Checklist

- [ ] All containers run as non-root users
- [ ] `no-new-privileges` security option set
- [ ] All unnecessary capabilities dropped
- [ ] Memory and CPU limits configured
- [ ] PID limits set to prevent fork bombs
- [ ] Read-only root filesystems where possible
- [ ] Tmpfs mounts for temporary data
- [ ] Network isolation configured
- [ ] Ports bound to localhost only (not 0.0.0.0)
- [ ] Secrets managed externally (not in env vars)
- [ ] Images scanned for vulnerabilities
- [ ] Minimal base images used
- [ ] Multi-stage builds implemented
- [ ] Logging configured with rotation
- [ ] Health checks defined
- [ ] Security profiles (AppArmor/Seccomp) applied

## Related Documentation

- [Image Signing with Cosign](cosign-quickstart.md)
- [Image Scanning with Trivy](../reference/image-scanning.md)
- [Security Best Practices](security-best-practices.md)
- [Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
