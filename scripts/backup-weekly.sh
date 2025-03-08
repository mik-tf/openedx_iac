#!/bin/bash
set -e

WEEK=$(date +%Y-week%U)
LATEST_DAILY=$(find /backup/daily -maxdepth 1 -type d -name "20*" | sort -r | head -1)

if [ -z "$LATEST_DAILY" ]; then
  echo "No daily backup found, cannot create weekly backup"
  exit 1
fi

echo "Creating weekly backup from $LATEST_DAILY"

# Create weekly backup directory
mkdir -p "/backup/weekly/$WEEK"

# Copy latest daily backup
cp -a "$LATEST_DAILY"/* "/backup/weekly/$WEEK/"

# Update manifest
sed -i 's/"backup_type": "daily"/"backup_type": "weekly"/' "/backup/weekly/$WEEK/backup_manifest.json"

# Cleanup old weekly backups (keep 4 weeks)
find /backup/weekly -maxdepth 1 -type d -mtime +28 -exec rm -rf {} \;

echo "Weekly backup completed"