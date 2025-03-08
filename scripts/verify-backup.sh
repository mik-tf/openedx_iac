#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <backup_directory>"
  exit 1
fi

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Backup directory not found: $BACKUP_DIR"
  exit 1
fi

echo "Verifying backup integrity in $BACKUP_DIR"

# Check manifest file
if [ ! -f "$BACKUP_DIR/backup_manifest.json" ]; then
  echo "ERROR: Manifest file not found"
  exit 1
fi

# Verify manifest structure
if ! jq -e . "$BACKUP_DIR/backup_manifest.json" > /dev/null; then
  echo "ERROR: Manifest file is not valid JSON"
  exit 1
fi

# Check backup date
BACKUP_DATE=$(jq -r '.backup_date' "$BACKUP_DIR/backup_manifest.json")
echo "Backup date: $BACKUP_DATE"

# Check backup type
BACKUP_TYPE=$(jq -r '.backup_type' "$BACKUP_DIR/backup_manifest.json")
echo "

