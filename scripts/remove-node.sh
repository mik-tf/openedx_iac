#!/bin/bash
set -e

source ../.env

if [ $# -ne 1 ]; then
  echo "Usage: $0 <node_ip_to_remove>"
  exit 1
fi

NODE_IP=$1
USER="${COUCHDB_USER:-admin}"
PASS="${COUCHDB_PASSWORD:-password}"

echo "Removing node $NODE_IP from CouchDB cluster"

# Get current node IP
CURRENT_IP="10.0.1.$((9 + VM_INDEX))"

# Check if the node to remove is in the cluster
MEMBERSHIP=$(curl -s "http://${USER}:${PASS}@${CURRENT_IP}:5984/_membership")
if ! echo "$MEMBERSHIP" | grep -q "$NODE_IP"; then
  echo "Node $NODE_IP is not in the cluster."
  exit 1
fi

# Get the node name from the membership info
NODE_NAME=$(echo "$MEMBERSHIP" | jq -r '.cluster_nodes[] | select(contains("'"$NODE_IP"'"))')

if [ -z "$NODE_NAME" ]; then
  echo "Could not find node name for $NODE_IP."
  exit 1
fi

echo "Found node name: $NODE_NAME"

# Remove the node
curl -X DELETE "http://${USER}:${PASS}@${CURRENT_IP}:5984/_node/_local/_nodes/${NODE_NAME}"

# Check cluster status
curl -X GET "http://${USER}:${PASS}@${CURRENT_IP}:5984/_membership"

echo "Node removed from cluster. Verify that it no longer appears in the cluster_nodes list above."

