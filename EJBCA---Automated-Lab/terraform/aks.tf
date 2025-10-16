# Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.aks_kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = var.aks_enable_auto_scaling
    min_count           = var.aks_enable_auto_scaling ? var.aks_min_node_count : null
    max_count           = var.aks_enable_auto_scaling ? var.aks_max_node_count : null
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    type                = "VirtualMachineScaleSets"
    zones               = ["1", "2", "3"]

    upgrade_settings {
      max_surge = "33%"
    }

    node_labels = {
      role        = "system"
      environment = var.environment
    }

    tags = local.common_tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    dns_service_ip    = "10.10.0.10"
    service_cidr      = "10.10.0.0/16"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Azure Active Directory Integration (Entra ID)
  azure_active_directory_role_based_access_control {
    # managed = true is now the default and deprecated
    azure_rbac_enabled     = true
    admin_group_object_ids = []
  }

  # Add-ons
  oms_agent {
    log_analytics_workspace_id = var.enable_oms_agent ? azurerm_log_analytics_workspace.main.id : null
  }

  azure_policy_enabled = var.enable_azure_policy

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Maintenance Window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  # Storage Profile
  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  tags = local.common_tags

  depends_on = [
    azurerm_subnet.aks
  ]
}

# Additional Node Pool for Application Workloads
resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.aks_node_vm_size
  node_count            = var.aks_node_count
  vnet_subnet_id        = azurerm_subnet.aks.id
  enable_auto_scaling   = var.aks_enable_auto_scaling
  min_count             = var.aks_enable_auto_scaling ? var.aks_min_node_count : null
  max_count             = var.aks_enable_auto_scaling ? var.aks_max_node_count : null
  os_disk_size_gb       = 128
  os_type               = "Linux"
  zones                 = ["1", "2", "3"]

  upgrade_settings {
    max_surge = "33%"
  }

  node_labels = {
    role        = "application"
    environment = var.environment
    workload    = "apps"
  }

  node_taints = []

  tags = local.common_tags
}

# Node Pool for PKI/EJBCA workloads with enhanced security
resource "azurerm_kubernetes_cluster_node_pool" "pki" {
  name                  = "pki"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D8s_v3" # Larger for PKI operations
  node_count            = 3
  vnet_subnet_id        = azurerm_subnet.aks.id
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 6
  os_disk_size_gb       = 256
  os_type               = "Linux"
  zones                 = ["1", "2", "3"]

  upgrade_settings {
    max_surge = "33%"
  }

  node_labels = {
    role        = "pki"
    environment = var.environment
    workload    = "ejbca"
    security    = "high"
  }

  node_taints = [
    "workload=pki:NoSchedule"
  ]

  tags = merge(
    local.common_tags,
    {
      Purpose = "PKI Certificate Authority"
    }
  )
}

# Role Assignment for AKS to access ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# Role Assignment for AKS to access Key Vault
resource "azurerm_role_assignment" "aks_keyvault" {
  principal_id                     = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = azurerm_key_vault.main.id
  skip_service_principal_aad_check = true
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}${local.resource_suffix}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false # SECURED: Use managed identities instead

  # Geo-replication configured via portal or CLI for Premium SKU if needed
  # Network rules configured to allow AKS subnet access

  retention_policy {
    days    = 30
    enabled = true
  }

  trust_policy {
    enabled = var.environment == "prod" ? true : false
  }

  tags = local.common_tags
}

# Log Analytics Workspace for AKS
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30

  tags = local.common_tags
}

