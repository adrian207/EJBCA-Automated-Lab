#!/bin/bash
###############################################################################
# Security Fixes Implementation Script
# This script applies all critical security fixes to the PKI platform
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

print_header "🔒 PKI Platform Security Fixes"

echo "This script will apply the following security fixes:"
echo "  1. ✅ Restrict NSG rules to your IP (73.140.169.168/32)"
echo "  2. ✅ Secure Azure Key Vault network access"
echo "  3. ✅ Secure Storage Account network access"
echo "  4. ✅ Disable ACR admin account"
echo "  5. ✅ Setup external secrets for Harbor"
echo "  6. ✅ Setup external secrets for Grafana"
echo ""

read -p "Continue with security fixes? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_error "Aborted by user"
    exit 1
fi

###############################################################################
# Step 1: Validate Terraform Configuration
###############################################################################
print_header "Step 1: Validating Terraform Configuration"

cd terraform

print_info "Running terraform fmt..."
terraform fmt -recursive

print_info "Running terraform validate..."
terraform init -backend=false > /dev/null 2>&1
terraform validate

if [ $? -eq 0 ]; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed"
    exit 1
fi

###############################################################################
# Step 2: Review Changes
###############################################################################
print_header "Step 2: Reviewing Security Changes"

print_info "Files modified:"
echo "  - terraform/networking.tf (NSG rules)"
echo "  - terraform/keyvault.tf (network ACLs)"
echo "  - terraform/storage.tf (network rules)"
echo "  - terraform/aks.tf (ACR admin disabled)"
echo "  - kubernetes/harbor/harbor-values.yaml (password removed)"
echo "  - kubernetes/observability/kube-prometheus-stack-values.yaml (password removed)"

print_info "You can review the changes with:"
echo "  git diff"
echo ""

read -p "Review changes now? (yes/no): " REVIEW
if [ "$REVIEW" == "yes" ]; then
    git diff
    echo ""
    read -p "Proceed with applying changes? (yes/no): " PROCEED
    if [ "$PROCEED" != "yes" ]; then
        print_error "Aborted by user"
        exit 1
    fi
fi

###############################################################################
# Step 3: Create Terraform Plan
###############################################################################
print_header "Step 3: Creating Terraform Plan"

print_info "Checking if Terraform backend is configured..."
if grep -q "backend \"azurerm\"" main.tf; then
    print_info "Backend detected. Initializing with backend..."
    terraform init
else
    print_info "No backend configured. Using local state..."
    terraform init
fi

print_info "Creating execution plan..."
terraform plan -out=security-fixes.tfplan

if [ $? -eq 0 ]; then
    print_success "Terraform plan created successfully"
else
    print_error "Terraform plan failed"
    exit 1
fi

print_warning "Review the plan above carefully!"
echo ""
echo "Key changes to look for:"
echo "  • NSG rules: source_address_prefixes = [\"73.140.169.168/32\"]"
echo "  • Key Vault: default_action = \"Deny\""
echo "  • Storage: default_action = \"Deny\""
echo "  • ACR: admin_enabled = false"
echo ""

read -p "Apply these Terraform changes? (yes/no): " APPLY_TF
if [ "$APPLY_TF" != "yes" ]; then
    print_error "Terraform apply aborted"
    rm -f security-fixes.tfplan
    exit 1
fi

###############################################################################
# Step 4: Apply Terraform Changes
###############################################################################
print_header "Step 4: Applying Terraform Changes"

terraform apply security-fixes.tfplan

if [ $? -eq 0 ]; then
    print_success "Terraform changes applied successfully"
    rm -f security-fixes.tfplan
else
    print_error "Terraform apply failed"
    exit 1
fi

###############################################################################
# Step 5: Setup Kubernetes Secrets
###############################################################################
print_header "Step 5: Setting Up Kubernetes Secrets"

cd "$PROJECT_ROOT"

# Get Key Vault name from Terraform output
print_info "Getting Key Vault name from Terraform..."
cd terraform
KEYVAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null || echo "")

if [ -z "$KEYVAULT_NAME" ]; then
    print_warning "Could not get Key Vault name from Terraform output"
    read -p "Enter your Key Vault name: " KEYVAULT_NAME
fi

print_info "Using Key Vault: $KEYVAULT_NAME"

# Generate strong passwords
print_info "Generating secure passwords..."
HARBOR_PASSWORD=$(openssl rand -base64 32)
GRAFANA_PASSWORD=$(openssl rand -base64 32)

# Store in Azure Key Vault
print_info "Storing passwords in Azure Key Vault..."
az keyvault secret set \
    --vault-name "$KEYVAULT_NAME" \
    --name "harbor-admin-password" \
    --value "$HARBOR_PASSWORD" \
    --description "Harbor admin password (auto-generated)" \
    > /dev/null

if [ $? -eq 0 ]; then
    print_success "Harbor password stored in Key Vault"
else
    print_error "Failed to store Harbor password in Key Vault"
fi

az keyvault secret set \
    --vault-name "$KEYVAULT_NAME" \
    --name "grafana-admin-password" \
    --value "$GRAFANA_PASSWORD" \
    --description "Grafana admin password (auto-generated)" \
    > /dev/null

if [ $? -eq 0 ]; then
    print_success "Grafana password stored in Key Vault"
else
    print_error "Failed to store Grafana password in Key Vault"
fi

# Check if kubectl is configured
print_info "Checking Kubernetes access..."
if kubectl cluster-info > /dev/null 2>&1; then
    print_success "Kubernetes cluster is accessible"
    
    # Create namespaces if they don't exist
    kubectl create namespace harbor --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
    kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
    
    # Create Kubernetes secrets
    print_info "Creating Kubernetes secrets..."
    
    kubectl create secret generic harbor-admin-secret \
        --from-literal=HARBOR_ADMIN_PASSWORD="$HARBOR_PASSWORD" \
        -n harbor \
        --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Harbor Kubernetes secret created"
    fi
    
    kubectl create secret generic grafana-admin \
        --from-literal=admin-user="admin" \
        --from-literal=admin-password="$GRAFANA_PASSWORD" \
        -n observability \
        --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Grafana Kubernetes secret created"
    fi
else
    print_warning "Kubernetes cluster not accessible. Create secrets manually:"
    echo ""
    echo "  # Harbor secret"
    echo "  kubectl create secret generic harbor-admin-secret \\"
    echo "    --from-literal=HARBOR_ADMIN_PASSWORD=\"\$HARBOR_PASSWORD\" \\"
    echo "    -n harbor"
    echo ""
    echo "  # Grafana secret"
    echo "  kubectl create secret generic grafana-admin \\"
    echo "    --from-literal=admin-user=\"admin\" \\"
    echo "    --from-literal=admin-password=\"\$GRAFANA_PASSWORD\" \\"
    echo "    -n observability"
fi

###############################################################################
# Step 6: Verification
###############################################################################
print_header "Step 6: Verification"

cd terraform

print_info "Verifying Terraform state..."
terraform show | grep -E "(default_action|admin_enabled|source_address_prefixes)" || true

print_info "Checking Azure resources..."

# Get resource group name
RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null || echo "")

if [ -n "$RG_NAME" ]; then
    print_info "Resource Group: $RG_NAME"
    
    # Check NSG rules
    print_info "Checking NSG rules..."
    az network nsg list --resource-group "$RG_NAME" --query "[].{name:name}" -o tsv | while read nsg; do
        echo "  NSG: $nsg"
        az network nsg rule list --resource-group "$RG_NAME" --nsg-name "$nsg" \
            --query "[?sourceAddressPrefix!='*'].{name:name,source:sourceAddressPrefix,port:destinationPortRange}" \
            -o table | head -5
    done
    
    # Check Key Vault network rules
    print_info "Checking Key Vault network rules..."
    az keyvault show --name "$KEYVAULT_NAME" --query "networkAcls.defaultAction" -o tsv
    
    print_success "Verification complete"
else
    print_warning "Could not get resource group name. Verify manually."
fi

###############################################################################
# Summary
###############################################################################
print_header "✅ Security Fixes Applied Successfully!"

echo "Summary of changes:"
echo "  ✓ NSG rules restricted to IP: 73.140.169.168/32"
echo "  ✓ Key Vault network access: Default Deny"
echo "  ✓ Storage Account network access: Default Deny"
echo "  ✓ ACR admin account: Disabled"
echo "  ✓ Harbor password: Stored in Key Vault"
echo "  ✓ Grafana password: Stored in Key Vault"
echo ""

print_info "To retrieve passwords later:"
echo "  # Harbor"
echo "  az keyvault secret show --vault-name $KEYVAULT_NAME --name harbor-admin-password --query value -o tsv"
echo ""
echo "  # Grafana"
echo "  az keyvault secret show --vault-name $KEYVAULT_NAME --name grafana-admin-password --query value -o tsv"
echo ""

print_warning "Important Next Steps:"
echo "  1. Test access from your IP to ensure everything works"
echo "  2. Update your IP if it changes: Update terraform/networking.tf, keyvault.tf, storage.tf"
echo "  3. Consider setting up Azure Bastion for production"
echo "  4. Review the full analysis report: docs/ANALYSIS-REPORT.md"
echo ""

print_info "Access information:"
echo "  Your IP: 73.140.169.168/32"
echo "  Key Vault: $KEYVAULT_NAME"
echo "  Harbor admin: Use password from Key Vault"
echo "  Grafana admin: Use password from Key Vault"
echo ""

print_success "Security hardening complete! 🔒"

