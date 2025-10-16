output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_kube_config" {
  description = "Kubernetes configuration for AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string for storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "acr_login_server" {
  description = "Login server for Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "Admin username for ACR"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for ACR"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "postgresql_fqdn" {
  description = "FQDN of PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_database_name" {
  description = "Name of EJBCA database"
  value       = azurerm_postgresql_flexible_server_database.ejbca.name
}

output "windows_server_private_ip" {
  description = "Private IP of Windows Server"
  value       = azurerm_network_interface.windows.private_ip_address
}

output "windows_server_public_ip" {
  description = "Public IP of Windows Server"
  value       = azurerm_public_ip.windows.ip_address
}

output "rhel_server_private_ip" {
  description = "Private IP of RHEL Server"
  value       = azurerm_network_interface.rhel.private_ip_address
}

output "rhel_server_public_ip" {
  description = "Public IP of RHEL Server"
  value       = azurerm_public_ip.rhel.ip_address
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "log_analytics_workspace_id" {
  description = "ID of Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "connection_commands" {
  description = "Commands to connect to resources"
  value = {
    aks_get_credentials = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
    acr_login           = "az acr login --name ${azurerm_container_registry.main.name}"
    windows_rdp         = "mstsc /v:${azurerm_public_ip.windows.ip_address}"
    rhel_ssh            = "ssh ${var.rhel_admin_username}@${azurerm_public_ip.rhel.ip_address}"
  }
}


# ============================================================================
# Azure Bastion Outputs
# ============================================================================

output "bastion_host_name" {
  description = "Name of the Azure Bastion host"
  value       = azurerm_bastion_host.main.name
}

output "bastion_dns_name" {
  description = "DNS name of the Azure Bastion host"
  value       = azurerm_bastion_host.main.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}

output "bastion_instructions" {
  description = "How to connect to VMs via Azure Bastion"
  value       = <<-EOT
    Azure Bastion - Secure VM Access (No IP Management Needed!)
    
    Connect via Azure Portal:
      1. Go to your VM → Connect → Bastion
      2. Enter credentials and connect
      
    Connect via Azure CLI:
      Windows: az network bastion rdp --name ${azurerm_bastion_host.main.name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id <VM_ID>
      Linux:   az network bastion ssh --name ${azurerm_bastion_host.main.name} --resource-group ${azurerm_resource_group.main.name} --target-resource-id <VM_ID> --auth-type password --username adminuser
    
    Benefits:
      ✓ Access from anywhere (no IP whitelist!)
      ✓ Encrypted over TLS (port 443)
      ✓ Copy/paste and file transfer enabled
      ✓ Full audit logging
      ✓ Cost: ~$140/month
    
    See docs/BASTION-SETUP-GUIDE.md for full instructions!
  EOT
}
