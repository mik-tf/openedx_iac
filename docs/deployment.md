# Deployment Guide

This guide walks through the complete process of deploying the Open edX High Availability solution.

## Prerequisites

- Hetzner Cloud account with API token
- OpenTofu installed on your local machine
- Domain name with access to DNS settings
- SSH key pair

## Step 1: Infrastructure Deployment

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/openedx-ha.git
   cd openedx-ha
   ```

2. Configure variables:
   ```bash
   cd infrastructure
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

   Example `terraform.tfvars` content:
   ```
   hcloud_token        = "your_hetzner_cloud_api_token"
   ssh_public_key_path = "~/.ssh/id_rsa.pub"
   production_vm_count = 3
   couchdb_user        = "admin"
   couchdb_password    = "your_secure_password"
   domain_name         = "yourdomain.com"
   ```

3. Initialize and apply OpenTofu:
   ```bash
   tofu init
   tofu apply
   ```

4. Note the output IP addresses of all VMs.

## Step 2: DNS Configuration

Add DNS A records for your domain pointing to all three production VMs:

| Record Type | Host/Name        | Value/Points to | TTL  |
|-------------|------------------|-----------------|------|
| A           | your-domain.com  | VM1_IP_ADDRESS  | 300  |
| A           | your-domain.com  | VM2_IP_ADDRESS  | 300  |
| A           | your-domain.com  | VM3_IP_ADDRESS  | 300  |
| A           | studio.your-domain.com  | VM1_IP_ADDRESS  | 300  |
| A           | studio.your-domain.com  | VM2_IP_ADDRESS  | 300  |
| A           | studio.your-domain.com  | VM3_IP_ADDRESS  | 300  |

Setting a low TTL (300 seconds) is recommended to allow for quicker failover if a VM becomes unavailable.

## Step 3: CouchDB Cluster Setup

SSH into the first VM and run:

```bash
ssh openedx@VM1_IP_ADDRESS
cd /home/openedx/openedx-ha/scripts
./setup-cluster.sh
```

This script will set up a CouchDB cluster across all three production VMs. Verify the cluster status:

```bash
curl -s http://admin:password@localhost:5984/_membership | jq
```

You should see all three nodes in the `cluster_nodes` list.

## Step 3.5: SSL Certificate Setup

With Caddy, SSL certificates are handled automatically:

1. Ensure your domain's DNS A records are pointing to all three production VMs
2. The first VM (primary node) will automatically obtain certificates
3. Wait approximately 5 minutes after deployment for certificate issuance
4. Verify certificate status:
   ```bash
   ssh openedx@VM1_IP_ADDRESS
   docker exec -it caddy caddy list-certs
   ```
5. Run the synchronization script to copy to other nodes:
   ```bash
   cd /home/openedx/openedx-ha/scripts
   ./sync-caddy-certs.sh
   ```

## Step 4: Verify Deployment

1. Check the status of all containers:
   ```bash
   docker ps
   ```

   You should see these containers running: caddy, lms, cms, couchdb, and watchtower

2. Verify the CouchDB cluster status:
   ```bash
   curl -s http://admin:password@localhost:5984/_membership | jq
   ```

3. Test the health check endpoint:
   ```bash
   curl -s https://your-domain.com/health
   ```
   
   It should respond with "OK"

4. Access the Open edX platform at:
   - LMS: https://your-domain.com
   - Studio: https://studio.your-domain.com

## Step 5: Configure Local Backup

On your local PC:

1. Copy the `backup/local/fetch-openedx-backup.sh` script
2. Edit it with your backup VM IP and SSH key path:
   ```bash
   # Edit these values
   BACKUP_VM_IP="your-backup-vm-ip"
   BACKUP_USER="backup-user"
   LOCAL_BACKUP_PATH="$HOME/openedx-backups"
   SSH_KEY="$HOME/.ssh/id_rsa"
   ```

3. Make it executable:
   ```bash
   chmod +x fetch-openedx-backup.sh
   ```

4. Run it to test:
   ```bash
   ./fetch-openedx-backup.sh
   ```

5. Set up a scheduled task to run this script regularly:
   - On Linux/Mac: Use crontab
   - On Windows: Use Task Scheduler

## Step 6: Configure Backup Rotation

SSH into the backup VM to verify that backup rotation is working correctly:

```bash
ssh openedx@BACKUP_VM_IP
ls -la /backup/daily/
ls -la /backup/weekly/
ls -la /backup/monthly/
```

Backup rotation is configured as follows:
- Daily backups: Kept for 7 days
- Weekly backups: Kept for 4 weeks
- Monthly backups: Kept for 12 months

## Step 7: Post-Deployment Configuration

### Configure Admin User

1. SSH into any production VM:
   ```bash
   ssh openedx@VM1_IP_ADDRESS
   ```

2. Create an admin user:
   ```bash
   docker exec -it lms bash -c "python /openedx/edx-platform/manage.py lms --settings=tutor.production createsuperuser"
   ```

3. Follow the prompts to create an admin username, email, and password.

### Customize Platform Name and Theme

1. Edit the configuration files:
   ```bash
   cd /home/openedx/openedx-ha/docker/config/lms
   vim config.yml  # Or use your preferred editor
   ```

2. Update the `PLATFORM_NAME` and other branding settings.

3. Restart the services:
   ```bash
   cd /home/openedx/openedx-ha/docker
   docker-compose restart lms cms
   ```

## Step 8: Health Check Verification

Ensure that the health check script is running correctly:

```bash
ssh openedx@VM1_IP_ADDRESS
cat /home/openedx/health-check.log
```

The script should be running every 5 minutes via cron and will automatically detect and fix common issues.

## Troubleshooting

If you encounter issues during deployment, refer to the [troubleshooting guide](troubleshooting.md) for common issues and solutions.

### Common Deployment Issues

1. **DNS not resolving**: Ensure DNS records are properly configured and have propagated
2. **CouchDB cluster not forming**: Check firewall settings and network connectivity between nodes
3. **Certificate issues**: Verify that port 80 and 443 are accessible from the internet
4. **Container startup failures**: Check container logs with `docker logs [container_name]`

## Next Steps

After successful deployment:

1. Review the [operations manual](operations.md) for day-to-day management
2. Test the backup and restore procedures as described in the [backup guide](backup.md)
3. Familiarize yourself with the [architecture overview](architecture.md) to understand the system

Congratulations! You now have a high-availability Open edX deployment.