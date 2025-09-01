import os
import requests
from google.cloud import storage
from urllib.parse import urlparse
import functions_framework
import json
import logging
import zipfile
import io
from pathlib import Path
import uuid

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@functions_framework.http
def download_url_to_gcs(request):
    """Downloads files from URLs directly to GCS bucket. Auto-extracts .zip files."""
    
    try:
        # Parse request
        request_json = request.get_json(silent=True)
        if not request_json:
            return {"error": "No JSON payload provided"}, 400
            
        urls = request_json.get('urls', [])
        folder = request_json.get('folder', '')
        
        if not urls:
            return {"error": "No URLs provided"}, 400
        
        bucket_name = os.environ['BUCKET_NAME']
        client = storage.Client()
        bucket = client.bucket(bucket_name)
        
        results = []
        
        for url in urls:
            try:
                logger.info(f"Downloading: {url}")
                
                # Stream download from URL
                response = requests.get(url, stream=True, timeout=60)
                response.raise_for_status()
                
                # File name from url
                parsed_url = urlparse(url)
                filename = os.path.basename(parsed_url.path.rstrip('/')) or f"file_{uuid.uuid4().hex}"

                # Upload from stream without loading into memory
                blob_name = f"{folder}{filename}" if folder else filename
                blob = bucket.blob(blob_name)
                blob.upload_from_file(response.raw, rewind=False)

                results.append({
                    "url": url,
                    "filename": filename,
                    "type": "file",
                    "gcs_path": f"gs://{bucket_name}/{blob_name}",
                    "status": "success"
                })
                
                logger.info(f"Successfully uploaded: {blob_name}")
                
            except Exception as e:
                error_msg = f"Failed to download {url}: {str(e)}"
                logger.error(error_msg)
                results.append({
                    "url": url,
                    "status": "error",
                    "error": str(e)
                })
        
        return {"results": results}, 200
        
    except Exception as e:
        logger.error(f"Function error: {str(e)}")
        return {"error": str(e)}, 500