# 🔴 CRITICAL SECURITY FIXES - Immediate Action Required

## Priority 1: Network Security (Do First - 30 minutes)

### ✅ Task 1: Fix NSG Rules

**File**: `terraform/networking.tf`

**Current (VULNERABLE)**:
```hcl
source_address_prefix = "*"  # Lines 76, 89, 116, 128, 139
```

**Fixed Version**:
```bash
# Edit terraform/networking.tf
sed -i 's/source_address_prefix      = "\*"/source_address_prefix      = "YOUR_IP\/32"/' terraform/networking.tf

# OR manually update lines 76, 89, 116, 128, 139
```

**Production Fix**:
```hcl
# For RDP access (line 116)
security_rule {
  name                       = "allow-rdp"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefixes    = ["YOUR_OFFICE_IP/32", "VPN_IP/32"]  # ✅ SPECIFIC IPs
  destination_address_prefix = "*"
}

# For SSH access (line 128)
security_rule {
  name                       = "allow-ssh"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefixes    = ["YOUR_OFFICE_IP/32"]  # ✅ SPECIFIC IPs
  destination_address_prefix = "*"
}
```

---

### ✅ Task 2: Secure Key Vault Network Access

**File**: `terraform/keyvault.tf` line 16

**Find and Replace**:
```bash
# Before
default_action             = "Allow" # Change to "Deny" in production

# After
default_action             = "Deny"  # ✅ SECURED
```

**Complete Fix**:
```hcl
network_acls {
  bypass                     = "AzureServices"
  default_action             = "Deny"  # ✅ Changed from Allow
  ip_rules                   = ["YOUR_OFFICE_IP"]  # Add your IPs
  virtual_network_subnet_ids = [
    azurerm_subnet.aks.id, 
    azurerm_subnet.services.id
  ]
}
```

---

### ✅ Task 3: Secure Storage Account

**File**: `terraform/storage.tf` line 28

```hcl
# BEFORE (line 27-31)
network_rules {
  default_action             = "Allow" # Change to "Deny" in production
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = [azurerm_subnet.aks.id, azurerm_subnet.services.id]
}

# AFTER
network_rules {
  default_action             = "Deny"  # ✅ Changed
  bypass                     = ["AzureServices"]
  ip_rules                   = ["YOUR_OFFICE_IP"]
  virtual_network_subnet_ids = [
    azurerm_subnet.aks.id, 
    azurerm_subnet.services.id
  ]
}
```

---

## Priority 2: Credential Management (30 minutes)

### ✅ Task 4: Remove Hardcoded Passwords

#### Harbor Password
**File**: `kubernetes/harbor/harbor-values.yaml` line 95

```yaml
# BEFORE
harborAdminPassword: "Harbor12345"  # ❌ Change this!

# AFTER
harborAdminPassword: ""  # Will be provided via external secret
```

**Create External Secret**:
```bash
# Store in Azure Key Vault
az keyvault secret set \
  --vault-name YOUR_KEYVAULT_NAME \
  --name harbor-admin-password \
  --value "$(openssl rand -base64 32)"
```

```yaml
# Add to harbor-values.yaml
existingSecret: "harbor-admin-secret"
existingSecretKey: "password"
```

#### Grafana Password
**File**: `kubernetes/observability/kube-prometheus-stack-values.yaml` line 109

```yaml
# BEFORE
adminPassword: "changeme"  # ❌ Change this!

# AFTER - use existing secret
admin:
  existingSecret: "grafana-admin"
  userKey: admin-user
  passwordKey: admin-password
```

---

### ✅ Task 5: Disable ACR Admin Account

**File**: `terraform/aks.tf` line 177

```hcl
# BEFORE
admin_enabled = true

# AFTER
admin_enabled = false  # ✅ Use service principals instead
```

**Setup Service Principal Access**:
```bash
# Get ACR ID
ACR_ID=$(az acr show --name myacr --query id --output tsv)

# Grant AKS access via managed identity (already in code at line 156-161)
# This is already correct, just disable admin account
```

---

## Priority 3: Apply Changes (10 minutes)

### Step 1: Validate Changes
```bash
cd terraform
terraform fmt
terraform validate
```

### Step 2: Plan Changes
```bash
terraform plan -out=security-fixes.tfplan
```

### Step 3: Review Plan Output
Look for:
- NSG rule changes ✅
- Key Vault network_acls changes ✅
- Storage Account network_rules changes ✅
- ACR admin_enabled changes ✅

### Step 4: Apply (ONLY IF PLAN LOOKS GOOD)
```bash
terraform apply security-fixes.tfplan
```

### Step 5: Verify
```bash
# Check NSG rules
az network nsg rule list \
  --resource-group ejbca-platform-dev-rg \
  --nsg-name ejbca-platform-dev-services-nsg \
  --output table

# Check Key Vault network rules
az keyvault network-rule list \
  --name YOUR_KEYVAULT \
  --resource-group ejbca-platform-dev-rg

# Check Storage account
az storage account show \
  --name YOUR_STORAGE \
  --query networkRuleSet
```

---

## Quick Command Reference

```bash
# Get your current public IP
curl -4 ifconfig.me

# Update all security settings in one go
export MY_IP=$(curl -4 -s ifconfig.me)

# Update terraform variables
cat > terraform/security-overrides.tfvars <<EOF
# Network Security
allowed_ip_ranges = ["${MY_IP}/32"]

# Storage & Key Vault should deny by default
storage_default_action = "Deny"
keyvault_default_action = "Deny"

# ACR settings
acr_admin_enabled = false
EOF

# Apply with overrides
terraform apply -var-file=terraform.tfvars -var-file=security-overrides.tfvars
```

---

## Verification Checklist

After applying fixes, verify:

- [ ] **NSG Rules**: RDP/SSH restricted to specific IPs
- [ ] **Key Vault**: Default action is "Deny"
- [ ] **Storage Account**: Default action is "Deny"  
- [ ] **ACR**: Admin account disabled
- [ ] **Harbor**: Password stored in Key Vault
- [ ] **Grafana**: Password stored in Key Vault
- [ ] **All services**: Still accessible from allowed IPs
- [ ] **Terraform state**: No sensitive data exposed

---

## Testing Access After Changes

### Test 1: Key Vault Access
```bash
# Should work from allowed IP
az keyvault secret show \
  --vault-name YOUR_KEYVAULT \
  --name ejbca-superadmin-password

# Should fail from unauthorized IP
# (Test from different network)
```

### Test 2: Storage Account Access
```bash
# Should work from AKS
kubectl run -it --rm debug --image=mcr.microsoft.com/azure-cli --restart=Never -- \
  az storage blob list \
    --account-name YOUR_STORAGE \
    --container-name ejbca-backups \
    --auth-mode login
```

### Test 3: VM Access
```bash
# RDP (from allowed IP)
mstsc /v:WINDOWS_PUBLIC_IP

# SSH (from allowed IP)
ssh adminuser@RHEL_PUBLIC_IP
```

---

## Emergency Rollback

If something breaks after applying changes:

```bash
# Quick rollback
cd terraform
terraform apply -auto-approve \
  -var="keyvault_default_action=Allow" \
  -var="storage_default_action=Allow"

# Or full rollback to previous state
terraform state pull > backup-state.json
terraform state push backup-state.json
```

---

## Next Steps (After Critical Fixes)

1. **Implement Azure Bastion** (eliminates need for public IPs)
   - Cost: ~$140/month
   - Benefit: No public SSH/RDP exposure

2. **Enable Private Endpoints**
   - Cost: ~$8/month per endpoint
   - Benefit: All traffic stays on Azure backbone

3. **Setup Azure Firewall**
   - Cost: ~$800/month
   - Benefit: Centralized egress filtering

4. **Enable JIT VM Access**
   - Cost: Free (Azure Defender required: ~$15/VM/month)
   - Benefit: Time-limited access only when needed

---

## Estimated Time to Complete

| Task | Time | Impact |
|------|------|--------|
| Fix NSG rules | 10 min | 🔴 CRITICAL |
| Secure Key Vault | 5 min | 🔴 CRITICAL |
| Secure Storage | 5 min | 🟠 HIGH |
| Remove hardcoded passwords | 15 min | 🟠 HIGH |
| Disable ACR admin | 2 min | 🟡 MEDIUM |
| Test & Verify | 15 min | Required |
| **TOTAL** | **~1 hour** | **High ROI** |

---

## Support

If you need help:
1. Check Terraform error messages carefully
2. Validate syntax: `terraform validate`
3. Use `-target` for specific resources: `terraform apply -target=azurerm_network_security_group.services`
4. Keep backup of state: `terraform state pull > backup.tfstate`

**Remember**: Always test in dev environment first! 🧪

---

Last Updated: October 2025  
Severity: 🔴 CRITICAL - Address immediately before production deployment

