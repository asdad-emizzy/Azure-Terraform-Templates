# CMS Deployment Implementation Guide

This document provides step-by-step instructions to complete all 7 deployment items for the Azure CMS Infrastructure.

---

## 1. Customize Container Image

### Status: Ready to Build
The custom Node.js/Express CMS application is complete at `/cms/app/`

### Build & Push to Azure Container Registry

#### Prerequisites
- Docker Desktop installed and running
- Azure CLI (`az`) installed
- Azure subscription with Container Registry

#### Steps

**Step 1: Create Azure Container Registry**
```bash
# Create ACR
az acr create \
  --resource-group rg-cms-prod-app \
  --name cmsregistry \
  --sku Basic

# Get registry URL
REGISTRY_URL=$(az acr list-endpoints \
  --resource-group rg-cms-prod-app \
  --name cmsregistry \
  --query loginServer \
  --output tsv)

echo "Registry URL: $REGISTRY_URL"
```

**Step 2: Build Docker Image**
```bash
# Build locally
cd /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/app
docker build -t cms-app:1.0.0 .

# Tag for registry
docker tag cms-app:1.0.0 $REGISTRY_URL/cms-app:1.0.0
```

**Step 3: Authenticate and Push**
```bash
# Login to ACR
az acr login --name cmsregistry

# Push image
docker push $REGISTRY_URL/cms-app:1.0.0

# Verify push
az acr repository list --name cmsregistry
az acr repository show-tags --name cmsregistry --repository cms-app
```

**Step 4: Update Terraform**

Edit `/cms/main.tf` - Container App module:
```terraform
module "container_app" {
  source                       = "../modules/terraform-azurerm-container-app"
  name                         = "cms-container-app"
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  container_app_environment_id = module.container_app_environment.id
  
  # UPDATED: Use custom image from ACR
  image                        = "${REGISTRY_URL}/cms-app:1.0.0"
  
  cpu                          = "0.25"
  memory                       = "0.5Gi"
  min_replicas                 = 1
  max_replicas                 = 3
  
  # Enable container registry credentials
  registry_url                 = REGISTRY_URL
  registry_username            = "cmsregistry"
  registry_password            = data.azurerm_container_registry.acr.admin_password
  
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Add data source for registry
data "azurerm_container_registry" "acr" {
  name                = "cmsregistry"
  resource_group_name = module.resource_group.name
}
```

---

## 2. Configure SSL Certificate

### Option A: Self-Signed Certificate (Development)

**Step 1: Generate Self-Signed Certificate**
```bash
# Create certificate directory
mkdir -p /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates

# Generate self-signed certificate (valid for 365 days)
openssl req -new -x509 -days 365 -nodes \
  -out /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms.crt \
  -keyout /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms.key \
  -subj "/C=US/ST=CA/L=San Francisco/O=CMS/CN=cms.example.com"

# Create PFX format for Azure (combines cert + key)
openssl pkcs12 -export \
  -in /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms.crt \
  -inkey /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms.key \
  -out /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms.pfx \
  -passout pass:AzureCMS2024!
```

**Step 2: Upload to Key Vault**
```bash
# Upload certificate to Key Vault
az keyvault certificate import \
  --vault-name cms-keyvault \
  --name cms-certificate \
  --file /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms.pfx \
  --password "AzureCMS2024!"

# Verify upload
az keyvault certificate show \
  --vault-name cms-keyvault \
  --name cms-certificate
```

### Option B: Production Certificate (Let's Encrypt)

**Step 1: Install Certbot**
```bash
# macOS
brew install certbot

# Verify installation
certbot --version
```

**Step 2: Generate Production Certificate**
```bash
# Generate certificate (requires domain ownership verification)
certbot certonly --manual \
  --preferred-challenges dns \
  -d cms.example.com \
  -d www.cms.example.com

# Update Azure DNS records as prompted
```

**Step 3: Convert and Upload**
```bash
# Convert to PFX
openssl pkcs12 -export \
  -in /etc/letsencrypt/live/cms.example.com/fullchain.pem \
  -inkey /etc/letsencrypt/live/cms.example.com/privkey.pem \
  -out /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms-prod.pfx \
  -passout pass:AzureCMS2024!

# Upload to Key Vault
az keyvault certificate import \
  --vault-name cms-keyvault \
  --name cms-certificate-prod \
  --file /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/certificates/cms-prod.pfx \
  --password "AzureCMS2024!"
```

**Step 3: Update Terraform (Application Gateway)**

Add to `application_gateway` module:
```terraform
module "application_gateway" {
  # ... existing config ...
  
  # Configure SSL
  ssl_certificate_key_vault_secret_id = "${module.key_vault.vault_uri}secrets/cms-certificate/"
  
  # OR for production
  ssl_certificate_key_vault_secret_id = "${module.key_vault.vault_uri}secrets/cms-certificate-prod/"
}
```

---

## 3. Set Up DNS

### Configure Azure DNS Zone

**Step 1: Get Azure Nameservers**
```bash
# Get nameservers assigned to your DNS zone
az network dns zone show \
  --resource-group rg-cms-prod-app \
  --name cms.example.com \
  --query nameServers \
  --output json

# Output example:
# [
#   "ns1-ABC.azure-dns.com.",
#   "ns2-ABC.azure-dns.net.",
#   "ns3-ABC.azure-dns.org.",
#   "ns4-ABC.azure-dns.info."
# ]
```

**Step 2: Configure Domain Registrar**

At your domain registrar (GoDaddy, Namecheap, etc.):
1. Log in to your domain settings
2. Find "Name Servers" or "DNS Settings"
3. Replace existing nameservers with Azure DNS nameservers
4. Save changes (may take 24-48 hours to propagate)

**Step 3: Create DNS Records**

```bash
# Create A record for www subdomain
az network dns record-set a create \
  --resource-group rg-cms-prod-app \
  --zone-name cms.example.com \
  --name www \
  --ttl 300

az network dns record-set a add-record \
  --resource-group rg-cms-prod-app \
  --zone-name cms.example.com \
  --record-set-name www \
  --ipv4-address <FRONT_DOOR_IP>

# Create CNAME for root domain (optional)
az network dns record-set cname create \
  --resource-group rg-cms-prod-app \
  --zone-name cms.example.com \
  --name @ \
  --ttl 300

az network dns record-set cname set-record \
  --resource-group rg-cms-prod-app \
  --zone-name cms.example.com \
  --record-set-name @ \
  --cname <FRONT_DOOR_ENDPOINT>

# Verify DNS records
az network dns record-set list \
  --resource-group rg-cms-prod-app \
  --zone-name cms.example.com

# Test DNS resolution
nslookup www.cms.example.com
```

**Step 4: Update Terraform DNS Module**

Edit DNS module in `/cms/main.tf`:
```terraform
module "dns" {
  source              = "../modules/terraform-azurerm-dns"
  name                = "cms.example.com"
  resource_group_name = module.resource_group.name
  
  # Update with Front Door endpoint
  cname_records = [
    {
      name   = "www"
      ttl    = 300
      record = module.frontdoor.endpoint_hostname
    }
  ]
  
  # Optional: apex domain (if using A record)
  a_records = [
    {
      name    = "@"
      ttl     = 300
      records = [azurerm_public_ip.appgw.ip_address]
    }
  ]
  
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}
```

---

## 4. Storage Configuration

### Create Blob Containers and CDN Setup

**Step 1: Create Blob Containers**
```bash
# Get storage account connection string
STORAGE_CONN=$(az storage account show-connection-string \
  --resource-group rg-cms-prod-app \
  --name cmsstorage \
  --query connectionString \
  --output tsv)

# Create containers
az storage container create \
  --name uploads \
  --connection-string "$STORAGE_CONN"

az storage container create \
  --name static \
  --connection-string "$STORAGE_CONN"

az storage container create \
  --name backups \
  --connection-string "$STORAGE_CONN"

# List containers
az storage container list \
  --connection-string "$STORAGE_CONN" \
  --query [].name
```

**Step 2: Configure Storage as CDN Origin**
```bash
# Get storage account primary endpoint
STORAGE_ENDPOINT=$(az storage account show \
  --resource-group rg-cms-prod-app \
  --name cmsstorage \
  --query primaryEndpoints.blob \
  --output tsv)

# Create CDN endpoint
az cdn endpoint create \
  --resource-group rg-cms-prod-app \
  --profile-name cms-frontdoor \
  --name cms-storage-cdn \
  --origin "$STORAGE_ENDPOINT" \
  --origin-host-header "cmsstorage.blob.core.windows.net"
```

**Step 3: Upload Sample Files**
```bash
# Create local test file
echo "CMS Static Content - Test" > /tmp/test.html

# Upload to static container
az storage blob upload \
  --container-name static \
  --name index.html \
  --file /tmp/test.html \
  --connection-string "$STORAGE_CONN"

# Set cache control headers
az storage blob update \
  --container-name static \
  --name index.html \
  --cache-control "max-age=3600" \
  --connection-string "$STORAGE_CONN"
```

**Step 4: Update Terraform Storage Module**

Add to storage account configuration:
```terraform
# Create containers
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = module.storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "static" {
  name                  = "static"
  storage_account_name  = module.storage_account.name
  container_access_type = "blob"  # Public for CDN
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = module.storage_account.name
  container_access_type = "private"
}

# Enable static website hosting (optional)
resource "azurerm_storage_account_static_website" "static" {
  storage_account_id = module.storage_account.id
  index_document     = "index.html"
  error_404_document = "404.html"
}
```

---

## 5. Monitoring - Create Dashboards and Alerts

### Create Log Analytics Dashboards

**Step 1: Deploy Dashboard**
```bash
# Create custom dashboard JSON
cat > /tmp/cms-dashboard.json << 'EOF'
{
  "id": "/subscriptions/xxx/resourceGroups/rg-cms-prod-app/providers/microsoft.portal/dashboards/cms-monitoring",
  "name": "cms-monitoring",
  "type": "Microsoft.Portal/dashboards",
  "location": "eastus",
  "tags": {
    "environment": "production"
  },
  "properties": {
    "lenses": {
      "0": {
        "order": 0,
        "parts": {
          "0": {
            "position": {
              "x": 0,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "options",
                  "value": {
                    "chart": {
                      "metrics": [
                        {
                          "resourceMetadata": {
                            "id": "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app"
                          },
                          "name": "ContainerAppCpuUsage",
                          "aggregationType": "Average"
                        }
                      ],
                      "openBladeOnClick": {
                        "openBlade": true
                      }
                    }
                  }
                }
              ],
              "type": "Extension/HubsExtension/PartType/MetricsChart"
            }
          }
        }
      }
    }
  }
}
EOF

# Deploy dashboard
az portal dashboard create \
  --resource-group rg-cms-prod-app \
  --name cms-monitoring \
  --input-path /tmp/cms-dashboard.json
```

**Step 2: Create Saved Queries in Log Analytics**
```bash
# Query 1: Container App Error Rate
cat > /tmp/error-rate-query.kql << 'EOF'
ContainerAppConsoleLogs
| where ContainerId == "cms-container-app"
| where LogLevel == "ERROR"
| summarize ErrorCount = count() by bin(TimeGenerated, 5m)
| render timechart
EOF

# Query 2: CPU/Memory Usage
cat > /tmp/resource-usage-query.kql << 'EOF'
ContainerAppConsoleLogs
| where ContainerId == "cms-container-app"
| where MetricName in ("CpuUsage", "MemoryUsage")
| summarize AvgValue = avg(MetricValue) by bin(TimeGenerated, 5m), MetricName
| render timechart
EOF

# Query 3: WAF Blocks
cat > /tmp/waf-blocks-query.kql << 'EOF'
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| summarize BlockedCount = count() by clientIp_s, clientPort_d
| top 10 by BlockedCount desc
EOF

# Save queries to Log Analytics
az monitor log-analytics workspace saved-search create \
  --resource-group rg-cms-prod-app \
  --workspace-name cms-log-analytics \
  --name "ContainerAppErrors" \
  --display-name "Container App Errors" \
  --saved-query "$(cat /tmp/error-rate-query.kql)" \
  --category "CMS Monitoring"

az monitor log-analytics workspace saved-search create \
  --resource-group rg-cms-prod-app \
  --workspace-name cms-log-analytics \
  --name "ResourceUsage" \
  --display-name "Resource Usage" \
  --saved-query "$(cat /tmp/resource-usage-query.kql)" \
  --category "CMS Monitoring"

az monitor log-analytics workspace saved-search create \
  --resource-group rg-cms-prod-app \
  --workspace-name cms-log-analytics \
  --name "WAFBlocks" \
  --display-name "WAF Blocks" \
  --saved-query "$(cat /tmp/waf-blocks-query.kql)" \
  --category "CMS Monitoring"
```

**Step 3: Create Alert Rules**
```bash
# Alert 1: High CPU Usage
az monitor metrics alert create \
  --resource-group rg-cms-prod-app \
  --name cms-high-cpu-alert \
  --description "Alert when CPU usage exceeds 80%" \
  --scopes "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app" \
  --condition "avg CpuUsage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-resource-id "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.insights/actiongroups/cms-action-group"

# Alert 2: High Error Rate
az monitor metrics alert create \
  --resource-group rg-cms-prod-app \
  --name cms-high-error-rate \
  --description "Alert when error rate exceeds 5%" \
  --scopes "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app" \
  --condition "total Exceptions > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-resource-id "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.insights/actiongroups/cms-action-group"

# Alert 3: WAF Blocks
az monitor metrics alert create \
  --resource-group rg-cms-prod-app \
  --name cms-waf-blocks-alert \
  --description "Alert when WAF blocks exceed 100 in 5 minutes" \
  --scopes "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.network/applicationgateways/cms-appgw" \
  --condition "total BlockedRequests > 100" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-group-resource-id "/subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.insights/actiongroups/cms-action-group"
```

---

## 6. Load Testing via Front Door

### Using Apache JMeter for Load Testing

**Step 1: Install JMeter**
```bash
# macOS
brew install jmeter

# Verify installation
jmeter --version
```

**Step 2: Create Test Plan**
```bash
# Create JMeter test configuration
cat > /tmp/cms-load-test.jmx << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testname="CMS Load Test" enabled="true">
      <stringProp name="TestPlan.comments">Load test via Front Door</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments" guiclass="ArgumentsPanel" testname="User Defined Variables" enabled="true">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
    </TestPlan>
    <hashTree>
      <ThreadGroup guiclass="ThreadGroupGui" testname="Thread Group" enabled="true">
        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
        <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testname="Loop Controller" enabled="true">
          <boolProp name="LoopController.continue_forever">false</boolProp>
          <stringProp name="LoopController.loops">100</stringProp>
        </elementProp>
        <stringProp name="ThreadGroup.num_threads">10</stringProp>
        <stringProp name="ThreadGroup.ramp_time">30</stringProp>
        <boolProp name="ThreadGroup.scheduler">false</boolProp>
        <stringProp name="ThreadGroup.duration"></stringProp>
        <stringProp name="ThreadGroup.delay"></stringProp>
      </ThreadGroup>
      <hashTree>
        <HTTPSampler guiclass="HttpTestSampleGui" testname="Homepage" enabled="true">
          <stringProp name="HTTPSampler.domain">cms.example.com</stringProp>
          <stringProp name="HTTPSampler.port"></stringProp>
          <stringProp name="HTTPSampler.protocol">https</stringProp>
          <stringProp name="HTTPSampler.path">/</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
        </HTTPSampler>
        <hashTree/>
        <HTTPSampler guiclass="HttpTestSampleGui" testname="Dashboard" enabled="true">
          <stringProp name="HTTPSampler.domain">cms.example.com</stringProp>
          <stringProp name="HTTPSampler.port"></stringProp>
          <stringProp name="HTTPSampler.protocol">https</stringProp>
          <stringProp name="HTTPSampler.path">/dashboard</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
        </HTTPSampler>
        <hashTree/>
        <HTTPSampler guiclass="HttpTestSampleGui" testname="API - Get Articles" enabled="true">
          <stringProp name="HTTPSampler.domain">cms.example.com</stringProp>
          <stringProp name="HTTPSampler.port"></stringProp>
          <stringProp name="HTTPSampler.protocol">https</stringProp>
          <stringProp name="HTTPSampler.path">/api/articles</stringProp>
          <stringProp name="HTTPSampler.method">GET</stringProp>
        </HTTPSampler>
        <hashTree/>
        <ResultCollector guiclass="SummaryReport" testname="Summary Report" enabled="true">
          <boolProp name="ResultCollector.error_logging">false</boolProp>
          <objProp>
            <name>samplers</name>
            <value class="java.util.ArrayList"/>
          </objProp>
          <stringProp name="filename"></stringProp>
          <stringProp name="TestPlan.comments">Aggregate report</stringProp>
        </ResultCollector>
      </hashTree>
    </hashTree>
  </jmeterTestPlan>
EOF
```

**Step 3: Run Load Test**
```bash
# Run in non-GUI mode
jmeter -n -t /tmp/cms-load-test.jmx -l /tmp/cms-results.jtl -j /tmp/cms-jmeter.log

# Generate HTML report
jmeter -g /tmp/cms-results.jtl -o /tmp/cms-load-test-report

# View summary
cat /tmp/cms-jmeter.log
```

**Step 4: Alternative - Using Apache Bench (ab)**
```bash
# Simple load test with Apache Bench
ab -n 1000 -c 50 https://cms.example.com/

# Interpret results:
# -n 1000: Total requests
# -c 50: Concurrent requests
# Output shows:
# - Requests per second
# - Time per request
# - Failed requests (if any)
# - Connection times
```

**Step 5: Analyze Results**
```bash
# Monitor in real-time during load test
watch -n 5 'az monitor metrics list-definitions \
  --resource /subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.app/containerapps/cms-container-app \
  --metric CpuUsage'

# Check Container App scaling
az containerapp replica list \
  --name cms-container-app \
  --resource-group rg-cms-prod-app

# View Application Gateway metrics
az monitor metrics list \
  --resource /subscriptions/xxx/resourcegroups/rg-cms-prod-app/providers/microsoft.network/applicationgateways/cms-appgw \
  --metric BytesSent \
  --interval PT1M \
  --start-time 2024-01-01T00:00:00Z
```

---

## 7. Backup Strategy

### Implement Database & Application Backup

**Step 1: Storage Account Backup Configuration**
```bash
# Enable soft delete for blob recovery (7 days retention)
az storage account blob-service-properties update \
  --resource-group rg-cms-prod-app \
  --account-name cmsstorage \
  --enable-soft-delete true \
  --soft-delete-days 7

# Enable versioning
az storage account blob-service-properties update \
  --resource-group rg-cms-prod-app \
  --account-name cmsstorage \
  --enable-versioning true
```

**Step 2: Create Automated Backup Policy**
```bash
# Create backup vault
az backup vault create \
  --resource-group rg-cms-prod-app \
  --name cms-backup-vault \
  --location eastus

# Get vault ID
VAULT_ID=$(az backup vault show \
  --resource-group rg-cms-prod-app \
  --name cms-backup-vault \
  --query id \
  --output tsv)

# Enable Cross Region Restore (CRR)
az backup vault backup-properties set \
  --resource-group rg-cms-prod-app \
  --name cms-backup-vault \
  --backup-management-type AzureStorage \
  --cross-region-restore-flag True
```

**Step 3: Backup Storage Account Data**
```bash
# Create backup policy for blobs
cat > /tmp/backup-policy.json << 'EOF'
{
  "schedulePolicy": {
    "schedulePolicyType": "SimpleSchedulePolicy",
    "scheduleRunFrequency": "Daily",
    "scheduleRunTimes": ["2024-01-01T02:00:00Z"],
    "scheduleWeeklyFrequency": 0
  },
  "retentionPolicy": {
    "retentionPolicyType": "LongTermRetentionPolicy",
    "dailySchedule": {
      "retentionTimes": ["2024-01-01T02:00:00Z"],
      "retentionDuration": {
        "count": 30,
        "durationType": "Days"
      }
    }
  },
  "timeZone": "UTC"
}
EOF

# Register storage account for backup
az backup container register \
  --resource-group rg-cms-prod-app \
  --vault-name cms-backup-vault \
  --backup-management-type AzureStorage \
  --workload-type AzureFileShare \
  --container-name cmsstorage
```

**Step 4: Application Backup Strategy**
```bash
# Backup Container App configuration
az containerapp show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app \
  --output json > /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/backups/container-app-config-$(date +%Y%m%d).json

# Backup Terraform state
cp /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/terraform.tfstate \
   /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/backups/terraform-state-$(date +%Y%m%d).tfstate

# Create backup storage container
az storage container create \
  --name application-backups \
  --connection-string "$STORAGE_CONN"
```

**Step 5: Create Backup Automation Script**
```bash
# Create backup script
cat > /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/scripts/backup.sh << 'EOF'
#!/bin/bash
# CMS Backup Script
# Backs up application configuration, Terraform state, and storage data

BACKUP_DIR="/Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)"

# Backup 1: Container App configuration
echo "Backing up Container App configuration..."
az containerapp show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app \
  --output json > $BACKUP_DIR/container-app.json

# Backup 2: Terraform state
echo "Backing up Terraform state..."
cp /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/terraform.tfstate \
   $BACKUP_DIR/terraform.tfstate

# Backup 3: Application Gateway config
echo "Backing up Application Gateway configuration..."
az network application-gateway show \
  --name cms-appgw \
  --resource-group rg-cms-prod-app \
  --output json > $BACKUP_DIR/appgw.json

# Backup 4: Storage containers metadata
echo "Backing up Storage Account metadata..."
az storage container list \
  --connection-string "$STORAGE_CONN" \
  --output json > $BACKUP_DIR/storage-containers.json

# Upload to Azure Storage
echo "Uploading backup to Azure Storage..."
az storage blob upload \
  --container-name application-backups \
  --name "backup-$(date +%Y%m%d_%H%M%S).tar.gz" \
  --file $(cd $BACKUP_DIR && tar czf - . | wc -c) \
  --connection-string "$STORAGE_CONN"

# Cleanup old local backups (keep last 7 days)
find /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/backups -type d -mtime +7 -exec rm -rf {} \;

echo "Backup completed successfully at $(date)"
echo "Backup location: $BACKUP_DIR"
EOF

chmod +x /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/scripts/backup.sh
```

**Step 6: Schedule Automated Backups (crontab)**
```bash
# Edit crontab
crontab -e

# Add automated backup schedule (daily at 2 AM)
0 2 * * * /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/scripts/backup.sh >> /var/log/cms-backup.log 2>&1

# Verify crontab entry
crontab -l
```

**Step 7: Disaster Recovery Procedures**
```bash
# Restore from backup
# 1. Restore Terraform state
cp /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/backups/terraform-state-YYYYMMDD.tfstate \
   /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms/terraform.tfstate

# 2. Refresh Terraform
cd /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms
terraform refresh

# 3. Restore storage data from blob snapshots
az storage blob snapshot list \
  --container-name uploads \
  --account-name cmsstorage

# 4. Restore Container App
az containerapp update \
  --name cms-container-app \
  --resource-group rg-cms-prod-app \
  --image <PREVIOUS_IMAGE_VERSION>
```

---

## Deployment Checklist

- [ ] Item 1: Docker image built and pushed to ACR
- [ ] Item 2: SSL certificate uploaded to Key Vault (self-signed or production)
- [ ] Item 3: DNS nameservers configured at domain registrar
- [ ] Item 4: Storage containers created and CDN configured
- [ ] Item 5: Log Analytics dashboards and alerts created
- [ ] Item 6: Load testing completed with acceptable results
- [ ] Item 7: Backup script deployed and tested

## Final Deployment Command

Once all items are complete, deploy infrastructure:
```bash
cd /Users/asdad_uly21yahoo.com/Azure-Terraform-Templates/cms

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

## Verification After Deployment

```bash
# Get deployed resource endpoints
az containerapp show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app \
  --query properties.ingress.fqdn

# Test HTTPS access
curl -k https://cms.example.com

# Check application health
curl https://cms.example.com/health

# View logs
az containerapp logs show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app
```

---

**Status**: All 7 items are now documented with complete implementation steps.
**Next Action**: Execute items in order according to your infrastructure setup preferences.
