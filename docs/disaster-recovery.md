# Disaster Recovery Guide

This guide outlines procedures for recovering your Open edX platform in case of catastrophic infrastructure failure.

## Complete Infrastructure Loss Recovery

Use this procedure when all VMs (both production and backup) are lost, but you have local PC backups available.

### Prerequisites
- Latest local backup (fetched using `fetch-openedx-backup.sh`)
- Hetzner Cloud API token
- OpenTofu/Terraform installed on local machine
- Original domain name access

### Step 1: Redeploy Infrastructure
```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
tofu init
tofu apply
```

### Step 2: Prepare Backup for Restore
```bash
# Identify your latest local backup
LATEST_BACKUP=$(find ~/openedx-backups -maxdepth 1 -type d -name "20*" | sort -r | head -1)

# Copy to new backup VM
scp -r $LATEST_BACKUP backup-user@NEW_BACKUP_VM_IP:/tmp/restore
```

### Step 3: Restore Database and Configuration
```bash
# SSH to backup VM
ssh openedx@NEW_BACKUP_VM_IP

# Run restore script
cd /home/openedx/openedx-ha/scripts
./restore-data.sh /tmp/restore
```

### Step 4: Set Up CouchDB Cluster
```bash
# On first production VM
ssh openedx@FIRST_VM_IP
cd /home/openedx/openedx-ha/scripts
./setup-cluster.sh
```

### Step 5: Verify Restoration
- Access LMS at https://yourdomain.com
- Access Studio at https://studio.yourdomain.com
- Login with admin credentials
- Check that courses, users, and content are restored

### Recovery Verification Checklist
- [ ] All VMs accessible via SSH
- [ ] CouchDB cluster formed successfully
- [ ] LMS and Studio accessible via web browser
- [ ] Admin login works
- [ ] Course content is visible
- [ ] User data is restored
- [ ] File uploads are accessible

## Emergency Contacts

If you need emergency assistance with recovery, contact the website admin.