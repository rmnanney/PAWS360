# Observability Architecture

## Overview

PAWS360 provides an optional observability stack for local development that mirrors production monitoring capabilities. This stack includes metrics collection (Prometheus), visualization (Grafana), and distributed tracing (Jaeger).

## Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  ┌──────────────┐              ┌──────────────┐            │
│  │   Backend    │◄────────────►│  Frontend    │            │
│  │ Spring Boot  │              │   Next.js    │            │
│  └──────┬───────┘              └──────┬───────┘            │
│         │ /actuator/prometheus        │ /api/metrics       │
│         │                             │                     │
└─────────┼─────────────────────────────┼─────────────────────┘
          │                             │
          ▼                             ▼
┌─────────────────────────────────────────────────────────────┐
│                  Observability Stack                        │
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                │
│  │  Prometheus  │────────►│   Grafana    │                │
│  │   (9090)     │         │    (3001)    │                │
│  └──────────────┘         └──────────────┘                │
│         ▲                                                   │
│         │ scrape                                           │
│         │                                                   │
│  ┌──────┴───────┬────────────┬────────────┐               │
│  │ PostgreSQL   │   etcd     │   Redis    │               │
│  │  Exporter    │  /metrics  │  Exporter  │               │
│  │   (9187)     │   (2379)   │   (9121)   │               │
│  └──────────────┴────────────┴────────────┘               │
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                │
│  │ OpenTelemetry│────────►│    Jaeger    │                │
│  │  Collector   │         │   (16686)    │                │
│  │ (4317/4318)  │         │              │                │
│  └──────────────┘         └──────────────┘                │
└─────────────────────────────────────────────────────────────┘
          ▲                             ▲
          │ OTLP traces                 │ OTLP traces
          │                             │
┌─────────┴─────────────────────────────┴─────────────────────┐
│              Application with Tracing                       │
│  Backend (Spring Boot Sleuth) + Frontend (OTLP exporter)   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Start Observability Stack

```bash
make observability-up
```

This starts:
- **Prometheus** on http://localhost:9090
- **Grafana** on http://localhost:3001 (admin/admin)
- **Jaeger** on http://localhost:16686

### Stop Observability Stack

```bash
make observability-down
```

## Metrics Collection

### Prometheus Configuration

Prometheus scrapes metrics from:

1. **PostgreSQL** (via postgres_exporter on port 9187)
   - Connection stats
   - Query performance
   - Replication lag
   - Database size

2. **Redis** (via redis_exporter on port 9121)
   - Memory usage
   - Command stats
   - Keyspace info
   - Replication status

3. **etcd** (native /metrics endpoint on port 2379)
   - Cluster health
   - Raft consensus metrics
   - Key/value operation rates

4. **Patroni** (native /patroni endpoint on port 8008)
   - Leader election status
   - Replication lag
   - Cluster topology

5. **Application Services** (if instrumented)
   - Backend: `/actuator/prometheus`
   - Frontend: `/api/metrics`

### Custom Metrics

Add custom metrics to your application:

**Spring Boot Backend** (add to pom.xml):
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

**Next.js Frontend**:
```typescript
// pages/api/metrics.ts
import { register } from 'prom-client';

export default async function handler(req, res) {
  res.setHeader('Content-Type', register.contentType);
  res.send(await register.metrics());
}
```

## Grafana Dashboards

### Pre-configured Dashboards

Access Grafana at http://localhost:3001 (admin/admin) to view:

1. **HA Stack Overview**
   - Cluster health across all components
   - Service availability
   - Resource utilization

2. **PostgreSQL Performance**
   - Active connections
   - Query latency
   - Replication lag
   - Transaction rates

3. **Redis Performance**
   - Memory usage
   - Command throughput
   - Cache hit rate
   - Keyspace distribution

4. **etcd Cluster**
   - Raft consensus status
   - Leader elections
   - Proposal commit rate

### Creating Custom Dashboards

1. Navigate to http://localhost:3001
2. Click "+" → "Dashboard" → "Add new panel"
3. Select "Prometheus" as data source
4. Write PromQL query
5. Save dashboard

**Example PromQL Queries**:

```promql
# PostgreSQL active connections
pg_stat_database_numbackends{datname="paws360_dev"}

# Redis memory usage
redis_memory_used_bytes

# etcd leader changes
rate(etcd_server_leader_changes_seen_total[5m])

# Patroni replication lag
patroni_postgres_replication_lag
```

## Distributed Tracing

### Jaeger UI

Access Jaeger at http://localhost:16686 to:
- Search traces by service, operation, tags
- View trace timeline and spans
- Analyze service dependencies
- Identify performance bottlenecks

### Instrumenting Applications

**Spring Boot Backend** (add to pom.xml):
```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-tracing-bridge-otel</artifactId>
</dependency>
<dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
</dependency>
```

**application.yml**:
```yaml
management:
  tracing:
    sampling:
      probability: 1.0
  otlp:
    tracing:
      endpoint: http://otel-collector:4318/v1/traces
```

**Next.js Frontend**:
```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector:4318/v1/traces',
  }),
});

sdk.start();
```

### Trace Correlation

Traces are automatically correlated across services using trace IDs:

```
Request Flow:
Frontend (trace_id: abc123)
    ↓
Backend (trace_id: abc123, span_id: def456)
    ↓
Database Query (trace_id: abc123, span_id: ghi789)
```

## Resource Requirements

When observability stack is enabled:

- **Additional RAM**: ~2GB
- **Additional CPU**: ~1 core
- **Additional Disk**: ~1GB for metrics retention
- **Additional Ports**: 9090, 3001, 16686, 4317, 4318, 9187, 9121

## Performance Impact

The observability stack has minimal performance impact:

- Prometheus scraping: <1% CPU overhead
- Metric exporters: <100MB RAM each
- Trace sampling: Configurable (default 100% for local dev)

## Troubleshooting

### Prometheus not scraping metrics

**Check target health**:
```bash
curl http://localhost:9090/api/v1/targets
```

**Common issues**:
- Service not exposing metrics endpoint
- Incorrect port in prometheus.yml
- Network connectivity between containers

### Grafana dashboards empty

**Verify Prometheus data source**:
1. Go to Configuration → Data Sources
2. Click "Prometheus"
3. Click "Test" button
4. Should see "Data source is working"

**Check if metrics exist**:
```bash
curl http://localhost:9090/api/v1/query?query=up
```

### No traces in Jaeger

**Verify OTLP collector is receiving traces**:
```bash
docker logs paws360-otel-collector | grep -i trace
```

**Check application instrumentation**:
- Verify OTLP endpoint configured correctly
- Check sampling rate (should be 1.0 for local dev)
- Ensure trace exporter is initialized

## Data Retention

### Prometheus

Default retention: 15 days

Modify in docker-compose.auxiliary.yml:
```yaml
command:
  - '--storage.tsdb.retention.time=30d'
```

### Jaeger

Default retention: In-memory (lost on restart)

For persistent storage, switch to Elasticsearch backend (not recommended for local dev).

## Security Considerations

### Grafana Credentials

Default: admin/admin

Change password after first login:
1. Log in with admin/admin
2. Click profile icon → "Change password"
3. Set new password

### Exposed Ports

All observability ports are exposed only on localhost by default. If you need remote access, update docker-compose.auxiliary.yml port bindings.

## See Also

- [Debugging Guide](../guides/debugging.md)
- [Cluster Inspection Commands](../reference/debugging-commands.md)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
