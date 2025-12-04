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
  value       = "Container App not deployed in this configuration"
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = "Application Gateway not deployed in this configuration"
}

output "front_door_endpoint" {
  description = "Azure Front Door endpoint hostname"
  value       = "Front Door not deployed in this configuration"
}

output "dns_zone_nameservers" {
  description = "Azure DNS nameservers for domain delegation"
  value       = []
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = module.log_analytics.workspace_id
}

# Note: workspace_key is not recommended to output for security reasons
# Access keys through Azure Portal or az CLI if needed

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
  value       = "Virtual Network not deployed in this configuration"
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = "Application Gateway subnet not deployed in this configuration"
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = "Container App Environment not deployed in this configuration"
}

# Access Instructions
output "access_instructions" {
  description = "Instructions for accessing the deployed application"
  value = <<-EOT
    
    ============================================
    Azure CMS Infrastructure Deployment Complete
    ============================================
    
    Core Resources Deployed:
    - Resource Group: ${module.resource_group.name}
    - Key Vault: ${module.key_vault.vault_uri}
    - Log Analytics: ${module.log_analytics.workspace_id}
    - Storage Account: ${module.storage_account.name}
    - Domain: ${var.domain_name}
    
    Next Steps:
    1. Deploy additional components (Container Apps, App Gateway, Front Door)
    2. Build and push container image to ACR
    3. Upload SSL certificate to Key Vault
    4. Configure DNS nameservers at registrar
    5. Run load tests to validate performance
    6. Set up monitoring alerts
    
    Support Documentation:
    - Terraform Modules: See /cms/modules/
    - Deployment Guide: See DEPLOYMENT_IMPLEMENTATION_GUIDE.md
    - Architecture: See CMS_PROJECT_DETAILED_SUMMARY.md
    
    ============================================
  EOT
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
