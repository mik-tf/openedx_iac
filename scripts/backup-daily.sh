#!/bin/bash
set -e

source ../.env

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/daily/$DATE"
mkdir -p "$BACKUP_DIR"

echo "Starting daily backup at $(date)"

# Ensure backup directory exists and is writable
if [ ! -d "$BACKUP_DIR" ]; then
  echo "Creating backup directory: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create backup directory: $BACKUP_DIR"
    exit 1
  fi
fi

# Check if directory is writable
if [ ! -w "$BACKUP_DIR" ]; then
  echo "ERROR: Backup directory is not writable: $BACKUP_DIR"
  exit 1
fi

# Check for available disk space (require at least 5GB free)
FREE_SPACE=$(df -k "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE" -lt 5242880 ]; then  # 5GB in KB
  echo "ERROR: Insufficient disk space. Only $(($FREE_SPACE/1024))MB available on backup volume."
  exit 1
fi

# Get production node IPs
IFS=',' read -ra PROD_IPS <<< "${PRODUCTION_NODE_IPS}"

# Back up each production node
for NODE_IP in "${PROD_IPS[@]}"; do
  NODE_DIR="$BACKUP_DIR/node-$NODE_IP"
  mkdir -p "$NODE_DIR"
  
  echo "Backing up CouchDB databases from $NODE_IP"
  
  # Get list of databases
  DBS=$(curl -s -X GET "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_IP}:5984/_all_dbs")
  
  # Backup each database
  echo $DBS | jq -r '.[]' | while read -r db; do
    echo "Backing up database: $db"
    curl -s "http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@${NODE_IP}:5984/$db/_all_docs?include_docs=true" > "$NODE_DIR/${db}.json"
  done
  
  # Backup configuration
  echo "Backing up configuration files"
  ssh openedx@$NODE_IP "cd /home/openedx/openedx-ha && tar -czf - docker/ config/" > "$NODE_DIR/config.tar.gz"
  
  # Backup logs
  echo "Backing up logs"
  ssh openedx@$NODE_IP "cd /home/openedx && tar -czf - *.log" > "$NODE_DIR/logs.tar.gz"
done

# Create backup manifest
cat > "$BACKUP_DIR/backup_manifest.json" << EOF
{
  "backup_date": "$(date -Iseconds)",
  "backup_type": "daily",
  "nodes": [
    $(for ip in "${PROD_IPS[@]}"; do echo "\"$ip\","; done | sed '$s/,$//')
  ],
  "checksum": "$(find $BACKUP_DIR -type f -exec md5sum {} \; | sort | md5sum | cut -d' ' -f1)"
}
EOF

# Cleanup old backups (keep 7 days)
find /backup/daily -maxdepth 1 -type d -name "20*" -mtime +7 -exec rm -rf {} \;

echo "Daily backup completed at $(date)"