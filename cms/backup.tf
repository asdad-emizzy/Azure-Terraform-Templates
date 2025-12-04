# backup.tf - Backup and Disaster Recovery Configuration

# Recovery Services Vault for Backup
resource "azurerm_recovery_services_vault" "backup" {
  count               = var.backup_enabled ? 1 : 0
  name                = "cms-backup-vault"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  sku                 = "Standard"
  
  soft_delete_enabled = true

  tags = var.tags
}

# Backup Policy (backup vault policies are managed differently in v4.x)
# Note: Backup policies are typically configured through Azure Portal or via
# azurerm_backup_policy_vm for VM backups or azurerm_backup_policy_file_share for file shares

# Storage Account Blob Service Configuration
# Blob service properties are configured at the storage account level
# Soft delete and versioning can be enabled through storage account settings

# Backup Containers for Application Data
resource "azurerm_storage_container" "backups" {
  name                  = "application-backups"
  storage_account_id    = module.storage_account.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "disaster_recovery" {
  name                  = "disaster-recovery"
  storage_account_id    = module.storage_account.id
  container_access_type = "private"
}

# Managed Identity for Backup Access
resource "azurerm_user_assigned_identity" "backup_identity" {
  count               = var.backup_enabled ? 1 : 0
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = "cms-backup-identity"

  tags = var.tags
}

# Role Assignment for Backup Identity
resource "azurerm_role_assignment" "backup_vault_contributor" {
  count              = var.backup_enabled ? 1 : 0
  scope              = azurerm_recovery_services_vault.backup[0].id
  role_definition_name = "Contributor"
  principal_id       = azurerm_user_assigned_identity.backup_identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_backup_contributor" {
  count              = var.backup_enabled ? 1 : 0
  scope              = module.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id       = azurerm_user_assigned_identity.backup_identity[0].principal_id
}

# Backup Alert Rule
resource "azurerm_monitor_metric_alert" "backup_job_failure" {
  count               = var.backup_enabled ? 1 : 0
  name                = "cms-backup-job-failure"
  resource_group_name = module.resource_group.name
  scopes              = [azurerm_recovery_services_vault.backup[0].id]
  description         = "Alert when backup job fails"

  criteria {
    metric_name      = "HealthStatus"
    metric_namespace = "Microsoft.RecoveryServices/vaults"
    operator         = "LessThan"
    threshold        = 1
    aggregation      = "Average"
  }

  window_size = "PT1H"
  frequency   = "PT5M"

  tags = var.tags
}

# Local File for Backup Instructions
resource "local_file" "backup_procedure" {
  filename = "${path.module}/BACKUP_PROCEDURE.md"
  content  = <<-EOT
# CMS Backup and Disaster Recovery Procedure

## Backup Configuration

### Enabled Services
- Recovery Services Vault: ${var.backup_enabled ? "Yes" : "No"}
- Storage Account Versioning: ${var.enable_blob_versioning ? "Yes" : "No"}
- Soft Delete: ${var.enable_soft_delete ? "Yes (${var.soft_delete_retention_days} days)" : "No"}
- Backup Retention: ${var.backup_retention_days} days

### Backup Locations
- Primary: ${azurerm_storage_container.backups.name}
- Disaster Recovery: ${azurerm_storage_container.disaster_recovery.name}
- Vault: ${var.backup_enabled ? azurerm_recovery_services_vault.backup[0].name : "Not configured"}

## Manual Backup Procedure

### Backup Container App Configuration
```bash
az containerapp show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app \
  --output json > backup-container-app.json

az storage blob upload \
  --container-name application-backups \
  --name backup-container-app-$(date +%Y%m%d).json \
  --file backup-container-app.json \
  --account-name ${module.storage_account.name}
```

### Backup Application Gateway Configuration
```bash
az network application-gateway show \
  --name cms-appgw \
  --resource-group rg-cms-prod-app \
  --output json > backup-appgw.json

az storage blob upload \
  --container-name application-backups \
  --name backup-appgw-$(date +%Y%m%d).json \
  --file backup-appgw.json \
  --account-name ${module.storage_account.name}
```

### Backup Terraform State
```bash
cp terraform.tfstate backup-terraform-$(date +%Y%m%d).tfstate

az storage blob upload \
  --container-name application-backups \
  --name backup-terraform-$(date +%Y%m%d).tfstate \
  --file backup-terraform-$(date +%Y%m%d).tfstate \
  --account-name ${module.storage_account.name}
```

## Disaster Recovery Procedure

### Scenario 1: Container App Failure

1. **Check Container App Status**
```bash
az containerapp show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app
```

2. **Restart Container App**
```bash
az containerapp restart \
  --name cms-container-app \
  --resource-group rg-cms-prod-app
```

3. **Restore from Backup if Needed**
```bash
# Download backup configuration
az storage blob download \
  --container-name application-backups \
  --name backup-container-app-YYYYMMDD.json \
  --file restore-config.json \
  --account-name ${module.storage_account.name}

# Re-deploy using backup configuration
# (Manual configuration required)
```

### Scenario 2: Storage Account Data Loss

1. **List Available Blob Versions**
```bash
az storage blob list \
  --container-name uploads \
  --include-snapshots \
  --account-name ${module.storage_account.name}
```

2. **Restore Blob from Version**
```bash
az storage blob copy start \
  --source-container uploads \
  --source-blob <blob-name> \
  --destination-container uploads \
  --destination-blob <blob-name>-restored \
  --account-name ${module.storage_account.name}
```

3. **Restore from Soft Delete (if within retention period)**
```bash
# List deleted blobs
az storage blob list \
  --container-name uploads \
  --include-deleted \
  --account-name ${module.storage_account.name}

# Undelete blob
az storage blob undelete \
  --container-name uploads \
  --name <deleted-blob-name> \
  --account-name ${module.storage_account.name}
```

### Scenario 3: Terraform State Recovery

1. **Restore from Backup**
```bash
# Download backup
az storage blob download \
  --container-name application-backups \
  --name backup-terraform-YYYYMMDD.tfstate \
  --file terraform-restore.tfstate \
  --account-name ${module.storage_account.name}

# Replace current state (CAREFULLY!)
cp terraform-restore.tfstate terraform.tfstate

# Verify and apply
terraform plan
```

2. **Refresh State**
```bash
terraform refresh
```

### Scenario 4: Full Resource Group Recovery

1. **Export Resource Group Template**
```bash
az group export \
  --name rg-cms-prod-app \
  --resource-ids $(az resource list --resource-group rg-cms-prod-app --query [].id --output tsv)
```

2. **Deploy to Alternative Location** (if primary region fails)
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Recovery Time Objectives (RTO)

| Component | RTO | Method |
|-----------|-----|--------|
| Container App | < 5 min | Restart or redeploy from backup |
| Storage Data | < 1 hour | Blob versioning or soft delete recovery |
| Configuration | < 1 hour | Terraform state restore |
| Full Environment | < 4 hours | Complete redeploy from backup |

## Recovery Point Objectives (RPO)

| Component | RPO |
|-----------|-----|
| Application Config | Daily (scheduled backup) |
| Storage Data | Hourly (versioning enabled) |
| Terraform State | Manual (on demand) |

## Verification Steps

After restoration, verify:

1. **Health Check**
```bash
curl https://cms.example.com/health
```

2. **Application Status**
```bash
az containerapp show \
  --name cms-container-app \
  --resource-group rg-cms-prod-app \
  --query properties.runningStatus
```

3. **Storage Access**
```bash
az storage container list \
  --account-name ${module.storage_account.name}
```

4. **Monitoring**
```bash
az monitor log-analytics workspace query \
  --workspace-name cms-log-analytics \
  --analytics-query "AppRequests | summarize by Status"
```

## Support

For assistance with backup/recovery:
- Review Azure Backup documentation: https://docs.microsoft.com/azure/backup/
- Check Log Analytics for error details
- Contact Azure Support for critical issues
EOT
}

# Outputs for Backup Configuration
output "backup_vault_id" {
  value = try(azurerm_recovery_services_vault.backup[0].id, null)
}

output "backup_enabled" {
  value = var.backup_enabled
}
