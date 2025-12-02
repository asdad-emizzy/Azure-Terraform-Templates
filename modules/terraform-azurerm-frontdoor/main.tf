variable "name" {
  description = "Name of the Front Door profile"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Front Door"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "backend_pool_name" {
  description = "Name of the backend pool"
  type        = string
}

variable "backend_addresses" {
  description = "List of backend addresses"
  type        = list(string)
}

variable "frontend_endpoint_name" {
  description = "Name of the frontend endpoint"
  type        = string
}

variable "custom_domain_name" {
  description = "Custom domain name"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = var.frontend_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "${var.backend_pool_name}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = toset(var.backend_addresses)

  name                           = replace(each.value, ".", "-")
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  enabled                        = true
  host_name                      = each.value
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = each.value
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "${var.frontend_endpoint_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [for origin in azurerm_cdn_frontdoor_origin.this : origin.id]
  enabled                       = true

  forwarding_protocol = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match     = ["/*"]
  supported_protocols   = ["Http", "Https"]
}

output "id" {
  description = "ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "name" {
  description = "Name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "endpoint_hostname" {
  description = "Hostname of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}