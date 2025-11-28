# HA Failover Testing Procedures

**Feature**: 001-local-dev-parity  
**Last Updated**: 2025-11-27

This guide covers procedures for testing High Availability (HA) failover scenarios in your local development environment.

## Overview

The local environment supports testing realistic HA scenarios:
- **Patroni/PostgreSQL failover**: Leader election, zero data loss
- **Redis Sentinel failover**: Master promotion, client reconnection
- **etcd node failure**: Quorum maintenance, recovery

## Prerequisites

```bash
# Start full HA environment
make -f Makefile.dev dev-up

# Verify all healthy
make -f Makefile.dev health
```

---

## Test 1: Patroni Leader Failover

**Objective**: Verify automatic leader election when current leader fails

**Expected Outcome**:
- Failover completes in ≤60 seconds
- New leader elected automatically
- Zero data loss (all committed transactions preserved)
- Applications reconnect automatically

### Automated Test

```bash
make -f Makefile.dev test-failover
```

### Manual Test Procedure

**Step 1**: Identify current leader
```bash
curl http://localhost:8008/patroni | jq -r '.role'  # Should return "master" or "replica"
curl http://localhost:8009/patroni | jq -r '.role'
curl http://localhost:8010/patroni | jq -r '.role'

# Or use patronictl
docker exec paws360-patroni1 patronictl -c /config/patroni.yml list
```

**Step 2**: Record baseline
```bash
# Count current transactions
docker exec paws360-patroni1 psql -U postgres -c "SELECT txid_current();"

# Note replication lag on replicas
curl http://localhost:8009/patroni | jq '.replication_state.lag'
```

**Step 3**: Simulate leader failure
```bash
# Pause the leader container (e.g., patroni1)
docker pause paws360-patroni1

# Start timer
START=$(date +%s)
```

**Step 4**: Monitor failover
```bash
# Watch leader election (runs continuously until new leader found)
watch -n 1 "curl -sf http://localhost:8009/patroni 2>/dev/null | jq -r '.role'"

# Or check all nodes
curl http://localhost:8008/patroni 2>/dev/null | jq -r '.role'  # Should error (paused)
curl http://localhost:8009/patroni | jq -r '.role'              # Should show "master" after election
curl http://localhost:8010/patroni | jq -r '.role'              # Should show "replica"
```

**Step 5**: Verify failover completion
```bash
# Calculate failover time
END=$(date +%s)
ELAPSED=$((END - START))
echo "Failover completed in ${ELAPSED} seconds"

# Verify new leader
NEW_LEADER=$(curl -sf http://localhost:8009/patroni 2>/dev/null | jq -r '.role')
if [ "$NEW_LEADER" = "master" ]; then
    echo "✅ New leader elected: patroni2"
else
    NEW_LEADER=$(curl -sf http://localhost:8010/patroni 2>/dev/null | jq -r '.role')
    if [ "$NEW_LEADER" = "master" ]; then
        echo "✅ New leader elected: patroni3"
    fi
fi
```

**Step 6**: Verify zero data loss
```bash
# Check transaction ID on new leader
docker exec paws360-patroni2 psql -U postgres -c "SELECT txid_current();"

# Should be ≥ the value from Step 2
```

**Step 7**: Resume failed node
```bash
# Unpause original leader
docker unpause paws360-patroni1

# Watch it rejoin as replica
curl http://localhost:8008/patroni | jq -r '.role'  # Should eventually show "replica"
```

**Step 8**: Validate cluster health
```bash
make -f Makefile.dev health

# All 3 nodes should be healthy
# 1 leader + 2 replicas
```

### Validation Criteria

- ✅ Failover time: ≤60 seconds
- ✅ New leader elected automatically
- ✅ Zero data loss (transaction ID preserved)
- ✅ Failed node rejoins as replica
- ✅ Replication resumes on all replicas

---

## Test 2: Redis Sentinel Failover

**Objective**: Verify automatic Redis master promotion when master fails

**Expected Outcome**:
- Failover completes in ≤30 seconds
- New master promoted from replicas
- Sentinels update their configuration
- Clients reconnect to new master

### Manual Test Procedure

**Step 1**: Identify current master
```bash
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name paws360-redis-master
```

**Step 2**: Simulate master failure
```bash
# Stop Redis master
docker stop paws360-redis-master

# Start timer
START=$(date +%s)
```

**Step 3**: Monitor Sentinel promotion
```bash
# Watch Sentinel status
watch -n 1 "docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name paws360-redis-master"

# Check Sentinel logs
docker-compose logs -f redis-sentinel1 | grep "+promote"
```

**Step 4**: Verify new master
```bash
# Get new master address
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name paws360-redis-master

# Should point to redis-replica1 or redis-replica2
```

**Step 5**: Calculate failover time
```bash
END=$(date +%s)
ELAPSED=$((END - START))
echo "Redis failover completed in ${ELAPSED} seconds"
```

**Step 6**: Restart old master
```bash
docker start paws360-redis-master

# It should rejoin as replica
docker exec paws360-redis-master redis-cli -a ${REDIS_PASSWORD} INFO replication | grep role
# Should show: role:slave
```

### Validation Criteria

- ✅ Failover time: ≤30 seconds
- ✅ New master promoted automatically
- ✅ All sentinels agree on new master
- ✅ Old master rejoins as replica
- ✅ Replication restored

---

## Test 3: etcd Node Failure and Recovery

**Objective**: Verify etcd cluster maintains quorum with 1 node failure

**Expected Outcome**:
- Cluster remains operational with 2/3 nodes (quorum maintained)
- Failed node rejoins automatically
- Patroni/DCS integration unaffected

### Manual Test Procedure

**Step 1**: Verify initial cluster health
```bash
curl http://localhost:2379/health | jq

# Check member list
curl http://localhost:2379/v2/members | jq
```

**Step 2**: Stop one etcd node
```bash
docker stop paws360-etcd3
```

**Step 3**: Verify cluster still operational
```bash
# Quorum should still be achieved (2/3)
curl http://localhost:2379/health | jq
curl http://localhost:2379/v2/members | jq

# Patroni should still work
curl http://localhost:8008/patroni | jq
```

**Step 4**: Write data to etcd (via Patroni)
```bash
# Patroni writes configuration to etcd
docker exec paws360-patroni1 patronictl -c /config/patroni.yml list
```

**Step 5**: Restart failed node
```bash
docker start paws360-etcd3

# Wait for it to rejoin
sleep 10

# Verify it's back in cluster
curl http://localhost:2379/v2/members | jq
```

### Validation Criteria

- ✅ Cluster operational with 2/3 nodes
- ✅ Patroni continues functioning
- ✅ Failed node rejoins automatically
- ✅ Data consistency maintained

---

## Test 4: Multiple Concurrent Failures

**Objective**: Test resilience under stress (worst-case scenario)

⚠️ **WARNING**: This test will temporarily make the environment unhealthy

### Procedure

**Step 1**: Start with healthy environment
```bash
make -f Makefile.dev health
```

**Step 2**: Simulate cascading failures
```bash
# Pause Patroni leader
docker pause paws360-patroni1

# Stop one etcd node
docker stop paws360-etcd2

# Stop Redis master
docker stop paws360-redis-master
```

**Step 3**: Monitor recovery
```bash
# Watch Patroni failover
curl http://localhost:8009/patroni | jq -r '.role'

# Watch Redis failover
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL get-master-addr-by-name paws360-redis-master

# Check etcd quorum (should still work with 2/3)
curl http://localhost:2379/health | jq
```

**Step 4**: Restore failed services
```bash
docker unpause paws360-patroni1
docker start paws360-etcd2
docker start paws360-redis-master

# Wait for stabilization
sleep 30
```

**Step 5**: Verify full recovery
```bash
make -f Makefile.dev health

# Should show all services healthy
```

### Validation Criteria

- ✅ Services recover automatically
- ✅ Final state: all healthy
- ✅ No manual intervention required
- ✅ Data consistency maintained

---

## Performance Metrics

| Test Scenario | Target | Measured | Status |
|---------------|--------|----------|--------|
| Patroni failover | ≤60s | ___ | ❌/✅ |
| Redis failover | ≤30s | ___ | ❌/✅ |
| etcd recovery | ≤20s | ___ | ❌/✅ |
| Zero data loss | 100% | ___ | ❌/✅ |

## Troubleshooting Failures

### Patroni Failover Takes >60s

**Check**:
- Replication lag before failure (`lag_in_mb` in Patroni API)
- etcd cluster health
- Network latency between nodes

**Fix**:
- Ensure etcd cluster is healthy first
- Reduce `loop_wait` in patroni.yml for faster detection
- Check `maximum_lag_on_failover` setting

### Redis Failover Doesn't Occur

**Check**:
- Sentinel quorum (need 2/3 agreement)
- `down-after-milliseconds` setting (might be too high)
- Network connectivity between sentinels and replicas

**Fix**:
```bash
# Verify Sentinel configuration
docker exec paws360-redis-sentinel1 redis-cli -p 26379 SENTINEL master paws360-redis-master

# Check quorum setting
echo $REDIS_QUORUM  # Should be 2
```

### Data Loss Detected

**This is a critical failure** - investigate:
1. Check Patroni synchronous replication settings
2. Verify replication lag was within acceptable bounds
3. Review transaction logs for timing
4. Check if any transactions were in-flight during failover

---

## Next Steps

After validating HA failover:
- [CI/CD Testing](../ci-cd/local-ci-execution.md) - Test deployment pipelines
- [Development Workflow](../guides/development-workflow.md) - Hot-reload and debugging
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
