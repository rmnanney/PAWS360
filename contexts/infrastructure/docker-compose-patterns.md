# Docker Compose Patterns - GPT Context

Context file for AI assistants working with PAWS360 Docker Compose infrastructure.

## Project Overview

PAWS360 uses Docker Compose to orchestrate a high-availability local development environment that mirrors production architecture.

## Architecture Summary

```yaml
# Service topology
services:
  # Application Layer
  - frontend (Next.js, port 3000)
  - backend (Spring Boot, port 8080)

  # Database Layer (Patroni HA Cluster)
  - patroni1 (PostgreSQL Primary, port 5432)
  - patroni2 (PostgreSQL Replica, port 5433)
  - patroni3 (PostgreSQL Replica, port 5434)

  # Coordination Layer
  - etcd1, etcd2, etcd3 (Consensus, ports 2379-2384)

  # Caching Layer
  - redis (Primary, port 6379)
  - redis-sentinel1/2/3 (Failover, ports 26379-26381)

  # Load Balancing
  - haproxy (DB routing, port 5000)
```

## Key Patterns

### Health-Based Dependencies

```yaml
services:
  backend:
    depends_on:
      patroni1:
        condition: service_healthy
      redis:
        condition: service_healthy
```

### Volume Persistence

```yaml
volumes:
  patroni1_data:
    driver: local
    name: paws360_patroni1_data
```

### Multi-Stage Health Checks

```yaml
healthcheck:
  test: ["CMD", "pg_isready", "-h", "localhost"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

## Common Tasks

### Starting the Stack
```bash
make dev-up
# Or: docker compose up -d
```

### Viewing Logs
```bash
make dev-logs SERVICE=backend
# Or: docker compose logs -f backend
```

### Rebuilding Services
```bash
make dev-rebuild SERVICE=backend
# Or: docker compose build --no-cache backend && docker compose up -d backend
```

### Accessing Containers
```bash
make dev-shell SERVICE=backend
# Or: docker compose exec backend /bin/sh
```

## Environment Variables

Key variables defined in `.env`:
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `SPRING_PROFILES_ACTIVE`
- `NODE_ENV`
- `PATRONI_SCOPE`
- `REDIS_HOST`, `REDIS_PORT`

## File Locations

- Main compose file: `docker-compose.yml`
- Development overrides: `docker-compose.override.yml`
- CI compose file: `docker-compose.ci.yml`
- Environment template: `config/dev.env`
- Dockerfiles: `infrastructure/docker/`

## Troubleshooting

### Service Won't Start
1. Check logs: `docker compose logs <service>`
2. Check dependencies are healthy: `docker compose ps`
3. Check port conflicts: `lsof -i :<port>`

### Database Connection Issues
1. Check Patroni status: `make patroni-status`
2. Verify etcd health: `make etcd-health`
3. Test connection: `make dev-psql`

### Memory Issues
1. Check resource usage: `docker stats`
2. Prune unused resources: `docker system prune`
3. Use lite mode: `./docs/quickstart.sh --lite`

## Important Notes

- Always use `make dev-down` before major config changes
- Database volumes persist across restarts
- Use `VOLUMES=1` flag with `dev-down` to clear data
- BuildKit is enabled by default (`DOCKER_BUILDKIT=1`)
