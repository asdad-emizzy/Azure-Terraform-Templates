variable "name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention period in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = var.tags
}

output "id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.this.name
}

output "primary_shared_key" {
  description = "Primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "workspace_id" {
  description = "Workspace ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.this.workspace_id
}