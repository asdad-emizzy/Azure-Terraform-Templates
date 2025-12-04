# outputs.tf - CMS Terraform Outputs

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = module.resource_group.id
}

output "container_app_fqdn" {
  description = "Fully qualified domain name of the Container App"
  value       = module.container_app.fqdn
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "front_door_endpoint" {
  description = "Azure Front Door endpoint hostname"
  value       = try(module.frontdoor.endpoint_hostname, "Not configured")
}

output "dns_zone_nameservers" {
  description = "Azure DNS nameservers for domain delegation"
  value       = try(module.dns.nameservers, [])
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workspace_key" {
  description = "Log Analytics Workspace primary key"
  value       = module.log_analytics.workspace_key
  sensitive   = true
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = module.storage_account.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Storage Account"
  value       = module.storage_account.primary_blob_endpoint
}

output "virtual_network_id" {
  description = "ID of the created Virtual Network"
  value       = module.virtual_network.id
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = module.virtual_network.subnets["appgw-subnet"].id
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = module.container_app_environment.id
}

# Access Instructions
output "access_instructions" {
  description = "Instructions for accessing the deployed application"
  value = format(<<-EOT
    
    ============================================
    Azure CMS Infrastructure Deployment Complete
    ============================================
    
    Application Access:
    - Container App FQDN: https://%s
    - Application Gateway IP: https://%s
    - Front Door Endpoint: https://%s
    
    DNS Configuration:
    - Domain: %s
    - Azure Nameservers: %s
    - Next: Configure nameservers at your domain registrar
    
    Management:
    - Resource Group: %s
    - Key Vault: %s
    - Log Analytics: %s (Workspace ID: %s)
    - Storage Account: %s
    
    Monitoring & Logs:
    - View logs: az monitor log-analytics workspace query
    - View metrics: az monitor metrics list
    - Create dashboards: Azure Portal > Dashboards
    
    Deployment Details:
    - Container Image: Check main.tf for current image
    - SSL Certificate: Stored in Key Vault
    - Backup: Configured in backup vault
    
    Next Steps:
    1. Update DNS records at your domain registrar
    2. Upload SSL certificate to Key Vault
    3. Configure Application Gateway with SSL
    4. Run load tests to validate performance
    5. Set up monitoring alerts
    
    Support Documentation:
    - Terraform Modules: See /cms/modules/
    - Deployment Guide: See DEPLOYMENT_IMPLEMENTATION_GUIDE.md
    - Architecture: See CMS_PROJECT_DETAILED_SUMMARY.md
    
    ============================================
  EOT
    ,
    module.container_app.fqdn,
    azurerm_public_ip.appgw.ip_address,
    try(module.frontdoor.endpoint_hostname, "Not configured"),
    var.domain_name,
    join(", ", try(module.dns.nameservers, ["Not configured"])),
    module.resource_group.name,
    module.key_vault.vault_uri,
    module.log_analytics.workspace_id,
    module.log_analytics.workspace_id,
    module.storage_account.name
  )
}

# Backup Configuration Output
output "backup_vault_id" {
  description = "ID of the Backup Vault (if enabled)"
  value       = try(azurerm_recovery_services_vault.backup[0].id, "Backup not enabled")
}

# Security Summary
output "security_summary" {
  description = "Security configuration summary"
  value = format(<<-EOT
    
    Security Configuration:
    - Web Application Firewall: %s
    - SSL/TLS: Configured in Key Vault
    - DDoS Protection: Azure Front Door
    - Network Isolation: Virtual Network with subnets
    - Access Control: RBAC via Key Vault
    - Audit Logging: Log Analytics enabled
    - Encryption: At-rest and in-transit
    
    Key Vault Secrets:
    - SSL Certificates: %s/secrets/
    - Application Secrets: Configure via Azure Portal
    
  EOT
    ,
    var.enable_waf ? "Enabled (WAF v2)" : "Disabled",
    module.key_vault.vault_uri
  )
}

# Cost Estimation
output "estimated_monthly_cost" {
  description = "Estimated monthly cost (rough calculation)"
  value = format(<<-EOT
    
    Estimated Monthly Costs (US East):
    - Container Apps: $40-60 (based on replica count)
    - Application Gateway WAF v2: $300-350
    - Front Door Standard: ~$19
    - Public IP (Static): $2.73
    - Key Vault: $0.60
    - Storage Account: $15-25
    - DNS Zone: $0.50
    - Log Analytics: Variable (typically $2-10/GB)
    
    Total Estimated: $380-460/month
    
    Cost Optimization Tips:
    1. Use Autoscaling to match traffic patterns
    2. Enable caching in Front Door
    3. Use LRS instead of GRS (if applicable)
    4. Monitor and adjust Log Analytics retention
    5. Use Reserved Instances for predictable workloads
    
  EOT
  )
}
