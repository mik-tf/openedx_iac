"""
Production settings for CMS (Studio).
"""

import os
import sys
from cms.envs.production import *

# Add the custom storage path
sys.path.append('/openedx/custom')

# CouchDB connection settings from environment
COUCHDB_HOST = os.environ.get('COUCHDB_HOST', 'couchdb')
COUCHDB_PORT = int(os.environ.get('COUCHDB_PORT', 5984))
COUCHDB_USER = os.environ.get('COUCHDB_USER', 'admin')
COUCHDB_PASSWORD = os.environ.get('COUCHDB_PASSWORD', 'password')
COUCHDB_DB_NAME = os.environ.get('COUCHDB_DB_NAME', 'edxapp')

# CouchDB URL
COUCHDB_URL = f"http://{COUCHDB_USER}:{COUCHDB_PASSWORD}@{COUCHDB_HOST}:{COUCHDB_PORT}"

# Configure DocumentStore to use CouchDB
DOC_STORE_CONFIG = {
    'host': COUCHDB_HOST,
    'port': COUCHDB_PORT,
    'db': COUCHDB_DB_NAME,
    'user': COUCHDB_USER,
    'password': COUCHDB_PASSWORD,
}

# Enable CouchDB features
FEATURES['ENABLE_COUCHDB'] = True

# Import custom storage backend
from storage.couchdb_storage import CouchDBStorage  # noqa

# Configure file storage to use CouchDB
COUCHDB_STORAGE_OPTIONS = {
    'base_url': COUCHDB_URL,
    'db_name': f"{COUCHDB_DB_NAME}_files"
}

# Use CouchDB for all types of storage
DEFAULT_FILE_STORAGE = 'storage.couchdb_storage.CouchDBStorage'
COURSE_IMPORT_EXPORT_STORAGE = 'storage.couchdb_storage.CouchDBStorage'
VIDEO_TRANSCRIPTS_STORAGE = 'storage.couchdb_storage.CouchDBStorage'
GRADES_DOWNLOAD_STORAGE = 'storage.couchdb_storage.CouchDBStorage'

# Session configuration for HA
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

