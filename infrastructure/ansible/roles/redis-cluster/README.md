Redis Cluster role
==================

Configures Redis for cluster mode and will attempt to bootstrap a 3-node cluster (or N nodes received). This is a convenience scaffolding — for production you should tune persistence, ACL, and memory sizing and integrate monitoring & failure testing.

Behavior:
- Writes cluster-enabled settings into redis.conf
- Restarts redis
- From the first redis node, calls `redis-cli --cluster create` with the list of redis member IPs to form the cluster
