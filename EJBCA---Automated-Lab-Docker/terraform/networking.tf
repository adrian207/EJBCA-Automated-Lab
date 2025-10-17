# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space

  tags = local.common_tags
}

# AKS Subnet
resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_address_prefix]

 
 service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.ContainerRegistry"
  ]
}

# Services Subnet (for VMs and other services)
resource "azurerm_subnet" "services" {
  name                 = "services-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.services_subnet_address_prefix]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

# Database Subnet
resource "azurerm_subnet" "database" {
  name           
      = "database-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.database_subnet_address_prefix]

  service_endpoints = [
    "Microsoft.Sql"
  ]

  delegation {
    name = "postgresql-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Azure Bastion Subnet (name must be exactly "AzureBastionSubnet")
resource "azurerm_subnet" "bastion" {
  count                = var.enable_bastion ? 1 : 0
  name   
              = "AzureBastionSubnet" # Required name, cannot be changed
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.250.0/26"] # Minimum /26 (64 IPs) required for Bastion
}

# Network Security Group for AKS
resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_name}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name 
                      = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    
protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTPS from anywhere (Load Balancer needs this)"
  }

  security_rule {
    name 
                      = "allow-http-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    
protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTP from anywhere (Load Balancer needs this)"
  }

  tags = local.common_tags
}

# NSG Association for 
AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Network Security Group for Services
resource "azurerm_network_security_group" "services" {
  name                = "${var.project_name}-${var.environment}-services-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  dynamic "security_rule" {
    for_each = var.enable_bastion ? [] : [1]
    content {
      name                   
    = "allow-rdp"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                  
 = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefixes    = ["${var.admin_ip_address}/32"] # SECURED: Specific IP only
      destination_address_prefix = "*"
      description                = "RDP access restricted to authorized IP"
    }
  }

  dynamic "security_rule" {
    for_each = var.enable_bastion ? [] : [1]
    content {
      name                  
     = "allow-ssh"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                 
  = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = ["${var.admin_ip_address}/32"] # SECURED: Specific IP only
      destination_address_prefix = "*"
      description                = "SSH access restricted to authorized IP"
    }
  }

  dynamic "security_rule" {
    for_each = var.enable_bastion ? [] : [1]
    content {
      name                 
      = "allow-winrm"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                
   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["5985", "5986"]
      source_address_prefixes    = ["${var.admin_ip_address}/32"] # SECURED: Specific IP only
      destination_address_prefix = "*"
      description                = "WinRM access restricted to authorized IP"
    }
  }

  tags = local.common_tags
}

# NSG Association for Services Subnet
resource "azurerm_subnet_network_security_group_association" "services" {
  subnet_id         
        = azurerm_subnet.services.id
  network_security_group_id = azurerm_network_security_group.services.id
}

# ============================================================================
# Azure Bastion - Secure VM Access Without Public IPs
# ============================================================================

# Public IP for Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${var.project_name}-${var.environment}-bastion-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = 
merge(local.common_tags, {
    Purpose = "Azure Bastion secure VM access"
  })
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = "${var.project_name}-${var.environment}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard" # Standard SKU for advanced features

  # Standard SKU features
  copy_paste_enabled     = true  # Enable 
copy/paste between local and remote
  file_copy_enabled      = true  # Enable file upload/download (up to 2GB)
  shareable_link_enabled = false # Disabled for security (allows unauthenticated access)
  tunneling_enabled      = true  # Enable native client support (az network bastion tunnel)
  ip_connect_enabled     = true  # Enable connect via private IP address

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id    
        = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = merge(local.common_tags, {
    Purpose    = "Secure RDP/SSH access without exposing VMs to internet"
    CostCenter = "Security"
    Compliance = "Eliminates dynamic IP management requirements"
  })
}

# ============================================================================
# VM Public IPs (Optional - not needed if Bastion is enabled)
# ============================================================================

# Public IP for Windows Server
resource "azurerm_public_ip" "windows" {
  count               = var.enable_bastion ? 0 : 1
  name                = "${var.project_name}-${var.environment}-windows-pip"
 
 location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Network Interface for Windows Server
resource "azurerm_network_interface" "windows" {
  name                = "${var.project_name}-${var.environment}-windows-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
   
 name                          = "internal"
    subnet_id                     = azurerm_subnet.services.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_bastion ? null : azurerm_public_ip.windows[0].id
  }

  tags = local.common_tags
}

# Public IP for RHEL Server
resource "azurerm_public_ip" "rhel" {
  count               = var.enable_bastion ? 0 : 1
  name         
       = "${var.project_name}-${var.environment}-rhel-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Network Interface for RHEL Server
resource "azurerm_network_interface" "rhel" {
  name                = "${var.project_name}-${var.environment}-rhel-nic"
  location            = azurerm_resource_group.main.location
 
 resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.services.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_bastion ? null : azurerm_public_ip.rhel[0].id
  }

  tags = local.common_tags
}

# DNS Zone (Optional - for custom domain)
resource "azurerm_dns_zone" "main" 
{
  name                = "${var.project_name}-${var.environment}.local"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}