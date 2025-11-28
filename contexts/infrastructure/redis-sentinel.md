# Redis Sentinel - GPT Context

Context file for AI assistants working with the PAWS360 Redis Sentinel high-availability configuration.

## Purpose

Redis Sentinel provides:
- **Monitoring** of Redis primary and replicas
- **Automatic failover** when primary fails (<30s)
- **Notification** of state changes
- **Configuration provider** for client discovery

## Cluster Configuration

```yaml
# Redis + 3 Sentinel nodes
redis:
  port: 6379
  role: Primary

redis-sentinel1:
  port: 26379

redis-sentinel2:
  port: 26380

redis-sentinel3:
  port: 26381
```

## Sentinel Configuration

```conf
# sentinel.conf
sentinel monitor mymaster redis 6379 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel auth-pass mymaster <password>
```

### Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `monitor` | mymaster redis 6379 2 | Monitor Redis, quorum 2 |
| `down-after-milliseconds` | 5000 | Down after 5s no response |
| `failover-timeout` | 60000 | Failover timeout 60s |
| `parallel-syncs` | 1 | Replicas to sync at once |

## Common Operations

### Check Sentinel Status
```bash
# Get master info
redis-cli -h localhost -p 26379 SENTINEL masters

# Get master address
redis-cli -h localhost -p 26379 SENTINEL get-master-addr-by-name mymaster
```

### Check Replicas
```bash
redis-cli -h localhost -p 26379 SENTINEL replicas mymaster
```

### Check Sentinel Info
```bash
redis-cli -h localhost -p 26379 SENTINEL sentinels mymaster
```

### Force Failover
```bash
redis-cli -h localhost -p 26379 SENTINEL failover mymaster
```

### Reset Sentinel
```bash
redis-cli -h localhost -p 26379 SENTINEL reset mymaster
```

## Client Connection

### Via Sentinel (Recommended)
```java
// Spring Boot configuration
@Bean
public LettuceConnectionFactory redisConnectionFactory() {
    RedisSentinelConfiguration sentinelConfig = new RedisSentinelConfiguration()
        .master("mymaster")
        .sentinel("redis-sentinel1", 26379)
        .sentinel("redis-sentinel2", 26379)
        .sentinel("redis-sentinel3", 26379);
    
    return new LettuceConnectionFactory(sentinelConfig);
}
```

```yaml
# application.yml
spring:
  redis:
    sentinel:
      master: mymaster
      nodes:
        - redis-sentinel1:26379
        - redis-sentinel2:26379
        - redis-sentinel3:26379
```

### Direct Connection (Development)
```bash
redis-cli -h localhost -p 6379

# Or via redis-cli
redis-cli
> PING
PONG
> SET key value
OK
> GET key
"value"
```

## Failover Process

```
T+0s    Primary becomes unresponsive
T+5s    Sentinels detect failure (down-after-milliseconds)
T+5s    Sentinels begin voting
T+10s   Quorum (2/3) agrees on failure
T+15s   Leader sentinel starts failover
T+20s   Best replica selected and promoted
T+25s   Other sentinels update configuration
T+30s   Clients reconnect to new primary
```

### Replica Selection Criteria
1. Replica with lowest replication lag
2. Replica with highest priority
3. Replica with lexicographically smallest runid

## Health Checks

```yaml
# Docker health check
healthcheck:
  test: ["CMD", "redis-cli", "-h", "localhost", "-p", "26379", "SENTINEL", "master", "mymaster"]
  interval: 10s
  timeout: 5s
  retries: 5
```

## Monitoring

### Key Metrics
```bash
# Sentinel info
redis-cli -h localhost -p 26379 INFO sentinel

# Master info
redis-cli -h localhost -p 6379 INFO replication

# Memory usage
redis-cli -h localhost -p 6379 INFO memory
```

### Important Events to Monitor
- `+sdown` - Subjectively down
- `+odown` - Objectively down
- `+failover-state-reconf-slaves` - Reconfiguring replicas
- `+slave` - New replica detected
- `-slave` - Replica removed

## Failure Scenarios

### Primary Failure
1. All sentinels detect down (5s)
2. Quorum votes for failover
3. Leader sentinel promotes replica
4. Other sentinels reconfigure
5. Clients reconnect

### Sentinel Failure
- Remaining sentinels continue monitoring
- Quorum still required (2 of 3)
- Reduced redundancy until recovered

### Network Partition
- Isolated sentinel marks primary as down
- Cannot reach quorum alone
- Majority partition continues normally

### All Sentinels Fail
- No automatic failover
- Manual intervention required
- Clients may continue with cached primary

## Data Persistence

```conf
# Redis persistence configuration
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

## Session Storage

```java
// Store session in Redis
@EnableRedisHttpSession
public class SessionConfig {
    @Value("${session.timeout:3600}")
    private int sessionTimeout;
    
    @Bean
    public RedisSerializer<Object> springSessionDefaultRedisSerializer() {
        return new GenericJackson2JsonRedisSerializer();
    }
}
```

## Caching

```java
@Cacheable(value = "users", key = "#id", unless = "#result == null")
public User findById(Long id) {
    return userRepository.findById(id).orElse(null);
}

@CacheEvict(value = "users", key = "#user.id")
public void save(User user) {
    userRepository.save(user);
}
```

## Troubleshooting

### Sentinels Not Detecting Primary
```bash
# Check sentinel connectivity
redis-cli -h localhost -p 26379 PING

# Verify master is reachable
redis-cli -h localhost -p 6379 PING

# Check sentinel configuration
redis-cli -h localhost -p 26379 SENTINEL master mymaster
```

### Failover Not Working
```bash
# Check quorum
redis-cli -h localhost -p 26379 SENTINEL ckquorum mymaster

# Check logs
docker compose logs redis-sentinel1 redis-sentinel2 redis-sentinel3
```

### Split Brain
```bash
# Check all sentinels agree on master
for port in 26379 26380 26381; do
  echo "Sentinel :$port"
  redis-cli -h localhost -p $port SENTINEL get-master-addr-by-name mymaster
done
```

## Important Notes

- Sentinels communicate via pub/sub
- Quorum required for failover decisions
- Clients should use Sentinel-aware drivers
- Session data persists in AOF
- Default down-after: 5 seconds
- Default failover-timeout: 60 seconds

## Related Files

- Docker config: `docker-compose.yml` (redis, redis-sentinel1/2/3)
- Sentinel config: `config/redis/sentinel.conf`
- Redis config: `config/redis/redis.conf`
- Documentation: `docs/architecture/ha-stack.md`
- Application config: `src/main/resources/application.yml`
