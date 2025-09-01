#!/bin/bash

REGION="us-central1"
FUNCTION_NAME="url-downloader"
URL_FILE="urls.txt"

# Check if file exists
if [[ ! -f "$URL_FILE" ]]; then
  echo "❌ URL file '$URL_FILE' not found!"
  exit 1
fi

echo "📄 Reading URLs from $URL_FILE"

# Read each line (URL) from the file and call the function
while IFS= read -r url || [[ -n "$url" ]]; do
  if [[ -n "$url" ]]; then
    echo "🔁 Calling function for URL: $url"
    
    RESPONSE=$(gcloud functions call "$FUNCTION_NAME" \
      --region="$REGION" \
      --data="{\"urls\": [\"$url\"]}" 2>&1)

    echo "📨 Function response:"
    echo "$RESPONSE"
  else
    echo "⚠️ Skipping empty line"
  fi
done < "$URL_FILE"