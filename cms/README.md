# CMS Azure Infrastructure

This Terraform configuration creates a complete Azure infrastructure for a Content Management System (CMS) using a modular approach.

## Architecture

The infrastructure includes:

- **Resource Group**: Central resource container
- **Container App Environment**: Environment for containerized applications
- **Container App**: The main CMS application running in a container
- **Virtual Network**: Network isolation and security
- **Application Gateway**: Load balancer with WAF protection
- **Key Vault**: Secure storage for certificates and secrets
- **Storage Account**: File and data storage
- **Front Door**: Global CDN and load balancing
- **DNS Zone**: Domain name management
- **Log Analytics**: Centralized logging and monitoring

## Module Structure

All custom modules are located in the `/modules` directory:

- `terraform-azurerm-container-app`: Container App resource
- `terraform-azurerm-container-app-environment`: Container App Environment
- `terraform-azurerm-application-gateway`: Application Gateway with WAF
- `terraform-azurerm-key-vault`: Key Vault for secrets
- `terraform-azurerm-frontdoor`: Front Door CDN
- `terraform-azurerm-dns`: DNS Zone management
- `terraform-azurerm-log-analytics`: Log Analytics workspace

Existing Azure-Terraform modules used:
- `terraform-azurerm-resource-group`
- `terraform-azurerm-storage-account`
- `terraform-azurerm-virtual-network`

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply the infrastructure:
   ```bash
   terraform apply
   ```

## Prerequisites

- Azure subscription with appropriate permissions
- Terraform >= 1.0
- Azure CLI authenticated (`az login`)

## Security Features

- Application Gateway WAF (Web Application Firewall)
- Key Vault for certificate management
- Network security through Virtual Networks
- Centralized logging with Log Analytics

## Notes

This configuration demonstrates a modular Terraform approach for Azure infrastructure. For production deployment, additional configuration would be needed for:

- SSL certificates in Key Vault
- Custom domain configuration
- Authentication and authorization
- Backup and disaster recovery
- Cost optimization

The configuration is validated and ready for deployment with proper Azure authentication.