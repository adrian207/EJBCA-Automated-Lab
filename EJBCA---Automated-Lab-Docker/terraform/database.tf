# ==============================================================================
# Azure Database for PostgreSQL Flexible Server
# ==============================================================================
# Author: Adrian Johnson <adrian207@gmail.com>
# Managed PostgreSQL for EJBCA (replaces self-hosted database)
# Cost: $120/month (dev) | $340/month (prod)
# ==============================================================================

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.project_name}-${var.environment}-postgres"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "15"
  administrator_login    = var.postgres_admin_username
  administrator_password = random_password.postgres_password.result
  
  # Development: B_Standard_B2s (2 vCores, 4GB RAM)
  # Production: GP_Standard_D4s_v3 (4 vCores, 16GB RAM)
  sku_name   = var.environment == "prod" ? "GP_Standard_D4s_v3" : "B_Standard_B2s"
  storage_mb = var.environment == "prod" ? 131072 : 32768  # 128GB prod, 32GB dev
  
  backup_retention_days        = var.environment == "prod" ? 35 : 7
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false
  
  high_availability {
    mode                      = var.environment == "prod" ? "ZoneRedundant" : null
    standby_availability_zone = var.environment == "prod" ? "2" : null
  }
  
  zone = "1"
  
  tags = merge(local.common_tags, {
    Component = "Database"
    Service   = "PostgreSQL"
  })
}

# PostgreSQL Database
resource "azurerm_postgresql_flexible_server_database" "ejbca" {
  name      = "ejbca"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Firewall rule for Azure services
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Firewall rule for VNet integration
resource "azurerm_postgresql_flexible_server_firewall_rule" "vnet" {
  name             = "AllowVNet"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = cidrhost(azurerm_subnet.vms.address_prefixes[0], 0)
  end_ip_address   = cidrhost(azurerm_subnet.vms.address_prefixes[0], -1)
}

# PostgreSQL password
resource "random_password" "postgres_password" {
  length  = 32
  special = true
}

# Store password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# PostgreSQL configuration
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = var.environment == "prod" ? "200" : "100"
}

resource "azurerm_postgresql_flexible_server_configuration" "shared_buffers" {
  name      = "shared_buffers"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = var.environment == "prod" ? "4194304" : "1048576"  # 4GB prod, 1GB dev (in 8KB pages)
}

resource "azurerm_postgresql_flexible_server_configuration" "ssl_enforcement" {
  name      = "ssl"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

