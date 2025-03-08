#!/bin/bash
set -e

source ../.env

# CouchDB credentials
USER="${COUCHDB_USER:-admin}"
PASS="${COUCHDB_PASSWORD:-password}"
COOKIE="${COUCHDB_COOKIE:-monster}"

# Get node IPs from environment
IFS=',' read -ra NODE_IPS <<< "${OTHER_NODE_IPS}"
CURRENT_IP="10.0.1.$((9 + VM_INDEX))"

echo "Setting up CouchDB cluster with nodes: ${CURRENT_IP} ${NODE_IPS[@]}"

# Wait for all nodes to be up
for NODE in "${NODE_IPS[@]}"; do
  until curl -s "http://${USER}:${PASS}@${NODE}:5984" > /dev/null; do
    echo "Waiting for CouchDB on ${NODE}..."
    sleep 2
  done
done

# Enable the cluster on the current node
curl -X POST -H "Content-Type: application/json" \
     "http://${USER}:${PASS}@${CURRENT_IP}:5984/_cluster_setup" \
     -d '{"action":"enable_cluster", "bind_address":"0.0.0.0", 
         "username":"'"${USER}"'", "password":"'"${PASS}"'", 
         "node_count":"3", "remote_node":"'"${CURRENT_IP}"'", 
         "remote_current_user":"'"${USER}"'", "remote_current_password":"'"${PASS}"'"}'

# Add other nodes to cluster
for NODE in "${NODE_IPS[@]}"; do
  echo "Adding node ${NODE} to cluster..."
  curl -X POST -H "Content-Type: application/json" \
       "http://${USER}:${PASS}@${CURRENT_IP}:5984/_cluster_setup" \
       -d '{"action":"add_node", "host":"'"${NODE}"'", 
           "port":"5984", "username":"'"${USER}"'", "password":"'"${PASS}"'"}'
done

# Finish cluster setup
curl -X POST -H "Content-Type: application/json" \
     "http://${USER}:${PASS}@${CURRENT_IP}:5984/_cluster_setup" \
     -d '{"action":"finish_cluster"}'

# Check cluster status
curl -X GET "http://${USER}:${PASS}@${CURRENT_IP}:5984/_membership"

echo "CouchDB cluster setup complete"