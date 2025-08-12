#!/bin/bash

LOG_TAG="solr_check"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SOLR_URL> <COLLECTION_NAME>"
    exit 1
fi

# Extract Solr URL and collection name from arguments
SOLR_URL="$1"
COLLECTION_NAME="$2"

# Set the log file path based on the collection name
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_FILE="$SCRIPT_DIR/check_status_${COLLECTION_NAME}.log"

echo "==========================================" >> "$LOG_FILE"

# Retrieve the status information from Solr using curl
response=$(curl -s $SOLR_URL/solr/admin/collections?action=CLUSTERSTATUS)

# Find cores in the 'recovering' state
recovering_count=$(echo $response | grep -o '"state":"recovering"' | wc -l)

# Find cores in the 'down' state
down_count=$(echo $response | grep -o '"state":"down"' | wc -l)

# Initialize status
status_ok=true

# Handle and log based on the status
if [ "$recovering_count" -gt 0 ]; then
    message="CRITICAL: $recovering_count core(s) are in recovering state on Solr instance $SOLR_URL, collection $COLLECTION_NAME"
    logger -t $LOG_TAG -p local0.err "$message"
    echo "$TIMESTAMP | $message" >> "$LOG_FILE"
    status_ok=false
fi

if [ "$down_count" -gt 0 ]; then
    message="CRITICAL: $down_count core(s) are in down state on Solr instance $SOLR_URL, collection $COLLECTION_NAME"
    logger -t $LOG_TAG -p local0.err "$message"
    echo "$TIMESTAMP | $message" >> "$LOG_FILE"
    status_ok=false
fi

# If all checks pass, log an OK status to the specified log file
if $status_ok; then
    message="Status=OK, Solr_URL=$SOLR_URL, Collection=$COLLECTION_NAME"
    echo "$TIMESTAMP | $message" >> "$LOG_FILE"
else
    message="Status=ERROR, Solr_URL=$SOLR_URL, Collection=$COLLECTION_NAME"
    echo "$TIMESTAMP | $message" >> "$LOG_FILE"
fi

echo "==========================================" >> "$LOG_FILE"

if $status_ok; then
    exit 0 # OK
else
    exit 2 # CRITICAL
fi
