# Log Analytics Queries for CMS Monitoring

## Container App Performance Queries

### Query 1: Container App CPU and Memory Usage
```kusto
ContainerAppConsoleLogs
| where ContainerId == "cms-container-app"
| where MetricName in ("CpuUsage", "MemoryUsage")
| summarize AvgCPU = avg(iif(MetricName == "CpuUsage", MetricValue, 0)),
            AvgMemory = avg(iif(MetricName == "MemoryUsage", MetricValue, 0)),
            MaxCPU = max(iif(MetricName == "CpuUsage", MetricValue, 0)),
            MaxMemory = max(iif(MetricName == "MemoryUsage", MetricValue, 0))
            by bin(TimeGenerated, 5m)
| render timechart
```

### Query 2: Error Rate and Exception Count
```kusto
ContainerAppConsoleLogs
| where ContainerId == "cms-container-app"
| summarize TotalLogs = count(),
            ErrorCount = sum(iif(LogLevel == "ERROR", 1, 0)),
            WarningCount = sum(iif(LogLevel == "WARNING", 1, 0))
            by bin(TimeGenerated, 5m)
| extend ErrorRate = (ErrorCount * 100.0) / TotalLogs
| render timechart
```

### Query 3: Replica Scaling Events
```kusto
ContainerAppConsoleLogs
| where ContainerId == "cms-container-app"
| where LogMessage contains "scaled" or LogMessage contains "replica"
| project TimeGenerated, LogMessage, ReplicaCount
| render table
```

### Query 4: Response Time Analysis
```kusto
AppRequests
| where AppId == "cms-container-app"
| summarize AvgDuration = avg(Duration),
            P50Duration = percentile(Duration, 50),
            P95Duration = percentile(Duration, 95),
            P99Duration = percentile(Duration, 99),
            FailureCount = sum(iif(Success == false, 1, 0))
            by bin(TimeGenerated, 1m), Name
| render timechart
```

---

## Application Gateway Monitoring Queries

### Query 5: WAF Detections and Blocks
```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize BlockedCount = sum(iif(action_s == "Blocked", 1, 0)),
            LoggedCount = sum(iif(action_s == "Logged", 1, 0)),
            RuleCount = dcount(ruleId_s)
            by bin(TimeGenerated, 5m), action_s
| render barchart
```

### Query 6: Top Blocked IPs
```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| summarize BlockCount = count() by clientIp_s
| top 10 by BlockCount desc
| render barchart
```

### Query 7: Backend Health Status
```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayAccessLog"
| summarize TotalRequests = count(),
            SuccessfulRequests = sum(iif(httpStatus_d >= 200 and httpStatus_d < 400, 1, 0)),
            ErrorRequests = sum(iif(httpStatus_d >= 500, 1, 0)),
            AvgResponseTime = avg(timeTaken_d)
            by bin(TimeGenerated, 5m), backendStatus_s
| render timechart
```

### Query 8: Slow Requests Analysis
```kusto
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayAccessLog"
| where timeTaken_d > 5000  // Requests taking more than 5 seconds
| summarize SlowCount = count(),
            AvgTime = avg(timeTaken_d),
            MaxTime = max(timeTaken_d)
            by requestUri_s, httpMethod_s
| top 20 by SlowCount desc
| render table
```

---

## Storage Account Queries

### Query 9: Storage Operations
```kusto
StorageBlobLogs
| summarize OpCount = count(),
            AvgDuration = avg(DurationMs),
            ErrorCount = sum(iif(StatusCode >= 400, 1, 0))
            by bin(TimeGenerated, 1h), OperationName
| render timechart
```

### Query 10: Blob Upload/Download Activity
```kusto
StorageBlobLogs
| where OperationName in ("PutBlob", "GetBlob", "DeleteBlob")
| summarize Count = count(),
            TotalBytes = sum(ContentLength),
            AvgBytes = avg(ContentLength)
            by bin(TimeGenerated, 1h), OperationName
| render barchart
```

---

## Key Vault Queries

### Query 11: Key Vault Access Audit
```kusto
AzureDiagnostics
| where ResourceType == "KEYVAULTS"
| summarize AccessCount = count(),
            FailureCount = sum(iif(ResultSignature == "Unauthorized", 1, 0))
            by bin(TimeGenerated, 1h), OperationName, CallerIPAddress
| render table
```

### Query 12: Secret Access Activity
```kusto
AzureDiagnostics
| where ResourceType == "KEYVAULTS"
| where OperationName in ("VaultGet", "SecretGet", "CertificateGet")
| summarize AccessCount = count() by SecretName_s, CallerIPAddress
| top 20 by AccessCount desc
| render table
```

---

## Virtual Network Queries

### Query 13: Network Security Group Flow
```kusto
AzureNetworkAnalytics_CL
| summarize FlowCount = count(),
            BytesSent = sum(toslong(bytes_sent_d)),
            BytesReceived = sum(toslong(bytes_received_d))
            by bin(TimeGenerated, 1h), action_s
| render timechart
```

---

## Alert Threshold Recommendations

| Metric | Threshold | Severity | Action |
|--------|-----------|----------|--------|
| CPU Usage | > 80% | High | Scale up replicas |
| Memory Usage | > 80% | High | Increase memory allocation |
| Error Rate | > 5% | Critical | Investigate application logs |
| WAF Blocks | > 100/min | Warning | Review WAF rules |
| Response Time P95 | > 2000ms | Warning | Check backend health |
| Failed Requests | > 1% | Warning | Investigate failures |
| Storage Quota | > 80% | Warning | Clean up old data |
| Key Vault Access Failures | > 10/min | Critical | Investigate access issues |

---

## Dashboard Configuration

### Recommended Dashboard Sections

1. **Container App Health**
   - CPU Usage (%) - Timechart
   - Memory Usage (%) - Timechart
   - Replica Count - Gauge
   - Error Rate (%) - Gauge

2. **Application Gateway Performance**
   - Requests/sec - Timechart
   - Average Response Time - Gauge
   - WAF Blocked Requests - Counter
   - Backend Health Status - Table

3. **Security Monitoring**
   - WAF Blocks by IP - Top IPs
   - Key Vault Access - Activity log
   - Failed Logins - Counter

4. **Resource Utilization**
   - Storage Usage - Gauge
   - Database Connections - Gauge
   - Network I/O - Timechart

---

## Alert Rules Configuration

### Alert 1: High CPU Usage
```bash
az monitor metrics alert create \
  --resource-group rg-cms-prod-app \
  --name cms-high-cpu \
  --description "Container App CPU > 80%" \
  --scopes "/subscriptions/{subscription-id}/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app" \
  --condition "avg CpuUsage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Alert 2: High Error Rate
```bash
az monitor metrics alert create \
  --resource-group rg-cms-prod-app \
  --name cms-high-error-rate \
  --description "Error rate > 5%" \
  --scopes "/subscriptions/{subscription-id}/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app" \
  --condition "total Exceptions > 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Alert 3: WAF Attacks
```bash
az monitor metrics alert create \
  --resource-group rg-cms-prod-app \
  --name cms-waf-blocks \
  --description "WAF blocks > 100 in 5 minutes" \
  --scopes "/subscriptions/{subscription-id}/resourcegroups/rg-cms-prod-app/providers/microsoft.network/applicationgateways/cms-appgw" \
  --condition "total BlockedRequests > 100" \
  --window-size 5m \
  --evaluation-frequency 1m
```

---

## Query Performance Tips

1. **Always use time filters**: Queries are faster with `where TimeGenerated > ago(1d)`
2. **Avoid wildcards at start**: `| where LogMessage contains "error"` is better than `| where LogMessage contains "*error"`
3. **Use summarize for aggregation**: Reduces result set significantly
4. **Index commonly filtered fields**: LogLevel, ContainerId, OperationName
5. **Use bin() for grouping**: `bin(TimeGenerated, 5m)` groups results by 5-minute intervals

---

## Export Logs Periodically

```bash
# Export logs to CSV for archival
az monitor log-analytics workspace data-export create \
  --resource-group rg-cms-prod-app \
  --workspace-name cms-log-analytics \
  --name cms-logs-export \
  --tables ContainerAppConsoleLogs,AzureDiagnostics \
  --destination "/subscriptions/{subscription-id}/resourcegroups/rg-cms-prod-app/providers/microsoft.storage/storageaccounts/cmsstorage/blobServices/default/containers/log-exports"
```
