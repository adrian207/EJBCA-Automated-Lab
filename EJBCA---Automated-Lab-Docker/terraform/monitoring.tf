# ==============================================================================
# Azure Monitor - Managed Observability Stack
# ==============================================================================
# Author: Adrian Johnson <adrian207@gmail.com>
# Replaces self-hosted Prometheus, Grafana, Loki
# Cost: $50/month (dev) | $150/month (prod)
# ==============================================================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
    Service   = "Log Analytics"
  })
}

# Azure Monitor Workspace (Managed Prometheus)
resource "azurerm_monitor_workspace" "main" {
  name                          = "${var.project_name}-${var.environment}-prometheus"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  public_network_access_enabled = true
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
    Service   = "Managed Prometheus"
  })
}

# Data Collection Endpoint
resource "azurerm_monitor_data_collection_endpoint" "main" {
  name                          = "${var.project_name}-${var.environment}-dce"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  public_network_access_enabled = true
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
  })
}

# Data Collection Rule for Prometheus
resource "azurerm_monitor_data_collection_rule" "prometheus" {
  name                        = "${var.project_name}-${var.environment}-dcr-prometheus"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.main.id
  
  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.main.id
      name              = "MonitoringAccount"
    }
  }
  
  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount"]
  }
  
  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
  })
}

# Azure Managed Grafana
resource "azurerm_dashboard_grafana" "main" {
  name                              = "${var.project_name}-${var.environment}-grafana"
  resource_group_name               = azurerm_resource_group.main.name
  location                          = azurerm_resource_group.main.location
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  
  identity {
    type = "SystemAssigned"
  }
  
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.main.id
  }
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
    Service   = "Managed Grafana"
  })
}

# Grant Grafana access to read from Prometheus
resource "azurerm_role_assignment" "grafana_prometheus_reader" {
  scope                = azurerm_monitor_workspace.main.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

# Application Insights (Distributed Tracing)
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-${var.environment}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
    Service   = "Application Insights"
  })
}

# Store Application Insights connection string in Key Vault
resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "appinsights-connection-string"
  value        = azurerm_application_insights.main.connection_string
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Store instrumentation key in Key Vault
resource "azurerm_key_vault_secret" "appinsights_instrumentation_key" {
  name         = "appinsights-instrumentation-key"
  value        = azurerm_application_insights.main.instrumentation_key
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Store Grafana endpoint in Key Vault
resource "azurerm_key_vault_secret" "grafana_endpoint" {
  name         = "grafana-endpoint"
  value        = azurerm_dashboard_grafana.main.endpoint
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Store Prometheus endpoint in Key Vault
resource "azurerm_key_vault_secret" "prometheus_endpoint" {
  name         = "prometheus-endpoint"
  value        = azurerm_monitor_workspace.main.query_endpoint
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# VM Insights (for VM monitoring)
resource "azurerm_monitor_data_collection_rule" "vm_insights" {
  name                        = "${var.project_name}-${var.environment}-dcr-vm"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.main.id
  
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "VMInsightsPerf"
    }
  }
  
  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["VMInsightsPerf"]
  }
  
  data_sources {
    performance_counter {
      name                          = "VMInsightsPerfCounters"
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\Network Interface(*)\\Bytes Sent/sec",
        "\\Network Interface(*)\\Bytes Received/sec",
      ]
    }
  }
  
  tags = merge(local.common_tags, {
    Component = "Monitoring"
  })
}

