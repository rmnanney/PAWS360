#!/bin/bash
set -e

# Patroni bootstrap script
# Handles initialization and migration execution

export PATRONI_NAME=${PATRONI_NAME:-patroni1}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-dev_password_change_me}

echo "Starting Patroni node: ${PATRONI_NAME}"
echo "  Scope: ${PATRONI_SCOPE:-paws360-cluster}"
echo "  etcd endpoints: ${ETCD_HOSTS:-etcd1:2379,etcd2:2379,etcd3:2379}"

# Wait for etcd to be available
echo "Waiting for etcd cluster..."
until curl -sf http://etcd1:2379/health > /dev/null 2>&1; do
  echo "  etcd not ready, waiting..."
  sleep 2
done
echo "etcd cluster is available"

# Create PostgreSQL data directory and fix permissions (as root)
mkdir -p /data/patroni
chown -R postgres:postgres /data/patroni
chmod 700 /data/patroni

# Start Patroni as postgres user
exec gosu postgres /usr/bin/python3 /usr/local/bin/patroni /config/patroni.yml
