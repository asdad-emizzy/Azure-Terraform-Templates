# Management Groups
output "management_groups" {
  description = "Created management groups"
  value       = azurerm_management_group.level1
}

# Resource Groups
output "resource_groups" {
  description = "Created resource groups"
  value = {
    hub_networking      = azurerm_resource_group.hub_networking
    platform_logging    = azurerm_resource_group.platform_logging
    platform_management = azurerm_resource_group.platform_management
  }
}

# Networking
output "hub_vnet" {
  description = "Hub virtual network details"
  value       = azurerm_virtual_network.hub
}

output "hub_subnets" {
  description = "Hub subnets"
  value       = azurerm_subnet.hub_subnets
}

# Storage
output "log_storage_account" {
  description = "Log storage account details"
  value       = azurerm_storage_account.log_storage
}

# Monitoring
output "log_analytics_workspace" {
  description = "Log Analytics workspace details"
  value       = azurerm_log_analytics_workspace.platform
}