# Windows Server 2025 Virtual Machine
resource "azurerm_windows_virtual_machine" "windows_server" {
  name                = "${var.project_name}-${var.environment}-win2025"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.windows_vm_size
  admin_username      = var.windows_admin_username
  admin_password      = random_password.windows_admin.result

  network_interface_ids = [
    azurerm_network_interface.windows.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 256
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-azure-edition"
    version   = "latest"
  }

  enable_automatic_updates = true
  patch_mode               = "AutomaticByPlatform"

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.common_tags,
    {
      OS      = "Windows Server 2025"
      Purpose = "PKI Integration Testing"
    }
  )
}

# VM Extension for Windows - Install necessary tools
resource "azurerm_virtual_machine_extension" "windows_setup" {
  name                 = "windows-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_server.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); choco install -y git openssh curl; Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All\""
  })

  tags = local.common_tags
}

# RHEL Virtual Machine
resource "azurerm_linux_virtual_machine" "rhel_server" {
  name                = "${var.project_name}-${var.environment}-rhel"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.rhel_vm_size
  admin_username      = var.rhel_admin_username

  network_interface_ids = [
    azurerm_network_interface.rhel.id,
  ]

  admin_ssh_key {
    username   = var.rhel_admin_username
    public_key = tls_private_key.rhel_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 256
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9_3"
    version   = "latest"
  }

  disable_password_authentication = true

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.common_tags,
    {
      OS      = "Red Hat Enterprise Linux 9.3"
      Purpose = "PKI Integration Testing"
    }
  )
}

# Generate SSH key for RHEL
resource "tls_private_key" "rhel_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store RHEL SSH private key in Key Vault
resource "azurerm_key_vault_secret" "rhel_ssh_private_key" {
  name         = "rhel-ssh-private-key"
  value        = tls_private_key.rhel_ssh.private_key_pem
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(
    local.common_tags,
    {
      Server  = "RHEL"
      Purpose = "SSH Private Key"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# VM Extension for RHEL - Install necessary tools
resource "azurerm_virtual_machine_extension" "rhel_setup" {
  name                 = "rhel-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.rhel_server.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    commandToExecute = "sudo dnf update -y && sudo dnf install -y git curl wget vim openssl java-11-openjdk python3 ansible"
  })

  tags = local.common_tags
}

# Role Assignment for Windows VM to access Key Vault
resource "azurerm_role_assignment" "windows_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_virtual_machine.windows_server.identity[0].principal_id
}

# Role Assignment for RHEL VM to access Key Vault
resource "azurerm_role_assignment" "rhel_keyvault" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.rhel_server.identity[0].principal_id
}

