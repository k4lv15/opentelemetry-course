# Loki Metrics - PromQL Queries

This document contains PromQL queries to monitor Loki metrics in Prometheus.
Access Prometheus at: http://localhost:9090

## Basic Loki Health Metrics

### 1. Loki Uptime
Check if Loki is up and running:
```promql
up{job="loki"}
```
**Expected Result:** `1` means Loki is up, `0` means down

---

## Ingestion Metrics

### 2. Log Ingestion Rate
Number of log lines ingested per second:
```promql
rate(loki_distributor_lines_received_total[5m])
```
**What it shows:** How many log lines Loki is receiving per second

### 3. Bytes Ingested Rate
Amount of log data (in bytes) ingested per second:
```promql
rate(loki_distributor_bytes_received_total[5m])
```
**What it shows:** The volume of log data being ingested

### 4. Log Streams in Memory
Current number of log streams in memory:
```promql
loki_ingester_memory_streams
```
**What it shows:** Each unique set of labels creates a stream. This shows streams currently held in memory

---

## Query Performance Metrics

### 5. Query Request Rate
Number of queries executed per second:
```promql
rate(loki_request_duration_seconds_count{route="loki_api_v1_query_range"}[5m])
```
**What it shows:** How frequently Loki is being queried

### 6. Query Latency (p99)
99th percentile query response time:
```promql
histogram_quantile(0.99, 
  rate(loki_request_duration_seconds_bucket{route="loki_api_v1_query_range"}[5m])
)
```
**What it shows:** Query performance - lower is better

### 7. Failed Queries
Rate of failed queries:
```promql
rate(loki_request_duration_seconds_count{route="loki_api_v1_query_range",status_code!~"2.."}[5m])
```
**What it shows:** Query errors - should be close to 0

---

## Storage Metrics

### 8. Chunk Creation Rate
Rate of chunks being created:
```promql
rate(loki_ingester_chunks_created_total[5m])
```
**What it shows:** Loki organizes logs into chunks for storage

### 9. Chunks Flushed
Rate of chunks being flushed to storage:
```promql
rate(loki_ingester_chunks_flushed_total[5m])
```
**What it shows:** How often data is persisted to disk

---

## Error Monitoring

### 10. Ingestion Errors
Rate of log ingestion errors:
```promql
rate(loki_distributor_lines_received_total{status="error"}[5m])
```
**What it shows:** Problems receiving logs - should be 0

### 11. Out of Order Samples
Logs rejected due to timestamp ordering issues:
```promql
rate(loki_discarded_samples_total{reason="out_of_order"}[5m])
```
**What it shows:** Logs with timestamps older than the most recent log in a stream

---

## Resource Usage

### 12. Memory Usage (if available)
```promql
process_resident_memory_bytes{job="loki"}
```
**What it shows:** Memory used by Loki process

### 13. CPU Usage (if available)
```promql
rate(process_cpu_seconds_total{job="loki"}[5m])
```
**What it shows:** CPU usage by Loki process

---

## How to Use These Queries

1. **In Prometheus UI (http://localhost:9090):**
   - Go to Graph tab
   - Copy and paste any query above
   - Click "Execute"
   - Switch between Table and Graph views

2. **In Grafana (http://localhost:3000):**
   - Create a new dashboard
   - Add a new panel
   - Select Prometheus as data source
   - Use these queries in the query editor

3. **Via API:**
   ```bash
   curl -G 'http://localhost:9090/api/v1/query' \
     --data-urlencode 'query=up{job="loki"}'
   ```

## Troubleshooting Tips

- **No metrics visible?** 
  - Check if Prometheus is scraping Loki: Look for `loki` target in http://localhost:9090/targets
  - Verify your prometheus.yml includes Loki as a scrape target

- **All queries return empty?**
  - Run the validation script first: `./validate-loki.sh`
  - This generates test logs which trigger metrics

- **Want to see metrics in real-time?**
  - Set range to `[1m]` instead of `[5m]` for faster updates
  - Use "Execute" repeatedly or enable auto-refresh in Prometheus UI
