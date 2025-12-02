# Prometheus Metrics Endpoints Reference

Comprehensive reference for all Prometheus metrics endpoints exposed by PAWS360 infrastructure components.

## Table of Contents

- [Overview](#overview)
- [PostgreSQL Metrics](#postgresql-metrics)
- [Redis Metrics](#redis-metrics)
- [etcd Metrics](#etcd-metrics)
- [Patroni Metrics](#patroni-metrics)
- [Application Metrics](#application-metrics)
- [Querying Metrics](#querying-metrics)
- [Alerting Rules](#alerting-rules)

## Overview

Each infrastructure component exposes Prometheus-compatible metrics endpoints that provide real-time operational visibility.

**Metrics Collection Stack**:
- Prometheus scrapes metrics every 15 seconds
- Metrics retained for 15 days by default
- Grafana visualizes metrics via dashboards
- Alert Manager can trigger alerts based on metric thresholds

**Access Metrics**:
```bash
# Start observability stack
make observability-up

# Access Prometheus UI
open http://localhost:9090

# Access Grafana dashboards
open http://localhost:3001  # admin/admin
```

## PostgreSQL Metrics

PostgreSQL metrics are collected via the **postgres_exporter** (port 9187).

### Exporter Configuration

```yaml
# infrastructure/compose/postgres-exporter.yml
services:
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:v0.15.0
    ports:
      - "9187:9187"
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:password@patroni1:5432/postgres?sslmode=disable"
    networks:
      - paws360-internal
```

### Key Metrics

#### Connection Statistics

```promql
# Active connections
pg_stat_database_numbackends{datname="paws360"}

# Connection pool utilization
pg_stat_database_numbackends{datname="paws360"} / pg_settings_max_connections * 100

# Idle connections
pg_stat_activity_count{state="idle"}

# Waiting connections (locks)
pg_stat_activity_count{state="idle in transaction"}
```

#### Query Performance

```promql
# Total queries executed
rate(pg_stat_database_xact_commit{datname="paws360"}[5m])

# Query execution time (95th percentile)
histogram_quantile(0.95, rate(pg_stat_statements_mean_time_seconds_bucket[5m]))

# Slow queries (> 100ms)
pg_stat_statements_mean_time_seconds > 0.1

# Temporary files created (indicates insufficient work_mem)
rate(pg_stat_database_temp_files{datname="paws360"}[5m])
```

#### Replication Metrics

```promql
# Replication lag in bytes
pg_replication_lag_bytes

# Replication lag in seconds
pg_replication_lag_seconds

# Number of replication slots
pg_replication_slots_active

# WAL files pending
pg_stat_archiver_failed_count
```

#### Cache Hit Ratio

```promql
# Buffer cache hit ratio (should be > 99%)
(sum(pg_stat_database_blks_hit{datname="paws360"}) / 
 sum(pg_stat_database_blks_hit{datname="paws360"} + pg_stat_database_blks_read{datname="paws360"})) * 100
```

#### Disk I/O

```promql
# Blocks read from disk
rate(pg_stat_database_blks_read{datname="paws360"}[5m])

# Blocks hit in cache
rate(pg_stat_database_blks_hit{datname="paws360"}[5m])

# Transaction commit rate
rate(pg_stat_database_xact_commit{datname="paws360"}[5m])

# Transaction rollback rate
rate(pg_stat_database_xact_rollback{datname="paws360"}[5m])
```

### Example Dashboard Queries

```promql
# Top 10 slowest queries
topk(10, avg_over_time(pg_stat_statements_mean_time_seconds[5m]))

# Database size growth rate
rate(pg_database_size_bytes{datname="paws360"}[1h])

# Deadlocks per second
rate(pg_stat_database_deadlocks{datname="paws360"}[5m])
```

## Redis Metrics

Redis metrics are collected via the **redis_exporter** (port 9121).

### Exporter Configuration

```yaml
# infrastructure/compose/redis-exporter.yml
services:
  redis-exporter:
    image: oliver006/redis_exporter:v1.55.0
    ports:
      - "9121:9121"
    environment:
      REDIS_ADDR: "redis://redis-master:6379"
      REDIS_PASSWORD: "${REDIS_PASSWORD}"
    networks:
      - paws360-internal
```

### Key Metrics

#### Memory Usage

```promql
# Total memory used by Redis
redis_memory_used_bytes

# Memory usage as percentage of max
(redis_memory_used_bytes / redis_memory_max_bytes) * 100

# Peak memory usage
redis_memory_max_bytes

# Fragmentation ratio (should be < 1.5)
redis_mem_fragmentation_ratio
```

#### Command Statistics

```promql
# Commands processed per second
rate(redis_commands_processed_total[5m])

# GET commands per second
rate(redis_commands_total{cmd="get"}[5m])

# SET commands per second
rate(redis_commands_total{cmd="set"}[5m])

# Slowlog entries
redis_slowlog_length
```

#### Cache Performance

```promql
# Cache hit rate (should be > 80%)
(redis_keyspace_hits_total / (redis_keyspace_hits_total + redis_keyspace_misses_total)) * 100

# Evicted keys per second
rate(redis_evicted_keys_total[5m])

# Expired keys per second
rate(redis_expired_keys_total[5m])

# Keyspace size
redis_db_keys{db="db0"}
```

#### Replication Metrics

```promql
# Replication lag (master perspective)
redis_connected_slaves

# Replication offset lag
redis_master_repl_offset - redis_slave_repl_offset

# Replication backlog size
redis_replication_backlog_bytes
```

#### Connection Statistics

```promql
# Connected clients
redis_connected_clients

# Blocked clients (waiting for BLPOP, etc.)
redis_blocked_clients

# Rejected connections (maxclients reached)
rate(redis_rejected_connections_total[5m])
```

### Example Dashboard Queries

```promql
# Memory usage trend
redis_memory_used_bytes / 1024 / 1024  # Convert to MB

# Top 10 most expensive commands
topk(10, sum by (cmd) (rate(redis_commands_duration_seconds_total[5m])))

# Network throughput
rate(redis_net_input_bytes_total[5m]) + rate(redis_net_output_bytes_total[5m])
```

## etcd Metrics

etcd exposes metrics natively at `/metrics` endpoint (port 2379).

### Endpoint Access

```bash
# Query etcd metrics directly
curl http://localhost:2379/metrics
```

### Key Metrics

#### Cluster Health

```promql
# etcd server health (1 = healthy, 0 = unhealthy)
etcd_server_health_success

# Number of cluster members
etcd_cluster_members

# Leader changes (should be stable)
rate(etcd_server_leader_changes_seen_total[5m])

# Has leader (1 = yes, 0 = no)
etcd_server_has_leader
```

#### Raft Consensus

```promql
# Raft proposals committed per second
rate(etcd_server_proposals_committed_total[5m])

# Raft proposals failed
rate(etcd_server_proposals_failed_total[5m])

# Raft proposals pending
etcd_server_proposals_pending
```

#### Request Performance

```promql
# 99th percentile request latency
histogram_quantile(0.99, rate(etcd_http_request_duration_seconds_bucket[5m]))

# Put operations per second
rate(etcd_mvcc_put_total[5m])

# Delete operations per second
rate(etcd_mvcc_delete_total[5m])

# Range queries per second
rate(etcd_mvcc_range_total[5m])
```

#### Database Size

```promql
# etcd database size in bytes
etcd_mvcc_db_total_size_in_bytes

# etcd database size in use
etcd_mvcc_db_total_size_in_use_in_bytes

# Database fragmentation
(etcd_mvcc_db_total_size_in_bytes - etcd_mvcc_db_total_size_in_use_in_bytes) / etcd_mvcc_db_total_size_in_bytes * 100
```

### Example Dashboard Queries

```promql
# etcd disk fsync duration (should be < 10ms)
histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[5m])) * 1000

# Network round-trip time between peers
histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[5m])) * 1000
```

## Patroni Metrics

Patroni exposes metrics via its REST API (port 8008).

### Endpoint Access

```bash
# Query Patroni metrics
curl http://localhost:8008/metrics
```

### Key Metrics

#### Cluster State

```promql
# Patroni is running (1 = yes, 0 = no)
patroni_postgres_running

# Patroni is leader (1 = yes, 0 = no)
patroni_master

# Patroni timeline
patroni_postgres_timeline

# Patroni cluster status
patroni_cluster_unlocked  # 0 = locked (maintenance), 1 = unlocked
```

#### Replication Lag

```promql
# Replication lag in bytes
patroni_replication_lag_bytes

# Replication lag in seconds
patroni_replication_lag_seconds

# Replication slot lag
patroni_replication_slot_lag_bytes
```

#### Failover Events

```promql
# Failover count
increase(patroni_failover_total[24h])

# Switchover count
increase(patroni_switchover_total[24h])

# Time since last failover
time() - patroni_last_failover_timestamp
```

## Application Metrics

### Spring Boot Backend (Micrometer)

Endpoint: `http://localhost:8080/actuator/metrics`

```promql
# JVM memory usage
jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"} * 100

# Garbage collection time
rate(jvm_gc_pause_seconds_sum[5m])

# HTTP request rate
rate(http_server_requests_seconds_count{uri!~"/actuator.*"}[5m])

# HTTP request duration (99th percentile)
histogram_quantile(0.99, rate(http_server_requests_seconds_bucket[5m]))

# Active HTTP connections
tomcat_threads_current_threads{name="http-nio-8080"}

# Database connection pool active connections
hikaricp_connections_active{pool="HikariPool-1"}

# Database connection pool usage
hikaricp_connections_active{pool="HikariPool-1"} / hikaricp_connections_max{pool="HikariPool-1"} * 100
```

### Next.js Frontend (Custom Metrics)

Endpoint: `http://localhost:3000/api/metrics`

```promql
# Page load time (99th percentile)
histogram_quantile(0.99, rate(page_load_duration_seconds_bucket[5m]))

# API call success rate
rate(api_requests_total{status="success"}[5m]) / rate(api_requests_total[5m]) * 100

# API call errors
rate(api_requests_total{status="error"}[5m])
```

## Querying Metrics

### PromQL Examples

```promql
# Average CPU usage across all containers
avg(rate(container_cpu_usage_seconds_total[5m])) by (container_name)

# Network throughput by service
sum(rate(container_network_receive_bytes_total[5m])) by (service)

# Disk I/O by service
sum(rate(container_fs_reads_bytes_total[5m]) + rate(container_fs_writes_bytes_total[5m])) by (service)

# Service uptime
(time() - container_start_time_seconds) / 3600  # Convert to hours
```

### Aggregation Functions

```promql
# Sum across all instances
sum(redis_connected_clients)

# Average across replicas
avg(pg_stat_database_numbackends{datname="paws360"}) by (instance)

# Maximum value
max(redis_memory_used_bytes)

# Minimum value
min(etcd_disk_wal_fsync_duration_seconds)

# Count number of instances
count(up{job="postgres"} == 1)
```

## Alerting Rules

### Example Alert Definitions

```yaml
# prometheus-alerts.yml
groups:
  - name: paws360-infrastructure
    interval: 30s
    rules:
      # PostgreSQL alerts
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL instance {{ $labels.instance }} is down"
      
      - alert: PostgreSQLReplicationLag
        expr: pg_replication_lag_seconds > 60
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Replication lag on {{ $labels.instance }} is {{ $value }}s"
      
      - alert: PostgreSQLConnectionPoolExhaustion
        expr: pg_stat_database_numbackends / pg_settings_max_connections > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Connection pool 80% utilized on {{ $labels.instance }}"
      
      # Redis alerts
      - alert: RedisDown
        expr: redis_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Redis instance {{ $labels.instance }} is down"
      
      - alert: RedisMemoryHigh
        expr: (redis_memory_used_bytes / redis_memory_max_bytes) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Redis memory usage > 90% on {{ $labels.instance }}"
      
      - alert: RedisCacheHitRateLow
        expr: (redis_keyspace_hits_total / (redis_keyspace_hits_total + redis_keyspace_misses_total)) < 0.8
        for: 10m
        labels:
          severity: info
        annotations:
          summary: "Redis cache hit rate < 80% on {{ $labels.instance }}"
      
      # etcd alerts
      - alert: EtcdNoLeader
        expr: etcd_server_has_leader == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "etcd cluster has no leader"
      
      - alert: EtcdHighNumberOfLeaderChanges
        expr: rate(etcd_server_leader_changes_seen_total[1h]) > 3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "etcd leader changed {{ $value }} times in last hour"
      
      # Application alerts
      - alert: HighErrorRate
        expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate ({{ $value }}/s) on {{ $labels.service }}"
```

## Best Practices

1. **Metric Naming**: Follow Prometheus naming conventions (e.g., `_total` suffix for counters)
2. **Label Cardinality**: Avoid high-cardinality labels (e.g., don't use user IDs as labels)
3. **Scrape Intervals**: Balance between granularity and resource usage (15s is standard)
4. **Retention**: Adjust retention period based on disk space and historical needs
5. **Alerting**: Set appropriate thresholds and `for` durations to avoid flapping
6. **Dashboards**: Organize metrics by service and use templating for multi-instance views

## Related Documentation

- [Observability Architecture](../architecture/observability.md)
- [Pre-Built Grafana Dashboards](../infrastructure/grafana-dashboards.md)
- [Distributed Tracing](../architecture/distributed-tracing.md)
- [Prometheus Official Documentation](https://prometheus.io/docs/)
