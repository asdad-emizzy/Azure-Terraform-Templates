provider "azurerm" {
  features {}
  subscription_id = "9560076a-7abb-4c8d-ab62-2ae63a8a7b32"
}

# Resource Group
module "resource_group" {
  source   = "../modules/terraform-azurerm-resource-group"
  names = {
    environment         = "prod"
    location            = "eastus"
    market              = "us"
    product_name        = "cms"
    resource_group_type = "app"
  }
  location = "East US"
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Log Analytics Workspace
module "log_analytics" {
  source              = "../modules/terraform-azurerm-log-analytics"
  name                = "cms-log-analytics"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = 30
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Storage Account (with unique name)
module "storage_account" {
  source               = "../modules/terraform-azurerm-storage-account"
  name                 = "cmsst${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  account_tier         = "Standard"
  replication_type     = "LRS"
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Key Vault (with unique name)
module "key_vault" {
  source              = "../modules/terraform-azurerm-key-vault"
  name                = "cms-keyvault-${substr(data.azurerm_client_config.current.subscription_id, 0, 8)}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

data "azurerm_client_config" "current" {}