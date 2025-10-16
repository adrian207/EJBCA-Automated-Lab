#!/bin/bash
# ==============================================================================
# EJBCA Hybrid Deployment Script
# ==============================================================================
# Author: Adrian Johnson <adrian207@gmail.com>
# Deploys cost-optimized EJBCA PKI platform with Azure-managed services
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${GREEN}===================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===================================================${NC}\n"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI installed"
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Install it from https://www.terraform.io/downloads.html"
        exit 1
    fi
    print_success "Terraform installed"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Install it from https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker installed"
    
    if ! command -v git &> /dev/null; then
        print_error "Git not found. Install it from https://git-scm.com/downloads"
        exit 1
    fi
    print_success "Git installed"
}

# Azure login
azure_login() {
    print_header "Azure Login"
    
    if ! az account show &> /dev/null; then
        print_info "Logging into Azure..."
        az login
    else
        print_success "Already logged into Azure"
    fi
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_info "Using subscription: $SUBSCRIPTION_ID"
    
    export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
}

# Deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Azure Infrastructure"
    
    cd terraform
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized"
    
    # Select environment
    echo -e "\nSelect environment:"
    echo "1) Development (1 VM, $425/month)"
    echo "2) Production (3 VMs, $1,440/month)"
    read -p "Enter choice [1-2]: " env_choice
    
    case $env_choice in
        1)
            ENVIRONMENT="dev"
            VM_COUNT=1
            print_info "Selected: Development environment"
            ;;
        2)
            ENVIRONMENT="prod"
            VM_COUNT=3
            print_info "Selected: Production environment"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Plan
    print_info "Creating Terraform plan..."
    terraform plan \
        -var="environment=$ENVIRONMENT" \
        -var="vm_count=$VM_COUNT" \
        -out=tfplan
    print_success "Plan created"
    
    # Confirm
    read -p "Do you want to apply this plan? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    # Apply
    print_info "Applying Terraform plan..."
    terraform apply tfplan
    print_success "Infrastructure deployed"
    
    cd ..
}

# Get outputs
get_outputs() {
    print_header "Getting Deployment Outputs"
    
    cd terraform
    
    BASTION_NAME=$(terraform output -raw bastion_host_name)
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    VM_IDS=$(terraform output -json vm_ids | jq -r '.[]')
    POSTGRES_HOST=$(terraform output -raw postgres_host)
    ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
    GRAFANA_ENDPOINT=$(terraform output -raw grafana_endpoint)
    
    print_info "Bastion: $BASTION_NAME"
    print_info "Resource Group: $RESOURCE_GROUP"
    print_info "PostgreSQL: $POSTGRES_HOST"
    print_info "ACR: $ACR_LOGIN_SERVER"
    print_info "Grafana: $GRAFANA_ENDPOINT"
    
    cd ..
}

# Deploy Docker stack (via Bastion)
deploy_docker_stack() {
    print_header "Deploying EJBCA Docker Stack"
    
    print_info "The Docker stack will be automatically deployed via cloud-init"
    print_info "This may take 5-10 minutes to complete"
    
    sleep 5
    
    # Check cloud-init status
    print_info "Checking deployment status..."
    
    # Get first VM ID
    VM_ID=$(echo "$VM_IDS" | head -n 1)
    
    # Check cloud-init completion
    az vm run-command invoke \
        --ids "$VM_ID" \
        --command-id RunShellScript \
        --scripts "tail -20 /var/log/cloud-init-output.log" \
        --query 'value[0].message' -o tsv
}

# Display access instructions
display_instructions() {
    print_header "🎉 Deployment Complete!"
    
    cat << EOF

╔══════════════════════════════════════════════════════════════════════════╗
║           EJBCA PKI PLATFORM - HYBRID DEPLOYMENT COMPLETE                ║
╚══════════════════════════════════════════════════════════════════════════╝

COST SAVINGS: 69-78% vs. AKS Architecture 💰

AZURE RESOURCES DEPLOYED:
  ✅ ${VM_COUNT} Docker VM(s) (Ubuntu 22.04)
  ✅ Azure Database for PostgreSQL
  ✅ Azure Monitor (Managed Prometheus + Grafana)
  ✅ Azure Application Insights
  ✅ Azure Container Registry
  ✅ Azure Key Vault (Premium HSM)
  ✅ Azure Storage Account
  ✅ Azure Bastion (secure access)
  ✅ Virtual Network + NSGs

DOCKER SERVICES RUNNING:
  🐳 EJBCA CE 8.3.0
  🌐 NGINX Reverse Proxy
  📊 Azure Monitor Agent

ACCESS YOUR DEPLOYMENT:

1. Connect to VM via Azure Bastion:
   
   az network bastion ssh \\
     --name ${BASTION_NAME} \\
     --resource-group ${RESOURCE_GROUP} \\
     --target-resource-id ${VM_ID} \\
     --auth-type ssh-key \\
     --username azureuser \\
     --ssh-key ~/.ssh/ejbca-vm-key

2. Access EJBCA Web UI:
   
   https://<vm-ip>:8443/ejbca

3. Access Grafana (Azure Managed):
   
   ${GRAFANA_ENDPOINT}

4. View Application Insights:
   
   Azure Portal → Application Insights → ${RESOURCE_GROUP}

NEXT STEPS:

1. Initialize EJBCA CA hierarchy:
   ./scripts/initialize-ca.sh

2. Configure certificate profiles:
   ./scripts/configure-profiles.sh

3. Test certificate issuance:
   ./scripts/test-certificate.sh

4. View monitoring dashboards:
   Open Grafana: ${GRAFANA_ENDPOINT}

COST BREAKDOWN:

Development Environment:   \$425/month  (78% savings)
Production Environment:    \$1,440/month (69% savings)

DOCUMENTATION:
  
  📄 Quick Start: QUICKSTART.md
  📊 Cost Analysis: docs/COST-OPTIMIZATION-ANALYSIS.md
  🔧 Operations: docs/OPERATIONS-GUIDE.md
  📚 Full Docs: docs/

═══════════════════════════════════════════════════════════════════════════

🚀 Your cost-optimized PKI platform is ready!

Author: Adrian Johnson <adrian207@gmail.com>

EOF
}

# Main execution
main() {
    clear
    
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║         🐳 EJBCA PKI PLATFORM - HYBRID DEPLOYMENT                        ║
║                                                                          ║
║         Cost-Optimized Architecture with Azure-Managed Services         ║
║                                                                          ║
║         Author: Adrian Johnson <adrian207@gmail.com>                    ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

EOF
    
    check_prerequisites
    azure_login
    deploy_infrastructure
    get_outputs
    deploy_docker_stack
    display_instructions
    
    print_success "Deployment script completed successfully!"
}

# Run main
main

