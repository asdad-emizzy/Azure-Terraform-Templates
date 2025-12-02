# Azure Landing Zone

This Terraform project creates a foundati## Modules Used

This project uses modules from the [Azure-Terraform](https://github.com/Azure-Terraform) organization with stable version tags for reproducible deployments:

### Current Modules
- **terraform-azurerm-storage-account** (v1.2.0): For log storage and shared storage resources

### Available Modules with Version Tags
- **terraform-azurerm-resource-group** (v2.1.1): Resource group creation and management
- **terraform-azurerm-virtual-network** (v8.2.0): Virtual network and subnet configuration
- **terraform-azurerm-storage-account** (v1.2.0): Storage account setup

### Module Usage with Version Control
```hcl
module "storage_account" {
  source  = "git::https://github.com/Azure-Terraform/terraform-azurerm-storage-account.git?ref=v1.2.0"
  version = "1.2.0"

  # ... module parameters
}
```

### Module Usage Strategy

**Direct azurerm Resources**: Used for resource groups and networking to maintain simplicity and control in the landing zone foundation.

**Azure-Terraform Modules**: Used for specialized services like storage accounts where the module provides significant value.

**When to Use Each Approach**:
- **Direct Resources**: Basic infrastructure components, custom naming requirements, landing zone foundations
- **Azure-Terraform Modules**: Complex services, standardized configurations, enterprise patterns

### Alternative Implementations

The `main.tf` file includes commented examples showing how to use the Resource Group and Virtual Network modules if you prefer their enterprise naming conventions and additional features.
- **Rollback**: Easy to revert to previous stable versions if needed Azure landing zone with hub-and-spoke networking, governance policies, and monitoring capabilities.

## Architecture

The landing zone implements:
- **Management Groups**: Hierarchical organization for governance
- **Hub Virtual Network**: Central networking hub with gateway and firewall subnets
- **Resource Groups**: Organized resource groups for different purposes
- **Storage Account**: For logging and shared storage
- **Log Analytics**: Centralized monitoring and logging
- **Policies**: Basic governance policies for compliance

## Prerequisites

- Azure subscription with Owner/Contributor permissions
- Azure CLI installed and authenticated
- Terraform >= 1.0

## Quick Start

1. **Clone and navigate**:
   ```bash
   cd projects/azure-landing-zone
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region | "East US" |
| `environment` | Environment name | "dev" |
| `hub_vnet_address_space` | Hub VNet CIDR | ["10.0.0.0/16"] |
| `log_storage_account_name` | Storage account name | "stlogslandingzone" |

### Customizing

Create a `terraform.tfvars` file to override defaults:

```hcl
location = "West Europe"
environment = "prod"
hub_vnet_address_space = ["10.100.0.0/16"]
```

## Modules Used

This project uses modules from [Azure-Terraform](https://github.com/Azure-Terraform):
- `terraform-azurerm-storage-account`: For log storage

## Outputs

After deployment, the following outputs are available:
- Management groups
- Resource groups
- Virtual network details
- Storage account information
- Log Analytics workspace

## Next Steps

1. Add spoke virtual networks for different workloads
2. Configure Azure Firewall rules
3. Set up VPN/ExpressRoute connectivity
4. Implement advanced policies and role assignments
5. Add monitoring dashboards and alerts

## Security Considerations

- Review and adjust NSG rules for your security requirements
- Implement Azure Firewall policies
- Configure Azure Policy for compliance
- Set up Azure Security Center

## Cost Optimization

- Monitor resource usage through Log Analytics
- Use Azure Cost Management for budget tracking
- Consider reserved instances for long-term deployments

## Contributing

1. Follow Terraform best practices
2. Use consistent naming conventions
3. Test changes in a development environment
4. Update documentation for any changes