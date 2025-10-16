# Storage Account for EJBCA backups and artifacts
resource "azurerm_storage_account" "main" {
  name                     = "${replace(var.project_name, "-", "")}${local.resource_suffix}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  account_kind             = "StorageV2"

  https_traffic_only_enabled = true # Updated from deprecated enable_https_traffic_only
  min_tls_version            = "TLS1_2"

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny" # SECURED: Default deny, explicit allow
    bypass                     = ["AzureServices"]
    ip_rules                   = ["73.140.169.168"] # SECURED: Your current IP
    virtual_network_subnet_ids = [azurerm_subnet.aks.id, azurerm_subnet.services.id]
  }

  tags = local.common_tags
}

# Container for EJBCA backups
resource "azurerm_storage_container" "ejbca_backups" {
  name                  = "ejbca-backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for EJBCA certificates
resource "azurerm_storage_container" "ejbca_certificates" {
  name                  = "ejbca-certificates"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for application logs
resource "azurerm_storage_container" "logs" {
  name                  = "application-logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for Terraform state (optional)
resource "azurerm_storage_container" "terraform_state" {
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for Harbor persistent storage
resource "azurerm_storage_container" "harbor" {
  name                  = "harbor-registry"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for Loki logs
resource "azurerm_storage_container" "loki" {
  name                  = "loki-logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# File Share for shared storage
resource "azurerm_storage_share" "shared" {
  name                 = "shared-storage"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 1024 # 1TB

  metadata = {
    environment = var.environment
    purpose     = "shared-storage"
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-psql"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = var.postgresql_version
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgresql_admin.result
  zone                   = "1"
  storage_mb             = var.postgresql_storage_mb
  sku_name               = var.postgresql_sku_name

  backup_retention_days        = var.postgresql_backup_retention_days
  geo_redundant_backup_enabled = var.postgresql_geo_redundant_backup_enabled

  high_availability {
    mode                      = var.environment == "prod" ? "ZoneRedundant" : "SameZone"
    standby_availability_zone = var.environment == "prod" ? "2" : null
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  tags = local.common_tags

  depends_on = [azurerm_subnet.database]
}

# PostgreSQL Firewall Rule - Allow Azure Services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# PostgreSQL Database for EJBCA
resource "azurerm_postgresql_flexible_server_database" "ejbca" {
  name      = "ejbca"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# PostgreSQL Database for Harbor
resource "azurerm_postgresql_flexible_server_database" "harbor" {
  name      = "harbor"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# PostgreSQL Configuration
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "500"
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_buffers" {
  name      = "shared_buffers"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "262144" # 2GB
}

