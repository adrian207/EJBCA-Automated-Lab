variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ejbca-platform"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure VM access (eliminates need for public IPs and IP whitelisting)"
  type        = bool
  default     = true
}

variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "use_random_suffix" {
  description = "Add random suffix to resource names for uniqueness"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# AKS Variables
variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28"
}

variable "aks_node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "aks_enable_auto_scaling" {
  description = "Enable autoscaling for node pools"
  type        = bool
  default     = true
}

variable "aks_min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "aks_max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on for AKS"
  type        = bool
  default     = true
}

variable "enable_oms_agent" {
  description = "Enable Azure Monitor Container Insights"
  type        = bool
  default     = true
}

# Network Variables
variable "vnet_address_space" {
  description = "Address space for Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "services_subnet_address_prefix" {
  description = "Address prefix for services subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_subnet_address_prefix" {
  description = "Address prefix for database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "vpn_gateway_subnet_address_prefix" {
  description = "Address prefix for VPN Gateway subnet"
  type        = string
  default     = "10.0.255.0/27"
}

# Key Vault Variables
variable "keyvault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.keyvault_sku)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

variable "keyvault_enabled_for_disk_encryption" {
  description = "Enable Key Vault for disk encryption"
  type        = bool
  default     = true
}

variable "keyvault_soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 90
}

# Storage Variables
variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "GRS"
}

# PostgreSQL Variables
variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "GP_Standard_D4s_v3"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 131072 # 128GB
}

variable "postgresql_backup_retention_days" {
  description = "Backup retention days"
  type        = number
  default     = 30
}

variable "postgresql_geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = true
}

# ACR Variables
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Windows Server Variables
variable "windows_vm_size" {
  description = "VM size for Windows Server"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "windows_admin_username" {
  description = "Admin username for Windows Server"
  type        = string
  default     = "adminuser"
}

# RHEL Variables
variable "rhel_vm_size" {
  description = "VM size for RHEL"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "rhel_admin_username" {
  description = "Admin username for RHEL"
  type        = string
  default     = "adminuser"
}

