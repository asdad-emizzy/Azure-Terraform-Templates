#!/bin/bash
# Load Testing Script for CMS Application
# Tests performance and scalability via Azure Front Door
# Usage: ./load-test.sh [duration_seconds] [concurrent_users]

set -e

# Configuration
DOMAIN="${1:-cms.example.com}"
DURATION="${2:-300}"
CONCURRENT="${3:-50}"
RESULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/load-test-results/$(date +%Y%m%d_%H%M%S)"

# Create results directory
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "CMS Load Testing"
echo "=========================================="
echo "Domain: https://$DOMAIN"
echo "Duration: ${DURATION}s"
echo "Concurrent Users: $CONCURRENT"
echo "Results Directory: $RESULTS_DIR"
echo ""

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 is not installed. Please install it first."
        echo "macOS: brew install $1"
        return 1
    fi
}

echo "Checking dependencies..."
check_tool "ab" || { echo "Install Apache Bench: brew install httpd"; exit 1; }
check_tool "curl" || { echo "Install curl: brew install curl"; exit 1; }

echo "✓ All dependencies available"
echo ""

# Pre-test: Health check
echo "Running health check..."
if curl -s -k -I "https://$DOMAIN/health" | grep -q "200\|OK"; then
    echo "✓ Application is healthy"
else
    echo "⚠ Application health check failed, continuing anyway..."
fi
echo ""

# Test 1: Homepage Load Test
echo "Test 1: Load testing homepage (/)..."
echo "Request count: 1000, Concurrency: $CONCURRENT"
ab -n 1000 -c "$CONCURRENT" -g "$RESULTS_DIR/homepage-results.tsv" "https://$DOMAIN/" \
    | tee "$RESULTS_DIR/homepage-results.txt"

# Test 2: Dashboard Load Test
echo ""
echo "Test 2: Load testing dashboard (/dashboard)..."
ab -n 1000 -c "$CONCURRENT" -g "$RESULTS_DIR/dashboard-results.tsv" "https://$DOMAIN/dashboard" \
    | tee "$RESULTS_DIR/dashboard-results.txt"

# Test 3: API Load Test
echo ""
echo "Test 3: Load testing API endpoint (/api/articles)..."
ab -n 1000 -c "$CONCURRENT" -g "$RESULTS_DIR/api-results.tsv" "https://$DOMAIN/api/articles" \
    | tee "$RESULTS_DIR/api-results.txt"

# Test 4: Sustained Load Test (longer duration)
echo ""
echo "Test 4: Sustained load test (${DURATION}s)..."
echo "This test will run for $DURATION seconds with $CONCURRENT concurrent users"

# Calculate number of requests for sustained load
# Approximately 100 requests/second baseline
TOTAL_REQUESTS=$((DURATION * 100))

ab -t "$DURATION" -c "$CONCURRENT" -g "$RESULTS_DIR/sustained-load.tsv" "https://$DOMAIN/" \
    | tee "$RESULTS_DIR/sustained-load.txt"

echo ""
echo "=========================================="
echo "Load Testing Completed"
echo "=========================================="
echo ""

# Generate summary report
echo "Generating summary report..."
REPORT="$RESULTS_DIR/LOAD_TEST_REPORT.md"

cat > "$REPORT" << 'EOFMD'
# CMS Load Test Report

**Generated**: $(date)
**Domain Tested**: $DOMAIN
**Test Duration**: $DURATION seconds
**Concurrent Users**: $CONCURRENT

## Test Results Summary

### Test 1: Homepage (/)
- Total Requests: 1000
- Concurrency: $CONCURRENT
- See: homepage-results.txt

### Test 2: Dashboard (/dashboard)
- Total Requests: 1000
- Concurrency: $CONCURRENT
- See: dashboard-results.txt

### Test 3: API (/api/articles)
- Total Requests: 1000
- Concurrency: $CONCURRENT
- See: api-results.txt

### Test 4: Sustained Load
- Duration: $DURATION seconds
- Concurrency: $CONCURRENT
- See: sustained-load.txt

## Performance Metrics to Review

From the Apache Bench output, look for:
1. **Requests per second** (higher is better)
2. **Time per request** (lower is better)
3. **Failed requests** (should be 0)
4. **Connection times**:
   - Connect: Time to establish connection
   - Processing: Server processing time
   - Total: End-to-end response time

## Azure Monitoring

During and after tests, check:

1. **Container App Metrics**:
   ```bash
   az monitor metrics list \
     --resource /subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app \
     --metric CpuUsage,MemoryUsage \
     --start-time 2024-01-01T00:00:00Z \
     --interval PT1M
   ```

2. **Auto-scaling Events**:
   ```bash
   az containerapp replica list \
     --name cms-container-app \
     --resource-group rg-cms-prod-app
   ```

3. **Application Gateway Metrics**:
   ```bash
   az monitor metrics list \
     --resource /subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.network/applicationgateways/cms-appgw \
     --metric BytesSent,BytesReceived,BackendResponseTime \
     --start-time 2024-01-01T00:00:00Z
   ```

4. **WAF Detections**:
   ```bash
   az monitor metrics list \
     --resource /subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.network/applicationgateways/cms-appgw \
     --metric BlockedRequests \
     --start-time 2024-01-01T00:00:00Z
   ```

## Recommendations

- **If CPU > 80%**: Increase Container App max replicas or CPU allocation
- **If Memory > 80%**: Increase memory allocation per replica
- **If Response Time > 2s**: Consider enabling Front Door caching
- **If WAF Blocks > 0**: Review WAF rules for false positives

## Next Steps

1. Review individual test result files (*.txt, *.tsv)
2. Check Azure Monitor dashboards
3. Adjust infrastructure if needed
4. Re-run tests to verify improvements
5. Document baseline performance metrics

EOFMD

echo "✓ Report generated: $REPORT"

# Display key statistics from first test
echo ""
echo "=========================================="
echo "Key Metrics from Homepage Test"
echo "=========================================="
echo ""
if [ -f "$RESULTS_DIR/homepage-results.txt" ]; then
    grep -E "Requests per second|Time per request|Failed requests|Connection Times" \
        "$RESULTS_DIR/homepage-results.txt" || echo "Results file generated but metrics extraction unavailable"
fi

echo ""
echo "All results saved to: $RESULTS_DIR"
echo "View detailed report: open $REPORT"
