"""
CouchDB storage backend for Open edX.
Allows storing files in CouchDB database for high availability.
"""
import os
import base64
import urllib.parse
from io import BytesIO

import requests
from django.conf import settings
from django.core.files.storage import Storage
from django.core.files.base import ContentFile


class CouchDBStorage(Storage):
    """
    CouchDB storage backend for Django.
    """
    def __init__(self, **kwargs):
        self.base_url = kwargs.get('base_url', getattr(settings, 'COUCHDB_URL', 'http://localhost:5984'))
        self.db_name = kwargs.get('db_name', getattr(settings, 'COUCHDB_DB_NAME', 'edxapp_files'))
        self.username = kwargs.get('username', getattr(settings, 'COUCHDB_USER', 'admin'))
        self.password = kwargs.get('password', getattr(settings, 'COUCHDB_PASSWORD', 'password'))
        
        # Create DB if it doesn't exist
        self._create_db_if_not_exists()
        
    def _create_db_if_not_exists(self):
        """Create the database if it doesn't exist."""
        auth = (self.username, self.password)
        db_url = f"{self.base_url}/{self.db_name}"
        response = requests.head(db_url, auth=auth)
        
        if response.status_code == 404:
            requests.put(db_url, auth=auth)

    def _get_document_url(self, name):
        """Get the URL for a document."""
        encoded_name = urllib.parse.quote(name, safe='')
        return f"{self.base_url}/{self.db_name}/{encoded_name}"
        
    def _save(self, name, content):
        """
        Save file content to CouchDB.
        """
        content.seek(0)
        file_data = content.read()
        encoded_data = base64.b64encode(file_data).decode('utf-8')
        
        auth = (self.username, self.password)
        document = {
            '_id': name,
            'content_type': getattr(content, 'content_type', 'application/octet-stream'),
            'data': encoded_data
        }
        
        url = self._get_document_url(name)
        response = requests.head(url, auth=auth)
        
        if response.status_code == 200:
            # Document exists, get rev
            rev = response.headers.get('ETag', '').strip('"')
            document['_rev'] = rev
        
        requests.put(
            url,
            auth=auth,
            json=document
        )
        
        return name
        
    def _open(self, name, mode='rb'):
        """
        Retrieve file from CouchDB.
        """
        auth = (self.username, self.password)
        url = self._get_document_url(name)
        
        response = requests.get(url, auth=auth)
        if response.status_code == 200:
            data = response.json().get('data', '')
            file_data = base64.b64decode(data)
            return ContentFile(file_data, name=name)
        else:
            raise FileNotFoundError(f"File {name} does not exist")
            
    def exists(self, name):
        """
        Check if file exists in CouchDB.
        """
        auth = (self.username, self.password)
        url = self._get_document_url(name)
        
        response = requests.head(url, auth=auth)
        return response.status_code == 200
        
    def delete(self, name):
        """
        Delete file from CouchDB.
        """
        auth = (self.username, self.password)
        url = self._get_document_url(name)
        
        response = requests.head(url, auth=auth)
        if response.status_code == 200:
            rev = response.headers.get('ETag', '').strip('"')
            delete_url = f"{url}?rev={rev}"
            requests.delete(delete_url, auth=auth)
            
    def url(self, name):
        """
        Return URL where the file can be accessed.
        """
        return f"{self.base_url}/{self.db_name}/{urllib.parse.quote(name, safe='')}/data"