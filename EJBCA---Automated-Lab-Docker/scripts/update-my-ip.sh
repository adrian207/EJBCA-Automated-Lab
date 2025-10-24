#!/bin/bash
###############################################################################
# Dynamic IP Address Update Script
# Automatically updates your IP in Terraform variables and applies changes.
# This script should only be used for development if Azure Bastion is disabled.
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
print_header() { echo -e "\n${BLUE}### $1 ###${NC}"; }

echo -e "${BLUE}EJBCA PKI Platform - Dynamic IP Updater${NC}"
echo "=========================================="

# Check for terraform.tfvars
TFVARS_FILE="terraform/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    print_error "$TFVARS_FILE not found."
    print_info "Please copy terraform/terraform.tfvars.example to $TFVARS_FILE and configure it first."
    exit 1
fi

# Get current public IP
print_info "Detecting your current public IP..."
CURRENT_IP=$(curl -4 -s --max-time 10 ifconfig.me) || CURRENT_IP=$(curl -4 -s --max-time 10 icanhazip.com)

if [ -z "$CURRENT_IP" ]; then
    print_error "Could not detect your public IP. Please check your internet connection."
    exit 1
fi
print_success "Detected IP: $CURRENT_IP"

# Find old IP in tfvars file
print_info "Reading current admin_ip_address from $TFVARS_FILE..."
OLD_IP=$(grep -E '^\s*admin_ip_address\s*=' "$TFVARS_FILE" | awk -F'"' '{print $2}')

if [ -z "$OLD_IP" ]; then
    print_error "Could not find 'admin_ip_address' in $TFVARS_FILE."
    print_info "Please add 'admin_ip_address = \"$CURRENT_IP\"' to your tfvars file."
    exit 1
fi
print_success "Current configured IP: $OLD_IP"

# Check if IP has changed
if [ "$CURRENT_IP" == "$OLD_IP" ]; then
    print_success "Your IP has not changed. No update needed!"
    exit 0
fi

print_header "IP Address Change Detected!"
echo -e "  ${RED}Old IP: $OLD_IP${NC}"
echo -e "  ${GREEN}New IP: $CURRENT_IP${NC}"

# Confirm update
read -p "Update configuration and apply changes? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_error "Update cancelled by user."
    exit 0
fi

# Update tfvars file
print_info "Updating $TFVARS_FILE..."
sed -i.bak "s/admin_ip_address\s*=\s*\"$OLD_IP\"/admin_ip_address = \"$CURRENT_IP\"/" "$TFVARS_FILE"
rm "${TFVARS_FILE}.bak"
print_success "$TFVARS_FILE updated successfully."

# Run Terraform
cd terraform

print_header "Running Terraform"

print_info "Initializing Terraform..."
terraform init -upgrade > /dev/null

print_info "Creating Terraform execution plan..."
terraform plan -out=ip-update.tfplan

print_info "Applying changes..."
if terraform apply -auto-approve ip-update.tfplan; then
    print_success "Terraform apply completed successfully!"
    print_info "Your Azure firewall rules have been updated with your new IP."
else
    print_error "Terraform apply failed. Please review the output above."
    exit 1
fi

# Clean up
rm -f ip-update.tfplan

echo "=========================================="
print_success "Dynamic IP update complete!"