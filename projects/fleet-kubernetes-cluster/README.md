# Fleet Kubernetes Cluster

This Terraform project creates Azure Kubernetes Service (AKS) clusters with optional Azure Kubernetes Fleet Manager for multi-cluster management scenarios.

## Features

- **AKS Clusters**: Create one or more AKS clusters with advanced configuration
- **Fleet Manager**: Optional Azure Kubernetes Fleet Manager for centralized multi-cluster management
- **Auto Scaling**: Node pool auto-scaling with configurable min/max counts
- **Network Configuration**: Advanced networking with Azure CNI, Calico, or Kubenet
- **Monitoring**: Integration with Azure Monitor and Log Analytics
- **Security**: Azure Policy integration and RBAC configuration
- **Multi-Cluster Support**: Create additional clusters and manage them through Fleet Manager

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Fleet Manager │────│  AKS Cluster 1  │
│                 │    │  (Primary)      │
└─────────────────┘    └─────────────────┘
          │
          ├─────────────────┐
          │  AKS Cluster 2  │
          │  (Additional)   │
          └─────────────────┘
          │
          ├─────────────────┐
          │  AKS Cluster N  │
          │  (Additional)   │
          └─────────────────┘
```

## Prerequisites

- Terraform >= 1.0
- Azure subscription with appropriate permissions
- Azure CLI authenticated (`az login`)

## Quick Start

1. **Clone and navigate to the project**:
   ```bash
   cd projects/fleet-kubernetes-cluster
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Configure variables** (create `terraform.tfvars`):
   ```hcl
   location            = "East US"
   environment         = "dev"
   resource_group_name = "rg-kubernetes-dev"

   # AKS Configuration
   create_aks_cluster = true
   aks_cluster_name   = "my-cluster"
   kubernetes_version = "1.27.0"

   # Fleet Manager (optional)
   create_fleet_manager = true
   fleet_name          = "my-fleet"

   # Networking
   vnet_subnet_id = "/subscriptions/.../subnets/kubernetes"
   ```

4. **Plan and apply**:
   ```bash
   terraform plan
   terraform apply
   ```

## Configuration Options

### Basic AKS Cluster

```hcl
create_aks_cluster = true
aks_cluster_name   = "my-cluster"
kubernetes_version = "1.27.0"
default_node_pool_node_count = 3
default_node_pool_vm_size    = "Standard_DS3_v2"
```

### Auto Scaling

```hcl
enable_auto_scaling = true
min_node_count     = 1
max_node_count     = 10
```

### Fleet Manager for Multi-Cluster

```hcl
create_fleet_manager = true
fleet_name          = "production-fleet"

additional_clusters = {
  "staging" = {
    node_count = 2
    vm_size    = "Standard_DS2_v2"
    fleet_group = "staging"
  },
  "production-east" = {
    node_count = 5
    vm_size    = "Standard_DS3_v2"
    fleet_group = "production"
  }
}
```

### API Server Security

```hcl
# Restrict API server access to specific IP ranges (recommended for production)
api_server_authorized_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]

# Or leave empty for public access (development only)
api_server_authorized_ip_ranges = []
```

### Monitoring and Security

```hcl
enable_log_analytics = true
log_analytics_workspace_id = "/subscriptions/.../workspaces/my-log-workspace"

enable_azure_policy = true
enable_rbac        = true
rbac_aad_managed   = true
```

## Outputs

- `aks_cluster`: Primary AKS cluster details
- `aks_cluster_kube_config`: Kube config for kubectl access (sensitive)
- `fleet_manager`: Fleet Manager details
- `additional_aks_clusters`: Additional cluster details
- `cluster_endpoints`: All cluster endpoints for management

## Usage Examples

### Single Cluster

```hcl
create_aks_cluster = true
create_fleet_manager = false
```

### Multi-Cluster with Fleet Manager

```hcl
create_aks_cluster = true
create_fleet_manager = true

additional_clusters = {
  "cluster-2" = {
    node_count = 3
    vm_size    = "Standard_DS3_v2"
  },
  "cluster-3" = {
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }
}
```

### Development Environment

```hcl
environment = "dev"
default_node_pool_node_count = 1
enable_auto_scaling = false
enable_log_analytics = false
```

## Integration with Landing Zone

This project is designed to work alongside the `azure-landing-zone` project:

1. Deploy the landing zone first to create networking and monitoring infrastructure
2. Use outputs from the landing zone (like `vnet_subnet_id`) as inputs to this project
3. The landing zone provides the foundational infrastructure that Kubernetes clusters need

## Security Considerations

- Enable RBAC (`enable_rbac = true`) for production deployments
- Use Azure AD integration for authentication
- Enable Azure Policy for compliance
- Configure network policies appropriately
- Use private clusters for sensitive workloads
- Regularly update Kubernetes versions

## Cost Optimization

- Use auto-scaling to match workload demands
- Choose appropriate VM sizes for your workloads
- Consider spot instances for non-critical workloads
- Use Azure reservations for predictable workloads

## Troubleshooting

### Common Issues

1. **Subnet Capacity**: Ensure your subnet has enough IP addresses for all nodes and services
2. **RBAC Permissions**: Verify your Azure account has appropriate permissions
3. **Network Policies**: Check that network security groups allow necessary traffic
4. **Resource Quotas**: Verify Azure subscription quotas for VMs and other resources

### Getting Cluster Access

After deployment, get kubeconfig:

```bash
terraform output -raw aks_cluster_kube_config > kubeconfig
export KUBECONFIG=./kubeconfig
kubectl get nodes
```

## Contributing

1. Follow Terraform best practices
2. Use consistent naming conventions
3. Document any new variables or features
4. Test changes in a development environment first