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

variable "resource_group_name" {
  description = "Name of the resource group for Kubernetes resources"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "Kubernetes"
    ManagedBy   = "Terraform"
    Project     = "Fleet Kubernetes Cluster"
  }
}

# AKS Configuration
variable "create_aks_cluster" {
  description = "Whether to create an AKS cluster"
  type        = bool
  default     = true
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-fleet-cluster"
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.27.0"
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS cluster integration"
  type        = string
}

# Azure Kubernetes Fleet Manager
variable "create_fleet_manager" {
  description = "Whether to create Azure Kubernetes Fleet Manager"
  type        = bool
  default     = false
}

variable "fleet_name" {
  description = "Name of the Azure Kubernetes Fleet"
  type        = string
  default     = "fleet-kubernetes"
}

# Additional Clusters (for multi-cluster scenarios)
variable "additional_clusters" {
  description = "Map of additional AKS clusters to create"
  type = map(object({
    node_count          = optional(number, 2)
    vm_size             = optional(string, "Standard_DS2_v2")
    subnet_id           = optional(string, null)
    dns_prefix          = optional(string, "")
    kubernetes_version  = optional(string, null)
    node_pool_name      = optional(string, "default")
    os_disk_size_gb     = optional(number, 128)
    enable_auto_scaling = optional(bool, false)
    min_count           = optional(number, 1)
    max_count           = optional(number, 10)
    max_pods            = optional(number, 30)
    node_pool_type      = optional(string, "VirtualMachineScaleSets")
    availability_zones  = optional(list(string), [])
    network_plugin      = optional(string, null)
    network_policy      = optional(string, null)
    load_balancer_sku   = optional(string, null)
    outbound_type       = optional(string, null)
    service_cidr        = optional(string, null)
    dns_service_ip      = optional(string, null)
    docker_bridge_cidr  = optional(string, null)
    enable_kube_dashboard = optional(bool, null)
    enable_azure_policy   = optional(bool, null)
    fleet_group         = optional(string, null)
  }))
  default = {}
}

# Advanced AKS Configuration Variables
variable "aks_dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS clusters"
  type        = string
  default     = "1.27.0"
}

variable "default_node_pool_name" {
  description = "Name of the default node pool"
  type        = string
  default     = "default"
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "default_node_pool_os_disk_size_gb" {
  description = "OS disk size in GB for default node pool"
  type        = number
  default     = 128
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for default node pool"
  type        = bool
  default     = false
}

variable "min_node_count" {
  description = "Minimum node count for auto scaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum node count for auto scaling"
  type        = number
  default     = 10
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 30
}

variable "node_pool_type" {
  description = "Type of node pool (VirtualMachineScaleSets or AvailabilitySet)"
  type        = string
  default     = "VirtualMachineScaleSets"
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = []
}

# Network Configuration
variable "network_plugin" {
  description = "Network plugin to use (azure or kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy to use (azure or calico)"
  type        = string
  default     = "azure"
}

variable "load_balancer_sku" {
  description = "SKU of the load balancer (basic or standard)"
  type        = string
  default     = "standard"
}

variable "outbound_type" {
  description = "Outbound type for cluster egress"
  type        = string
  default     = "loadBalancer"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for DNS service"
  type        = string
  default     = "10.0.0.10"
}

variable "docker_bridge_cidr" {
  description = "CIDR for Docker bridge"
  type        = string
  default     = "172.17.0.1/16"
}

# Add-ons Configuration
variable "enable_log_analytics" {
  description = "Enable Azure Monitor for containers"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
  default     = null
}

variable "enable_kube_dashboard" {
  description = "Enable Kubernetes dashboard"
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy for Kubernetes"
  type        = bool
  default     = true
}

# RBAC Configuration
variable "enable_rbac" {
  description = "Enable role-based access control"
  type        = bool
  default     = true
}

variable "rbac_aad_managed" {
  description = "Enable managed Azure Active Directory integration"
  type        = bool
  default     = true
}

variable "rbac_aad_admin_group_object_ids" {
  description = "Object IDs of Azure AD groups to be AAD cluster admins"
  type        = list(string)
  default     = []
}

# API Server Security
variable "api_server_authorized_ip_ranges" {
  description = "IP ranges authorized to access the Kubernetes API server. Leave empty for public access (not recommended for production)"
  type        = list(string)
  default     = []
}

# Fleet Manager Configuration
variable "fleet_dns_prefix" {
  description = "DNS prefix for Fleet Manager"
  type        = string
  default     = ""
}

variable "fleet_member_group" {
  description = "Group name for fleet members"
  type        = string
  default     = "member"
}