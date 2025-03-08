#!/bin/bash
set -e

source ../.env

if [ $# -ne 1 ]; then
  echo "Usage: $0 <backup_directory>"
  exit 1
fi

BACKUP_DIR="$1"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Backup directory not found: $BACKUP_DIR"
  exit 1
fi

# Basic validation of backup content
echo "Validating backup integrity..."

# Check for manifest file
if [ ! -f "$BACKUP_DIR/backup_manifest.json" ]; then
  echo "ERROR: No backup manifest found. This doesn't appear to be a valid backup."
  exit 1
fi

# Verify backup type and date
BACKUP_TYPE=$(jq -r '.backup_type' "$BACKUP_DIR/backup_manifest.json" 2>/dev/null)
BACKUP_DATE=$(jq -r '.backup_date' "$BACKUP_DIR/backup_manifest.json" 2>/dev/null)

if [ -z "$BACKUP_TYPE" ] || [ -z "$BACKUP_DATE" ]; then
  echo "ERROR: Manifest is missing required fields."
  exit 1
fi

echo "Backup type: $BACKUP_TYPE"
echo "Backup date: $BACKUP_DATE"

# Check for database files
DB_FILES=$(find "$BACKUP_DIR" -name "*.json" | wc -l)
if [ "$DB_FILES" -eq 0 ]; then
  echo "ERROR: No database files found in backup."
  exit 1
fi
echo "Found $DB_FILES database files."

# Verify checksum if present in manifest
if jq -e '.checksum' "$BACKUP_DIR/backup_manifest.json" >/dev/null 2>&1; then
  MANIFEST_CHECKSUM=$(jq -r '.checksum' "$BACKUP_DIR/backup_manifest.json")
  echo "Verifying backup checksum..."
  
  # Calculate actual checksum of files (excluding manifest)
  CALCULATED_CHECKSUM=$(find "$BACKUP_DIR" -type f -not -name "backup_manifest.json" -exec md5sum {} \; | sort | md5sum | cut -d' ' -f1)
  
  if [ "$MANIFEST_CHECKSUM" != "$CALCULATED_CHECKSUM" ]; then
    echo "WARNING: Backup checksum verification failed!"
    echo "Expected: $MANIFEST_CHECKSUM"
    echo "Actual:   $CALCULATED_CHECKSUM"
    
    read -p "Continue with restore despite checksum mismatch? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Restore cancelled."
      exit 1
    fi
  else
    echo "Checksum verification passed."
  fi
fi

echo "Backup validation complete. Proceeding with restore..."

echo "Restoring CouchDB data from $BACKUP_DIR"

# Find all JSON files (database dumps)
find "$BACKUP_DIR" -name "*.json" | while read -r db_file; do
  db_name=$(basename "$db_file" .json)
  echo "Restoring database: $db_name"
  
  # Create database if it doesn't exist
  curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984/$db_name" || true
  
  # Extract documents and insert them
  cat "$db_file" | jq -c '.rows[] | .doc' | while read -r doc; do
    # Skip design documents for now
    if [[ $(echo "$doc" | jq -r '._id') != _design* ]]; then
      echo "$doc" | curl -X POST "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984/$db_name" -H "Content-Type: application/json" -d @-
    fi
  done
  
  # Now handle design documents
  cat "$db_file" | jq -c '.rows[] | .doc' | while read -r doc; do
    if [[ $(echo "$doc" | jq -r '._id') == _design* ]]; then
      doc_id=$(echo "$doc" | jq -r '._id')
      echo "Restoring design document: $doc_id"
      echo "$doc" | curl -X PUT "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984/$db_name/$doc_id" -H "Content-Type: application/json" -d @-
    fi
  done
done

echo "CouchDB restore completed"