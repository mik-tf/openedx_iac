#!/bin/bash
# Local PC backup script for Open edX HA deployment

# Configuration - Edit these values
BACKUP_VM_IP="your-backup-vm-ip"
BACKUP_USER="backup-user"
LOCAL_BACKUP_PATH="$HOME/openedx-backups"
SSH_KEY="$HOME/.ssh/id_rsa"  # Path to your SSH key

# Create local directory structure
DATE=$(date +%Y%m%d)
mkdir -p "$LOCAL_BACKUP_PATH/$DATE"
mkdir -p "$LOCAL_BACKUP_PATH/logs"

# Log file
LOG_FILE="$LOCAL_BACKUP_PATH/logs/backup-$DATE.log"

echo "Starting OpenEdX backup pull at $(date)" | tee -a "$LOG_FILE"

# Test connection
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 "$BACKUP_USER@$BACKUP_VM_IP" "echo Connection successful"; then
    echo "ERROR: Cannot connect to backup VM" | tee -a "$LOG_FILE"
    exit 1
fi

# Get list of available backups
AVAILABLE_BACKUPS=$(ssh -i "$SSH_KEY" "$BACKUP_USER@$BACKUP_VM_IP" "ls -1 /backup/daily/")
if [ -z "$AVAILABLE_BACKUPS" ]; then
    echo "ERROR: No backups found on server" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Available backups:" | tee -a "$LOG_FILE"
echo "$AVAILABLE_BACKUPS" | tee -a "$LOG_FILE"

# Determine latest backup
LATEST_BACKUP=$(echo "$AVAILABLE_BACKUPS" | sort -r | head -1)
echo "Fetching latest backup: $LATEST_BACKUP" | tee -a "$LOG_FILE"

# Pull the backup using rsync
echo "Starting download..." | tee -a "$LOG_FILE"
rsync -avz --progress -e "ssh -i $SSH_KEY" \
    "$BACKUP_USER@$BACKUP_VM_IP:/backup/daily/$LATEST_BACKUP/" \
    "$LOCAL_BACKUP_PATH/$DATE/" \
    2>&1 | tee -a "$LOG_FILE"

# Verify backup integrity
if [ ! -f "$LOCAL_BACKUP_PATH/$DATE/backup_manifest.json" ]; then
    echo "WARNING: Backup may be incomplete, manifest file not found" | tee -a "$LOG_FILE"
else
    # Check if manifest contains the expected checksum
    MANIFEST_CHECKSUM=$(cat "$LOCAL_BACKUP_PATH/$DATE/backup_manifest.json" | jq -r '.checksum')
    
    # Calculate checksum of downloaded files (excluding the manifest itself)
    find "$LOCAL_BACKUP_PATH/$DATE" -type f -not -name "backup_manifest.json" -exec md5sum {} \; | sort | md5sum | cut -d' ' -f1 > "$LOCAL_BACKUP_PATH/$DATE/calculated_checksum.txt"
    CALCULATED_CHECKSUM=$(cat "$LOCAL_BACKUP_PATH/$DATE/calculated_checksum.txt")
    
    if [ "$MANIFEST_CHECKSUM" != "$CALCULATED_CHECKSUM" ]; then
        echo "WARNING: Backup integrity check failed! Checksums don't match" | tee -a "$LOG_FILE"
        echo "  Manifest checksum: $MANIFEST_CHECKSUM" | tee -a "$LOG_FILE"
        echo "  Calculated checksum: $CALCULATED_CHECKSUM" | tee -a "$LOG_FILE"
    else
        echo "Backup verification passed" | tee -a "$LOG_FILE"
    fi
fi

# Cleanup old local backups (keep last 10)
find "$LOCAL_BACKUP_PATH" -maxdepth 1 -type d -name "20*" | sort | head -n -10 | xargs -r rm -rf
echo "Cleaned up old backups, keeping most recent 10" | tee -a "$LOG_FILE"

echo "Backup completed at $(date)" | tee -a "$LOG_FILE"
echo "Backup stored in: $LOCAL_BACKUP_PATH/$DATE" | tee -a "$LOG_FILE"