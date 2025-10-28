#!/bin/bash

# GitHub Repository Tags Setup Script
# This script adds comprehensive tags/topics to the repository

set -e

echo "🏷️ Adding comprehensive tags to GitHub repository..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"

# Repository configuration
REPO="adrian207/EJBCA---Automated-Lab"

# Comprehensive topics array
TOPICS=(
    # Core PKI Topics
    "pki"
    "ejbca"
    "certificate-authority"
    "public-key-infrastructure"
    "keyfactor"
    "x509"
    "digital-certificates"
    "certificate-management"
    "certificate-lifecycle"
    "ca-hierarchy"
    "certificate-profiles"
    
    # Technology Stack
    "kubernetes"
    "terraform"
    "ansible"
    "helm"
    "argocd"
    "docker"
    "containers"
    "microservices"
    
    # Cloud & Infrastructure
    "azure"
    "aks"
    "azure-kubernetes-service"
    "cloud-native"
    "infrastructure-as-code"
    "gitops"
    "devops"
    "automation"
    
    # Security & Compliance
    "security"
    "cryptography"
    "ssl-tls"
    "enterprise-security"
    "compliance"
    "security-scanning"
    "vulnerability-management"
    "secrets-management"
    "key-management"
    "audit-logging"
    "compliance-reporting"
    
    # Monitoring & Observability
    "monitoring"
    "observability"
    "prometheus"
    "grafana"
    "loki"
    "tempo"
    "opentelemetry"
    "metrics"
    "logging"
    "tracing"
    
    # Service Mesh & Networking
    "linkerd"
    "service-mesh"
    "nginx"
    "ingress"
    "networking"
    "load-balancing"
    
    # CI/CD & Automation
    "ci-cd"
    "github-actions"
    "automated-deployment"
    "infrastructure-automation"
    "configuration-management"
    "security-automation"
    
    # Artifact Management
    "harbor"
    "artifactory"
    "container-registry"
    "artifact-management"
    
    # Enterprise Features
    "enterprise-grade"
    "production-ready"
    "scalable"
    "high-availability"
    "disaster-recovery"
    "backup-restore"
    
    # Learning & Lab
    "lab-environment"
    "learning"
    "tutorial"
    "examples"
    "demo"
    "proof-of-concept"
    
    # Industry Standards
    "enterprise-pki"
    "pki-platform"
    "certificate-services"
    "identity-management"
    "access-control"
)

echo "📝 Adding $(echo "${TOPICS[@]}" | wc -w) topics to repository..."

# Add topics to repository
gh api repos/$REPO/topics \
  --method PUT \
  --field names="$(IFS=,; echo "${TOPICS[*]}")"

if [ $? -eq 0 ]; then
    echo "✅ Successfully added all topics to repository!"
    echo ""
    echo "📊 Topics Summary:"
    echo "  🏢 Core PKI: $(echo "${TOPICS[@]}" | grep -E '^(pki|ejbca|certificate|keyfactor|x509)' | wc -w) topics"
    echo "  🛠️ Technology: $(echo "${TOPICS[@]}" | grep -E '^(kubernetes|terraform|ansible|helm|docker)' | wc -w) topics"
    echo "  ☁️ Cloud: $(echo "${TOPICS[@]}" | grep -E '^(azure|cloud|infrastructure)' | wc -w) topics"
    echo "  🔒 Security: $(echo "${TOPICS[@]}" | grep -E '^(security|cryptography|compliance)' | wc -w) topics"
    echo "  📊 Monitoring: $(echo "${TOPICS[@]}" | grep -E '^(monitoring|observability|prometheus)' | wc -w) topics"
    echo "  🚀 DevOps: $(echo "${TOPICS[@]}" | grep -E '^(devops|ci-cd|automation)' | wc -w) topics"
    echo ""
    echo "🔗 View topics at: https://github.com/$REPO"
else
    echo "❌ Failed to add topics to repository"
    echo "Please check your permissions and try again"
fi

echo ""
echo "🎯 Next Steps:"
echo "  1. Visit your repository to see the topics"
echo "  2. Topics will help with repository discoverability"
echo "  3. Users can filter repositories by these topics"
echo "  4. Topics appear in GitHub search results"
