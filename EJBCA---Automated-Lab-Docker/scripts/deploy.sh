#!/bin/bash
###############################################################################
# EJBCA PKI Platform Deployment Script
# This script deploys the complete PKI platform to Azure Kubernetes Service
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-ejbca-platform-dev-rg}"
CLUSTER_NAME="${CLUSTER_NAME:-ejbca-platform-dev-aks}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

# Prerequisites check
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local tools=("az" "kubectl" "helm" "terraform")
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            print_success "$tool is installed"
        else
            print_error "$tool is not installed"
            exit 1
        fi
    done
}

# Deploy Terraform infrastructure
deploy_infrastructure() {
    print_header "Deploying Azure Infrastructure with Terraform"
    
    cd terraform
    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan
    cd ..
    
    print_success "Infrastructure deployed"
}

# Configure kubectl
configure_kubectl() {
    print_header "Configuring kubectl"
    
    az aks get-credentials \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CLUSTER_NAME" \
        --overwrite-existing
    
    print_success "kubectl configured"
}

# Install Linkerd
install_linkerd() {
    print_header "Installing Linkerd Service Mesh"
    
    # Install Linkerd CLI if not present
    if ! command -v linkerd &> /dev/null; then
        curl -sL https://run.linkerd.io/install | sh
        export PATH=$PATH:$HOME/.linkerd2/bin
    fi
    
    # Install Linkerd
    linkerd install | kubectl apply -f -
    linkerd check
    
    # Install Linkerd Viz
    linkerd viz install | kubectl apply -f -
    
    print_success "Linkerd installed"
}

# Deploy platform components
deploy_platform() {
    print_header "Deploying Platform Components"
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add harbor https://helm.goharbor.io
    helm repo add jfrog https://charts.jfrog.io
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # Create namespaces
    kubectl apply -f kubernetes/*/namespace.yaml
    
    # Install NGINX Ingress
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        -f kubernetes/ingress-nginx/values.yaml \
        -n ingress-nginx --create-namespace --wait
    
    # Install Observability Stack
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        -f kubernetes/observability/kube-prometheus-stack-values.yaml \
        -n observability --create-namespace --wait
    
    helm upgrade --install loki grafana/loki-distributed \
        -f kubernetes/observability/loki-values.yaml \
        -n observability --wait
    
    helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
        -f kubernetes/observability/opentelemetry-collector-values.yaml \
        -n observability --wait
    
    # Install Harbor
    helm upgrade --install harbor harbor/harbor \
        -f kubernetes/harbor/harbor-values.yaml \
        -n harbor --create-namespace --wait
    
    # Install ArgoCD
    helm upgrade --install argocd argo/argo-cd \
        -f argocd/argocd-values.yaml \
        -n argocd --create-namespace --wait
    
    # Install EJBCA
    helm upgrade --install ejbca-ce ./helm/ejbca-ce \
        -f helm/ejbca-ce/values.yaml \
        -n ejbca --create-namespace --wait
    
    print_success "Platform components deployed"
}

# Configure ArgoCD
configure_argocd() {
    print_header "Configuring ArgoCD"
    
    # Create ArgoCD project
    kubectl apply -f argocd/projects/pki-platform-project.yaml
    
    # Create ArgoCD applications
    kubectl apply -f argocd/applications/
    
    print_success "ArgoCD configured"
}

# Display access information
display_access_info() {
    print_header "Deployment Complete!"
    
    echo -e "${GREEN}Access Information:${NC}\n"
    
    # Get external IPs
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    echo "EJBCA Admin UI: https://ejbca.local"
    echo "ArgoCD UI: https://argocd.local"
    echo "Grafana UI: https://grafana.local"
    echo "Prometheus UI: https://prometheus.local"
    echo "Harbor Registry: https://harbor.local"
    echo "Linkerd Dashboard: https://linkerd.local"
    echo ""
    echo "Ingress IP: $INGRESS_IP"
    echo ""
    echo "Add these entries to /etc/hosts or configure DNS:"
    echo "$INGRESS_IP ejbca.local"
    echo "$INGRESS_IP argocd.local"
    echo "$INGRESS_IP grafana.local"
    echo "$INGRESS_IP prometheus.local"
    echo "$INGRESS_IP harbor.local"
    echo "$INGRESS_IP linkerd.local"
    echo ""
    
    # Get initial passwords
    echo -e "${YELLOW}Initial Passwords:${NC}"
    echo "ArgoCD admin password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
    
    print_info "Run './scripts/demo-scenarios.sh' to test EJBCA features"
}

# Main execution
main() {
    print_header "EJBCA PKI Platform Deployment"
    
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    install_linkerd
    deploy_platform
    configure_argocd
    display_access_info
    
    print_success "Deployment completed successfully!"
}

# Run main
main

