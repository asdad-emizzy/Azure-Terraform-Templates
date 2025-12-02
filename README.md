# Azure Terraform Templates

This repository contains reusable Terraform templates for deploying infrastructure on Microsoft Azure, organized in a structured project-based layout.

## Repository Structure

```
├── projects/                    # Individual project implementations
│   ├── azure-landing-zone/     # Azure landing zone project
│   │   ├── main.tf             # Main Terraform configuration
│   │   ├── variables.tf        # Input variables
│   │   ├── outputs.tf          # Output values
│   │   ├── providers.tf        # Provider configuration
│   │   ├── .gitignore          # Git ignore rules
│   │   └── README.md           # Project documentation
│   └── fleet-kubernetes-cluster/ # Kubernetes infrastructure project
│       ├── main.tf             # AKS and Fleet Manager configuration
│       ├── variables.tf        # Input variables
│       ├── outputs.tf          # Output values
│       ├── providers.tf        # Provider configuration
│       ├── .gitignore          # Git ignore rules
│       └── README.md           # Project documentation
├── modules/                     # Reusable Terraform modules
│   ├── terraform-azurerm-resource-group/
│   ├── terraform-azurerm-virtual-network/
│   └── terraform-azurerm-storage-account/
└── README.md                   # This file
```

## Projects

### Azure Landing Zone
A foundational landing zone implementation with:
- Hub-and-spoke network topology
- Management groups and governance
- Centralized logging and monitoring
- Basic security policies

**Location**: `projects/azure-landing-zone/`

### Fleet Kubernetes Cluster
A comprehensive Kubernetes infrastructure solution with:
- Azure Kubernetes Service (AKS) clusters
- Azure Kubernetes Fleet Manager for multi-cluster management
- Advanced networking and security configurations
- Auto-scaling and monitoring integration
- Support for multiple clusters in different environments

**Location**: `projects/fleet-kubernetes-cluster/`

**Dependencies**: Requires networking infrastructure from `azure-landing-zone`

## Modules

Modules are cloned from the [Azure-Terraform](https://github.com/Azure-Terraform) organization and provide reusable components for Azure infrastructure.

### Available Modules
- **terraform-azurerm-resource-group**: Resource group creation utilities
- **terraform-azurerm-virtual-network**: Virtual network and subnet management
- **terraform-azurerm-storage-account**: Storage account configuration

### Version Management
All modules are referenced with stable version tags for reproducible deployments. See [modules/README.md](modules/README.md) for detailed usage examples and version management strategies.

## Getting Started

1. **Choose a project** to work with from the `projects/` directory
2. **Review prerequisites** in the project README
3. **Configure variables** as needed
4. **Initialize and deploy**:

```bash
cd projects/<project-name>
terraform init
terraform plan
terraform apply
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (version 1.0 or later)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- Azure subscription with appropriate permissions

## Authentication

```bash
az login
az account set --subscription <subscription-id>
```

## Best Practices

- Always review `terraform plan` output before applying
- Use remote state for team collaboration
- Implement proper naming conventions
- Tag resources consistently

## Contributing

1. Follow the established project structure
2. Update documentation for any changes
3. Test configurations thoroughly
4. Use meaningful commit messages

## License

This project follows the same licensing as the source modules from Azure-Terraform.

## References

- [Azure Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure-Terraform Modules](https://github.com/Azure-Terraform)
