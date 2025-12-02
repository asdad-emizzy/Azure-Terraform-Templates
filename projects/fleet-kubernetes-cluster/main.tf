# Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  count = var.create_aks_cluster ? 1 : 0

  name                = "${var.aks_cluster_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.aks_dns_prefix != "" ? var.aks_dns_prefix : var.aks_cluster_name

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                = var.default_node_pool_name
    node_count          = var.default_node_pool_node_count
    vm_size             = var.default_node_pool_vm_size
    os_disk_size_gb     = var.default_node_pool_os_disk_size_gb
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_node_count : null
    max_count           = var.enable_auto_scaling ? var.max_node_count : null
    max_pods            = var.max_pods_per_node
    type                = var.node_pool_type
    zones               = var.availability_zones
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    load_balancer_sku  = var.load_balancer_sku
    outbound_type      = var.outbound_type
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
  }

  # API Server authorized IP ranges for security
  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Add-ons using oms_agent block (replaces addon_profile)
  oms_agent {
    log_analytics_workspace_id = var.enable_log_analytics ? var.log_analytics_workspace_id : null
  }

  # Azure Policy addon
  azure_policy_enabled = var.enable_azure_policy

  # RBAC configuration
  local_account_disabled = !var.enable_rbac
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = var.enable_rbac
    admin_group_object_ids = var.enable_rbac ? var.rbac_aad_admin_group_object_ids : []
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = "fleet-kubernetes-cluster"
    }
  )
}

# Additional AKS Clusters
resource "azurerm_kubernetes_cluster" "additional_aks" {
  for_each = var.additional_clusters

  name                = "${each.key}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = each.value.dns_prefix != "" ? each.value.dns_prefix : each.key

  kubernetes_version = lookup(each.value, "kubernetes_version", var.kubernetes_version)

  default_node_pool {
    name                = lookup(each.value, "node_pool_name", var.default_node_pool_name)
    node_count          = lookup(each.value, "node_count", var.default_node_pool_node_count)
    vm_size             = lookup(each.value, "vm_size", var.default_node_pool_vm_size)
    os_disk_size_gb     = lookup(each.value, "os_disk_size_gb", var.default_node_pool_os_disk_size_gb)
    vnet_subnet_id      = var.vnet_subnet_id
    enable_auto_scaling = lookup(each.value, "enable_auto_scaling", var.enable_auto_scaling)
    min_count           = lookup(each.value, "enable_auto_scaling", var.enable_auto_scaling) ? lookup(each.value, "min_count", var.min_node_count) : null
    max_count           = lookup(each.value, "enable_auto_scaling", var.enable_auto_scaling) ? lookup(each.value, "max_count", var.max_node_count) : null
    max_pods            = lookup(each.value, "max_pods", var.max_pods_per_node)
    type                = lookup(each.value, "node_pool_type", var.node_pool_type)
    zones               = lookup(each.value, "availability_zones", var.availability_zones)
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = lookup(each.value, "network_plugin", var.network_plugin)
    network_policy     = lookup(each.value, "network_policy", var.network_policy)
    load_balancer_sku  = lookup(each.value, "load_balancer_sku", var.load_balancer_sku)
    outbound_type      = lookup(each.value, "outbound_type", var.outbound_type)
    service_cidr       = lookup(each.value, "service_cidr", var.service_cidr)
    dns_service_ip     = lookup(each.value, "dns_service_ip", var.dns_service_ip)
  }

  # API Server authorized IP ranges for security
  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # Add-ons using oms_agent block (replaces addon_profile)
  oms_agent {
    log_analytics_workspace_id = var.enable_log_analytics ? var.log_analytics_workspace_id : null
  }

  # Azure Policy addon
  azure_policy_enabled = lookup(each.value, "enable_azure_policy", var.enable_azure_policy)

  # RBAC configuration
  local_account_disabled = !var.enable_rbac
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = var.enable_rbac
    admin_group_object_ids = var.enable_rbac ? var.rbac_aad_admin_group_object_ids : []
  }

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = "fleet-kubernetes-cluster"
      Cluster     = each.key
    }
  )
}

# Azure Kubernetes Fleet Manager
resource "azurerm_kubernetes_fleet_manager" "fleet" {
  count = var.create_fleet_manager ? 1 : 0

  name                = "${var.fleet_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = "fleet-kubernetes-cluster"
    }
  )
}

# Fleet Member for Primary AKS Cluster
resource "azurerm_kubernetes_fleet_member" "aks_member" {
  count = var.create_aks_cluster && var.create_fleet_manager ? 1 : 0

  name                        = "${var.aks_cluster_name}-${var.environment}"
  kubernetes_fleet_id         = azurerm_kubernetes_fleet_manager.fleet[0].id
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.aks[0].id
  group                       = var.fleet_member_group

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_kubernetes_fleet_manager.fleet
  ]
}

# Fleet Members for Additional Clusters
resource "azurerm_kubernetes_fleet_member" "additional_members" {
  for_each = var.create_fleet_manager ? var.additional_clusters : {}

  name                        = "${each.key}-${var.environment}"
  kubernetes_fleet_id         = azurerm_kubernetes_fleet_manager.fleet[0].id
  kubernetes_cluster_id       = azurerm_kubernetes_cluster.additional_aks[each.key].id
  group                       = lookup(each.value, "fleet_group", var.fleet_member_group)

  depends_on = [
    azurerm_kubernetes_cluster.additional_aks,
    azurerm_kubernetes_fleet_manager.fleet
  ]
}