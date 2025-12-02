variable "name" {
  description = "Name of the Application Gateway"
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

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "WAF_v2"
}

variable "sku_tier" {
  description = "SKU tier"
  type        = string
  default     = "WAF_v2"
}

variable "capacity" {
  description = "Capacity"
  type        = number
  default     = 2
}

variable "subnet_id" {
  description = "Subnet ID for the Application Gateway"
  type        = string
}

variable "public_ip_address_id" {
  description = "Public IP address ID"
  type        = string
}

variable "key_vault_secret_id" {
  description = "Key Vault secret ID for SSL certificate"
  type        = string
  default     = null
}

variable "certificate_name" {
  description = "Name of the SSL certificate"
  type        = string
  default     = null
}

variable "backend_addresses" {
  description = "List of backend addresses"
  type        = list(object({
    fqdn = optional(string)
    ip_address = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = var.public_ip_address_id
  }

  dynamic "ssl_certificate" {
    for_each = var.key_vault_secret_id != null ? [1] : []
    content {
      name                = var.certificate_name
      key_vault_secret_id = var.key_vault_secret_id
    }
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = var.certificate_name
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-settings"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = var.tags
}

output "id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.this.name
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_application_gateway.this.frontend_ip_configuration[0].public_ip_address_id
}