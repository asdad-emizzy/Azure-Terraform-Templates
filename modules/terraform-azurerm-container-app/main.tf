variable "name" {
  description = "Name of the container app"
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

variable "container_app_environment_id" {
  description = "ID of the container app environment"
  type        = string
}

variable "image" {
  description = "Container image"
  type        = string
  default     = "nginx:latest"
}

variable "cpu" {
  description = "CPU cores"
  type        = string
  default     = "0.5"
}

variable "memory" {
  description = "Memory"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum replicas"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

resource "azurerm_container_app" "this" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "app"
      image  = var.image
      cpu    = var.cpu
      memory = var.memory
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

output "id" {
  description = "ID of the container app"
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "Name of the container app"
  value       = azurerm_container_app.this.name
}

output "fqdn" {
  description = "FQDN of the container app"
  value       = azurerm_container_app.this.latest_revision_fqdn
}