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
echo "Step 1: Sending test logs to Loki with randomized levels and messages..."
TIMESTAMP=$(date +%s%N)  # Current timestamp in nanoseconds

# Define arrays for randomization
LOG_LEVELS=("debug" "info" "warn" "error")
LOG_MESSAGES=(
  "Application started successfully"
  "Processing user request"
  "Database connection established"
  "Cache hit for key"
  "API response time exceeded threshold"
  "Configuration loaded"
  "Memory usage normal"
  "Task completed"
  "Service health check passed"
  "Request validation failed"
)

# Generate random log entries grouped by level as separate streams
generate_log_streams() {
  local base_ts=$1
  local streams="["
  local first_stream=true
  
  # Generate 10 logs total, distributed across random levels
  declare -A level_logs
  
  for i in {0..9}; do
    local level="${LOG_LEVELS[$((RANDOM % ${#LOG_LEVELS[@]}))]}"
    local message="${LOG_MESSAGES[$((RANDOM % ${#LOG_MESSAGES[@]}))]}"
    local ts=$((base_ts + i * 1000000))  # 1ms apart
    
    # Append to the level's log array
    if [ -z "${level_logs[$level]}" ]; then
      level_logs[$level]="[\"${ts}\", \"${message} (id=${i})\"]"
    else
      level_logs[$level]="${level_logs[$level]},[\"${ts}\", \"${message} (id=${i})\"]"
    fi
  done
  
  # Build streams JSON for each level that has logs
  for level in "${!level_logs[@]}"; do
    if [ "$first_stream" = false ]; then
      streams+=","
    fi
    first_stream=false
    
    streams+="{\"stream\":{\"job\":\"${TEST_LABEL}\",\"environment\":\"${TEST_VALUE}\",\"level\":\"${level}\"},\"values\":[${level_logs[$level]}]}"
  done
  
  streams+="]"
  echo "$streams"
}

# Generate log streams
LOG_STREAMS=$(generate_log_streams "$TIMESTAMP")

# Send logs to Loki with level as a label in separate streams
curl -s -X POST "${LOKI_URL}/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d "{\"streams\": ${LOG_STREAMS}}"

echo "✓ Test logs sent successfully (10 entries with random levels and messages)"
echo ""

# Step 2: Wait for Loki to process the logs
echo "Step 2: Waiting for Loki to process logs (3 seconds)..."
sleep 3
echo ""

# Step 3: Query Loki to verify logs are stored
echo "Step 3: Querying Loki to verify logs..."

# Query logs using LogQL (Loki's query language)
# {job="test_app"} selects all logs with job label equal to test_app
# Adding limit=100 to ensure we get all our test logs
RESPONSE=$(curl -s -G "${LOKI_URL}/loki/api/v1/query_range" \
  --data-urlencode "query={job=\"${TEST_LABEL}\"}" \
  --data-urlencode "start=$((TIMESTAMP / 1000000000 - 60))" \
  --data-urlencode "end=$((TIMESTAMP / 1000000000 + 60))" \
  --data-urlencode "limit=100")

# Check if we got results
LOG_COUNT=$(echo "$RESPONSE" | jq -r '[.data.result[].values | length] | add // 0')

if [ "$LOG_COUNT" -gt 0 ]; then
  echo "✓ Successfully retrieved $LOG_COUNT log entries from Loki"
  echo ""
  echo "Sample logs retrieved (grouped by level):"
  echo "$RESPONSE" | jq -r '.data.result[] | "  Level: \(.stream.level)\n" + (.values[] | "    [\(.[0])] \(.[1])")' | head -20
  echo ""
  echo "=== VALIDATION SUCCESSFUL ==="
  echo "Loki is correctly receiving, processing, and storing logs with different levels!"
else
  echo "✗ VALIDATION FAILED: No logs found in Loki"
  echo "Response: $RESPONSE"
  exit 1
fi
