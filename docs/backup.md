# Backup and Restore Guide

This document details the backup strategy and restore procedures.

## Backup Strategy Overview

Our backup strategy has three tiers:

1. **Production VM to Backup VM**: Daily automated backups
2. **Backup VM Rotation**: Daily → Weekly → Monthly retention
3. **Local PC Backup**: On-demand offline backups

## Server-Side Backup Configuration

The backup process is automated on the backup VM:

- **Daily backups**: Every day at 1:00 AM
- **Weekly retention**: Last 4 weeks
- **Monthly retention**: Last 12 months

### Backup Contents

Each backup includes:
- CouchDB database dumps
- Configuration files
- User-uploaded content
- System logs

## Local PC Backup

The local backup script pulls the latest backup from the backup VM to your local machine.

### Setup

1. Copy `backup/local/fetch-openedx-backup.sh` to your local machine
2. Edit with your backup VM IP and SSH key details
3. Make executable: `chmod +x fetch-openedx-backup.sh`

### Usage

```bash
./fetch-openedx-backup.sh
```

This will:
- Connect to the backup VM
- Download the latest backup
- Verify its integrity
- Store it locally with a date-based directory structure
- Remove old backups (keeping the latest 10)

## Restore Procedures

### Full System Restore

In case of catastrophic failure:

1. Deploy new infrastructure using OpenTofu
2. On each VM, restore configuration:
   ```bash
   cd /home/openedx
   # Copy backup files
   tar -xzvf backup_file.tar.gz
   cd openedx-ha
   docker-compose up -d
   ```

3. On the first VM, restore CouchDB data:
   ```bash
   cd /home/openedx/openedx-ha/scripts
   ./restore-couchdb.sh /path/to/backup
   ```

### Single VM Restore

If only one VM has failed:

1. Deploy a new VM using OpenTofu
2. Join it to the CouchDB cluster:
   ```bash
   cd /home/openedx/openedx-ha/scripts
   ./join-cluster.sh
   ```

CouchDB will automatically sync data from other nodes.

### Data-Only Restore

To restore just the data without rebuilding infrastructure:

```bash
cd /home/openedx/openedx-ha/scripts
./restore-data.sh /path/to/backup
```

## Backup Verification

It's recommended to verify backups regularly:

```bash
cd /home/openedx/openedx-ha/scripts
./verify-backup.sh /path/to/backup
```
## Catastrophic Recovery Preparation

While our multi-tier backup strategy provides robust data protection, it's essential to be prepared for worst-case scenarios where all cloud infrastructure is lost. The local PC backup is your last line of defense in such situations.

### Why Your Local Backup Is Critical

Your local PC backup contains everything needed to completely rebuild the Open edX platform, including:
- All course content and structure
- User data, enrollments, and progress
- System configurations and customizations
- Database schema and relationships

### Safeguarding Your Local Backup

To ensure your local backup remains viable for disaster recovery:

1. **Storage Security**: 
   - Store backups on an encrypted drive
   - Consider a secondary offline copy (external drive)
   - Protect backup media from physical damage and theft

2. **Verification**:
   - Regularly run the backup verification script:
     ```bash
     ./verify-backup.sh ~/openedx-backups/LATEST_DATE
     ```
   - Address any integrity issues immediately

3. **Documentation**:
   - Keep notes on any custom configurations made to your deployment
   - Store a copy of your infrastructure credentials securely
   - Document your domain registrar access

### Disaster Recovery Testing

We recommend conducting a disaster recovery test at least once per quarter:

1. Create a temporary test environment with reduced resources
2. Attempt to restore from your local backup
3. Verify application functionality
4. Document any issues encountered and their solutions

### Complete Disaster Recovery

In the event of total infrastructure loss, follow our comprehensive [Disaster Recovery Guide](disaster-recovery.md) which provides step-by-step instructions for rebuilding your entire platform from a local backup.

The time to establish your disaster recovery protocol is before you need it. Regular testing and preparation ensure that even in the worst-case scenario, your educational platform can be fully restored with minimal downtime.

## Emergency Contact Information

In case of critical failures, contact the website admin.

