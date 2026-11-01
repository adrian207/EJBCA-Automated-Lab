# Azure Bastion Setup Guide

## ✅ What's Been Added

Azure Bastion has been integrated into your PKI platform! This solves your dynamic IP problem.

### Components Added:

1. **Bastion Subnet** (`networking.tf`)
   - Name: `AzureBastionSubnet` (required name)
   - Address range: `10.0.250.0/26` (64 IPs)
   
2. **Bastion Host** (`networking.tf`)
   - SKU: Standard (includes all advanced features)
   - Features enabled:
     - ✅ Copy/paste
     - ✅ File transfer (up to 2GB)
     - ✅ Native SSH/RDP tunneling
     - ✅ Private IP connect
     - ❌ Shareable links (disabled for security)

3. **Configuration Variable** (`variables.tf`)
   - `enable_bastion` = `true` (default)
   
4. **Outputs** (`outputs.tf`)
   - Bastion host name
   - Bastion DNS name
   - Public IP
   - Connection instructions

---

## 🚀 Deployment

### When you run `terraform apply`, Bastion will be deployed automatically.

**Deployment time**: ~10-15 minutes (Bastion takes time to provision)

### Cost

- **Standard SKU**: ~$140/month (~$0.19/hour)
- Includes:
  - Unlimited sessions
  - Up to 50 concurrent connections
  - File copy enabled
  - Native client support

---

## 📖 How to Connect to VMs

### Option 1: Azure Portal (Recommended)

This is the easiest method:

1. **Open Azure Portal**: https://portal.azure.com

2. **Navigate to your VM**:
   - Go to "Virtual machines"
   - Select "ejbca-platform-dev-windows-vm" or "ejbca-platform-dev-rhel-vm"

3. **Connect via Bastion**:
   - Click "Connect" button (top of VM page)
   - Select "Bastion" from the dropdown
   
4. **Enter credentials**:
   - Username: `adminuser`
   - Password: (from Key Vault - see below)
   
5. **Click "Connect"**:
   - A new browser tab opens with your VM session
   - Full copy/paste support
   - File upload/download available

**Features in browser session:**
- 📋 Copy/paste text
- 📁 Upload files (drag & drop)
- 📥 Download files
- 🖥️ Full screen mode
- ⌨️ Keyboard shortcuts work

### Option 2: Azure CLI

For command-line fans:

```bash
# Get your resource group name
RG_NAME=$(cd terraform && terraform output -raw resource_group_name)

# Get Bastion name
BASTION_NAME=$(cd terraform && terraform output -raw bastion_host_name)

# Get VM IDs
WINDOWS_VM_ID=$(az vm show -n ejbca-platform-dev-windows-vm -g $RG_NAME --query id -o tsv)
RHEL_VM_ID=$(az vm show -n ejbca-platform-dev-rhel-vm -g $RG_NAME --query id -o tsv)

# Connect to Windows Server (RDP)
az network bastion rdp \
  --name $BASTION_NAME \
  --resource-group $RG_NAME \
  --target-resource-id $WINDOWS_VM_ID

# Connect to RHEL Server (SSH)
az network bastion ssh \
  --name $BASTION_NAME \
  --resource-group $RG_NAME \
  --target-resource-id $RHEL_VM_ID \
  --auth-type password \
  --username adminuser
```

### Option 3: Native SSH Client (Advanced)

Use your favorite SSH client:

```bash
# Create SSH tunnel
az network bastion tunnel \
  --name $BASTION_NAME \
  --resource-group $RG_NAME \
  --target-resource-id $RHEL_VM_ID \
  --resource-port 22 \
  --port 2222

# In another terminal, connect
ssh adminuser@localhost -p 2222

# Or use SCP for file transfers
scp -P 2222 file.txt adminuser@localhost:/home/adminuser/
```

### Option 4: Native RDP Client (Advanced)

```bash
# Create RDP tunnel
az network bastion tunnel \
  --name $BASTION_NAME \
  --resource-group $RG_NAME \
  --target-resource-id $WINDOWS_VM_ID \
  --resource-port 3389 \
  --port 3390

# In another terminal, connect with native RDP client
# On macOS: Microsoft Remote Desktop
# On Windows: mstsc /v:localhost:3390
# On Linux: rdesktop localhost:3390
```

---

## 🔑 Getting VM Passwords

Passwords are stored in Azure Key Vault:

```bash
# Get Key Vault name
KEYVAULT_NAME=$(cd terraform && terraform output -raw key_vault_name)

# Windows admin password
az keyvault secret show \
  --vault-name $KEYVAULT_NAME \
  --name windows-admin-password \
  --query value -o tsv

# RHEL admin password (if using password auth)
# Default username is: adminuser
```

---

## 🎯 Benefits Over Public IPs

### Before (with public IPs):
- ❌ Must manage IP whitelists
- ❌ IP changes = lost access
- ❌ Exposed to internet
- ❌ Port scanning risks
- ❌ Brute force attack risks

### After (with Azure Bastion):
- ✅ Access from anywhere
- ✅ No IP management needed
- ✅ VMs not exposed to internet
- ✅ Encrypted TLS (port 443)
- ✅ Azure AD authentication support
- ✅ Full audit logging
- ✅ MFA support
- ✅ Session recording capability

---

## 🔒 Security Features

### Authentication
- Azure AD integration
- Multi-factor authentication (MFA)
- Role-based access control (RBAC)
- Just-in-time (JIT) access compatible

### Encryption
- All traffic over TLS 1.2+
- Encrypted RDP/SSH sessions
- No credentials stored in browser

### Audit
- All connections logged to Azure Monitor
- Session duration tracked
- User identity captured
- Integration with Azure Sentinel

### Network Security
- No inbound rules needed on VMs
- No public IPs on VMs
- Traffic stays on Azure backbone
- DDoS protection included

---

## 📊 Monitoring & Management

### View Active Sessions

```bash
# Via Azure Portal
# Go to Bastion → Monitoring → Metrics
# Select "Sessions Count" metric

# Via Azure CLI
az network bastion show \
  --name $BASTION_NAME \
  --resource-group $RG_NAME
```

### View Logs

```bash
# Enable diagnostic logging
az monitor diagnostic-settings create \
  --name bastion-logs \
  --resource $(az network bastion show --name $BASTION_NAME --resource-group $RG_NAME --query id -o tsv) \
  --logs '[{"category": "BastionAuditLogs","enabled": true}]' \
  --workspace <LOG_ANALYTICS_WORKSPACE_ID>

# Query logs
az monitor log-analytics query \
  --workspace <WORKSPACE_ID> \
  --analytics-query "AzureDiagnostics | where ResourceType == 'BASTIONHOSTS' | take 100"
```

---

## 🔧 Configuration Options

### Current Settings

Your Bastion is configured with:

```hcl
sku                    = "Standard"
copy_paste_enabled     = true
file_copy_enabled      = true
shareable_link_enabled = false  # Disabled for security
tunneling_enabled      = true
ip_connect_enabled     = true
```

### Customization

To change settings, edit `terraform/networking.tf`:

```hcl
resource "azurerm_bastion_host" "main" {
  # ... existing config ...
  
  # Disable file copy (if needed)
  file_copy_enabled = false
  
  # Enable shareable links (NOT recommended)
  shareable_link_enabled = true  # Allows unauthenticated access!
  
  # Scale settings (for Premium SKU when available)
  scale_units = 2  # 2-50 scale units
}
```

---

## 💰 Cost Optimization

### Current Cost: ~$140/month

**To reduce costs:**

1. **Downgrade to Basic SKU**: Saves ~$55/month
   ```hcl
   sku = "Basic"  # ~$87/month
   ```
   
   **Trade-offs:**
   - ❌ No file copy
   - ❌ No native client support
   - ❌ Limited to 25 connections
   - ✅ Still have copy/paste
   - ✅ Still have portal access

2. **Use on-demand deployment**: Deploy only when needed
   - Stop: `az network bastion delete ...`
   - Start: `terraform apply` (takes 10 mins)
   - Cost: Only pay when deployed

3. **Share across multiple projects**: One Bastion per VNet
   - Can access all VMs in VNet
   - Even VMs in peered VNets

---

## 🆚 Alternatives Comparison

| Solution | Monthly Cost | Setup Time | Maintenance | Your Dynamic IP Problem |
|----------|-------------|------------|-------------|------------------------|
| **Azure Bastion** | $140 | 15 mins | None | ✅ Solved |
| Public IPs + IP Update Script | $0 | 5 mins | Manual updates | ⚠️ Need to run script |
| VPN Gateway | $160 | 45 mins | Moderate | ✅ Solved |
| JIT Access | $30 | 10 mins | Per-session | ⚠️ Still need IP management |
| Private Endpoints | $24 | 30 mins | Low | ❌ Need Bastion or VPN anyway |

**Verdict**: Bastion is the best solution for your use case!

---

## 🐛 Troubleshooting

### Can't connect to VM

1. **Check Bastion status**:
   ```bash
   az network bastion show \
     --name $BASTION_NAME \
     --resource-group $RG_NAME \
     --query provisioningState
   ```
   
   Should be: `Succeeded`

2. **Check VM is running**:
   ```bash
   az vm get-instance-view \
     --name ejbca-platform-dev-windows-vm \
     --resource-group $RG_NAME \
     --query instanceView.statuses[1].displayStatus
   ```

3. **Verify network connectivity**:
   - Bastion and VM must be in same VNet (or peered VNets)
   - NSG rules don't affect Bastion (it bypasses them)

### File upload not working

1. **Verify Standard SKU**:
   ```bash
   az network bastion show \
     --name $BASTION_NAME \
     --resource-group $RG_NAME \
     --query sku.name
   ```

2. **Check file size**: Max 2GB per file

3. **Try different browser**: Chrome/Edge work best

### Slow performance

1. **Check scale units** (Standard SKU):
   ```bash
   # Increase scale units
   az network bastion update \
     --name $BASTION_NAME \
     --resource-group $RG_NAME \
     --scale-units 4  # Default is 2
   ```
   
   Cost increases: ~$70/scale unit/month

---

## 📚 Additional Resources

- **Official Docs**: https://aka.ms/bastion/docs
- **Pricing**: https://azure.microsoft.com/pricing/details/azure-bastion/
- **Best Practices**: https://aka.ms/bastion/best-practices
- **Troubleshooting**: https://aka.ms/bastion/troubleshoot

---

## ✅ Next Steps

After deploying:

1. **Test Connection**:
   - Go to Azure Portal
   - Connect to Windows VM via Bastion
   - Verify copy/paste works
   - Test file upload

2. **Remove Public IPs** (optional):
   - After verifying Bastion works
   - Edit `terraform/networking.tf`
   - Comment out `azurerm_public_ip.windows` and `azurerm_public_ip.rhel`
   - Comment out `public_ip_address_id` in NICs
   - Run `terraform apply`
   - Saves ~$8/month

3. **Configure Logging**:
   - Enable diagnostic logs
   - Send to Log Analytics Workspace
   - Create alerts for failed connections

4. **Document for Team**:
   - Share connection instructions
   - Provide RBAC roles: `Virtual Machine Administrator Login` or `Virtual Machine User Login`

---

**Your dynamic IP problem is solved! 🎉**

No more running update scripts or managing IP whitelists.
Connect from anywhere, anytime, securely.

