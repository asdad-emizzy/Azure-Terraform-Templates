#!/bin/bash
# CMS Backup Script
# Backs up application configuration, Terraform state, and storage data
# Usage: ./backup.sh
# Schedule: Add to crontab for automated daily backups

set -e

# Configuration
RESOURCE_GROUP="rg-cms-prod-app"
STORAGE_ACCOUNT="cmsstorage"
CONTAINER_APP="cms-container-app"
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/cms-backup.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Initialize log
{
    echo "=========================================="
    echo "CMS Backup Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo "Backup Directory: $BACKUP_DIR"
    echo ""
} | tee -a "$LOG_FILE"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Backup 1: Container App Configuration
log_message "Backing up Container App configuration..."
if az containerapp show \
    --name "$CONTAINER_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --output json > "$BACKUP_DIR/container-app-config.json" 2>> "$LOG_FILE"; then
    log_message "✓ Container App configuration backed up"
else
    log_message "✗ Failed to backup Container App configuration"
    exit 1
fi

# Backup 2: Terraform State
log_message "Backing up Terraform state..."
if [ -f "$(dirname "${BASH_SOURCE[0]}")/../terraform.tfstate" ]; then
    cp "$(dirname "${BASH_SOURCE[0]}")/../terraform.tfstate" "$BACKUP_DIR/terraform.tfstate"
    log_message "✓ Terraform state backed up"
else
    log_message "⚠ No Terraform state file found (remote state may be in use)"
fi

# Backup 3: Application Gateway Configuration
log_message "Backing up Application Gateway configuration..."
if az network application-gateway show \
    --name cms-appgw \
    --resource-group "$RESOURCE_GROUP" \
    --output json > "$BACKUP_DIR/appgw-config.json" 2>> "$LOG_FILE"; then
    log_message "✓ Application Gateway configuration backed up"
else
    log_message "⚠ Could not backup Application Gateway (may not exist yet)"
fi

# Backup 4: Key Vault Secrets Metadata
log_message "Backing up Key Vault metadata..."
if az keyvault list --resource-group "$RESOURCE_GROUP" --output json > "$BACKUP_DIR/keyvault-list.json" 2>> "$LOG_FILE"; then
    log_message "✓ Key Vault metadata backed up"
else
    log_message "⚠ Could not backup Key Vault metadata"
fi

# Backup 5: Storage Account Metadata
log_message "Backing up Storage Account metadata..."
if az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --output json > "$BACKUP_DIR/storage-account.json" 2>> "$LOG_FILE"; then
    log_message "✓ Storage Account metadata backed up"
else
    log_message "⚠ Could not backup Storage Account metadata"
fi

# Backup 6: Virtual Network Configuration
log_message "Backing up Virtual Network configuration..."
if az network vnet list \
    --resource-group "$RESOURCE_GROUP" \
    --output json > "$BACKUP_DIR/vnet-config.json" 2>> "$LOG_FILE"; then
    log_message "✓ Virtual Network configuration backed up"
else
    log_message "⚠ Could not backup Virtual Network configuration"
fi

# Backup 7: Create Tar Archive
log_message "Creating compressed backup archive..."
ARCHIVE_FILE="/tmp/cms-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
if tar -czf "$ARCHIVE_FILE" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")" 2>> "$LOG_FILE"; then
    log_message "✓ Compressed backup created: $ARCHIVE_FILE"
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
    log_message "  Archive size: $ARCHIVE_SIZE"
else
    log_message "✗ Failed to create compressed archive"
fi

# Backup 8: Upload to Azure Storage (if configured)
if command -v az &> /dev/null && [ ! -z "$(az account show --query id -o tsv 2>/dev/null)" ]; then
    log_message "Uploading backup to Azure Storage..."
    
    # Get storage connection string
    STORAGE_CONN=$(az storage account show-connection-string \
        --resource-group "$RESOURCE_GROUP" \
        --name "$STORAGE_ACCOUNT" \
        --query connectionString -o tsv 2>> "$LOG_FILE")
    
    if [ ! -z "$STORAGE_CONN" ]; then
        # Upload archive
        if az storage blob upload \
            --container-name application-backups \
            --name "backup-$(date +%Y%m%d_%H%M%S).tar.gz" \
            --file "$ARCHIVE_FILE" \
            --connection-string "$STORAGE_CONN" \
            2>> "$LOG_FILE"; then
            log_message "✓ Backup uploaded to Azure Storage"
            rm -f "$ARCHIVE_FILE"
        else
            log_message "⚠ Could not upload backup to Azure Storage (container may not exist)"
        fi
    else
        log_message "⚠ Could not retrieve storage connection string"
    fi
else
    log_message "⚠ Azure CLI not configured, skipping cloud upload"
fi

# Cleanup old backups (keep last 7 days of local backups)
log_message "Cleaning up old local backups (retaining 7 days)..."
OLD_BACKUPS=$(find "$(dirname "$BACKUP_DIR")" -type d -name "20[0-9][0-9]*" -mtime +7 2>/dev/null | wc -l)
if [ "$OLD_BACKUPS" -gt 0 ]; then
    find "$(dirname "$BACKUP_DIR")" -type d -name "20[0-9][0-9]*" -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
    log_message "✓ Removed $OLD_BACKUPS old backup directories"
else
    log_message "✓ No old backups to clean up"
fi

# Final summary
{
    echo ""
    echo "=========================================="
    echo "CMS Backup Completed: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo "Backup Directory: $BACKUP_DIR"
    echo "Files Backed Up: $(find "$BACKUP_DIR" -type f | wc -l)"
    echo "Total Size: $(du -sh "$BACKUP_DIR" | cut -f1)"
    echo ""
} | tee -a "$LOG_FILE"

log_message "Backup script completed successfully"
exit 0
