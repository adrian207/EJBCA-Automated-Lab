# ==============================================================================
# Virtual Machines - Docker Hosts for EJBCA
# ==============================================================================
# Author: Adrian Johnson <adrian207@gmail.com>
# Ubuntu VMs running Docker Compose (hybrid approach)
# Dev: 1x Standard_D4s_v3 ($170/month)
# Prod: 3x Standard_D4s_v3 ($510/month) or 3x Standard_D8s_v3 ($1,020/month)
# ==============================================================================

# Linux VMs for Docker
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.vm_count
  name                = "${var.project_name}-${var.environment}-vm${count.index + 1}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]
  
  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  disable_password_authentication = true
  
  identity {
    type = "SystemAssigned"
  }
  
  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init.yaml", {
    environment           = var.environment
    storage_account_name  = azurerm_storage_account.main.name
    storage_account_key   = azurerm_storage_account.main.primary_access_key
    keyvault_name         = azurerm_key_vault.main.name
    postgres_host         = azurerm_postgresql_flexible_server.main.fqdn
    acr_login_server      = azurerm_container_registry.main.login_server
  }))
  
  tags = merge(local.common_tags, {
    OS        = "Ubuntu 22.04 LTS"
    Purpose   = "Docker Host - EJBCA"
    Component = "Compute"
  })
}

# Generate SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store SSH private key in Key Vault
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "vm-ssh-private-key"
  value        = tls_private_key.ssh.private_key_pem
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# VM Extension - Azure Monitor Agent
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  count                      = var.vm_count
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.25"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  
  tags = local.common_tags
}

# VM Extension - Dependency Agent (for VM Insights)
resource "azurerm_virtual_machine_extension" "dependency_agent" {
  count                      = var.vm_count
  name                       = "DependencyAgentLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.main[count.index].id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.10"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true
  
  depends_on = [azurerm_virtual_machine_extension.azure_monitor_agent]
  
  tags = local.common_tags
}

# Data Collection Rule Association
resource "azurerm_monitor_data_collection_rule_association" "vm_insights" {
  count                   = var.vm_count
  name                    = "${var.project_name}-${var.environment}-dcra-vm${count.index + 1}"
  target_resource_id      = azurerm_linux_virtual_machine.main[count.index].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights.id
  
  description = "Association of VM to Data Collection Rule for VM Insights"
}

# Data Collection Rule Association - Prometheus
resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  count                   = var.vm_count
  name                    = "${var.project_name}-${var.environment}-dcra-prom-vm${count.index + 1}"
  target_resource_id      = azurerm_linux_virtual_machine.main[count.index].id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
  
  description = "Association of VM to Data Collection Rule for Prometheus"
}

# Role Assignment - VMs can access Key Vault
resource "azurerm_role_assignment" "vm_keyvault" {
  count                = var.vm_count
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.main[count.index].identity[0].principal_id
}

# Role Assignment - VMs can access Storage Account
resource "azurerm_role_assignment" "vm_storage" {
  count                = var.vm_count
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.main[count.index].identity[0].principal_id
}

# Azure Load Balancer (Production only, HA setup with 3+ VMs)
resource "azurerm_lb" "main" {
  count               = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb[0].id
  }
  
  tags = merge(local.common_tags, {
    Component = "Load Balancer"
  })
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "lb" {
  count               = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-lb-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = merge(local.common_tags, {
    Component = "Load Balancer"
  })
}

# Backend Address Pool
resource "azurerm_lb_backend_address_pool" "main" {
  count           = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  loadbalancer_id = azurerm_lb.main[0].id
  name            = "ejbca-backend-pool"
}

# Backend Address Pool Association
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.vm_count >= 3 && var.environment == "prod" ? var.vm_count : 0
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main[0].id
}

# Load Balancer Rule - HTTPS (8443)
resource "azurerm_lb_rule" "https" {
  count                          = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "HTTPS"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 8443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  probe_id                       = azurerm_lb_probe.https[0].id
  enable_floating_ip             = false
  enable_tcp_reset               = true
}

# Load Balancer Rule - HTTP (redirect to HTTPS handled by NGINX)
resource "azurerm_lb_rule" "http" {
  count                          = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  loadbalancer_id                = azurerm_lb.main[0].id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main[0].id]
  probe_id                       = azurerm_lb_probe.http[0].id
  enable_floating_ip             = false
  enable_tcp_reset               = true
}

# Health Probe - HTTPS
resource "azurerm_lb_probe" "https" {
  count               = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  loadbalancer_id     = azurerm_lb.main[0].id
  name                = "https-probe"
  protocol            = "Tcp"
  port                = 8443
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Health Probe - HTTP
resource "azurerm_lb_probe" "http" {
  count               = var.vm_count >= 3 && var.environment == "prod" ? 1 : 0
  loadbalancer_id     = azurerm_lb.main[0].id
  name                = "http-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Generate random passwords
resource "random_password" "ejbca_cli" {
  length  = 32
  special = true
}

# Store EJBCA CLI password in Key Vault
resource "azurerm_key_vault_secret" "ejbca_cli_password" {
  name         = "ejbca-cli-password"
  value        = random_password.ejbca_cli.result
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.terraform]
}
