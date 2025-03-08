# Troubleshooting Guide

This guide helps diagnose and fix common issues with the Open edX HA deployment.

## Common Issues

### CouchDB Cluster Problems

#### Symptoms:
- Database sync failures
- Error messages about nodes disconnected
- Inconsistent data across instances

#### Solutions:

1. **Check Cluster Status**:
   ```bash
   curl -s http://admin:password@localhost:5984/_membership | jq
   ```

2. **Verify Network Connectivity**:
   ```bash
   # From one production VM to another
   ping 10.0.1.x
   telnet 10.0.1.x 5984
   ```

3. **Rebuild Cluster**:
   If the cluster is in a bad state, you might need to rebuild it:
   ```bash
   cd /home/openedx/openedx-ha/scripts
   ./setup-cluster.sh
   ```

### Container Failures

#### Symptoms:
- Services unavailable
- Docker container exiting unexpectedly
- Error logs showing container issues

#### Solutions:

1. **Check Container Status**:
   ```bash
   docker ps -a
   ```

2. **View Container Logs**:
   ```bash
   docker logs lms
   docker logs cms
   docker logs couchdb
   ```

3. **Restart Containers**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

4. **Check Resource Usage**:
   ```bash
   docker stats
   ```

### DNS Issues

#### Symptoms:
- Intermittent service availability
- Some users can access, others cannot

#### Solutions:

1. **Verify DNS Records**:
   ```bash
   dig yourdomain.com
   # Should return all production VM IPs
   ```

2. **Check TTL Settings**:
   Ensure your DNS TTL is set to a low value (300 seconds recommended)

3. **Test from Different Networks**:
   DNS caching can vary by network, test access from different locations

### SSL/TLS Issues

#### Symptoms:
- Browser security warnings
- Certificate errors
- Mixed content warnings

#### Solutions:

1. **Verify Certificate Validity**:
   ```bash
   openssl x509 -in /path/to/certificate.pem -text -noout
   ```

2. **Check Certificate Chain**:
   ```bash
   openssl verify -CAfile /path/to/chain.pem /path/to/certificate.pem
   ```

3. **Renew Certificates**:
   ```bash
   certbot renew
   ```

### Backup/Restore Issues

#### Symptoms:
- Backup process failing
- Incomplete backups
- Restore process errors

#### Solutions:

1. **Check Disk Space**:
   ```bash
   df -h
   ```

2. **Verify Backup Permissions**:
   ```bash
   ls -la /backup
   ```

3. **Test Backup Integrity**:
   ```bash
   cd /home/openedx/openedx-ha/scripts
   ./verify-backup.sh /path/to/backup
   ```

4. **Manual Backup**:
   ```bash
   cd /home/openedx/openedx-ha/scripts
   ./backup-daily.sh
   ```

## Advanced Troubleshooting

### Database Corruption

If you suspect database corruption:

1. Take a backup of the current state
2. Try compacting the database:
   ```bash
   curl -X POST -H "Content-Type: application/json" \
        "http://admin:password@localhost:5984/openedx_1/_compact"
   ```

3. Verify document count and consistency:
   ```bash
   curl "http://admin:password@localhost:5984/openedx_1" | jq
   ```

### Application Code Issues

If Open edX application is behaving unexpectedly:

1. Check application logs:
   ```bash
   docker exec -it lms tail -f /openedx/logs/lms.log
   ```

2. Try restarting just the application:
   ```bash
   docker restart lms cms
   ```

3. Update container to latest version:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

## Getting Help

If you're unable to resolve the issue using this guide:

1. Check the [Open edX documentation](https://docs.openedx.org/)
2. Search the [Open edX discussion forums](https://discuss.openedx.org/)
3. File an issue on the GitHub repository
```

### `docs/images/architecture.png`

For the architecture diagram, I can't directly create an image file, but you can generate one based on the ASCII diagram in the architecture.md file. You can use tools like draw.io, lucidchart, or even simple drawing tools to create this diagram. 

Here's a description for creating the architecture.png file:

Create a diagram showing:
1. Three production VMs, each containing Docker containers (Open edX LMS/CMS, CouchDB, Watchtower)
2. CouchDB replication between the three VMs
3. DNS round-robin directing traffic to all three VMs
4. A backup VM pulling data from production VMs
5. Local PC backup pulling from the backup VM

The diagram should match the ASCII representation in the architecture.md file.

## 4. Additional Scripts

### `scripts/add-node.sh`

```bash
#!/bin/bash
set -e

source ../.env

if [ $# -ne 1 ]; then
  echo "Usage: $0 <new_node_ip>"
  exit 1
fi

NEW_NODE_IP=$1
USER="${COUCHDB_USER:-admin}"
PASS="${COUCHDB_PASSWORD:-password}"

echo "Adding node $NEW_NODE_IP to CouchDB cluster"

# Wait for new node to be up
until curl -s "http://${USER}:${PASS}@${NEW_NODE_IP}:5984" > /dev/null; do
  echo "Waiting for CouchDB on ${NEW_NODE_IP}..."
  sleep 2
done

# Get current node IP
CURRENT_IP="10.0.1.$((9 + VM_INDEX))"

# Add the node to the cluster
curl -X POST -H "Content-Type: application/json" \
     "http://${USER}:${PASS}@${CURRENT_IP}:5984/_cluster_setup" \
     -d '{"action":"add_node", "host":"'"${NEW_NODE_IP}"'", 
         "port":"5984", "username":"'"${USER}"'", "password":"'"${PASS}"'"}'

# Check cluster status
curl -X GET "http://${USER}:${PASS}@${CURRENT_IP}:5984/_membership"

echo "Node added to cluster. Verify that it appears in the cluster_nodes list above."

