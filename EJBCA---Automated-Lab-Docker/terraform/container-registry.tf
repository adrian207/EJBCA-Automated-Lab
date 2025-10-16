# ==============================================================================
# Azure Container Registry
# ==============================================================================
# Author: Adrian Johnson <adrian207@gmail.com>
# Replaces Harbor Registry (cost-optimized)
# Cost: $5/month (Basic) | $20/month (Standard)
# ==============================================================================

resource "azurerm_container_registry" "main" {
  name                = replace("${var.project_name}${var.environment}acr", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  # Basic for dev, Standard for prod
  sku = var.environment == "prod" ? "Standard" : "Basic"
  
  # Admin user disabled - use managed identities
  admin_enabled = false
  
  # Network rules (production only)
  dynamic "network_rule_set" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      default_action = "Deny"
      
      ip_rule {
        action   = "Allow"
        ip_range = var.admin_ip_address
      }
      
      virtual_network_rule {
        action    = "Allow"
        subnet_id = azurerm_subnet.vms.id
      }
    }
  }
  
  # Geo-replication (production only, requires Premium SKU if enabled)
  # Commented out to save costs - can enable with Premium SKU
  # dynamic "georeplications" {
  #   for_each = var.environment == "prod" ? var.acr_geo_replications : []
  #   content {
  #     location = georeplications.value
  #     tags     = local.common_tags
  #   }
  # }
  
  tags = merge(local.common_tags, {
    Component = "Container Registry"
    Service   = "ACR"
  })
}

# Grant VM managed identity pull access
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.vm_count
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.main[count.index].identity[0].principal_id
}

# Grant Key Vault access to ACR managed identity (if using managed identity)
resource "azurerm_key_vault_access_policy" "acr" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_container_registry.main.identity[0].principal_id
  
  secret_permissions = [
    "Get",
    "List"
  ]
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# ACR webhook for automated deployments (optional)
resource "azurerm_container_registry_webhook" "deployment" {
  name                = "${var.project_name}${var.environment}webhook"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  registry_name       = azurerm_container_registry.main.name
  
  service_uri = var.acr_webhook_url
  status      = var.acr_webhook_url != "" ? "enabled" : "disabled"
  scope       = "ejbca-ce:*"
  actions     = ["push"]
  
  custom_headers = {
    "Content-Type" = "application/json"
  }
}

