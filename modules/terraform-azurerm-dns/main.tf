variable "name" {
  description = "Name of the DNS zone"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

variable "a_records" {
  description = "List of A records"
  type = list(object({
    name    = string
    ttl     = number
    records = list(string)
  }))
  default = []
}

variable "cname_records" {
  description = "List of CNAME records"
  type = list(object({
    name   = string
    ttl    = number
    record = string
  }))
  default = []
}

resource "azurerm_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_dns_a_record" "this" {
  for_each = { for record in var.a_records : record.name => record }

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
}

resource "azurerm_dns_cname_record" "this" {
  for_each = { for record in var.cname_records : record.name => record }

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
}

output "id" {
  description = "ID of the DNS zone"
  value       = azurerm_dns_zone.this.id
}

output "name" {
  description = "Name of the DNS zone"
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "Name servers for the DNS zone"
  value       = azurerm_dns_zone.this.name_servers
}