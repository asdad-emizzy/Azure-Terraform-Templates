# Azure Landing Zone Variables

variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "Landing Zone"
    ManagedBy   = "Terraform"
    Project     = "Azure Landing Zone"
  }
}

# Management Groups
variable "root_management_group_id" {
  description = "Root management group ID"
  type        = string
  default     = "root"
}

# Networking
variable "hub_vnet_address_space" {
  description = "Address space for hub virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "hub_subnets" {
  description = "Subnets for hub virtual network"
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    "GatewaySubnet" = {
      address_prefixes = ["10.0.0.0/24"]
    }
    "AzureFirewallSubnet" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "Management" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}

# Resource Groups
# Removed complex resource_groups variable, using direct resource creation

# Storage
variable "log_storage_account_name" {
  description = "Name of the storage account for logs"
  type        = string
  default     = "stlogslandingzone"
}