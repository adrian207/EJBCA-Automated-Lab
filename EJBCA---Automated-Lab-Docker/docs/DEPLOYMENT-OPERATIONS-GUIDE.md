# Enterprise PKI Platform - Deployment & Operations Guide

**Author**: Adrian Johnson | adrian207@gmail.com  
**Version**: 1.0.0  
**Last Updated**: October 2025  
**Status**: Production-Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Models](#deployment-models)
4. [Initial Deployment](#initial-deployment)
5. [Configuration](#configuration)
6. [Day-2 Operations](#day-2-operations)
7. [Backup & Recovery](#backup--recovery)
8. [Scaling Operations](#scaling-operations)
9. [Maintenance Procedures](#maintenance-procedures)
10. [Security Operations](#security-operations)

---

## Overview

### Document Purpose

This guide provides step-by-step instructions for deploying, configuring, and operating the Enterprise PKI Platform in both development and production environments.

### Deployment Timeline

| Phase | Duration | Activities |
|-------|----------|------------|
| **Preparation** | 30 minutes | Install tools, configure credentials |
| **Infrastructure** | 45 minutes | Deploy Azure resources via Terraform |
| **Platform** | 90 minutes | Deploy applications and services |
| **Configuration** | 45 minutes | Configure EJBCA, DNS, certificates |
| **Validation** | 30 minutes | Run tests, verify functionality |
| **Total** | **~4 hours** | Complete deployment |

---

## Prerequisites

### Required Tools

Install and configure these tools before beginning deployment:

#### 1. Azure CLI

```bash
# Install Azure CLI
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
winget install Microsoft.AzureCLI

# Verify installation
az version
# Required: v2.50.0 or higher

# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show
```

#### 2. Terraform

```bash
# Install Terraform
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows
winget install Hashicorp.Terraform

# Verify installation
terraform version
# Required: v1.5.0 or higher
```

#### 3. kubectl (for Kubernetes deployment)

```bash
# Install kubectl
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
winget install Kubernetes.kubectl

# Verify installation
kubectl version --client
# Required: v1.28.0 or higher
```

#### 4. Helm (for Kubernetes deployment)

```bash
# Install Helm
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
winget install Helm.Helm

# Verify installation
helm version
# Required: v3.12.0 or higher
```

#### 5. Docker (for Docker Compose deployment)

```bash
# Install Docker
# macOS
brew install --cask docker

# Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Windows
winget install Docker.DockerDesktop

# Verify installation
docker --version
docker-compose --version
# Required: Docker 24.0+, Compose 2.20+
```

### Azure Requirements

#### Permissions Required

Your Azure account needs these role assignments:

| Resource | Required Role |
|----------|--------------|
| **Subscription** | Contributor |
| **Resource Groups** | Owner (to assign roles) |
| **Azure Key Vault** | Key Vault Administrator |
| **AKS** | Azure Kubernetes Service Cluster Admin |
| **Networking** | Network Contributor |

#### Verify Permissions

```bash
# Check your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table
```

#### Resource Quotas

Verify you have sufficient quotas:

```bash
# Check compute quotas
az vm list-usage --location eastus \
  --query "[?name.value=='standardDSv3Family'].{Name:name.localizedValue, Current:currentValue, Limit:limit}" \
  --output table

# Should show:
# Development: At least 12 available vCPUs
# Production: At least 36 available vCPUs
```

### Local Machine Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10, macOS 11, Ubuntu 20.04 | Latest stable |
| **RAM** | 8 GB | 16 GB |
| **Disk Space** | 20 GB free | 50 GB free |
| **CPU** | 4 cores | 8 cores |
| **Internet** | 10 Mbps | 100 Mbps |

---

## Deployment Models

### Model 1: Kubernetes (AKS) Deployment

**Recommended for**: Production environments, high availability, auto-scaling requirements

#### Cost Estimate
- **Development**: $1,835/month
- **Production**: $4,500-6,000/month

#### Features
- ✅ Auto-scaling (3-50 nodes)
- ✅ Service mesh (Linkerd)
- ✅ GitOps (ArgoCD)
- ✅ Advanced observability
- ✅ Zero-downtime updates

### Model 2: Docker Compose Deployment

**Recommended for**: Development, testing, cost-sensitive deployments

#### Cost Estimate
- **Development**: $425/month (78% savings)
- **Production**: $1,440/month (69% savings)

#### Features
- ✅ Simple deployment
- ✅ Lower operational complexity
- ✅ Full EJBCA functionality
- ✅ Standard observability
- ⚠️ Manual scaling

---

## Initial Deployment

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/your-org/EJBCA---Automated-Lab-Docker.git
cd EJBCA---Automated-Lab-Docker

# Verify branch
git branch
# Should show: feat/dynamic-ip-solutions or main

# Review structure
ls -la
```

### Step 2: Configure Terraform Variables

```bash
# Navigate to terraform directory
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit variables file
vim terraform.tfvars
```

#### Minimum Required Configuration

```hcl
# terraform.tfvars

# Project Configuration
project_name    = "ejbca-platform"
environment     = "dev"  # or "staging", "prod"
azure_region    = "eastus"

# Your Administrator IP (for NSG rules if Bastion is disabled)
admin_ip_address = "YOUR_PUBLIC_IP_HERE"  # Get from: curl ifconfig.me

# Enable Azure Bastion (recommended - eliminates IP management)
enable_bastion = true

# Network Configuration
vnet_address_space = ["10.0.0.0/16"]

# AKS Configuration (for Kubernetes deployment)
aks_kubernetes_version = "1.28"
aks_node_count         = 3
aks_node_vm_size       = "Standard_D4s_v3"

# Database Configuration
postgresql_sku_name = "GP_Standard_D4s_v3"  # Dev
# postgresql_sku_name = "GP_Standard_D8s_v3"  # Prod

# Storage Configuration
storage_account_replication_type = "LRS"  # Dev: LRS, Prod: GRS

# Tags
tags = {
  Owner       = "adrian207@gmail.com"
  Department  = "Infrastructure"
  CostCenter  = "IT"
}
```

### Step 3: Deploy Infrastructure

#### Initialize Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

#### Plan Deployment

```bash
# Create execution plan
terraform plan -out=deployment.tfplan

# Review the plan carefully
# Look for:
# - Number of resources to be created (~40-60)
# - No unexpected deletions
# - Correct resource sizes
# - Proper network configuration
```

#### Apply Infrastructure

```bash
# Apply the plan
terraform apply deployment.tfplan

# This will take 20-45 minutes
# Progress indicators:
# ✓ Resource group created (1 min)
# ✓ Virtual network created (2 min)
# ✓ AKS cluster created (10-15 min)
# ✓ PostgreSQL server created (5-10 min)
# ✓ Key Vault created (2 min)
# ✓ Storage account created (2 min)
# ✓ Azure Bastion created (10-15 min)
# ✓ VMs created (5 min)

# When complete, you'll see:
# Apply complete! Resources: XX added, 0 changed, 0 destroyed.
```

#### Capture Outputs

```bash
# Save important outputs
terraform output -json > ../deployment-outputs.json

# View specific outputs
terraform output resource_group_name
terraform output aks_cluster_name
terraform output bastion_host_name
terraform output key_vault_name
terraform output postgresql_server_fqdn
```

### Step 4A: Deploy Kubernetes Platform

For Kubernetes/AKS deployment:

```bash
# Return to project root
cd ..

# Configure kubectl
az aks get-credentials \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --name $(terraform -chdir=terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify cluster access
kubectl cluster-info
kubectl get nodes

# Expected output: 9 nodes (3 per node pool) in Ready state
```

#### Run Automated Deployment Script

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh

# The script will:
# 1. Check prerequisites ✓
# 2. Install Linkerd service mesh
# 3. Deploy NGINX Ingress Controller
# 4. Deploy observability stack (Prometheus, Grafana, Loki, Tempo)
# 5. Deploy Harbor container registry
# 6. Deploy JFrog Artifactory
# 7. Deploy ArgoCD for GitOps
# 8. Deploy EJBCA CE
# 9. Configure DNS entries
# 10. Display access information

# Deployment time: ~45-60 minutes
```

### Step 4B: Deploy Docker Compose Platform

For Docker Compose deployment:

```bash
# Return to project root
cd ..

# Connect to VM via Azure Bastion
# (Use Azure Portal or az CLI)

# SSH via Bastion
az network bastion ssh \
  --name $(terraform -chdir=terraform output -raw bastion_host_name) \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --target-resource-id $(terraform -chdir=terraform output -json vm_ids | jq -r '.[0]') \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/id_rsa

# On the VM:
cd /opt/ejbca-platform

# Configure environment
cp docker/.env.example docker/.env
vim docker/.env

# Deploy stack
docker-compose -f docker/docker-compose.yml up -d

# Verify deployment
docker-compose ps

# Expected: All services "Up"
```

### Step 5: Configure DNS

Add these entries to your DNS or local `/etc/hosts` file:

```bash
# Get ingress IP (Kubernetes)
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Or get VM IP (Docker)
VM_IP=$(terraform -chdir=terraform output -raw vm_public_ip)

# Add to /etc/hosts (local development)
echo "$INGRESS_IP ejbca.local" | sudo tee -a /etc/hosts
echo "$INGRESS_IP argocd.local" | sudo tee -a /etc/hosts
echo "$INGRESS_IP grafana.local" | sudo tee -a /etc/hosts
echo "$INGRESS_IP prometheus.local" | sudo tee -a /etc/hosts
echo "$INGRESS_IP harbor.local" | sudo tee -a /etc/hosts

# For production, configure proper DNS A records
```

### Step 6: Initial Access

#### Retrieve Passwords

```bash
# Get Key Vault name
KEYVAULT_NAME=$(terraform -chdir=terraform output -raw key_vault_name)

# ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Grafana admin password
az keyvault secret show \
  --vault-name $KEYVAULT_NAME \
  --name grafana-admin-password \
  --query value -o tsv

# Harbor admin password
az keyvault secret show \
  --vault-name $KEYVAULT_NAME \
  --name harbor-admin-password \
  --query value -o tsv
```

#### Access Web Interfaces

```bash
# EJBCA Admin UI
open https://ejbca.local/ejbca/adminweb

# Grafana
open https://grafana.local
# Login: admin / <password-from-keyvault>

# ArgoCD
open https://argocd.local
# Login: admin / <password-from-kubectl>

# Prometheus
open https://prometheus.local

# Harbor
open https://harbor.local
# Login: admin / <password-from-keyvault>
```

---

## Configuration

### EJBCA Initial Configuration

#### 1. Access Admin UI

```bash
# First-time access requires certificate authentication
# The platform auto-generates a superadmin certificate

# For development/testing, accept the self-signed certificate

# Access: https://ejbca.local:8443/ejbca/adminweb
```

#### 2. Create CA Hierarchy

Navigate to **CA Functions** → **Certificate Authorities** → **Create CA**

**Root CA:**
```yaml
CA Name: Root-CA
Subject DN: CN=Root CA,O=Enterprise PKI,C=US
Validity: 7300 days (20 years)
Key Type: RSA
Key Size: 4096 bits
Signature Algorithm: SHA256WithRSA
Crypto Token: AzureKeyVaultCryptoToken
```

**Subordinate CA - TLS:**
```yaml
CA Name: TLS-CA
Subject DN: CN=TLS Issuing CA,O=Enterprise PKI,C=US
Validity: 3652 days (10 years)
Key Type: RSA
Key Size: 4096 bits
Signed By: Root-CA
```

**Subordinate CA - Code Signing:**
```yaml
CA Name: CodeSign-CA
Subject DN: CN=Code Signing CA,O=Enterprise PKI,C=US
Validity: 3652 days (10 years)
Key Type: RSA
Key Size: 4096 bits
Signed By: Root-CA
```

#### 3. Configure Certificate Profiles

The platform includes 8 pre-configured profiles:

1. **SERVER_CERTIFICATE** - TLS/SSL servers
2. **CLIENT_CERTIFICATE** - User authentication
3. **CODE_SIGNING** - Software signing
4. **DOCUMENT_SIGNING** - PDF signing
5. **IPSEC_VPN** - VPN endpoints
6. **CONTAINER_SIGNING** - Docker/OCI images
7. **IOT_DEVICE** - IoT devices
8. **TIMESTAMPING** - Timestamp authority

Review and adjust as needed:
- **CA Functions** → **Certificate Profiles** → [Profile Name]

#### 4. Configure End Entity Profiles

Create profiles for common use cases:

**Web Server Profile:**
```yaml
Name: WEB_SERVER
Available Certificate Profiles: SERVER_CERTIFICATE
Subject DN Attributes: CN (required), O, C
Subject Alternative Names: DNS Name (required)
Default CA: TLS-CA
Approval Required: No
```

**Software Publisher Profile:**
```yaml
Name: SOFTWARE_PUBLISHER
Available Certificate Profiles: CODE_SIGNING
Subject DN Attributes: CN, O (required), C
Approval Required: Yes (2 approvers)
Default CA: CodeSign-CA
```

#### 5. Enable Protocols

Configure each protocol endpoint:

**ACME:**
- Navigate to: **System Functions** → **Protocol Configuration** → **ACME**
- Enable: ✓
- Alias: `default`
- End Entity Profile: `WEB_SERVER`
- Certificate Profile: `SERVER_CERTIFICATE`

**SCEP:**
- Navigate to: **System Functions** → **Protocol Configuration** → **SCEP**
- Enable: ✓
- Alias: `scep`
- Authentication: Challenge password

**REST API:**
- Navigate to: **System Functions** → **REST API Configuration**
- Enable: ✓
- Authentication: Client certificate or API key

#### 6. Configure OCSP

**Enable OCSP Responder:**
- Navigate to: **CA Functions** → **Internal Key Bindings** → **OCSP Key Binding**
- Create new OCSP key binding for each CA
- Signing Algorithm: SHA256WithRSA
- Certificate Profile: OCSP_RESPONDER

**Test OCSP:**
```bash
openssl ocsp \
  -issuer tls-ca.crt \
  -cert server.crt \
  -url http://ocsp.ejbca.local \
  -text
```

#### 7. Configure CRL

**CRL Settings per CA:**
- Navigate to: **CA Functions** → **Certificate Authorities** → [CA Name] → **Edit**
- CRL Period: 24 hours
- CRL Issue Interval: 1 hour
- CRL Distribution Points: `http://crl.ejbca.local/tls-ca.crl`
- Enable Delta CRL: ✓

**Generate Initial CRL:**
- **CA Functions** → **Certificate Authorities** → [CA Name] → **Create CRL**

---

## Day-2 Operations

### Daily Operations

#### Morning Health Checks

```bash
# Check cluster status (Kubernetes)
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Check EJBCA health
curl -f https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth

# Check database connections
kubectl exec -n ejbca ejbca-ce-0 -- psql -h postgresql -U ejbca -c "SELECT count(*) FROM CertificateData;"

# Check disk usage
kubectl top nodes
kubectl top pods -n ejbca
```

#### Monitor Certificate Issuance

```bash
# View certificate metrics in Grafana
# Dashboard: EJBCA PKI Overview

# Query Prometheus directly
curl -s 'http://prometheus.local/api/v1/query?query=ejbca_certificates_issued_total' | jq

# Check last 24 hours
# Certificates issued
# Certificates revoked
# Failed issuance attempts
```

#### Review Logs

```bash
# EJBCA application logs (Kubernetes)
kubectl logs -n ejbca ejbca-ce-0 --tail=100 -f

# EJBCA logs (Docker)
docker-compose -f docker/docker-compose.yml logs ejbca --tail=100 -f

# Database logs
kubectl logs -n database postgresql-0 --tail=100

# Query logs in Loki via Grafana
# Navigate to: Grafana → Explore → Loki
# Query: {namespace="ejbca"} |= "ERROR"
```

### Weekly Operations

#### Certificate Expiration Review

```bash
# Check certificates expiring in 30 days
# Via Grafana dashboard: EJBCA PKI Overview → Expiring Certificates

# Or query database directly
kubectl exec -n ejbca ejbca-ce-0 -- psql -h postgresql -U ejbca -d ejbca <<EOF
SELECT 
  username, 
  subject_dn, 
  expire_date 
FROM CertificateData 
WHERE expire_date < NOW() + INTERVAL '30 days' 
  AND status = 20 
ORDER BY expire_date;
EOF
```

#### Review Security Alerts

```bash
# Check failed authentication attempts
# Grafana → Security Events Dashboard

# Review audit logs
kubectl logs -n ejbca ejbca-ce-0 | grep AUDIT | grep FAIL

# Check for unusual activity
# - High certificate issuance rate
# - Multiple failed logins
# - Unauthorized access attempts
```

#### Backup Verification

```bash
# Verify automated backups completed
az storage blob list \
  --account-name $(terraform -chdir=terraform output -raw storage_account_name) \
  --container-name ejbca-backups \
  --query "[?properties.lastModified > '$(date -d '1 day ago' -I)'].name" \
  --output table

# Expected: Daily backup from last 24 hours
```

### Monthly Operations

#### Apply Security Updates

```bash
# Update container images (Kubernetes)
# Pull latest images
kubectl set image deployment/ejbca-ce ejbca=keyfactor/ejbca-ce:8.3.1 -n ejbca

# Rolling update (zero downtime)
kubectl rollout status deployment/ejbca-ce -n ejbca

# Update Docker images
docker-compose pull
docker-compose up -d

# Update node OS (AKS)
az aks upgrade \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --name $(terraform -chdir=terraform output -raw aks_cluster_name) \
  --kubernetes-version 1.29
```

#### Capacity Review

```bash
# Review resource utilization
# Grafana → Infrastructure Health Dashboard

# Check trends:
# - CPU utilization (target: <70% avg)
# - Memory utilization (target: <80% avg)
# - Database connections (target: <80% of max)
# - Storage growth rate

# Scale if needed (see Scaling Operations section)
```

#### Certificate Cleanup

```bash
# Archive expired certificates older than 1 year
kubectl exec -n ejbca ejbca-ce-0 -- java -jar /opt/ejbca/bin/ejbca.jar ca archiveexpiredcerts TLS-CA 365

# Clean up revoked certificates
# Certificates remain in database but are marked for cleanup
```

---

## Backup & Recovery

### Backup Strategy

#### What Gets Backed Up

| Component | Backup Method | Frequency | Retention |
|-----------|---------------|-----------|-----------|
| **PostgreSQL Database** | Azure automated backup | Every 6 hours | 30 days |
| **CA Keys** | Azure Key Vault backup | Continuous | Indefinite |
| **Configuration Files** | Git repository | On change | Indefinite |
| **Certificates** | Database + Blob Storage | Daily | 5 years |
| **Audit Logs** | Loki + Blob Storage | Daily | 7 years |

#### Manual Backup

```bash
# Backup database
kubectl exec -n database postgresql-0 -- pg_dump -U ejbca ejbca > ejbca-backup-$(date +%Y%m%d).sql

# Upload to blob storage
az storage blob upload \
  --account-name $(terraform -chdir=terraform output -raw storage_account_name) \
  --container-name ejbca-backups \
  --name ejbca-backup-$(date +%Y%m%d).sql \
  --file ejbca-backup-$(date +%Y%m%d).sql

# Backup Key Vault keys
az keyvault key backup \
  --vault-name $(terraform -chdir=terraform output -raw key_vault_name) \
  --name ejbca-root-ca-key \
  --file ejbca-root-ca-key-backup.key

# Backup Kubernetes configs
kubectl get all -n ejbca -o yaml > ejbca-k8s-backup-$(date +%Y%m%d).yaml
```

### Recovery Procedures

#### Scenario 1: Database Corruption

```bash
# 1. Stop EJBCA pods
kubectl scale deployment ejbca-ce --replicas=0 -n ejbca

# 2. Restore database from Azure backup
az postgres flexible-server restore \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --name $(terraform -chdir=terraform output -raw postgresql_server_name) \
  --source-server <source-server-id> \
  --restore-time "2025-10-15T10:00:00Z"

# 3. Update connection string if needed
kubectl edit secret ejbca-db-secret -n ejbca

# 4. Restart EJBCA
kubectl scale deployment ejbca-ce --replicas=3 -n ejbca

# 5. Verify
kubectl logs -n ejbca ejbca-ce-0 --tail=100
curl https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth
```

#### Scenario 2: Complete Cluster Failure

```bash
# 1. Deploy new infrastructure
cd terraform
terraform init
terraform apply

# 2. Restore database
# Follow database restoration steps above

# 3. Restore CA keys from Key Vault
# Keys are automatically available via managed identity

# 4. Redeploy platform
cd ..
./scripts/deploy.sh

# 5. Restore configuration
kubectl apply -f ejbca-k8s-backup-YYYYMMDD.yaml

# 6. Verify all services
kubectl get pods --all-namespaces
curl https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth
```

#### Scenario 3: CA Key Compromise

[Inference] This is a critical security incident requiring immediate action:

```bash
# IMMEDIATE ACTIONS:
# 1. Revoke compromised CA immediately
# 2. Generate new CA with new keys
# 3. Re-issue all certificates
# 4. Notify all certificate consumers
# 5. Update CRL and OCSP
# 6. Conduct security review

# This is a complex scenario requiring executive approval
# Follow your organization's incident response procedures
```

#### Recovery Time Objectives (RTO)

| Scenario | RTO | RPO | Notes |
|----------|-----|-----|-------|
| **Pod failure** | < 5 minutes | 0 | Auto-healing |
| **Node failure** | < 15 minutes | 0 | Auto-replacement |
| **Database corruption** | < 30 minutes | 6 hours | From backup |
| **Complete cluster failure** | < 2 hours | 6 hours | Full redeploy |
| **Region failure** | < 4 hours | 24 hours | Requires DR setup |

---

## Scaling Operations

### Vertical Scaling

#### Scale Up EJBCA Resources

```bash
# Kubernetes: Update resource limits
kubectl edit deployment ejbca-ce -n ejbca

# Change:
resources:
  limits:
    cpu: 8000m      # From 4000m
    memory: 16Gi    # From 8Gi
  requests:
    cpu: 4000m      # From 2000m
    memory: 8Gi     # From 4Gi

# Apply changes (triggers rolling update)
kubectl rollout status deployment/ejbca-ce -n ejbca
```

#### Scale Up Database

```bash
# Scale PostgreSQL SKU
az postgres flexible-server update \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --name $(terraform -chdir=terraform output -raw postgresql_server_name) \
  --sku-name GP_Standard_D8s_v3

# This operation takes 5-10 minutes
# EJBCA will reconnect automatically
```

### Horizontal Scaling

#### Scale EJBCA Pods

```bash
# Manual scaling
kubectl scale deployment ejbca-ce --replicas=5 -n ejbca

# Or enable autoscaling
kubectl autoscale deployment ejbca-ce \
  --cpu-percent=70 \
  --min=3 \
  --max=10 \
  -n ejbca

# Check autoscaler status
kubectl get hpa -n ejbca
```

#### Scale AKS Cluster

```bash
# Scale specific node pool
az aks nodepool scale \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --cluster-name $(terraform -chdir=terraform output -raw aks_cluster_name) \
  --name pkinodepool \
  --node-count 5

# Or enable cluster autoscaler
az aks nodepool update \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --cluster-name $(terraform -chdir=terraform output -raw aks_cluster_name) \
  --name pkinodepool \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 6
```

#### Scale Docker Deployment

```bash
# Add more VMs via Terraform
cd terraform
vim terraform.tfvars

# Change:
vm_count = 3  # From 1

terraform apply

# Deploy Docker Compose to new VMs
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/deploy-docker-stack.yml

# Configure load balancer (production)
# See terraform/compute.tf for LB configuration
```

---

## Maintenance Procedures

### Updating EJBCA

```bash
# 1. Review release notes
# Visit: https://doc.primekey.com/ejbca/ejbca-release-information

# 2. Backup current configuration
kubectl exec -n ejbca ejbca-ce-0 -- /opt/ejbca/bin/ejbca.jar backup /tmp/ejbca-backup.zip
kubectl cp ejbca/ejbca-ce-0:/tmp/ejbca-backup.zip ./ejbca-backup-$(date +%Y%m%d).zip

# 3. Update image version
kubectl set image deployment/ejbca-ce ejbca=keyfactor/ejbca-ce:8.4.0 -n ejbca

# 4. Monitor rollout
kubectl rollout status deployment/ejbca-ce -n ejbca
kubectl logs -n ejbca ejbca-ce-0 -f

# 5. Verify functionality
curl https://ejbca.local/ejbca/publicweb/healthcheck/ejbcahealth

# 6. Test certificate issuance
./scripts/demo-scenarios.sh
```

### Certificate Renewal

#### Renew Platform Certificates

```bash
# Renew ingress TLS certificates (automated via cert-manager)
kubectl get certificate -n ejbca
# Check expiry dates

# Force renewal if needed
kubectl delete secret ejbca-tls -n ejbca
kubectl annotate certificate ejbca-tls -n ejbca cert-manager.io/issue-temporary-certificate-

# Verify new certificate
kubectl get secret ejbca-tls -n ejbca -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates
```

#### Renew CA Certificates

[Inference] CA certificate renewal is a complex, infrequent operation (every 10-20 years) requiring:
- Planning and approval
- Communication to all certificate consumers
- Gradual transition period
- Testing in staging environment

Consult EJBCA documentation and your security team.

### Database Maintenance

```bash
# Vacuum database (reclaim space)
kubectl exec -n database postgresql-0 -- vacuumdb -U ejbca -d ejbca --full --analyze

# Update statistics
kubectl exec -n database postgresql-0 -- psql -U ejbca -d ejbca -c "ANALYZE;"

# Check database size
kubectl exec -n database postgresql-0 -- psql -U ejbca -d ejbca -c "
SELECT 
  pg_size_pretty(pg_database_size('ejbca')) as database_size,
  pg_size_pretty(pg_total_relation_size('CertificateData')) as certificates_size;
"

# Archive old audit logs (if needed)
# Move logs older than 2 years to cold storage
```

---

## Security Operations

### Security Monitoring

#### Daily Security Checks

```bash
# 1. Review failed authentications
kubectl logs -n ejbca ejbca-ce-0 | grep "Authentication failed" | tail -20

# 2. Check for suspicious certificate requests
kubectl logs -n ejbca ejbca-ce-0 | grep "Certificate request" | grep -i "suspicious"

# 3. Review Key Vault access logs
az monitor activity-log list \
  --resource-group $(terraform -chdir=terraform output -raw resource_group_name) \
  --max-events 100 \
  --query "[?contains(resourceId, 'keyvault')].{Time:eventTimestamp, User:caller, Operation:operationName}" \
  --output table

# 4. Check for vulnerabilities
# Review Trivy scan results in Harbor
```

### Incident Response

#### Security Incident Procedure

```bash
# 1. DETECT
# - Alert triggered from monitoring
# - Suspicious activity noticed
# - External report received

# 2. CONTAIN
# Isolate affected systems
kubectl scale deployment ejbca-ce --replicas=0 -n ejbca  # If needed
# Update NSG rules to block suspicious IPs

# 3. INVESTIGATE
# Collect logs
kubectl logs -n ejbca ejbca-ce-0 > incident-logs-$(date +%Y%m%d-%H%M%S).txt
# Review audit trails
# Analyze traffic patterns

# 4. ERADICATE
# Remove malicious code/access
# Patch vulnerabilities
# Rotate credentials

# 5. RECOVER
# Restore from clean backup if needed
# Redeploy if necessary
# Verify system integrity

# 6. LESSONS LEARNED
# Document incident
# Update procedures
# Implement preventive measures
```

### Access Reviews

#### Quarterly Access Review

```bash
# Review Azure AD role assignments
az role assignment list \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$(terraform -chdir=terraform output -raw resource_group_name) \
  --output table

# Review Key Vault access policies
az keyvault show \
  --name $(terraform -chdir=terraform output -raw key_vault_name) \
  --query properties.accessPolicies \
  --output table

# Review EJBCA admin roles
# Login to EJBCA Admin UI
# Navigate to: System Functions → Administrator Roles
# Review all administrator accounts and permissions

# Document findings and remove unnecessary access
```

---

## Appendix

### Useful Commands Reference

#### Kubernetes

```bash
# Get all resources in namespace
kubectl get all -n ejbca

# Describe pod (troubleshooting)
kubectl describe pod ejbca-ce-0 -n ejbca

# Execute command in pod
kubectl exec -it ejbca-ce-0 -n ejbca -- bash

# Port forward for local access
kubectl port-forward -n ejbca svc/ejbca-ce 8443:8443

# View pod logs
kubectl logs -f ejbca-ce-0 -n ejbca

# Get pod resource usage
kubectl top pod ejbca-ce-0 -n ejbca
```

#### Docker Compose

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose stop

# View logs
docker-compose logs -f ejbca

# Execute command in container
docker-compose exec ejbca bash

# Restart service
docker-compose restart ejbca

# View resource usage
docker stats
```

#### Azure CLI

```bash
# List resource groups
az group list --output table

# Show resource group
az group show --name <rg-name>

# List all resources in RG
az resource list --resource-group <rg-name> --output table

# Get AKS credentials
az aks get-credentials --resource-group <rg-name> --name <aks-name>

# SSH via Bastion
az network bastion ssh --name <bastion-name> --resource-group <rg-name> --target-resource-id <vm-id> --auth-type ssh-key --username azureuser --ssh-key ~/.ssh/id_rsa
```

### Troubleshooting Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| **Pod won't start** | `kubectl describe pod <pod-name> -n ejbca` |
| **Database connection failed** | Check connection string in secret, verify PostgreSQL is running |
| **Certificate issuance fails** | Check CA status, review EJBCA logs |
| **Can't access UI** | Verify ingress, check DNS, confirm TLS certificate |
| **High memory usage** | Scale up resources or add replicas |
| **Slow performance** | Check database queries, review resource limits |

### Support Contacts

| Component | Contact | Documentation |
|-----------|---------|---------------|
| **EJBCA** | [EJBCA Community Forum](https://forum.keyfactor.com) | [docs.primekey.com](https://doc.primekey.com/ejbca) |
| **Azure** | Azure Support Portal | [learn.microsoft.com](https://learn.microsoft.com/azure) |
| **Platform** | adrian207@gmail.com | This documentation |

---

**Document Maintenance**: This guide should be reviewed quarterly and updated after each major deployment or configuration change.

**Feedback**: Please report errors or suggestions to adrian207@gmail.com

---

*End of Deployment & Operations Guide*



