# AKS Clusters
output "aks_cluster" {
  description = "Primary AKS cluster details"
  value       = var.create_aks_cluster ? azurerm_kubernetes_cluster.aks[0] : null
}

output "aks_cluster_name" {
  description = "Primary AKS cluster name"
  value       = var.create_aks_cluster ? azurerm_kubernetes_cluster.aks[0].name : null
}

output "aks_cluster_kube_config" {
  description = "Primary AKS cluster kube config (sensitive)"
  value       = var.create_aks_cluster ? azurerm_kubernetes_cluster.aks[0].kube_config_raw : null
  sensitive   = true
}

output "aks_cluster_fqdn" {
  description = "Primary AKS cluster FQDN"
  value       = var.create_aks_cluster ? azurerm_kubernetes_cluster.aks[0].fqdn : null
}

# Additional AKS Clusters
output "additional_aks_clusters" {
  description = "Additional AKS clusters details"
  value       = azurerm_kubernetes_cluster.additional_aks
}

output "additional_cluster_names" {
  description = "Names of additional AKS clusters"
  value       = keys(var.additional_clusters)
}

# Azure Kubernetes Fleet Manager
output "fleet_manager" {
  description = "Azure Kubernetes Fleet Manager details"
  value       = var.create_fleet_manager ? azurerm_kubernetes_fleet_manager.fleet[0] : null
}

output "fleet_name" {
  description = "Azure Kubernetes Fleet name"
  value       = var.create_fleet_manager ? azurerm_kubernetes_fleet_manager.fleet[0].name : null
}

output "fleet_id" {
  description = "Azure Kubernetes Fleet ID"
  value       = var.create_fleet_manager ? azurerm_kubernetes_fleet_manager.fleet[0].id : null
}

# Fleet Members
output "fleet_members" {
  description = "Fleet member associations"
  value = var.create_fleet_manager ? merge(
    var.create_aks_cluster ? {
      "${var.aks_cluster_name}-${var.environment}" = azurerm_kubernetes_fleet_member.aks_member[0]
    } : {},
    { for k, v in azurerm_kubernetes_fleet_member.additional_members : k => v }
  ) : {}
}

# Cluster Endpoints
output "cluster_endpoints" {
  description = "All cluster endpoints for kubectl access"
  value = merge(
    var.create_aks_cluster ? {
      "${var.aks_cluster_name}-${var.environment}" = {
        host = azurerm_kubernetes_cluster.aks[0].kube_config[0].host
        cluster_ca_certificate = azurerm_kubernetes_cluster.aks[0].kube_config[0].cluster_ca_certificate
        client_certificate = azurerm_kubernetes_cluster.aks[0].kube_config[0].client_certificate
        client_key = azurerm_kubernetes_cluster.aks[0].kube_config[0].client_key
      }
    } : {},
    { for k, v in azurerm_kubernetes_cluster.additional_aks : k => {
      host = v.kube_config[0].host
      cluster_ca_certificate = v.kube_config[0].cluster_ca_certificate
      client_certificate = v.kube_config[0].client_certificate
      client_key = v.kube_config[0].client_key
    }}
  )
  sensitive = true
}