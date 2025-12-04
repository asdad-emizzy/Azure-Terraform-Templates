# variables.tf - CMS Terraform Configuration Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "domain_name" {
  description = "Custom domain name for DNS zone"
  type        = string
  default     = "cms.example.com"
}

variable "container_image" {
  description = "Container image URI (ACR URL or Docker Hub)"
  type        = string
  default     = "nginx:latest"  # Change to your ACR image
}

variable "container_registry_username" {
  description = "Container registry username (for ACR authentication)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "container_registry_password" {
  description = "Container registry password (for ACR authentication)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssl_certificate_path" {
  description = "Path to SSL certificate PFX file"
  type        = string
  default     = ""
}

variable "ssl_certificate_password" {
  description = "SSL certificate password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_waf" {
  description = "Enable Web Application Firewall on Application Gateway"
  type        = bool
  default     = true
}

variable "enable_front_door" {
  description = "Enable Azure Front Door CDN"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backup configuration"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

variable "container_cpu" {
  description = "Container CPU allocation (0.25, 0.5, 1, etc.)"
  type        = string
  default     = "0.25"
}

variable "container_memory" {
  description = "Container memory allocation (0.5Gi, 1Gi, etc.)"
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Minimum number of Container App replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of Container App replicas for auto-scaling"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "CMS"
    ManagedBy   = "Terraform"
  }
}

# Backup configuration variables
variable "backup_enabled" {
  description = "Enable backup vault and policies"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "storage_replication_type" {
  description = "Storage account replication type (LRS, GRS, RA-GRS)"
  type        = string
  default     = "LRS"
}

variable "enable_blob_versioning" {
  description = "Enable blob versioning for data protection"
  type        = bool
  default     = true
}

variable "enable_soft_delete" {
  description = "Enable soft delete for blob recovery"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention period in days"
  type        = number
  default     = 7
}
