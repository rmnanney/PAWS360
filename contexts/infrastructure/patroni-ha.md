# Patroni HA - GPT Context

Context file for AI assistants working with the PAWS360 Patroni PostgreSQL high-availability cluster.

## Purpose

Patroni manages a 3-node PostgreSQL cluster with:
- **Automatic failover** when primary fails (<60s)
- **Leader election** via etcd consensus
- **Streaming replication** to replicas
- **REST API** for management
- **Zero data loss** (synchronous replication)

## Cluster Configuration

```yaml
# 3-node Patroni cluster
patroni1:
  PostgreSQL port: 5432
  Patroni API port: 8008
  Role: Primary (leader election)

patroni2:
  PostgreSQL port: 5433
  Patroni API port: 8009
  Role: Replica

patroni3:
  PostgreSQL port: 5434
  Patroni API port: 8010
  Role: Replica
```

## Key Environment Variables

```bash
PATRONI_NAME=patroni1
PATRONI_SCOPE=paws360
PATRONI_POSTGRESQL_DATA_DIR=/var/lib/postgresql/data
PATRONI_POSTGRESQL_CONNECT_ADDRESS=patroni1:5432
PATRONI_RESTAPI_CONNECT_ADDRESS=patroni1:8008
PATRONI_ETCD3_HOSTS=etcd1:2379,etcd2:2379,etcd3:2379
PATRONI_REPLICATION_USERNAME=replicator
PATRONI_SUPERUSER_USERNAME=postgres
```

## Common Operations

### Check Cluster Status
```bash
# Via Makefile
make patroni-status

# Direct command
docker exec paws360-patroni1 patronictl list

# JSON output
docker exec paws360-patroni1 patronictl list -f json
```

### Planned Switchover
```bash
# Switch primary to patroni2
make patroni-switchover TARGET=patroni2

# Or directly
docker exec paws360-patroni1 patronictl switchover --leader patroni2 --force
```

### Restart Cluster
```bash
docker exec paws360-patroni1 patronictl restart paws360 --force
```

### Reinitialize Failed Node
```bash
docker exec paws360-patroni1 patronictl reinit paws360 patroni3
```

## REST API Endpoints

```bash
# Cluster info
curl http://localhost:8008/cluster | jq

# Node info
curl http://localhost:8008/ | jq

# Health (returns 200 for primary)
curl http://localhost:8008/primary

# Health (returns 200 for replica)
curl http://localhost:8008/replica

# Trigger switchover
curl -X POST http://localhost:8008/switchover \
  -H "Content-Type: application/json" \
  -d '{"leader": "patroni2"}'
```

## Failover Process

```
T+0s    Primary becomes unresponsive
T+10s   Other nodes detect missing heartbeat
T+15s   Leader key expires in etcd
T+20s   Election: most up-to-date replica wins
T+25s   Winner acquires leader lock
T+30s   PostgreSQL promoted to primary
T+35s   Other replicas reconfigure
T+40s   HAProxy detects new primary
T+45s   Application reconnects
T+<60s  FAILOVER COMPLETE
```

## Replication

### Check Replication Lag
```bash
# Via patronictl
docker exec paws360-patroni1 patronictl list

# SQL query on primary
docker exec paws360-patroni1 psql -U postgres -c \
  "SELECT client_addr, state, sent_lsn, replay_lsn, 
   pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes 
   FROM pg_stat_replication;"
```

### Replication Modes
- **Asynchronous** (default): Better performance, potential data loss
- **Synchronous**: Zero data loss, higher latency

## Database Connection

### Direct to Primary
```bash
psql postgresql://paws360:paws360_dev@localhost:5432/paws360
```

### Via HAProxy (Recommended)
```bash
# Auto-routes to current primary
psql postgresql://paws360:paws360_dev@localhost:5000/paws360

# Read replicas
psql postgresql://paws360:paws360_dev@localhost:5001/paws360
```

### From Application
```yaml
spring:
  datasource:
    url: jdbc:postgresql://haproxy:5000/paws360
    username: paws360
    password: paws360_dev
```

## Failure Scenarios

### Primary Failure
1. etcd detects missing heartbeat
2. Leader key expires
3. Replicas elect new primary
4. HAProxy routes to new primary
5. Application reconnects

### Replica Failure
- No impact on writes
- Read capacity reduced
- Automatic recovery when restarted

### etcd Quorum Loss
- Cluster becomes read-only
- No failover possible
- Must restore etcd quorum

### Split Brain Prevention
- Patroni requires etcd lock to accept writes
- Isolated node demotes to replica
- Fencing via etcd TTL

## Configuration (patroni.yml)

```yaml
scope: paws360
namespace: /paws360/
name: patroni1

restapi:
  listen: 0.0.0.0:8008
  connect_address: patroni1:8008

etcd3:
  hosts:
    - etcd1:2379
    - etcd2:2379
    - etcd3:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576  # 1MB
    postgresql:
      use_pg_rewind: true
      parameters:
        max_connections: 100
        shared_buffers: 256MB

postgresql:
  listen: 0.0.0.0:5432
  connect_address: patroni1:5432
  data_dir: /var/lib/postgresql/data
  authentication:
    superuser:
      username: postgres
      password: ${PATRONI_SUPERUSER_PASSWORD}
    replication:
      username: replicator
      password: ${PATRONI_REPLICATION_PASSWORD}
```

## Troubleshooting

### No Leader Elected
```bash
# Check etcd connectivity
docker exec paws360-patroni1 etcdctl --endpoints=http://etcd1:2379 endpoint health

# Check Patroni logs
docker compose logs patroni1 | tail -100
```

### Replication Lag
```bash
# Check lag
docker exec paws360-patroni1 patronictl list | grep Lag

# Force sync
docker exec paws360-patroni1 patronictl reinit paws360 patroni2
```

### Timeline Divergence
```bash
# Use pg_rewind (enabled by default)
docker exec paws360-patroni1 patronictl reinit paws360 patroni3 --force
```

## Important Notes

- Patroni depends on etcd being healthy
- Leader key TTL is 30 seconds
- Maximum lag for failover: 1MB
- Use HAProxy for automatic primary routing
- pg_rewind enabled for fast replica resync
- Database volumes persist across restarts

## Related Files

- Docker config: `docker-compose.yml` (patroni1/2/3 services)
- Patroni config: `config/patroni/patroni.yml`
- HAProxy config: `config/haproxy/haproxy.cfg`
- Documentation: `docs/architecture/ha-stack.md`
- Failover tests: `scripts/test-failover.sh`
