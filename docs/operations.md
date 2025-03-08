# Operations Manual

This document covers day-to-day operations and maintenance tasks for the Open edX HA deployment.

## Routine Maintenance

### Checking System Health

SSH into any production VM and run:

```bash
cd /home/openedx/openedx-ha/scripts
./health-check.sh
```

### Manually Updating Containers

Normally Watchtower handles updates, but for manual updates:

```bash
docker-compose pull
docker-compose up -d
```

### Viewing Logs

```bash
# Open edX LMS logs
docker logs -f lms

# Open edX CMS logs
docker logs -f cms

# CouchDB logs
docker logs -f couchdb
```

### Checking CouchDB Cluster Status

```bash
curl -s http://admin:password@localhost:5984/_membership | jq
```

## Adding a New Node

1. Add a new VM using OpenTofu:
   ```bash
   # Edit infrastructure/variables.tf to increase vm_count
   tofu apply
   ```

2. Add the new VM's IP to DNS

3. SSH into the first VM and run:
   ```bash
   ./scripts/add-node.sh NEW_NODE_IP
   ```

## Removing a Node

1. SSH into the first VM and run:
   ```bash
   ./scripts/remove-node.sh NODE_IP_TO_REMOVE
   ```

2. Remove the VM's IP from DNS

3. Destroy the VM using OpenTofu:
   ```bash
   tofu destroy -target=hcloud_server.openedx_production[NODE_INDEX]
   ```

## Applying Open edX Configuration Changes

1. Edit the configuration files in `docker/config/`
2. Commit changes to Git
3. On each VM:
   ```bash
   cd /home/openedx/openedx-ha
   git pull
   docker-compose up -d
   ```

## Security Updates

Host OS security updates are handled automatically via the cloud-init configuration. For manual updates:

```bash
sudo apt update
sudo apt upgrade -y
```

## Verifying Backups

SSH into the backup VM:

```bash
ls -la /backup/daily/
ls -la /backup/weekly/
ls -la /backup/monthly/
```

Run a test restore:

```bash
cd /home/openedx/openedx-ha/scripts
./test-restore.sh
```

## Common Tasks

### Restart Services

```bash
docker-compose restart lms cms
```

### Reset Admin Password

```bash
docker exec -it lms bash -c "python /openedx/edx-platform/manage.py lms --settings=tutor.production changepassword admin"
```

### Clear Cache

```bash
docker exec -it lms bash -c "python /openedx/edx-platform/manage.py lms --settings=tutor.production cache_clear"
```

## SSL Certificate Management

This deployment uses Caddy for automatic SSL certificate management:

### How It Works

- The primary node (VM1) handles certificate acquisition with Caddy
- Certificates are synchronized weekly to other nodes
- Caddy handles automatic renewal on the primary node

### Certificate Synchronization

Certificates are automatically synchronized from the primary node to all other nodes. If you need to trigger synchronization manually:

```bash
# On the primary node (VM1)
cd /home/openedx/openedx-ha/scripts
./sync-caddy-certs.sh
```

### Checking Certificate Status

To check certificate status on any node:

```bash
docker exec -it caddy caddy list-certs
```

### Forcing Certificate Renewal

If you need to force certificate renewal:

```bash
# On the primary node
docker exec -it caddy caddy reload
# Then sync certificates to other nodes
cd /home/openedx/openedx-ha/scripts
./sync-caddy-certs.sh
```

