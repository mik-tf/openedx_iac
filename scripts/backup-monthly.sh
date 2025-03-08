#!/bin/bash
set -e

MONTH=$(date +%Y-%m)
LATEST_WEEKLY=$(find /backup/weekly -maxdepth 1 -type d -name "20*" | sort -r | head -1)

if [ -z "$LATEST_WEEKLY" ]; then
  echo "No weekly backup found, cannot create monthly backup"
  exit 1
fi

echo "Creating monthly backup from $LATEST_WEEKLY"

# Create monthly backup directory
mkdir -p "/backup/monthly/$MONTH"

# Copy latest weekly backup
cp -a "$LATEST_WEEKLY"/* "/backup/monthly/$MONTH/"

# Update manifest
sed -i 's/"backup_type": "weekly"/"backup_type": "monthly"/' "/backup/monthly/$MONTH/backup_manifest.json"

# Cleanup old monthly backups (keep 12 months)
find /backup/monthly -maxdepth 1 -type d -mtime +365 -exec rm -rf {} \;

echo "Monthly backup completed"