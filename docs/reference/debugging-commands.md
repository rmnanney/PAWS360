# Debugging Commands Reference

This document provides a comprehensive reference for debugging PAWS360's HA infrastructure components.

## Quick Reference

| Component | Command | Purpose |
|-----------|---------|---------|
| etcd | `make inspect-etcd` | Check cluster health and member status |
| Patroni | `make inspect-patroni` | Check PostgreSQL replication and failover |
| Redis | `make inspect-redis` | Check Sentinel quorum and replication |
| All | `make inspect-cluster` | Full cluster inspection |
| Logs | `make aggregate-logs SERVICE=backend` | Filter and aggregate logs |

## etcd Commands

### Member Management

**List all etcd members**:
```bash
docker exec paws360-etcd1 etcdctl member list --write-out=table
```

Output:
```
+------------------+---------+-------+---------------------------+---------------------------+------------+
|        ID        | STATUS  | NAME  |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
+------------------+---------+-------+---------------------------+---------------------------+------------+
| 8e9e05c52164694d | started | etcd1 | http://etcd1:2380         | http://etcd1:2379         |      false |
| fd422379fda50e48 | started | etcd2 | http://etcd2:2380         | http://etcd2:2379         |      false |
| b6c480b22b92f0c1 | started | etcd3 | http://etcd3:2380         | http://etcd3:2379         |      false |
+------------------+---------+-------+---------------------------+---------------------------+------------+
```

**Check member health**:
```bash
docker exec paws360-etcd1 etcdctl endpoint health --cluster --write-out=table
```

Expected output (healthy):
```
+---------------------------+--------+-------------+-------+
|         ENDPOINT          | HEALTH |    TOOK     | ERROR |
+---------------------------+--------+-------------+-------+
| http://etcd1:2379         |   true | 2.123456ms  |       |
| http://etcd2:2379         |   true | 1.987654ms  |       |
| http://etcd3:2379         |   true | 2.456789ms  |       |
+---------------------------+--------+-------------+-------+
```

**Check endpoint status**:
```bash
docker exec paws360-etcd1 etcdctl endpoint status --cluster --write-out=table
```

Output shows:
- DB size
- Raft index
- Raft term
- Leader status

### Data Operations

**List all keys**:
```bash
docker exec paws360-etcd1 etcdctl get "" --prefix --keys-only
```

**Get specific key**:
```bash
docker exec paws360-etcd1 etcdctl get /service/postgres/config
```

**Watch key changes**:
```bash
docker exec paws360-etcd1 etcdctl watch /service/postgres/leader
```

### Troubleshooting

**Check etcd logs**:
```bash
docker logs paws360-etcd1 --tail 100 --follow
```

**Compact etcd database** (if DB size is large):
```bash
docker exec paws360-etcd1 etcdctl compact $(docker exec paws360-etcd1 etcdctl endpoint status --write-out="json" | jq -r '.[0].Status.header.revision')
docker exec paws360-etcd1 etcdctl defrag
```

## Patroni Commands

### Cluster Management

**List cluster status**:
```bash
docker exec paws360-patroni1 patronictl list
```

Output:
```
+ Cluster: postgres (7143824516165414968) ---+----+-----------+
| Member    | Host      | Role    | State   | TL | Lag in MB |
+-----------+-----------+---------+---------+----+-----------+
| patroni1  | patroni1  | Leader  | running |  1 |           |
| patroni2  | patroni2  | Replica | running |  1 |         0 |
| patroni3  | patroni3  | Replica | running |  1 |         0 |
+-----------+-----------+---------+---------+----+-----------+
```

**Check replication lag** (on each node):
```bash
for node in patroni1 patroni2 patroni3; do
  echo "=== $node ==="
  docker exec paws360-$node patronictl list -f json | jq -r ".[] | select(.Member == \"$node\") | \"Role: \(.Role), Lag: \(.\"Lag in MB\") MB\""
done
```

**Show timeline history**:
```bash
docker exec paws360-patroni1 patronictl history
```

Output shows:
- Timeline number
- LSN (Log Sequence Number)
- Reason for timeline change (e.g., failover)
- Timestamp

### Failover Operations

**Trigger manual failover**:
```bash
docker exec paws360-patroni1 patronictl failover
```

**Switch leader to specific node**:
```bash
docker exec paws360-patroni1 patronictl switchover --master patroni1 --candidate patroni2
```

**Reinitialize replica**:
```bash
docker exec paws360-patroni2 patronictl reinit postgres patroni2
```

### Configuration

**Show current configuration**:
```bash
docker exec paws360-patroni1 patronictl show-config
```

**Edit configuration** (stored in etcd):
```bash
docker exec paws360-patroni1 patronictl edit-config
```

### Troubleshooting

**Check Patroni logs**:
```bash
docker logs paws360-patroni1 --tail 100 --follow | grep -i error
```

**Check PostgreSQL logs**:
```bash
docker exec paws360-patroni1 tail -f /var/lib/postgresql/data/log/postgresql-*.log
```

**Check replication slots**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "SELECT * FROM pg_replication_slots;"
```

**Check streaming replication status**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

## Redis Sentinel Commands

### Cluster Management

**Get master info**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL masters
```

Output shows:
- Master name (mymaster)
- IP and port
- Number of replicas
- Number of sentinels
- Quorum setting

**Check quorum**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL ckquorum mymaster
```

Expected output:
```
OK 3 usable Sentinels. Quorum and failover authorization can be reached
```

**List replicas**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL replicas mymaster
```

**List all sentinels**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL sentinels mymaster
```

### Failover Operations

**Trigger manual failover**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL failover mymaster
```

**Reset sentinel** (clears old master info):
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL reset mymaster
```

### Monitoring

**Monitor sentinel events**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SUBSCRIBE +switch-master +sdown +odown
```

**Get sentinel info**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 INFO sentinel
```

**Check master connection**:
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
```

### Data Operations

**Connect to current master**:
```bash
# Get master address first
MASTER=$(docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster | head -n1)

# Connect to master
docker exec paws360-redis-master redis-cli -h $MASTER INFO replication
```

**Check key distribution**:
```bash
docker exec paws360-redis-master redis-cli DBSIZE
```

**Monitor commands in real-time**:
```bash
docker exec paws360-redis-master redis-cli MONITOR
```

### Troubleshooting

**Check Sentinel logs**:
```bash
docker logs paws360-redis-sentinel1 --tail 100 --follow
```

**Check Redis master logs**:
```bash
docker logs paws360-redis-master --tail 100 --follow
```

**Check replication lag**:
```bash
docker exec paws360-redis-master redis-cli INFO replication
```

Look for `master_repl_offset` vs `slave_repl_offset` values.

## Log Aggregation

### Basic Usage

**View logs from all services**:
```bash
make aggregate-logs
```

**View logs from specific service**:
```bash
make aggregate-logs SERVICE=backend
```

**Filter logs by pattern**:
```bash
./scripts/aggregate-logs.sh --filter "ERROR"
```

**Combine service and filter**:
```bash
./scripts/aggregate-logs.sh backend --filter "ERROR" --since 5m
```

### Advanced Filtering

**Multiple patterns** (using regex):
```bash
./scripts/aggregate-logs.sh --filter "ERROR|WARN|FATAL"
```

**Case-sensitive search**:
```bash
./scripts/aggregate-logs.sh --filter "ERROR" | grep -v "grep"
```

**Time-based filtering**:
```bash
# Last 10 minutes
./scripts/aggregate-logs.sh --since 10m

# Last hour
./scripts/aggregate-logs.sh --since 1h

# Specific timestamp
./scripts/aggregate-logs.sh --since "2024-01-15T10:00:00"
```

**Tail latest logs**:
```bash
./scripts/aggregate-logs.sh --tail 50
```

**Follow logs in real-time**:
```bash
./scripts/aggregate-logs.sh --follow
# or
./scripts/aggregate-logs.sh -f
```

### Service-Specific Examples

**Backend application errors**:
```bash
./scripts/aggregate-logs.sh backend --filter "Exception|Error" --since 30m
```

**Database connection issues**:
```bash
./scripts/aggregate-logs.sh patroni1 --filter "connection|timeout" --tail 100
```

**Redis cache misses**:
```bash
./scripts/aggregate-logs.sh redis-master --filter "MISS" --since 1h
```

**etcd cluster state changes**:
```bash
./scripts/aggregate-logs.sh etcd1 --filter "leader|election" --follow
```

## Common Debugging Scenarios

### Scenario 1: Database Connection Failures

```bash
# 1. Check Patroni cluster status
make inspect-patroni

# 2. Check replication lag
docker exec paws360-patroni1 patronictl list

# 3. Check PostgreSQL logs
docker logs paws360-patroni1 --tail 100 | grep -i error

# 4. Verify application can connect
docker exec paws360-backend psql -h patroni1 -U postgres -d paws360_dev -c "SELECT 1;"
```

### Scenario 2: Cache Performance Issues

```bash
# 1. Check Redis cluster status
make inspect-redis

# 2. Check memory usage
docker exec paws360-redis-master redis-cli INFO memory

# 3. Check hit rate
docker exec paws360-redis-master redis-cli INFO stats | grep hit

# 4. Check slowlog
docker exec paws360-redis-master redis-cli SLOWLOG GET 10
```

### Scenario 3: etcd Split-Brain

```bash
# 1. Check cluster health
make inspect-etcd

# 2. Verify member list is consistent
docker exec paws360-etcd1 etcdctl member list
docker exec paws360-etcd2 etcdctl member list
docker exec paws360-etcd3 etcdctl member list

# 3. Check endpoint status for leader
docker exec paws360-etcd1 etcdctl endpoint status --cluster --write-out=table

# 4. If split-brain detected, restart affected node
docker restart paws360-etcd2
```

### Scenario 4: Replication Lag Troubleshooting

```bash
# 1. Check current lag
make inspect-patroni

# 2. Check PostgreSQL replication status
docker exec paws360-patroni1 psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# 3. Check for long-running queries
docker exec paws360-patroni1 psql -U postgres -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC;"

# 4. Check disk I/O
docker stats paws360-patroni1 paws360-patroni2 paws360-patroni3
```

## Performance Profiling

### Database Query Performance

**Enable query logging**:
```bash
docker exec paws360-patroni1 psql -U postgres -c "ALTER SYSTEM SET log_min_duration_statement = 100;"
docker exec paws360-patroni1 psql -U postgres -c "SELECT pg_reload_conf();"
```

**View slow queries**:
```bash
docker exec paws360-patroni1 tail -f /var/lib/postgresql/data/log/postgresql-*.log | grep "duration:"
```

**Check query plan**:
```bash
docker exec paws360-patroni1 psql -U postgres -d paws360_dev -c "EXPLAIN ANALYZE SELECT * FROM students LIMIT 10;"
```

### Redis Performance

**Check command stats**:
```bash
docker exec paws360-redis-master redis-cli INFO commandstats
```

**Monitor latency**:
```bash
docker exec paws360-redis-master redis-cli --latency
```

**Check client list**:
```bash
docker exec paws360-redis-master redis-cli CLIENT LIST
```

## See Also

- [Observability Architecture](../architecture/observability.md)
- [Debugging Guide](../guides/debugging.md)
- [etcd Documentation](https://etcd.io/docs/)
- [Patroni Documentation](https://patroni.readthedocs.io/)
- [Redis Sentinel Documentation](https://redis.io/topics/sentinel)
