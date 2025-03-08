#!/bin/bash
set -e

source ../.env

# Get production node IPs
IFS=',' read -ra PROD_IPS <<< "${OTHER_NODE_IPS}"
CURRENT_IP="10.0.1.$((9 + VM_INDEX))"

# If we're not the primary node (node #1), exit
if [ "$VM_INDEX" != "1" ]; then
  echo "This script should only run on the primary node (VM_INDEX=1)"
  exit 0
fi

# Prepare certificates for sync
cd /home/openedx/openedx-ha/docker
mkdir -p /tmp/caddy-certs-sync
tar -czf /tmp/caddy-certs-sync/certs.tar.gz -C config/caddy data config

# Stop Caddy on other nodes, copy certs, restart Caddy
for NODE_IP in "${PROD_IPS[@]}"; do
  echo "Syncing certificates to $NODE_IP"
  scp /tmp/caddy-certs-sync/certs.tar.gz openedx@$NODE_IP:/tmp/
  ssh openedx@$NODE_IP "cd /home/openedx/openedx-ha/docker && \
                       docker-compose stop caddy && \
                       rm -rf config/caddy/data config/caddy/config && \
                       mkdir -p config/caddy && \
                       tar -xzf /tmp/certs.tar.gz -C config/caddy && \
                       docker-compose start caddy"
done

# Clean up
rm -rf /tmp/caddy-certs-sync

echo "Certificate synchronization completed at $(date)"

