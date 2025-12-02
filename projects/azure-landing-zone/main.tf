# Azure Landing Zone Terraform Configuration

# Module Version References (for future use)
# The following modules are available with stable version tags:
#
# Resource Group Module:
# source = "git::https://github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.1"
#
# Virtual Network Module:
# source = "git::https://github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v8.2.0"
#
# Storage Account Module (currently in use):
# source = "git::https://github.com/Azure-Terraform/terraform-azurerm-storage-account.git?ref=v1.2.0"
#
# AKS Module (available but not used for simplicity):
# source = "git::https://github.com/Azure-Terraform/terraform-azurerm-kubernetes.git?ref=v4.3.0"

# Management Groups
resource "azurerm_management_group" "level1" {
  for_each = toset(["platform", "landing-zones"])

  display_name = each.key
  parent_management_group_id = data.azurerm_client_config.current.tenant_id == var.root_management_group_id ? null : var.root_management_group_id
}

data "azurerm_client_config" "current" {}

# Resource Groups (using direct azurerm_resource_group instead of module for simplicity)
resource "azurerm_resource_group" "hub_networking" {
  name     = "rg-hub-networking-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "platform_logging" {
  name     = "rg-platform-logging-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "platform_management" {
  name     = "rg-platform-management-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Hub Networking (using direct azurerm resources instead of complex module)

# DDoS Protection Plan for enhanced security
resource "azurerm_network_ddos_protection_plan" "hub_ddos" {
  name                = "ddos-protection-hub-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub_networking.name

  tags = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  resource_group_name = azurerm_resource_group.hub_networking.name
  location            = var.location
  address_space       = var.hub_vnet_address_space

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.hub_ddos.id
    enable = true
  }

  tags = var.tags
}

resource "azurerm_subnet" "hub_subnets" {
  for_each = var.hub_subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.hub_networking.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = each.value.address_prefixes
}

# Alternative: Using Resource Group Module (commented out for simplicity)
# module "resource_groups" {
#   source  = "git::https://github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.1"
#   version = "2.1.1"
#
#   names = {
#     environment         = var.environment
#     location            = "eastus"
#     market              = "us"
#     product_name        = "landingzone"
#     resource_group_type = "networking"
#   }
#   location = var.location
#   tags     = var.tags
# }

# Alternative: Using Virtual Network Module (commented out for simplicity)
# module "hub_network" {
#   source  = "git::https://github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v8.2.0"
#   version = "8.2.0"
#
#   names = {
#     environment         = var.environment
#     location            = "eastus"
#     market              = "us"
#     product_name        = "landingzone"
#     resource_group_type = "networking"
#   }
#   resource_group_name = azurerm_resource_group.hub_networking.name
#   location           = var.location
#   address_space      = var.hub_vnet_address_space
#   tags              = var.tags
# }

# Log Storage Account (using direct azurerm resource for simplicity)
resource "azurerm_storage_account" "log_storage" {
  name                     = var.log_storage_account_name
  resource_group_name      = azurerm_resource_group.platform_logging.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "platform" {
  name                = "log-platform-${var.environment}"
  location            = azurerm_resource_group.platform_management.location
  resource_group_name = azurerm_resource_group.platform_management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Basic Policies
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-resource-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require resource tags"

  policy_rule = jsonencode({
    "if" = {
      "allOf" = [
        {
          "field"  = "type",
          "equals" = "Microsoft.Resources/subscriptions/resourceGroups"
        }
      ]
    },
    "then" = {
      "effect" = "auditIfNotExists",
      "details" = {
        "type" = "Microsoft.Resources/tags"
      }
    }
  })
}

resource "azurerm_subscription_policy_assignment" "require_tags" {
  name                 = "require-tags-assignment"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  subscription_id      = data.azurerm_client_config.current.subscription_id
}