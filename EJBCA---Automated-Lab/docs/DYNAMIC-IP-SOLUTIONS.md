# 🌐 Dynamic IP Address Solutions

## Problem

Your security fixes restrict access to your current IP (73.140.169.168), but this IP isn't static. When it changes, you'll lose access to:
- Azure Key Vault
- Storage Account  
- VMs (SSH/RDP)

## ✅ Recommended Solutions

### Option 1: Azure Bastion (Best for Production) 🏆

Azure Bastion provides secure RDP/SSH access without exposing public IPs.

**Advantages:**
- ✅ No public IP management needed
- ✅ Access from any location
- ✅ Built-in audit logging
- ✅ No client software needed (browser-based)
- ✅ Most secure option

**Cost:** ~$140/month

**Implementation:**

```hcl
# Add to terraform/networking.tf

# Bastion Subnet (required name)
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"  # Name is required
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.250.0/27"]  # Minimum /27
}

# Bastion Public IP
resource "azurerm_public_ip" "bastion" {
  name                = "${var.project_name}-${var.environment}-bastion-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = local.common_tags
}

# Azure Bastion Host
resource "azurerm_bastion_host" "main" {
  name                = "${var.project_name}-${var.environment}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  
  copy_paste_enabled     = true
  file_copy_enabled      = true
  shareable_link_enabled = false
  tunneling_enabled      = true
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  
  tags = local.common_tags
}
```

**After deploying, update NSG rules to remove public access:**

```hcl
# In networking.tf, remove or restrict these rules:
# - allow-rdp
# - allow-ssh
# - allow-winrm

# VMs are accessed via Bastion, not directly
```

**Usage:**
```bash
# Access via Azure Portal
# Go to VM → Connect → Bastion → Enter credentials

# Or use Azure CLI
az network bastion rdp \
  --name ejbca-platform-dev-bastion \
  --resource-group ejbca-platform-dev-rg \
  --target-resource-id "/subscriptions/.../virtualMachines/windows-vm"
```

---

### Option 2: Azure VPN Gateway

Create a Point-to-Site VPN for secure access.

**Advantages:**
- ✅ Fixed internal IP range
- ✅ Secure encrypted tunnel
- ✅ Access all resources in VNet

**Cost:** ~$160/month (VpnGw1)

**Implementation:**

```hcl
# Add to terraform/networking.tf

# Gateway Subnet
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"  # Name is required
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.vpn_gateway_subnet_address_prefix]
}

# VPN Gateway Public IP
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${var.project_name}-${var.environment}-vpn-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = local.common_tags
}

# VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "${var.project_name}-${var.environment}-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "VpnGw1"
  
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }
  
  vpn_client_configuration {
    address_space = ["172.16.0.0/24"]  # VPN client IP pool
    
    vpn_client_protocols = ["OpenVPN"]
    
    root_certificate {
      name             = "P2SRootCert"
      public_cert_data = file("${path.module}/certs/root-cert.cer")
    }
  }
  
  tags = local.common_tags
}
```

**Then update security to allow VPN range:**

```hcl
# In keyvault.tf, storage.tf
ip_rules = ["172.16.0.0/24"]  # VPN client range

# In networking.tf NSG rules
source_address_prefixes = ["172.16.0.0/24"]  # VPN client range
```

---

### Option 3: Just-In-Time (JIT) VM Access (Free!)

Enable JIT access through Azure Defender.

**Advantages:**
- ✅ Free (requires Azure Defender for Servers)
- ✅ Time-limited access
- ✅ Automatic IP detection
- ✅ Audit logging

**Cost:** ~$15/VM/month (Azure Defender)

**Implementation:**

```bash
# Enable Azure Defender
az security pricing create \
  --name VirtualMachines \
  --tier Standard

# Enable JIT on VMs
az security jit-policy create \
  --resource-group ejbca-platform-dev-rg \
  --location eastus \
  --name default \
  --virtual-machines "/subscriptions/.../virtualMachines/windows-vm" \
  --ports '[{"number": 3389, "protocol": "*", "allowedSourceAddressPrefix": "*", "maxRequestAccessDuration": "PT3H"}]'
```

**Usage:**
```bash
# Request access (auto-detects your IP)
az security jit-policy request-access \
  --resource-group ejbca-platform-dev-rg \
  --jit-policy-name default \
  --virtual-machines '[{"id": "/subscriptions/.../virtualMachines/windows-vm", "ports": [{"number": 3389, "duration": "PT2H"}]}]'

# Access granted for 2 hours from your current IP
```

---

### Option 4: Quick IP Update Script (Temporary Solution)

For development/testing, use a script to update your IP quickly.

**Create this script:**

```bash
#!/bin/bash
# File: scripts/update-my-ip.sh

set -e

# Get current IP
CURRENT_IP=$(curl -4 -s ifconfig.me)
echo "Current IP: $CURRENT_IP"

# Find old IP in files
OLD_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' terraform/keyvault.tf | head -1)
echo "Old IP: $OLD_IP"

if [ "$CURRENT_IP" == "$OLD_IP" ]; then
    echo "✓ IP hasn't changed"
    exit 0
fi

echo "Updating IP from $OLD_IP to $CURRENT_IP..."

# Update all files
cd terraform
sed -i.bak "s/$OLD_IP/$CURRENT_IP/g" networking.tf
sed -i.bak "s/$OLD_IP/$CURRENT_IP/g" keyvault.tf
sed -i.bak "s/$OLD_IP/$CURRENT_IP/g" storage.tf

# Apply changes
echo "Planning changes..."
terraform plan -out=ip-update.tfplan

read -p "Apply IP update? (yes/no): " CONFIRM
if [ "$CONFIRM" == "yes" ]; then
    terraform apply ip-update.tfplan
    echo "✓ IP updated successfully!"
else
    echo "Aborted"
    exit 1
fi
```

**Usage:**
```bash
chmod +x scripts/update-my-ip.sh
./scripts/update-my-ip.sh
```

---

### Option 5: Use IP Range Instead of Single IP

If you have a predictable range (e.g., your ISP's subnet), use that.

**Example:**

```hcl
# Instead of:
source_address_prefixes = ["73.140.169.168/32"]  # Single IP

# Use your ISP's range:
source_address_prefixes = ["73.140.0.0/16"]  # Entire ISP subnet

# Or multiple locations:
source_address_prefixes = [
  "73.140.0.0/16",    # Home ISP
  "10.20.0.0/16",     # Office network
  "1.2.3.4/32"        # VPN exit IP
]
```

**To find your ISP range:**
```bash
# Look up your IP
whois $(curl -4 -s ifconfig.me) | grep -i "CIDR\|NetRange"
```

---

### Option 6: Private Endpoints (Enterprise Solution)

Eliminate public access entirely with Private Endpoints.

**Advantages:**
- ✅ No public internet access at all
- ✅ Traffic stays on Azure backbone
- ✅ Best security
- ✅ Lower latency

**Cost:** ~$8/month per endpoint × 3 = $24/month

**Implementation:**

```hcl
# Private DNS Zones
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

# Link DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "keyvault-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "${var.project_name}-kv-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.services.id

  private_service_connection {
    name                           = "keyvault-connection"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}

# Then set Key Vault to deny all public access
resource "azurerm_key_vault" "main" {
  # ... existing config
  
  public_network_access_enabled = false  # ✅ No public access at all
}
```

---

## 🎯 Recommended Approach

### For Development/Testing:
**Option 4** (IP Update Script) - Quick and free

### For Production:
**Option 1** (Azure Bastion) + **Option 6** (Private Endpoints)
- Total cost: ~$164/month
- Maximum security
- No IP management hassles

### Budget-Conscious Production:
**Option 3** (JIT Access) + **Option 5** (IP Range)
- Total cost: ~$30/month (2 VMs)
- Good balance of security and cost

---

## 📋 Implementation Checklist

Choose your solution and follow these steps:

### If using Azure Bastion:
- [ ] Add Bastion subnet and resources to Terraform
- [ ] Deploy Bastion (~15 minutes to provision)
- [ ] Remove public IPs from VMs (optional)
- [ ] Update NSG rules to remove SSH/RDP from internet
- [ ] Test access via Azure Portal

### If using JIT Access:
- [ ] Enable Azure Defender for Servers
- [ ] Configure JIT policies via Portal or CLI
- [ ] Test requesting access
- [ ] Update team on JIT process

### If using IP Update Script:
- [ ] Copy script to scripts/update-my-ip.sh
- [ ] Make executable: `chmod +x scripts/update-my-ip.sh`
- [ ] Run when IP changes
- [ ] Document for team

### If using Private Endpoints:
- [ ] Add Private DNS zones
- [ ] Add Private Endpoints for each service
- [ ] Set services to deny public access
- [ ] Test from within VNet
- [ ] Update documentation

---

## 🚨 Current Temporary Access

While you decide on a solution, here's how to handle your dynamic IP:

### When your IP changes:

```bash
# Quick fix (temporary allow-all for emergency access)
az keyvault update \
  --name $(cd terraform && terraform output -raw key_vault_name) \
  --default-action Allow

# Do your work...

# Re-secure when done
az keyvault update \
  --name $(cd terraform && terraform output -raw key_vault_name) \
  --default-action Deny
```

### Or use the IP update script:
```bash
./scripts/update-my-ip.sh
```

---

## 💡 Recommendation Summary

| Solution | Cost/Month | Security | Ease of Use | Best For |
|----------|-----------|----------|-------------|----------|
| Azure Bastion | $140 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Production |
| VPN Gateway | $160 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Remote teams |
| JIT Access | $15/VM | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Budget prod |
| IP Update Script | $0 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Dev/Testing |
| IP Range | $0 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Stable ISP |
| Private Endpoints | $24 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Enterprise |

**My recommendation for you**: Start with **Option 4 (IP Update Script)** for development, then implement **Option 1 (Azure Bastion)** when moving to production.

---

Need help implementing any of these? Let me know which option you'd like to use!

