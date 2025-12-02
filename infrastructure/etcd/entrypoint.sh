#!/bin/bash
set -e

# etcd cluster initialization script
# Supports static cluster configuration for local development

ETCD_NAME=${ETCD_NAME:-etcd1}
ETCD_INITIAL_ADVERTISE_PEER_URLS=${ETCD_INITIAL_ADVERTISE_PEER_URLS:-http://${ETCD_NAME}:2380}
ETCD_LISTEN_PEER_URLS=${ETCD_LISTEN_PEER_URLS:-http://0.0.0.0:2380}
ETCD_LISTEN_CLIENT_URLS=${ETCD_LISTEN_CLIENT_URLS:-http://0.0.0.0:2379}
ETCD_ADVERTISE_CLIENT_URLS=${ETCD_ADVERTISE_CLIENT_URLS:-http://${ETCD_NAME}:2379}
ETCD_INITIAL_CLUSTER_TOKEN=${ETCD_INITIAL_CLUSTER_TOKEN:-paws360-etcd-cluster}
ETCD_INITIAL_CLUSTER_STATE=${ETCD_INITIAL_CLUSTER_STATE:-new}

# Default cluster configuration (will be overridden by docker-compose)
ETCD_INITIAL_CLUSTER=${ETCD_INITIAL_CLUSTER:-etcd1=http://etcd1:2380,etcd2=http://etcd2:2380,etcd3=http://etcd3:2380}

echo "Starting etcd node: ${ETCD_NAME}"
echo "  Initial cluster: ${ETCD_INITIAL_CLUSTER}"
echo "  Peer URLs: ${ETCD_INITIAL_ADVERTISE_PEER_URLS}"
echo "  Client URLs: ${ETCD_ADVERTISE_CLIENT_URLS}"

exec /usr/local/bin/etcd \
  --name "${ETCD_NAME}" \
  --data-dir /etcd-data \
  --initial-advertise-peer-urls "${ETCD_INITIAL_ADVERTISE_PEER_URLS}" \
  --listen-peer-urls "${ETCD_LISTEN_PEER_URLS}" \
  --listen-client-urls "${ETCD_LISTEN_CLIENT_URLS}" \
  --advertise-client-urls "${ETCD_ADVERTISE_CLIENT_URLS}" \
  --initial-cluster "${ETCD_INITIAL_CLUSTER}" \
  --initial-cluster-token "${ETCD_INITIAL_CLUSTER_TOKEN}" \
  --initial-cluster-state "${ETCD_INITIAL_CLUSTER_STATE}" \
  --heartbeat-interval 250 \
  --election-timeout 1250 \
  --auto-compaction-retention 1 \
  --max-request-bytes 10485760
