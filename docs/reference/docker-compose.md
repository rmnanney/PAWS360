# Docker Compose Service Reference

Complete reference for all Docker Compose services in the PAWS360 local development environment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PAWS360 Service Architecture                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐     ┌──────────────┐                                      │
│  │   Frontend   │     │   Backend    │         Application Layer            │
│  │  (Next.js)   │────▶│ (Spring Boot)│                                      │
│  │   :3000      │     │   :8080      │                                      │
│  └──────────────┘     └──────┬───────┘                                      │
│                              │                                               │
├──────────────────────────────┼───────────────────────────────────────────────┤
│                              │                                               │
│  ┌───────────────────────────▼───────────────────────────────────────────┐  │
│  │                     HAProxy Load Balancer                              │  │
│  │                          :5000                                         │  │
│  └─────────────┬─────────────┬─────────────┬─────────────────────────────┘  │
│                │             │             │                                 │
│  ┌─────────────▼──┐ ┌────────▼───┐ ┌───────▼────┐                           │
│  │   Patroni 1    │ │  Patroni 2 │ │  Patroni 3 │    Database Layer        │
│  │   (Primary)    │ │  (Replica) │ │  (Replica) │                           │
│  │   :5432        │ │   :5433    │ │   :5434    │                           │
│  └───────┬────────┘ └─────┬──────┘ └──────┬─────┘                           │
│          │                │               │                                  │
│  ┌───────▼────────────────▼───────────────▼─────┐                           │
│  │              etcd Cluster (Consensus)         │    Coordination Layer    │
│  │     etcd1:2379    etcd2:2380    etcd3:2381   │                           │
│  └───────────────────────────────────────────────┘                           │
│                                                                              │
│  ┌───────────────────────────────────────────────┐                           │
│  │              Redis Sentinel Cluster           │    Caching Layer         │
│  │  Primary:6379  Sentinel1  Sentinel2  Sentinel3│                           │
│  └───────────────────────────────────────────────┘                           │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Service Definitions

### Application Services

#### `frontend`

Next.js web application serving the user interface.

```yaml
frontend:
  build:
    context: .
    dockerfile: infrastructure/docker/Dockerfile.frontend
  ports:
    - "3000:3000"
  environment:
    - NODE_ENV=development
    - NEXT_PUBLIC_API_URL=http://localhost:8080
  volumes:
    - ./app:/app/app
    - ./public:/app/public
  depends_on:
    - backend
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000"]
    interval: 30s
    timeout: 10s
    retries: 3
```

| Property | Value |
|----------|-------|
| **Image** | node:20-alpine (build) |
| **Port** | 3000 |
| **Dependencies** | backend |
| **Health Check** | HTTP GET / |
| **Volumes** | Source code (hot reload) |
| **Restart Policy** | unless-stopped |

**Environment Variables:**
- `NODE_ENV`: development
- `NEXT_PUBLIC_API_URL`: Backend API URL

---

#### `backend`

Spring Boot application providing REST API.

```yaml
backend:
  build:
    context: .
    dockerfile: infrastructure/docker/Dockerfile.backend
  ports:
    - "8080:8080"
  environment:
    - SPRING_PROFILES_ACTIVE=dev
    - DATABASE_URL=jdbc:postgresql://patroni1:5432/paws360
    - REDIS_HOST=redis
  volumes:
    - ./src:/app/src
    - ./target:/app/target
  depends_on:
    patroni1:
      condition: service_healthy
    redis:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
    interval: 30s
    timeout: 10s
    retries: 5
```

| Property | Value |
|----------|-------|
| **Image** | eclipse-temurin:21-jdk-alpine (build) |
| **Port** | 8080 |
| **Dependencies** | patroni1 (healthy), redis (healthy) |
| **Health Check** | HTTP GET /actuator/health |
| **Volumes** | Source code, build artifacts |
| **Restart Policy** | unless-stopped |

**Environment Variables:**
- `SPRING_PROFILES_ACTIVE`: dev
- `DATABASE_URL`: JDBC connection string
- `REDIS_HOST`: Redis hostname
- `JWT_SECRET`: Authentication secret

---

### Database Services

#### `patroni1` (Primary)

PostgreSQL primary node managed by Patroni.

```yaml
patroni1:
  image: patroni/patroni:latest
  hostname: patroni1
  ports:
    - "5432:5432"
    - "8008:8008"
  environment:
    - PATRONI_NAME=patroni1
    - PATRONI_SCOPE=paws360
    - PATRONI_POSTGRESQL_DATA_DIR=/var/lib/postgresql/data
    - PATRONI_POSTGRESQL_CONNECT_ADDRESS=patroni1:5432
    - PATRONI_RESTAPI_CONNECT_ADDRESS=patroni1:8008
    - PATRONI_ETCD3_HOSTS=etcd1:2379,etcd2:2379,etcd3:2379
  volumes:
    - patroni1_data:/var/lib/postgresql/data
  depends_on:
    etcd1:
      condition: service_healthy
    etcd2:
      condition: service_healthy
    etcd3:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "pg_isready", "-h", "localhost"]
    interval: 10s
    timeout: 5s
    retries: 5
```

| Property | Value |
|----------|-------|
| **Image** | patroni/patroni:latest |
| **PostgreSQL Port** | 5432 |
| **Patroni API Port** | 8008 |
| **Dependencies** | etcd cluster (healthy) |
| **Health Check** | pg_isready |
| **Volume** | patroni1_data |
| **Role** | Primary (leader election) |

---

#### `patroni2` (Replica)

PostgreSQL replica node managed by Patroni.

```yaml
patroni2:
  image: patroni/patroni:latest
  hostname: patroni2
  ports:
    - "5433:5432"
    - "8009:8008"
  environment:
    - PATRONI_NAME=patroni2
    - PATRONI_SCOPE=paws360
    # ... similar to patroni1
  volumes:
    - patroni2_data:/var/lib/postgresql/data
  depends_on:
    - patroni1
```

| Property | Value |
|----------|-------|
| **PostgreSQL Port** | 5433 (mapped from 5432) |
| **Patroni API Port** | 8009 |
| **Role** | Replica (streaming replication) |

---

#### `patroni3` (Replica)

PostgreSQL replica node managed by Patroni.

```yaml
patroni3:
  image: patroni/patroni:latest
  hostname: patroni3
  ports:
    - "5434:5432"
    - "8010:8008"
  # ... similar configuration
  volumes:
    - patroni3_data:/var/lib/postgresql/data
```

| Property | Value |
|----------|-------|
| **PostgreSQL Port** | 5434 (mapped from 5432) |
| **Patroni API Port** | 8010 |
| **Role** | Replica (streaming replication) |

---

### Coordination Services (etcd)

#### `etcd1`

etcd cluster node 1 (distributed consensus).

```yaml
etcd1:
  image: quay.io/coreos/etcd:v3.5.9
  hostname: etcd1
  ports:
    - "2379:2379"
    - "2380:2380"
  environment:
    - ETCD_NAME=etcd1
    - ETCD_INITIAL_CLUSTER=etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380
    - ETCD_INITIAL_CLUSTER_TOKEN=paws360-etcd-cluster
    - ETCD_INITIAL_CLUSTER_STATE=new
    - ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
    - ETCD_ADVERTISE_CLIENT_URLS=http://etcd1:2379
    - ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
    - ETCD_INITIAL_ADVERTISE_PEER_URLS=http://etcd1:2380
  volumes:
    - etcd1_data:/etcd-data
  healthcheck:
    test: ["CMD", "etcdctl", "endpoint", "health"]
    interval: 10s
    timeout: 5s
    retries: 5
```

| Property | Value |
|----------|-------|
| **Image** | quay.io/coreos/etcd:v3.5.9 |
| **Client Port** | 2379 |
| **Peer Port** | 2380 |
| **Health Check** | etcdctl endpoint health |
| **Volume** | etcd1_data |

---

#### `etcd2` / `etcd3`

Additional etcd cluster nodes (similar configuration).

| Service | Client Port | Peer Port |
|---------|-------------|-----------|
| etcd2 | 2381 | 2382 |
| etcd3 | 2383 | 2384 |

---

### Caching Services (Redis)

#### `redis`

Redis primary node for caching and session storage.

```yaml
redis:
  image: redis:7-alpine
  hostname: redis
  ports:
    - "6379:6379"
  command: redis-server --appendonly yes --replica-announce-ip redis
  volumes:
    - redis_data:/data
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
```

| Property | Value |
|----------|-------|
| **Image** | redis:7-alpine |
| **Port** | 6379 |
| **Persistence** | AOF (append-only file) |
| **Health Check** | redis-cli ping |
| **Volume** | redis_data |

---

#### `redis-sentinel1/2/3`

Redis Sentinel nodes for automatic failover.

```yaml
redis-sentinel1:
  image: redis:7-alpine
  hostname: redis-sentinel1
  ports:
    - "26379:26379"
  command: redis-sentinel /etc/redis/sentinel.conf
  volumes:
    - ./config/redis/sentinel.conf:/etc/redis/sentinel.conf
  depends_on:
    - redis
```

| Property | Value |
|----------|-------|
| **Image** | redis:7-alpine |
| **Port** | 26379, 26380, 26381 |
| **Config** | sentinel.conf |
| **Quorum** | 2 (of 3 sentinels) |

---

### Load Balancing

#### `haproxy`

HAProxy load balancer for database connections.

```yaml
haproxy:
  image: haproxy:2.8-alpine
  hostname: haproxy
  ports:
    - "5000:5000"
    - "7000:7000"
  volumes:
    - ./config/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
  depends_on:
    - patroni1
    - patroni2
    - patroni3
```

| Property | Value |
|----------|-------|
| **Image** | haproxy:2.8-alpine |
| **Primary Port** | 5000 (write) |
| **Replica Port** | 5001 (read) |
| **Stats Port** | 7000 |
| **Config** | haproxy.cfg |

---

## Volume Definitions

```yaml
volumes:
  patroni1_data:
    driver: local
    name: paws360_patroni1_data
  patroni2_data:
    driver: local
    name: paws360_patroni2_data
  patroni3_data:
    driver: local
    name: paws360_patroni3_data
  etcd1_data:
    driver: local
    name: paws360_etcd1_data
  etcd2_data:
    driver: local
    name: paws360_etcd2_data
  etcd3_data:
    driver: local
    name: paws360_etcd3_data
  redis_data:
    driver: local
    name: paws360_redis_data
```

### Volume Details

| Volume | Service | Purpose | Persist? |
|--------|---------|---------|----------|
| patroni1_data | patroni1 | PostgreSQL data | Yes |
| patroni2_data | patroni2 | PostgreSQL data | Yes |
| patroni3_data | patroni3 | PostgreSQL data | Yes |
| etcd1_data | etcd1 | etcd consensus | Yes |
| etcd2_data | etcd2 | etcd consensus | Yes |
| etcd3_data | etcd3 | etcd consensus | Yes |
| redis_data | redis | Cache & sessions | Yes |

### Volume Backup

```bash
# Backup all volumes
make dev-snapshot

# Backup specific volume
docker run --rm -v paws360_patroni1_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/patroni1_backup.tar.gz -C /data .
```

---

## Network Configuration

```yaml
networks:
  paws360-network:
    driver: bridge
    name: paws360-network
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Network Details

| Property | Value |
|----------|-------|
| **Driver** | bridge |
| **Subnet** | 172.20.0.0/16 |
| **DNS** | Docker embedded DNS |

### Service Discovery

All services can communicate via hostname:
- `frontend` → `backend` via `http://backend:8080`
- `backend` → `patroni1` via `jdbc:postgresql://patroni1:5432`
- `patroni1-3` → `etcd1-3` via `http://etcd1:2379`

---

## Profiles

Docker Compose profiles allow selective service startup.

### Full Profile (Default)

```bash
docker compose --profile full up
```

Starts: All services including HA cluster

### Lite Profile

```bash
docker compose --profile lite up
```

Starts: Single PostgreSQL, Redis, backend, frontend (no HA)

### Infrastructure Only

```bash
docker compose --profile infra up
```

Starts: etcd, Redis, Patroni (no application services)

---

## Resource Limits

### Recommended Limits (Production-like)

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M

  patroni1:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Development Defaults

By default, no limits are set to simplify development. Enable limits for performance testing:

```bash
COMPOSE_FILE=docker-compose.yml:docker-compose.limits.yml docker compose up
```

---

## Health Check Summary

| Service | Check | Interval | Timeout | Retries |
|---------|-------|----------|---------|---------|
| frontend | HTTP GET / | 30s | 10s | 3 |
| backend | HTTP GET /actuator/health | 30s | 10s | 5 |
| patroni1-3 | pg_isready | 10s | 5s | 5 |
| etcd1-3 | etcdctl endpoint health | 10s | 5s | 5 |
| redis | redis-cli ping | 10s | 5s | 5 |

---

## Dependency Graph

```
                    frontend
                       │
                       ▼
                    backend
                    /     \
                   /       \
                  ▼         ▼
             patroni1     redis
             /   |   \      │
            ▼    ▼    ▼     ▼
         etcd1 etcd2 etcd3  redis-sentinel1/2/3
```

### Startup Order

1. **Layer 1**: etcd1, etcd2, etcd3 (parallel)
2. **Layer 2**: patroni1, patroni2, patroni3, redis (after etcd healthy)
3. **Layer 3**: redis-sentinel1/2/3 (after redis healthy)
4. **Layer 4**: backend (after patroni1 + redis healthy)
5. **Layer 5**: frontend (after backend started)

---

## Environment Variables Reference

See [Environment Variables Reference](./environment-variables.md) for complete list.

### Quick Reference

```yaml
# Database
POSTGRES_USER=paws360
POSTGRES_PASSWORD=paws360_dev
POSTGRES_DB=paws360

# Application
SPRING_PROFILES_ACTIVE=dev
NODE_ENV=development

# Cluster
PATRONI_SCOPE=paws360
ETCD_INITIAL_CLUSTER_TOKEN=paws360-etcd-cluster
```

---

## Extending the Configuration

### Adding a New Service

```yaml
services:
  my-service:
    image: my-image:latest
    ports:
      - "9000:9000"
    environment:
      - CONFIG_VAR=value
    networks:
      - paws360-network
    depends_on:
      backend:
        condition: service_healthy
```

### Overriding for Development

Create `docker-compose.override.yml`:

```yaml
services:
  backend:
    environment:
      - DEBUG=true
    ports:
      - "5005:5005"  # Debug port
```

---

## See Also

- [Port Mappings Reference](./ports.md)
- [Environment Variables Reference](./environment-variables.md)
- [Makefile Targets Reference](./makefile-targets.md)
- [HA Architecture Documentation](../architecture/ha-stack.md)
