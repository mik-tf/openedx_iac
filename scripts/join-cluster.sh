#!/bin/bash
set -e

source ../.env

# CouchDB credentials
USER="${COUCHDB_USER:-admin}"
PASS="${COUCHDB_PASSWORD:-password}"

# Get node IPs from environment
IFS=',' read -ra NODE_IPS <<< "${OTHER_NODE_IPS}"
CURRENT_IP="10.0.1.$((9 + VM_INDEX))"

echo "Joining CouchDB cluster with existing nodes: ${NODE_IPS[@]}"

# Wait for an existing node to be available
MASTER_NODE=""
for NODE in "${NODE_IPS[@]}"; do
  if curl -s "http://${USER}:${PASS}@${NODE}:5984" > /dev/null; then
    MASTER_NODE="${NODE}"
    echo "Found available node: ${MASTER_NODE}"
    break
  fi
done

if [ -z "${MASTER_NODE}" ]; then
  echo "No existing nodes are available. Cannot join cluster."
  exit 1
fi

# Initialize local node
curl -X POST -H "Content-Type: application/json" \
     "http://${USER}:${PASS}@${CURRENT_IP}:5984/_cluster_setup" \
     -d '{"action":"enable_cluster", "bind_address":"0.0.0.0", 
         "username":"'"${USER}"'", "password":"'"${PASS}"'"}'

# Ask master node to add this node
curl -X POST -H "Content-Type: application/json" \
     "http://${USER}:${PASS}@${MASTER_NODE}:5984/_cluster_setup" \
     -d '{"action":"add_node", "host":"'"${CURRENT_IP}"'", 
         "port":"5984", "username":"'"${USER}"'", "password":"'"${PASS}"'"}'

# Check cluster status
curl -X GET "http://${USER}:${PASS}@${MASTER_NODE}:5984/_membership"

echo "Node joined the cluster. Verify that it appears in the cluster_nodes list above."

