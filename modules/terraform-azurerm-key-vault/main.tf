variable "name" {
  description = "Name of the Key Vault"
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

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

variable "object_id" {
  description = "Object ID of the user/service principal"
  type        = string
}

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = var.sku_name

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]
  }

  tags = var.tags
}

output "id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}