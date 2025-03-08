#!/bin/bash

# Load environment variables
source ../docker/.env

LOG_FILE="/home/openedx/health-checks.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Running health check" >> $LOG_FILE

# Check CouchDB
if ! curl -sf http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984/ > /dev/null; then
  echo "[$DATE] CouchDB is down, restarting..." >> $LOG_FILE
  docker restart couchdb
  sleep 10
fi

# Check CouchDB cluster status
CLUSTER_STATUS=$(curl -sf http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984/_membership)
if [ $? -ne 0 ]; then
  echo "[$DATE] Cannot check cluster status" >> $LOG_FILE
else
  NODE_COUNT=$(echo $CLUSTER_STATUS | jq '.cluster_nodes | length')
  if [ "$NODE_COUNT" -lt 3 ]; then
    echo "[$DATE] CouchDB cluster issue detected, nodes: $NODE_COUNT" >> $LOG_FILE
    # Alert could be added here
  fi
fi

# Check LMS
if ! curl -sf http://localhost:8000/heartbeat > /dev/null; then
  echo "[$DATE] LMS is down, restarting..." >> $LOG_FILE
  docker restart lms
  sleep 10
fi

# Check CMS
if ! curl -sf http://localhost:8001/heartbeat > /dev/null; then
  echo "[$DATE] CMS is down, restarting..." >> $LOG_FILE
  docker restart cms
  sleep 10
fi

# Check Caddy
if ! curl -sf http://localhost:80/health > /dev/null; then
  echo "[$DATE] Caddy is down, restarting..." >> $LOG_FILE
  docker restart caddy
fi

echo "[$DATE] Health check completed" >> $LOG_FILE