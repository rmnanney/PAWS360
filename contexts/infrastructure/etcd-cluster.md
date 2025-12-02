# etcd Cluster - GPT Context

Context file for AI assistants working with the PAWS360 etcd distributed consensus cluster.

## Purpose

etcd provides distributed consensus for the Patroni PostgreSQL cluster, enabling:
- **Leader election** for database primary selection
- **Configuration storage** for cluster state
- **Distributed locking** for failover coordination
- **Watch mechanism** for state change notifications

## Cluster Configuration

```yaml
# 3-node etcd cluster
etcd1:
  port: 2379 (client), 2380 (peer)
  hostname: etcd1

etcd2:
  port: 2381 (client), 2382 (peer)
  hostname: etcd2

etcd3:
  port: 2383 (client), 2384 (peer)
  hostname: etcd3
```

## Key Environment Variables

```bash
ETCD_NAME=etcd1
ETCD_INITIAL_CLUSTER=etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380
ETCD_INITIAL_CLUSTER_TOKEN=paws360-etcd-cluster
ETCD_INITIAL_CLUSTER_STATE=new
ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
ETCD_ADVERTISE_CLIENT_URLS=http://etcd1:2379
ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
ETCD_INITIAL_ADVERTISE_PEER_URLS=http://etcd1:2380
```

## Common Operations

### Check Cluster Health
```bash
# Via Makefile
make etcd-health

# Direct command
etcdctl --endpoints=localhost:2379 endpoint health

# All endpoints
etcdctl --endpoints=localhost:2379,localhost:2381,localhost:2383 endpoint health
```

### List Members
```bash
etcdctl --endpoints=localhost:2379 member list
```

### Check Leader
```bash
etcdctl --endpoints=localhost:2379 endpoint status --write-out=table
```

### View Patroni Keys
```bash
# List all keys under /paws360/
etcdctl --endpoints=localhost:2379 get --prefix /paws360/

# Watch for changes
etcdctl --endpoints=localhost:2379 watch --prefix /paws360/
```

## Patroni Key Structure

```
/paws360/
├── leader              # Current leader name
├── config              # Cluster configuration
├── initialize          # Cluster initialization key
├── members/
│   ├── patroni1        # Node 1 info
│   ├── patroni2        # Node 2 info
│   └── patroni3        # Node 3 info
└── optime/
    └── leader          # Leader timeline
```

## Raft Consensus

etcd uses Raft for consensus:
- **Quorum**: 2 of 3 nodes must agree
- **Leader**: One node accepts writes
- **Followers**: Replicate from leader
- **Election**: Automatic on leader failure

### Write Flow
1. Client sends write to leader
2. Leader appends to log
3. Leader replicates to followers
4. Majority acknowledges
5. Leader commits and responds

## Failure Scenarios

### Single Node Failure
- Cluster continues with 2/3 quorum
- Automatic leader election if leader fails
- No data loss

### Two Node Failure (Quorum Loss)
- Cluster becomes read-only
- No writes accepted
- Patroni cluster enters maintenance mode
- **Recovery**: Restart failed nodes

### Network Partition
- Minority partition becomes read-only
- Majority partition continues
- Automatic reconciliation on reconnect

## Health Checks

```yaml
healthcheck:
  test: ["CMD", "etcdctl", "endpoint", "health"]
  interval: 10s
  timeout: 5s
  retries: 5
```

## Troubleshooting

### Cluster Unhealthy
```bash
# Check all member status
etcdctl endpoint status --cluster -w table

# Check logs
docker compose logs etcd1 etcd2 etcd3
```

### Data Corruption
```bash
# Backup current data
make etcd-backup

# Remove member and rejoin
etcdctl member remove <member_id>
etcdctl member add etcd1 --peer-urls=http://etcd1:2380
```

### High Latency
```bash
# Check disk I/O
etcdctl check perf

# Monitor metrics
curl http://localhost:2379/metrics | grep etcd_disk
```

## Important Notes

- etcd must start before Patroni
- Quorum required for any writes
- Data stored in named volumes
- Default heartbeat: 100ms
- Default election timeout: 1000ms
- Snapshot interval: 10000 transactions

## Related Files

- Docker config: `docker-compose.yml` (etcd1, etcd2, etcd3 services)
- Documentation: `docs/architecture/ha-stack.md`
- Health checks: `scripts/etcd-health.sh`
