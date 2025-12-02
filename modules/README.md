# Azure-Terraform Modules Reference

This document provides a reference for all available Azure-Terraform modules with their stable version tags for use in your Terraform projects.

## Available Modules

### terraform-azurerm-resource-group
- **Repository**: https://github.com/Azure-Terraform/terraform-azurerm-resource-group
- **Latest Version**: v2.1.1
- **Purpose**: Resource group creation and management
- **Usage**:
```hcl
module "resource_group" {
  source  = "git::https://github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v2.1.1"
  version = "2.1.1"

  names = {
    environment         = "dev"
    location            = "eastus"
    market              = "us"
    product_name        = "myapp"
    resource_group_type = "networking"
  }
  location = "East US"
  tags     = var.tags
}
```

### terraform-azurerm-virtual-network
- **Repository**: https://github.com/Azure-Terraform/terraform-azurerm-virtual-network
- **Latest Version**: v8.2.0
- **Purpose**: Virtual network and subnet configuration
- **Usage**:
```hcl
module "virtual_network" {
  source  = "git::https://github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v8.2.0"
  version = "8.2.0"

  names = {
    environment         = "dev"
    location            = "eastus"
    market              = "us"
    product_name        = "myapp"
    resource_group_type = "networking"
  }
  resource_group_name = azurerm_resource_group.example.name
  location           = "East US"
  address_space      = ["10.0.0.0/16"]
  tags              = var.tags
}
```

### terraform-azurerm-storage-account
- **Repository**: https://github.com/Azure-Terraform/terraform-azurerm-storage-account
- **Latest Version**: v1.2.0
- **Purpose**: Storage account setup and configuration
- **Usage**:
```hcl
module "storage_account" {
  source  = "git::https://github.com/Azure-Terraform/terraform-azurerm-storage-account.git?ref=v1.2.0"
  version = "1.2.0"

  name                = "mystorageaccount"
  resource_group_name = azurerm_resource_group.example.name
  location           = "East US"
  account_tier       = "Standard"
  replication_type   = "LRS"
  tags              = var.tags
}
```

## Version Management Strategy

### Semantic Versioning
All modules follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Recommended Practices
1. **Pin to specific versions** in production environments
2. **Test upgrades** in development environments first
3. **Document version changes** in your deployment notes
4. **Use version constraints** for flexibility within safe ranges

### Version Constraints Examples
```hcl
# Exact version
version = "1.2.0"

# Compatible with minor versions
version = "~> 1.2.0"

# Compatible with major versions
version = "~> 1.0"
```

## Local Development

For local development and testing, you can reference the cloned modules:

```hcl
module "storage_account" {
  source = "../../modules/terraform-azurerm-storage-account"
  # ... parameters
}
```

## Updating Versions

To update to newer versions:

1. Check the [Azure-Terraform releases](https://github.com/Azure-Terraform) for each module
2. Review the changelog for breaking changes
3. Test in a development environment
4. Update the version tag in your Terraform code
5. Run `terraform plan` to verify changes
6. Apply the updates

## Contributing

When adding new modules to your projects:
1. Use the latest stable version tag
2. Document the module usage in your project README
3. Test the module integration thoroughly
4. Consider the module's maintenance status and community support

## Module Complexity Considerations

### Enterprise-Grade Features
The Azure-Terraform modules provide enterprise-grade features but require complex setup:

- **Naming Conventions**: Standardized naming using metadata modules
- **Interdependencies**: Modules often require other modules (naming, metadata)
- **Configuration Overhead**: Extensive variable requirements

### When to Use Complex Modules
- **Large Enterprises**: With standardized naming requirements
- **Multi-Team Environments**: Where consistency is critical
- **Complex Deployments**: Requiring extensive tagging and metadata

### When to Use Direct Resources
- **Landing Zone Foundations**: Basic infrastructure setup
- **Custom Requirements**: Non-standard naming or configurations
- **Learning/Projects**: Simpler implementations for education

### Recommended Approach
1. **Start Simple**: Use direct azurerm resources for basic landing zones
2. **Adopt Gradually**: Introduce complex modules as standardization needs grow
3. **Mix and Match**: Use complex modules for specialized services, direct resources for basics