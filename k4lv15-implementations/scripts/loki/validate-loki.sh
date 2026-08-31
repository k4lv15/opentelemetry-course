#!/bin/bash
# Script to validate Loki can receive, process and store logs
# Loki must be running on localhost:3100

set -e  # Exit on error

LOKI_URL="http://localhost:3100"
TEST_LABEL="test_app"
TEST_VALUE="loki_validation_test"

echo "=== Validating Loki Setup ==="
echo ""

# Step 1: Send test logs to Loki
echo "Step 1: Sending test logs to Loki..."
TIMESTAMP=$(date +%s%N)  # Current timestamp in nanoseconds

# Send a batch of test logs using Loki's push API
# Format: JSON with streams array containing labels and log entries
curl -X POST "${LOKI_URL}/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d "{
    \"streams\": [
      {
        \"stream\": {
          \"job\": \"${TEST_LABEL}\",
          \"environment\": \"${TEST_VALUE}\"
        },
        \"values\": [
          [\"${TIMESTAMP}\", \"Test log entry 1: Validation started\"],
          [\"$((TIMESTAMP + 1000000))\", \"Test log entry 2: Processing data\"],
          [\"$((TIMESTAMP + 2000000))\", \"Test log entry 3: Validation complete\"]
        ]
      }
    ]
  }"

echo "✓ Test logs sent successfully"
echo ""

# Step 2: Wait for Loki to process the logs
echo "Step 2: Waiting for Loki to process logs (3 seconds)..."
sleep 3
echo ""

# Step 3: Query Loki to verify logs are stored
echo "Step 3: Querying Loki to verify logs..."

# Query logs using LogQL (Loki's query language)
# {job="test_app"} selects all logs with job label equal to test_app
RESPONSE=$(curl -s -G "${LOKI_URL}/loki/api/v1/query_range" \
  --data-urlencode "query={job=\"${TEST_LABEL}\"}" \
  --data-urlencode "start=$((TIMESTAMP / 1000000000 - 60))" \
  --data-urlencode "end=$((TIMESTAMP / 1000000000 + 60))")

# Check if we got results
LOG_COUNT=$(echo "$RESPONSE" | jq -r '.data.result[0].values | length // 0')

if [ "$LOG_COUNT" -gt 0 ]; then
  echo "✓ Successfully retrieved $LOG_COUNT log entries from Loki"
  echo ""
  echo "Sample logs retrieved:"
  echo "$RESPONSE" | jq -r '.data.result[0].values[] | "  [\(.[0])] \(.[1])"' | head -5
  echo ""
  echo "=== VALIDATION SUCCESSFUL ==="
  echo "Loki is correctly receiving, processing, and storing logs!"
else
  echo "✗ VALIDATION FAILED: No logs found in Loki"
  echo "Response: $RESPONSE"
  exit 1
fi
