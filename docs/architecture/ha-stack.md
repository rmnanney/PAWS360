# High Availability Stack Architecture

Comprehensive documentation of the PAWS360 local development HA architecture, including design rationale, component interactions, and operational procedures.

## Executive Summary

The PAWS360 local development environment implements a production-grade high availability (HA) stack that mirrors real-world deployment scenarios. This enables developers to:

- **Test failure scenarios** without impacting production
- **Understand HA behaviors** before deployment
- **Debug replication issues** in a controlled environment
- **Validate application resilience** to infrastructure failures

### Architecture Highlights

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| PostgreSQL | 3-node Patroni cluster | Database HA with automatic failover |
| etcd | 3-node cluster | Distributed consensus for leader election |
| Redis | Primary + 3 Sentinels | Cache HA with automatic failover |
| HAProxy | Active load balancer | Connection routing and health checks |

**Target Metrics:**
- **Failover Time**: <60 seconds
- **Data Loss (RPO)**: 0 (synchronous replication)
- **Availability**: 99.9% (with quorum maintained)

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              Application Layer                              │
│  ┌─────────────────┐                      ┌─────────────────┐              │
│  │    Frontend     │◄────────────────────►│     Backend     │              │
│  │   (Next.js)     │       HTTP/REST      │  (Spring Boot)  │              │
│  │     :3000       │                      │      :8080      │              │
│  └─────────────────┘                      └────────┬────────┘              │
│                                                    │                        │
├────────────────────────────────────────────────────┼────────────────────────┤
│                         Data Access Layer          │                        │
│                                                    │                        │
│  ┌─────────────────┐                      ┌────────▼────────┐              │
│  │  Redis Cluster  │◄─────────────────────│    HikariCP     │              │
│  │  (Cache/Session)│      Cache Lookup    │  Connection Pool │              │
│  └────────┬────────┘                      └────────┬────────┘              │
│           │                                        │                        │
├───────────┼────────────────────────────────────────┼────────────────────────┤
│           │              HA Infrastructure         │                        │
│           │                                        │                        │
│  ┌────────▼────────┐                      ┌────────▼────────┐              │
│  │  Redis Sentinel │                      │     HAProxy     │              │
│  │    (Quorum)     │                      │  (Load Balancer)│              │
│  │  26379/80/81    │                      │      :5000      │              │
│  └────────┬────────┘                      └────────┬────────┘              │
│           │                                        │                        │
│  ┌────────▼────────┐              ┌────────────────┼────────────────┐      │
│  │  Redis Primary  │              │                │                │      │
│  │     :6379       │              │                │                │      │
│  └─────────────────┘     ┌────────▼────┐  ┌────────▼────┐  ┌────────▼────┐│
│                          │  Patroni 1  │  │  Patroni 2  │  │  Patroni 3  ││
│                          │  (Primary)  │  │  (Replica)  │  │  (Replica)  ││
│                          │    :5432    │  │    :5433    │  │    :5434    ││
│                          └──────┬──────┘  └──────┬──────┘  └──────┬──────┘│
│                                 │                │                │        │
├─────────────────────────────────┼────────────────┼────────────────┼────────┤
│                    Consensus Layer (etcd)        │                │        │
│                                 │                │                │        │
│                          ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐│
│                          │    etcd1    │  │    etcd2    │  │    etcd3    ││
│                          │    :2379    │  │    :2381    │  │    :2383    ││
│                          └─────────────┘  └─────────────┘  └─────────────┘│
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Deep Dives

### etcd Cluster

#### Why etcd?

etcd is a distributed key-value store that provides:
- **Strong consistency** via Raft consensus
- **High availability** with leader election
- **Watch mechanism** for state changes
- **Proven reliability** (used by Kubernetes)

#### Configuration

```yaml
# etcd cluster configuration
etcd1:
  image: quay.io/coreos/etcd:v3.5.9
  environment:
    ETCD_NAME: etcd1
    ETCD_INITIAL_CLUSTER: etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380
    ETCD_INITIAL_CLUSTER_TOKEN: paws360-etcd-cluster
    ETCD_INITIAL_CLUSTER_STATE: new
    ETCD_LISTEN_CLIENT_URLS: http://0.0.0.0:2379
    ETCD_ADVERTISE_CLIENT_URLS: http://etcd1:2379
    ETCD_LISTEN_PEER_URLS: http://0.0.0.0:2380
    ETCD_INITIAL_ADVERTISE_PEER_URLS: http://etcd1:2380
```

#### Consensus Mechanics

```
┌─────────────────────────────────────────────────────────────┐
│                    etcd Raft Consensus                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Write Request                                              │
│        │                                                     │
│        ▼                                                     │
│   ┌─────────┐    Append Entry    ┌─────────┐                │
│   │ Leader  │───────────────────►│Follower1│                │
│   │ (etcd1) │                    └────┬────┘                │
│   └────┬────┘    Append Entry    ┌────▼────┐                │
│        │    ────────────────────►│Follower2│                │
│        │                         └────┬────┘                │
│        │                              │                      │
│        │◄─────────────────────────────┤                      │
│        │         ACK (2/3)            │                      │
│        │                                                     │
│        ▼                                                     │
│   Commit & Apply                                             │
│   Return Success                                             │
│                                                              │
│   Quorum: 2 of 3 nodes must acknowledge                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### Health Monitoring

```bash
# Check cluster health
etcdctl --endpoints=localhost:2379 endpoint health

# Check member list
etcdctl --endpoints=localhost:2379 member list

# Watch Patroni keys
etcdctl --endpoints=localhost:2379 get --prefix /paws360/
```

---

### Patroni (PostgreSQL HA)

#### Why Patroni?

Patroni provides automated PostgreSQL HA through:
- **Automatic failover** when primary fails
- **Leader election** via distributed consensus (etcd)
- **Streaming replication** management
- **REST API** for cluster management
- **Switchover** support for maintenance

#### Cluster Topology

```
┌───────────────────────────────────────────────────────────────┐
│                    Patroni Cluster Architecture                │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│   ┌─────────────────────────────────────────────────────┐     │
│   │                 etcd (Leader Election)               │     │
│   │                                                      │     │
│   │   /paws360/leader = "patroni1"                      │     │
│   │   /paws360/members/patroni1 = {...}                 │     │
│   │   /paws360/members/patroni2 = {...}                 │     │
│   │   /paws360/members/patroni3 = {...}                 │     │
│   │                                                      │     │
│   └──────────────────────┬──────────────────────────────┘     │
│                          │                                     │
│      ┌───────────────────┼───────────────────┐                │
│      │                   │                   │                │
│      ▼                   ▼                   ▼                │
│  ┌────────┐         ┌────────┐         ┌────────┐            │
│  │Patroni1│         │Patroni2│         │Patroni3│            │
│  │PRIMARY │◄───────►│REPLICA │◄───────►│REPLICA │            │
│  │        │  Sync   │        │  Sync   │        │            │
│  │ :5432  │  Rep    │ :5433  │  Rep    │ :5434  │            │
│  └────────┘         └────────┘         └────────┘            │
│      │                   │                   │                │
│      │◄──────────────────┤                   │                │
│      │   WAL Streaming   │                   │                │
│      │◄──────────────────────────────────────┤                │
│      │                                                        │
│      ▼                                                        │
│  ┌────────────────────────────────────────────────────┐      │
│  │                   PostgreSQL Data                   │      │
│  │                                                     │      │
│  │   WAL Segments → Shipped to Replicas               │      │
│  │   Synchronous Commit (configurable)                 │      │
│  │   Hot Standby (read queries on replicas)           │      │
│  └────────────────────────────────────────────────────┘      │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```

#### Failover Process

```
┌──────────────────────────────────────────────────────────────────┐
│                    Automatic Failover Sequence                    │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   T+0s    Primary (patroni1) becomes unresponsive                │
│           │                                                       │
│           ▼                                                       │
│   T+10s   Other Patroni nodes detect missing heartbeat           │
│           patroni2 & patroni3 check etcd for leader key          │
│           │                                                       │
│           ▼                                                       │
│   T+15s   Leader key TTL expires in etcd                         │
│           Election process begins                                 │
│           │                                                       │
│           ▼                                                       │
│   T+20s   patroni2 checks: "Am I most up-to-date?"               │
│           - Compare WAL positions                                 │
│           - Check timeline                                        │
│           │                                                       │
│           ▼                                                       │
│   T+25s   Most up-to-date replica wins election                  │
│           patroni2 acquires leader lock in etcd                  │
│           │                                                       │
│           ▼                                                       │
│   T+30s   patroni2 promotes PostgreSQL to primary                │
│           - pg_ctl promote                                        │
│           - Update connection strings                             │
│           │                                                       │
│           ▼                                                       │
│   T+35s   patroni3 reconfigures to replicate from patroni2       │
│           │                                                       │
│           ▼                                                       │
│   T+40s   HAProxy health checks detect new primary               │
│           Traffic routed to patroni2                              │
│           │                                                       │
│           ▼                                                       │
│   T+45s   Application reconnects (connection pool refresh)       │
│           │                                                       │
│           ▼                                                       │
│   T+<60s  FAILOVER COMPLETE                                      │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

#### Patroni REST API

```bash
# Get cluster status
curl http://localhost:8008/cluster | jq

# Get node status
curl http://localhost:8008/ | jq

# Trigger switchover (planned failover)
curl -X POST http://localhost:8008/switchover \
  -H "Content-Type: application/json" \
  -d '{"leader": "patroni2"}'

# Reinitialize failed node
curl -X POST http://localhost:8008/reinitialize
```

---

### Redis Sentinel

#### Why Sentinel?

Redis Sentinel provides:
- **Automatic failover** when Redis primary fails
- **Monitoring** of Redis instances
- **Notification** of state changes
- **Configuration provider** for clients

#### Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    Redis Sentinel Architecture                  │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Application                                                   │
│       │                                                         │
│       │ Query: "Who is the master?"                            │
│       ▼                                                         │
│   ┌───────────────────────────────────────────────────────┐    │
│   │                  Sentinel Cluster                      │    │
│   │                                                        │    │
│   │  ┌──────────┐   ┌──────────┐   ┌──────────┐          │    │
│   │  │Sentinel 1│   │Sentinel 2│   │Sentinel 3│          │    │
│   │  │  :26379  │◄─►│  :26380  │◄─►│  :26381  │          │    │
│   │  └────┬─────┘   └────┬─────┘   └────┬─────┘          │    │
│   │       │              │              │                 │    │
│   │       └──────────────┼──────────────┘                 │    │
│   │                      │                                │    │
│   │            Quorum: 2 of 3                             │    │
│   │                      │                                │    │
│   └──────────────────────┼────────────────────────────────┘    │
│                          │                                      │
│                          │ Monitor & Failover                   │
│                          │                                      │
│                          ▼                                      │
│   ┌──────────────────────────────────────────────────────┐     │
│   │                    Redis Instances                    │     │
│   │                                                       │     │
│   │  ┌─────────────┐        ┌─────────────┐             │     │
│   │  │   Primary   │───────►│   Replica   │             │     │
│   │  │   (redis)   │  Async │             │             │     │
│   │  │    :6379    │  Rep   │             │             │     │
│   │  └─────────────┘        └─────────────┘             │     │
│   │                                                       │     │
│   └──────────────────────────────────────────────────────┘     │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

#### Sentinel Configuration

```conf
# sentinel.conf
sentinel monitor mymaster redis 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| `monitor` | mymaster redis 6379 2 | Watch Redis at port 6379, quorum 2 |
| `down-after-milliseconds` | 5000 | Mark down after 5s no response |
| `failover-timeout` | 60000 | Failover timeout 60s |
| `parallel-syncs` | 1 | Replicas to sync simultaneously |

#### Failover Process

```bash
# Check sentinel status
redis-cli -h localhost -p 26379 SENTINEL masters

# Check replicas
redis-cli -h localhost -p 26379 SENTINEL replicas mymaster

# Force failover (for testing)
redis-cli -h localhost -p 26379 SENTINEL failover mymaster
```

---

### HAProxy (Load Balancer)

#### Why HAProxy?

HAProxy provides:
- **Health-based routing** to database nodes
- **Connection pooling** and multiplexing
- **Automatic failover** detection
- **Statistics dashboard** for monitoring

#### Configuration

```haproxy
# haproxy.cfg

global
    maxconn 1000

defaults
    mode tcp
    timeout connect 10s
    timeout client 30s
    timeout server 30s

# PostgreSQL Primary (read-write)
frontend postgres_primary
    bind *:5000
    default_backend postgres_primary_backend

backend postgres_primary_backend
    option httpchk GET /primary
    http-check expect status 200
    default-server inter 3s fall 3 rise 2
    server patroni1 patroni1:5432 check port 8008
    server patroni2 patroni2:5432 check port 8009
    server patroni3 patroni3:5432 check port 8010

# PostgreSQL Replicas (read-only)
frontend postgres_replica
    bind *:5001
    default_backend postgres_replica_backend

backend postgres_replica_backend
    option httpchk GET /replica
    http-check expect status 200
    balance roundrobin
    default-server inter 3s fall 3 rise 2
    server patroni1 patroni1:5432 check port 8008
    server patroni2 patroni2:5432 check port 8009
    server patroni3 patroni3:5432 check port 8010

# Statistics Dashboard
frontend stats
    bind *:7000
    stats enable
    stats uri /stats
    stats auth admin:haproxy_dev
```

#### Routing Logic

```
┌──────────────────────────────────────────────────────────────┐
│                    HAProxy Routing Logic                      │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│   Incoming Connection                                         │
│         │                                                     │
│         ▼                                                     │
│   ┌─────────────┐                                            │
│   │ Port 5000?  │──Yes──► Primary Backend                    │
│   │ (Read-Write)│         │                                  │
│   └──────┬──────┘         │                                  │
│          │                ▼                                  │
│          │         ┌──────────────┐                          │
│          │         │ Health Check │                          │
│          │         │ GET /primary │                          │
│          │         └──────┬───────┘                          │
│          │                │                                  │
│          │                ▼                                  │
│          │         Only node returning                       │
│          │         200 OK gets traffic                       │
│          │                                                   │
│          ▼                                                   │
│   ┌─────────────┐                                            │
│   │ Port 5001?  │──Yes──► Replica Backend                    │
│   │ (Read-Only) │         │                                  │
│   └─────────────┘         │                                  │
│                           ▼                                  │
│                    ┌──────────────┐                          │
│                    │ Health Check │                          │
│                    │ GET /replica │                          │
│                    └──────┬───────┘                          │
│                           │                                  │
│                           ▼                                  │
│                    Round-robin among                         │
│                    healthy replicas                          │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Failure Scenarios

### Scenario 1: Primary Database Failure

**Trigger:** patroni1 container stops or crashes

**Expected Behavior:**
1. etcd detects missing heartbeat (~10s)
2. Leader key expires (~15s)
3. Remaining nodes elect new primary (~10s)
4. HAProxy routes to new primary (~5s)
5. **Total failover time: ~40-60s**

**Application Impact:**
- Brief connection errors during failover
- Transactions in-flight may need retry
- No data loss (synchronous replication)

**Recovery:**
```bash
# Restart failed node
docker compose start patroni1

# Node automatically rejoins as replica
make patroni-status
```

---

### Scenario 2: etcd Quorum Loss

**Trigger:** 2 of 3 etcd nodes fail

**Expected Behavior:**
1. etcd cluster loses quorum
2. Patroni cannot renew leader lock
3. **Cluster enters read-only mode**
4. No failover possible until quorum restored

**Mitigation:**
```bash
# Check etcd health
make etcd-health

# Restart failed etcd nodes
docker compose restart etcd2 etcd3

# Verify quorum restored
etcdctl endpoint health
```

---

### Scenario 3: Network Partition

**Trigger:** Primary isolated from etcd cluster

**Expected Behavior:**
1. Primary cannot renew leader key
2. Leader key expires in etcd
3. Replica promotes to primary
4. **Split-brain prevention:** Old primary demotes

**Why It's Safe:**
- Patroni requires etcd lock to accept writes
- Isolated primary demotes to replica
- STONITH (Shoot The Other Node In The Head) not required

---

### Scenario 4: Redis Primary Failure

**Trigger:** Redis primary crashes

**Expected Behavior:**
1. Sentinels detect down (~5s)
2. Quorum agrees on failure (~5s)
3. Best replica elected (~5s)
4. Clients reconnect to new primary (~5s)
5. **Total failover time: ~20s**

**Application Impact:**
- Cache misses during failover
- Session reconnection required
- No session data loss (if persistent)

---

## Testing HA Features

### Automated Failover Test

```bash
# Run the complete failover test suite
make test-failover
```

This test:
1. Records current cluster state
2. Kills the primary database
3. Monitors failover progress
4. Verifies new primary elected
5. Checks replica reconfiguration
6. Validates application connectivity
7. Restores original node

### Manual Switchover

```bash
# Planned switchover (zero downtime)
make patroni-switchover TARGET=patroni2

# Verify new primary
make patroni-status
```

### Chaos Testing

```bash
# Network partition simulation
make chaos-network-partition DURATION=60

# Kill random node
make chaos-kill-random

# Resource exhaustion
make chaos-cpu-stress SERVICE=patroni1
```

---

## Monitoring and Alerting

### Health Check Endpoints

| Service | Endpoint | Healthy Response |
|---------|----------|------------------|
| Backend | /actuator/health | 200 OK |
| Patroni | /primary or /replica | 200 OK |
| etcd | endpoint health | "is healthy" |
| Redis | PING | PONG |

### Key Metrics

```bash
# Patroni replication lag
curl http://localhost:8008/cluster | jq '.[].Lag'

# etcd cluster health
etcdctl endpoint status --write-out=table

# Redis memory usage
redis-cli info memory | grep used_memory_human
```

### Recommended Alerts

| Metric | Threshold | Severity |
|--------|-----------|----------|
| Replication lag | >1MB | Warning |
| Replication lag | >10MB | Critical |
| Failover count | >2/hour | Critical |
| etcd quorum loss | Any | Critical |
| Connection pool exhaustion | >80% | Warning |

---

## Configuration Tuning

### PostgreSQL Performance

```yaml
# patroni.yml
postgresql:
  parameters:
    max_connections: 100
    shared_buffers: 256MB
    effective_cache_size: 1GB
    maintenance_work_mem: 64MB
    checkpoint_completion_target: 0.9
    wal_buffers: 16MB
    default_statistics_target: 100
    random_page_cost: 1.1
    effective_io_concurrency: 200
```

### etcd Tuning

```yaml
environment:
  ETCD_HEARTBEAT_INTERVAL: 100  # ms
  ETCD_ELECTION_TIMEOUT: 1000   # ms
  ETCD_SNAPSHOT_COUNT: 10000
  ETCD_MAX_SNAPSHOTS: 5
```

### Redis Memory

```conf
maxmemory 512mb
maxmemory-policy allkeys-lru
```

---

## Best Practices

### 1. Always Test Failover

Before any deployment:
```bash
make test-failover
```

### 2. Monitor Replication Lag

Replication lag >10MB indicates potential data loss during failover.

### 3. Use Connection Pooling

Configure HikariCP with:
- `maximumPoolSize`: Match max_connections / nodes
- `connectionTimeout`: 30000ms
- `validationTimeout`: 5000ms

### 4. Implement Retry Logic

```java
@Retryable(
    value = {SQLException.class},
    maxAttempts = 3,
    backoff = @Backoff(delay = 1000)
)
public void performDatabaseOperation() {
    // Operation that may fail during failover
}
```

### 5. Use Read Replicas

Route read-heavy queries to port 5001 (replica pool):
```java
@Transactional(readOnly = true)
public List<User> findAllUsers() {
    // Routed to read replica
}
```

---

## Troubleshooting

### Patroni Won't Start

```bash
# Check etcd connectivity
docker compose exec patroni1 etcdctl --endpoints=http://etcd1:2379 endpoint health

# Check Patroni logs
docker compose logs patroni1 | tail -100
```

### Split-Brain Detection

```bash
# Should only see ONE primary
make patroni-status | grep -i leader

# If multiple primaries, force reconciliation
docker compose restart patroni1 patroni2 patroni3
```

### Slow Failover

Check these factors:
1. etcd heartbeat interval (default: 100ms)
2. Patroni TTL (default: 30s)
3. HAProxy health check interval (default: 3s)
4. Network latency between containers

---

## See Also

- [Patroni Documentation](https://patroni.readthedocs.io/)
- [etcd Operations Guide](https://etcd.io/docs/)
- [Redis Sentinel Documentation](https://redis.io/docs/management/sentinel/)
- [HAProxy Configuration Manual](https://www.haproxy.com/documentation/)
- [Performance Tuning Guide](./performance.md)
- [Testing Strategy](./testing-strategy.md)
