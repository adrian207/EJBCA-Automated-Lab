#!/bin/bash
###############################################################################
# Dynamic IP Address Update Script
# Automatically updates your IP in Terraform configuration and applies changes
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }
print_header() { echo -e "${BLUE}$1${NC}"; }

echo ""
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "  Dynamic IP Address Update for PKI Platform"
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/terraform"

# Get current public IP
print_info "Detecting your current public IP address..."
CURRENT_IP=$(curl -4 -s --max-time 10 ifconfig.me)

if [ -z "$CURRENT_IP" ]; then
    print_error "Failed to detect public IP address"
    print_info "Trying alternative service..."
    CURRENT_IP=$(curl -4 -s --max-time 10 icanhazip.com)
fi

if [ -z "$CURRENT_IP" ]; then
    print_error "Could not detect public IP. Check internet connection."
    exit 1
fi

print_success "Current IP: $CURRENT_IP"

# Find old IP in files
print_info "Finding old IP address in configuration..."
OLD_IP=$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?=/32|")' keyvault.tf 2>/dev/null | head -1 || \
         grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' keyvault.tf | head -1)

if [ -z "$OLD_IP" ]; then
    print_error "Could not find old IP in configuration"
    exit 1
fi

print_success "Old IP: $OLD_IP"

# Check if IP has changed
if [ "$CURRENT_IP" == "$OLD_IP" ]; then
    print_success "Your IP hasn't changed. No update needed!"
    exit 0
fi

echo ""
print_header "IP Address Change Detected!"
echo "  Old IP: $OLD_IP"
echo "  New IP: $CURRENT_IP"
echo ""

# Confirm update
read -p "Update configuration and apply changes? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_error "Update cancelled by user"
    exit 0
fi

# Backup files
print_info "Creating backup of configuration files..."
mkdir -p ../backups
BACKUP_DIR="../backups/ip-update-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp networking.tf keyvault.tf storage.tf "$BACKUP_DIR/"
print_success "Backup created: $BACKUP_DIR"

# Update files
print_info "Updating IP address in configuration files..."

# Update networking.tf
sed -i.tmp "s/$OLD_IP/$CURRENT_IP/g" networking.tf && rm networking.tf.tmp
print_success "Updated: networking.tf"

# Update keyvault.tf  
sed -i.tmp "s/$OLD_IP/$CURRENT_IP/g" keyvault.tf && rm keyvault.tf.tmp
print_success "Updated: keyvault.tf"

# Update storage.tf
sed -i.tmp "s/$OLD_IP/$CURRENT_IP/g" storage.tf && rm storage.tf.tmp
print_success "Updated: storage.tf"

# Verify changes
echo ""
print_info "Verifying changes..."
if grep -q "$CURRENT_IP" networking.tf && \
   grep -q "$CURRENT_IP" keyvault.tf && \
   grep -q "$CURRENT_IP" storage.tf; then
    print_success "All files updated successfully"
else
    print_error "Verification failed. Restoring from backup..."
    cp "$BACKUP_DIR"/* .
    exit 1
fi

# Format and validate
print_info "Formatting and validating Terraform configuration..."
terraform fmt -recursive > /dev/null 2>&1
if terraform validate > /dev/null 2>&1; then
    print_success "Configuration is valid"
else
    print_error "Configuration validation failed"
    print_info "Restoring from backup..."
    cp "$BACKUP_DIR"/* .
    exit 1
fi

# Create plan
echo ""
print_info "Creating Terraform execution plan..."
terraform plan -out=ip-update.tfplan

if [ $? -ne 0 ]; then
    print_error "Terraform plan failed"
    exit 1
fi

echo ""
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_header "  Review the plan above"
print_header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Apply changes
read -p "Apply these changes? (yes/no): " APPLY_CONFIRM
if [ "$APPLY_CONFIRM" != "yes" ]; then
    print_error "Apply cancelled by user"
    rm -f ip-update.tfplan
    exit 0
fi

print_info "Applying changes..."
terraform apply ip-update.tfplan

if [ $? -eq 0 ]; then
    echo ""
    print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "  IP Address Updated Successfully!"
    print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Old IP: $OLD_IP"
    echo "  New IP: $CURRENT_IP"
    echo ""
    echo "  Updated resources:"
    echo "    ✓ Network Security Groups"
    echo "    ✓ Azure Key Vault network rules"
    echo "    ✓ Storage Account network rules"
    echo ""
    print_success "You can now access your resources from the new IP!"
    echo ""
    
    # Clean up
    rm -f ip-update.tfplan
else
    print_error "Apply failed!"
    print_info "Your backup is available at: $BACKUP_DIR"
    exit 1
fi

# Optional: Clean up old backups (keep last 10)
print_info "Cleaning up old backups (keeping last 10)..."
cd ../backups
ls -t | tail -n +11 | xargs rm -rf 2>/dev/null || true
cd ../terraform

print_success "Done!"

