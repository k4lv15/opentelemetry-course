#!/bin/bash
# Script to cleanup test data from Loki
# This removes logs with the test labels created by validate-loki.sh

set -e  # Exit on error

LOKI_URL="http://localhost:3100"
TEST_LABEL="test_app"

echo "=== Cleaning up test data from Loki ==="
echo ""

# Calculate time range (last hour to cover test logs)
END_TIME=$(date +%s)
START_TIME=$((END_TIME - 3600))

echo "Deleting logs with job=\"${TEST_LABEL}\"..."
echo "Time range: Last hour"
echo ""

# Send delete request to Loki
# The delete API requires query parameters in the URL (not POST body)
# Timestamps should be in Unix seconds (not nanoseconds)
# API returns HTTP 204 No Content on success

# URL encode the query: {job="test_app"} -> %7Bjob%3D%22test_app%22%7D
QUERY_ENCODED="%7Bjob%3D%22${TEST_LABEL}%22%7D"

# Capture HTTP status code and response body
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${LOKI_URL}/loki/api/v1/delete?query=${QUERY_ENCODED}&start=${START_TIME}&end=${END_TIME}")

# Extract status code (last line) and body (everything else)
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

# Check response status - 204 No Content means success
if [ "$HTTP_CODE" = "204" ]; then
  echo "✓ Delete request sent successfully (HTTP 204)"
  echo ""
  echo "Note: Loki compactor will process the deletion in the background."
  echo "It may take a few minutes for logs to be fully removed."
  echo ""
  echo "To verify deletion, wait a few minutes and run:"
  echo "  curl -G \"${LOKI_URL}/loki/api/v1/query_range\" \\"
  echo "    --data-urlencode 'query={job=\"${TEST_LABEL}\"}' \\"
  echo "    --data-urlencode 'start=$((START_TIME))' \\"
  echo "    --data-urlencode 'end=$((END_TIME))'"
else
  echo "✗ Delete request failed (HTTP ${HTTP_CODE})"
  if [ -n "$RESPONSE_BODY" ]; then
    echo "Response: $RESPONSE_BODY"
  fi
  exit 1
fi

echo ""
echo "=== CLEANUP COMPLETED ==="
