# Port Mappings Reference

Complete reference for all exposed ports in the PAWS360 local development environment.

## Quick Reference

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 3000 | Frontend | HTTP | Next.js web application |
| 8080 | Backend | HTTP | Spring Boot API |
| 5432 | Patroni 1 | TCP | PostgreSQL (Primary) |
| 5433 | Patroni 2 | TCP | PostgreSQL (Replica) |
| 5434 | Patroni 3 | TCP | PostgreSQL (Replica) |
| 5000 | HAProxy | TCP | PostgreSQL (Load Balanced) |
| 6379 | Redis | TCP | Cache/Sessions |
| 2379 | etcd 1 | HTTP | Consensus (Client) |
| 2380 | etcd 1 | HTTP | Consensus (Peer) |
| 8008 | Patroni 1 | HTTP | Patroni REST API |

---

## Detailed Port Reference

### Application Layer

#### Frontend (Next.js)

| Port | Container Port | Protocol | Description |
|------|----------------|----------|-------------|
| **3000** | 3000 | HTTP | Web application interface |

**Access URL:** http://localhost:3000

**Hot Reload:** Enabled in development mode

**Related Services:** Backend API (8080)

---

#### Backend (Spring Boot)

| Port | Container Port | Protocol | Description |
|------|----------------|----------|-------------|
| **8080** | 8080 | HTTP | REST API endpoints |
| 5005 | 5005 | TCP | Remote debugging (optional) |

**Access URLs:**
- API Base: http://localhost:8080
- Health: http://localhost:8080/actuator/health
- Info: http://localhost:8080/actuator/info
- Metrics: http://localhost:8080/actuator/prometheus

**Debug Port:** Enable with `DEBUG=1 make dev-up`

---

### Database Layer

#### PostgreSQL (Patroni Cluster)

| Port | Service | Container Port | Role | Description |
|------|---------|----------------|------|-------------|
| **5432** | patroni1 | 5432 | Primary | Main database (writes) |
| **5433** | patroni2 | 5432 | Replica | Read replica |
| **5434** | patroni3 | 5432 | Replica | Read replica |

**Connection Strings:**
```bash
# Primary (read-write)
psql postgresql://paws360:paws360_dev@localhost:5432/paws360

# Replica 1 (read-only)
psql postgresql://paws360:paws360_dev@localhost:5433/paws360

# Replica 2 (read-only)
psql postgresql://paws360:paws360_dev@localhost:5434/paws360
```

**Notes:**
- Primary may change during failover
- Use HAProxy (5000) for automatic routing

---

#### HAProxy (Load Balancer)

| Port | Container Port | Protocol | Description |
|------|----------------|----------|-------------|
| **5000** | 5000 | TCP | PostgreSQL (auto-routing to primary) |
| **5001** | 5001 | TCP | PostgreSQL (read replicas) |
| **7000** | 7000 | HTTP | HAProxy statistics dashboard |

**Connection String (Recommended):**
```bash
# Auto-routes to current primary
psql postgresql://paws360:paws360_dev@localhost:5000/paws360
```

**Stats Dashboard:** http://localhost:7000/stats

---

#### Patroni REST API

| Port | Service | Container Port | Description |
|------|---------|----------------|-------------|
| **8008** | patroni1 | 8008 | Patroni API (node 1) |
| **8009** | patroni2 | 8008 | Patroni API (node 2) |
| **8010** | patroni3 | 8008 | Patroni API (node 3) |

**API Endpoints:**
```bash
# Cluster status
curl http://localhost:8008/cluster

# Node status
curl http://localhost:8008/

# Switchover
curl -X POST http://localhost:8008/switchover -d '{"leader":"patroni2"}'
```

---

### Coordination Layer (etcd)

| Port | Service | Container Port | Protocol | Description |
|------|---------|----------------|----------|-------------|
| **2379** | etcd1 | 2379 | HTTP | Client API |
| **2380** | etcd1 | 2380 | HTTP | Peer communication |
| **2381** | etcd2 | 2379 | HTTP | Client API |
| **2382** | etcd2 | 2380 | HTTP | Peer communication |
| **2383** | etcd3 | 2379 | HTTP | Client API |
| **2384** | etcd3 | 2380 | HTTP | Peer communication |

**Client Endpoints:**
```bash
# Check cluster health
etcdctl --endpoints=localhost:2379,localhost:2381,localhost:2383 endpoint health

# List members
etcdctl --endpoints=localhost:2379 member list
```

---

### Caching Layer (Redis)

#### Redis Primary

| Port | Container Port | Protocol | Description |
|------|----------------|----------|-------------|
| **6379** | 6379 | TCP | Redis primary node |

**Connection:**
```bash
redis-cli -h localhost -p 6379
```

---

#### Redis Sentinels

| Port | Service | Container Port | Description |
|------|---------|----------------|-------------|
| **26379** | redis-sentinel1 | 26379 | Sentinel node 1 |
| **26380** | redis-sentinel2 | 26379 | Sentinel node 2 |
| **26381** | redis-sentinel3 | 26379 | Sentinel node 3 |

**Sentinel Commands:**
```bash
# Get master info
redis-cli -h localhost -p 26379 SENTINEL masters

# Get replicas
redis-cli -h localhost -p 26379 SENTINEL replicas mymaster
```

---

## Port Allocation Map

```
APPLICATION PORTS
─────────────────────────────────────────────────
3000    │ ████████████████████████████ Frontend (Next.js)
8080    │ ████████████████████████████ Backend (Spring Boot)
5005    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ Debug (optional)

DATABASE PORTS
─────────────────────────────────────────────────
5432    │ ████████████████████████████ PostgreSQL Primary
5433    │ ████████████████████████████ PostgreSQL Replica 1
5434    │ ████████████████████████████ PostgreSQL Replica 2
5000    │ ████████████████████████████ HAProxy (DB LB)
5001    │ ████████████████████████████ HAProxy (Read Replicas)

PATRONI API PORTS
─────────────────────────────────────────────────
8008    │ ████████████████████████████ Patroni 1 API
8009    │ ████████████████████████████ Patroni 2 API
8010    │ ████████████████████████████ Patroni 3 API

ETCD PORTS
─────────────────────────────────────────────────
2379    │ ████████████████████████████ etcd 1 Client
2380    │ ████████████████████████████ etcd 1 Peer
2381    │ ████████████████████████████ etcd 2 Client
2382    │ ████████████████████████████ etcd 2 Peer
2383    │ ████████████████████████████ etcd 3 Client
2384    │ ████████████████████████████ etcd 3 Peer

REDIS PORTS
─────────────────────────────────────────────────
6379    │ ████████████████████████████ Redis Primary
26379   │ ████████████████████████████ Sentinel 1
26380   │ ████████████████████████████ Sentinel 2
26381   │ ████████████████████████████ Sentinel 3

MONITORING PORTS (Optional)
─────────────────────────────────────────────────
7000    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ HAProxy Stats
9090    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ Prometheus
3001    │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ Grafana
```

---

## Lite Mode Ports

When running with `--lite` flag, only essential ports are exposed:

| Port | Service | Description |
|------|---------|-------------|
| 3000 | Frontend | Web application |
| 8080 | Backend | REST API |
| 5432 | PostgreSQL | Single database (no cluster) |
| 6379 | Redis | Cache (no sentinels) |

---

## Port Conflict Resolution

### Check for Port Conflicts

```bash
# Check all PAWS360 ports
for port in 3000 8080 5432 5433 5434 5000 5001 6379 26379 26380 26381 2379 2380 2381 2382 2383 2384 8008 8009 8010 7000; do
  if lsof -Pi :$port -sTCP:LISTEN -t &>/dev/null; then
    echo "Port $port is in use by: $(lsof -Pi :$port -sTCP:LISTEN)"
  fi
done
```

### Common Conflicts

| Port | Common Conflict | Resolution |
|------|-----------------|------------|
| 3000 | Another Node.js app | Stop other app or change `FRONTEND_PORT` |
| 5432 | Local PostgreSQL | Stop local PG: `sudo systemctl stop postgresql` |
| 6379 | Local Redis | Stop local Redis: `sudo systemctl stop redis` |
| 8080 | Tomcat, Jenkins | Stop other service or change `BACKEND_PORT` |

### Changing Ports

Create `.env` with custom ports:

```bash
# Application ports
FRONTEND_PORT=3001
BACKEND_PORT=8081

# Database ports
PG_PRIMARY_PORT=5435
PG_REPLICA1_PORT=5436
PG_REPLICA2_PORT=5437

# Redis ports
REDIS_PORT=6380
SENTINEL1_PORT=26382
SENTINEL2_PORT=26383
SENTINEL3_PORT=26384
```

---

## Firewall Configuration

### Linux (UFW)

```bash
# Allow all PAWS360 ports
sudo ufw allow 3000/tcp comment "PAWS360 Frontend"
sudo ufw allow 8080/tcp comment "PAWS360 Backend"
sudo ufw allow 5432:5434/tcp comment "PAWS360 PostgreSQL"
# ... etc
```

### macOS

Ports are automatically allowed for Docker Desktop.

### Windows (WSL2)

```powershell
# Forward ports from Windows to WSL2
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=<WSL_IP>
```

---

## External Access

To access PAWS360 from another machine on your network:

1. **Find your IP:**
   ```bash
   ip addr show  # Linux
   ipconfig      # Windows
   ```

2. **Configure firewall** (see above)

3. **Access via IP:**
   ```
   http://192.168.1.100:3000  # Frontend
   http://192.168.1.100:8080  # Backend API
   ```

---

## Port Security

### Production Considerations

| Port | Local Dev | Production |
|------|-----------|------------|
| 3000 | Exposed | Behind reverse proxy |
| 8080 | Exposed | Behind reverse proxy |
| 5432-5434 | Exposed | Internal only |
| 6379 | Exposed | Internal only |
| 2379-2384 | Exposed | Internal only |
| 8008-8010 | Exposed | Internal only |

### Never Expose in Production

- Database ports (5432-5434)
- etcd ports (2379-2384)
- Redis ports (6379, 26379-26381)
- Patroni API ports (8008-8010)
- Debug ports (5005)

---

## See Also

- [Docker Compose Reference](./docker-compose.md)
- [Environment Variables Reference](./environment-variables.md)
- [Network Architecture](../architecture/ha-stack.md)
- [Security Guide](../guides/security-checklist.md)
