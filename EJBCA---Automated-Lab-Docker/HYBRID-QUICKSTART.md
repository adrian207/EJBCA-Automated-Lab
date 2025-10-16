# EJBCA PKI Platform - Hybrid Architecture Quick Start

**Author**: Adrian Johnson | adrian207@gmail.com  
**Architecture**: Docker + Azure-Managed Services  
**Cost Savings**: 69-78% vs. AKS

---

## 🎯 Quick Deploy (5 Minutes)

### Prerequisites

- Azure CLI installed
- Terraform 1.5+ installed
- Docker installed (for local testing)
- Git installed
- Azure subscription

### Deploy Command

```bash
# Clone repository
git clone https://github.com/adrian207/EJBCA---Automated-Lab.git
cd EJBCA---Automated-Lab

# Switch to docker branch
git checkout docker

# Run deployment script
./scripts/deploy-hybrid.sh
```

That's it! The script will:

1. ✅ Check prerequisites
2. ✅ Login to Azure
3. ✅ Deploy infrastructure (Terraform)
4. ✅ Configure Docker VMs (cloud-init)
5. ✅ Deploy EJBCA containers
6. ✅ Setup monitoring

---

## 💰 Cost Breakdown

### Development Environment: **$425/month**

| Service | SKU | Cost |
|---------|-----|------|
| VM (1x) | Standard_D4s_v3 | $170 |
| PostgreSQL | Basic, 2 vCores | $120 |
| Azure Monitor | Managed Prometheus | $50 |
| App Insights | Pay-as-you-go | $30 |
| ACR | Basic | $5 |
| Key Vault | Standard | $10 |
| Storage | LRS | $20 |
| Networking | VNet, NSG | $20 |

**Total**: $425/month (78% savings vs. $1,835 AKS)

### Production Environment: **$1,440/month**

| Service | SKU | Cost |
|---------|-----|------|
| VMs (3x) | Standard_D4s_v3 each | $510 |
| Load Balancer | Standard | $25 |
| PostgreSQL | GP, 4 vCores | $340 |
| Azure Monitor | Managed Prometheus | $150 |
| App Insights | Standard | $100 |
| ACR | Standard | $20 |
| Key Vault | Premium HSM | $25 |
| Storage | GRS | $80 |
| Bastion | Standard | $140 |
| Networking | VNet, NSG, etc. | $50 |

**Total**: $1,440/month (69% savings vs. $4,585 AKS)

---

## 🏗️ Architecture

```
                    Azure Bastion (secure access)
                            |
        +-------------------+-------------------+
        |                   |                   |
    VM1 (Docker)        VM2 (Docker)        VM3 (Docker)
    - EJBCA CE          - EJBCA CE          - EJBCA CE
    - NGINX             - NGINX             - NGINX
    - Monitor Agent     - Monitor Agent     - Monitor Agent
        |                   |                   |
        +-------------------+-------------------+
                            |
        +-------------------+-------------------+
        |                   |                   |
   PostgreSQL          Azure Monitor        Key Vault
   (Managed)           (Prometheus +        (HSM Keys)
                        Grafana)
```

### What Runs in Docker:
- ✅ EJBCA CE 8.3.0
- ✅ NGINX (reverse proxy)
- ✅ Azure Monitor Agent

### What's Azure-Managed:
- ✅ PostgreSQL Flexible Server
- ✅ Prometheus (Azure Monitor)
- ✅ Grafana (Azure Managed)
- ✅ Application Insights (tracing)
- ✅ Container Registry
- ✅ Key Vault (HSM)
- ✅ Storage (backups)
- ✅ Bastion (access)

---

## 🚀 Step-by-Step Deployment

### 1. Clone and Configure

```bash
git clone https://github.com/adrian207/EJBCA---Automated-Lab.git
cd EJBCA---Automated-Lab
git checkout docker
```

### 2. Login to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 3. Deploy Infrastructure

```bash
cd terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit variables (optional)
vim terraform.tfvars

# Initialize Terraform
terraform init

# Deploy (Development)
terraform plan -var="environment=dev" -var="vm_count=1" -out=tfplan
terraform apply tfplan

# Or Deploy (Production)
terraform plan -var="environment=prod" -var="vm_count=3" -out=tfplan
terraform apply tfplan
```

### 4. Get Access Info

```bash
# Get Bastion connection command
terraform output bastion_instructions

# Get Grafana URL
terraform output grafana_endpoint

# Get VM IDs
terraform output vm_ids
```

### 5. Connect via Bastion

```bash
# SSH to first VM
az network bastion ssh \
  --name $(terraform output -raw bastion_host_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --target-resource-id $(terraform output -json vm_ids | jq -r '.[0]') \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/id_rsa
```

### 6. Verify Deployment

```bash
# On the VM:
cd /opt/ejbca-platform

# Check Docker containers
docker-compose -f docker/docker-compose.hybrid.yml ps

# Check logs
docker-compose -f docker/docker-compose.hybrid.yml logs ejbca

# View cloud-init status
tail -f /var/log/cloud-init-output.log
```

---

## 🔐 Access Services

### EJBCA Web UI

```bash
# Get VM public IP (if not using load balancer)
VM_IP=$(az vm show -d -g <resource-group> -n <vm-name> --query publicIps -o tsv)

# Access EJBCA
open https://${VM_IP}:8443/ejbca
```

### Grafana (Azure Managed)

```bash
# Get Grafana URL
terraform output grafana_endpoint

# Open in browser
open $(terraform output -raw grafana_endpoint)
```

### Application Insights

```bash
# Open Azure Portal
az portal

# Navigate to: Application Insights → <resource-group> → ejbca-pki-dev-appinsights
```

---

## 📊 Monitoring

### View Metrics in Grafana

1. Open Grafana: `$(terraform output -raw grafana_endpoint)`
2. Login with Azure AD
3. Navigate to Dashboards
4. View:
   - EJBCA Performance
   - Docker Container Metrics
   - PostgreSQL Metrics
   - VM Performance

### View Logs in App Insights

1. Azure Portal → Application Insights
2. Select your resource
3. Navigate to:
   - Logs (query logs)
   - Transaction search
   - Application map
   - Live metrics

### Query Prometheus

```bash
# Get Prometheus endpoint
PROM_ENDPOINT=$(terraform output -raw prometheus_endpoint)

# Query metrics (using curl)
curl -G "$PROM_ENDPOINT/api/v1/query" \
  --data-urlencode 'query=up' \
  --header "Authorization: Bearer $(az account get-access-token --resource https://prometheus.monitor.azure.com --query accessToken -o tsv)"
```

---

## 🛠️ Day-2 Operations

### Scale Up (Add VMs)

```bash
cd terraform
terraform apply -var="vm_count=5"
```

### Update EJBCA Image

```bash
# On VM:
cd /opt/ejbca-platform

# Pull new image
docker-compose -f docker/docker-compose.hybrid.yml pull ejbca

# Rolling update
docker-compose -f docker/docker-compose.hybrid.yml up -d --no-deps ejbca
```

### Backup

```bash
# Automatic backups to Azure Storage (daily at 2 AM)
# Manual backup:
docker-compose -f docker/docker-compose.hybrid.yml exec ejbca /opt/ejbca/bin/backup.sh
```

### Restore

```bash
# List backups
az storage blob list \
  --account-name <storage-account> \
  --container-name ejbca-backups

# Download backup
az storage blob download \
  --account-name <storage-account> \
  --container-name ejbca-backups \
  --name backup-2025-10-16.tar.gz \
  --file backup.tar.gz

# Restore
docker-compose -f docker/docker-compose.hybrid.yml exec ejbca /opt/ejbca/bin/restore.sh /mnt/backup.tar.gz
```

---

## 🧹 Cleanup

### Destroy Everything

```bash
cd terraform
terraform destroy
```

### Destroy Specific Environment

```bash
terraform destroy -var="environment=dev"
```

---

## 📚 Documentation

- [Cost Optimization Analysis](docs/COST-OPTIMIZATION-ANALYSIS.md)
- [Full Deployment Guide](DEPLOYMENT-GUIDE.md)
- [Operations Guide](docs/OPERATIONS-GUIDE.md)
- [EJBCA Features](docs/ejbca-features.md)

---

## ❓ Troubleshooting

### EJBCA not starting

```bash
# Check logs
docker-compose -f docker/docker-compose.hybrid.yml logs ejbca

# Check database connection
docker-compose -f docker/docker-compose.hybrid.yml exec ejbca nc -zv <postgres-host> 5432

# Restart
docker-compose -f docker/docker-compose.hybrid.yml restart ejbca
```

### Can't connect via Bastion

```bash
# Verify Bastion is running
az network bastion show \
  --name <bastion-name> \
  --resource-group <resource-group>

# Check VM is running
az vm get-instance-view \
  --ids <vm-id> \
  --query instanceView.statuses
```

### High costs

```bash
# Check resource usage
az consumption usage list \
  --start-date $(date -d "30 days ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query '[].{Service:name.value, Cost:pretaxCost}' \
  --output table

# Reduce costs:
# 1. Scale down VMs (D4s → D2s)
# 2. Use Basic PostgreSQL tier
# 3. Reduce backup retention
```

---

## 🎉 Success!

You now have a cost-optimized, production-ready PKI platform with:

- ✅ 69-78% cost savings vs. AKS
- ✅ Azure-managed services (less ops)
- ✅ Full EJBCA functionality
- ✅ Enterprise monitoring
- ✅ HSM-backed CA keys
- ✅ Automated backups

**Annual Savings**: $54,900/year

---

**Built by Adrian Johnson** | adrian207@gmail.com  
*Enterprise PKI & Cloud Infrastructure Specialist*

