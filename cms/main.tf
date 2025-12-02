provider "azurerm" {
  features {}
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

# Container App Environment
module "container_app_environment" {
  source              = "../modules/terraform-azurerm-container-app-environment"
  name                = "cms-container-app-env"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Container App
module "container_app" {
  source                       = "../modules/terraform-azurerm-container-app"
  name                         = "cms-container-app"
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  container_app_environment_id = module.container_app_environment.id
  image                        = "nginx:latest"
  cpu                          = "0.25"
  memory                       = "0.5Gi"
  min_replicas                 = 1
  max_replicas                 = 3
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Virtual Network
module "virtual_network" {
  source              = "../modules/terraform-azurerm-virtual-network"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names = {
    environment = "prod"
    location    = "eastus"
    market      = "us"
    product_name = "cms"
  }
  address_space = ["10.0.0.0/16"]
  subnets = [
    {
      name             = "appgw-subnet"
      address_prefixes = ["10.0.1.0/24"]
    }
  ]
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "cms-appgw-pip"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Key Vault
module "key_vault" {
  source              = "../modules/terraform-azurerm-key-vault"
  name                = "cms-keyvault"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Application Gateway
module "application_gateway" {
  source               = "../modules/terraform-azurerm-application-gateway"
  name                 = "cms-appgw"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  subnet_id            = module.virtual_network.subnets["appgw-subnet"].id
  public_ip_address_id = azurerm_public_ip.appgw.id
  backend_addresses = [
    {
      fqdn = module.container_app.fqdn
    }
  ]
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Storage Account
module "storage_account" {
  source               = "../modules/terraform-azurerm-storage-account"
  name                 = "cmsstorage"
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  account_tier         = "Standard"
  replication_type     = "LRS"
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# Front Door
module "frontdoor" {
  source              = "../modules/terraform-azurerm-frontdoor"
  name                = "cms-frontdoor"
  resource_group_name = module.resource_group.name
  sku_name            = "Standard_AzureFrontDoor"
  backend_pool_name   = "cms-backend-pool"
  backend_addresses   = [azurerm_public_ip.appgw.ip_address]
  frontend_endpoint_name = "cms-frontend"
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

# DNS Zone
module "dns" {
  source              = "../modules/terraform-azurerm-dns"
  name                = "cms.example.com"
  resource_group_name = module.resource_group.name
  a_records = [
    {
      name    = "www"
      ttl     = 300
      records = [module.frontdoor.endpoint_hostname]
    }
  ]
  tags = {
    Environment = "Production"
    Project     = "CMS"
  }
}

data "azurerm_client_config" "current" {}