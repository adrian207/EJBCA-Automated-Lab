# EJBCA PKI Platform - Quick Start Guide

Welcome to the enterprise-grade PKI platform demonstrating Keyfactor EJBCA Community Edition with modern DevOps practices.

**Author**: Adrian Johnson | adrian207@gmail.com

## 🚀 Quick Deployment

### Prerequisites

Ensure you have the following installed:
- Azure CLI (`az`) - v2.50+
- Terraform - v1.6+
- kubectl - v1.28+
- Helm - v3.12+
- Ansible - v2.15+
- Docker - v24+

### Step 1: Configure Azure Credentials

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Export credentials for Terraform
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

### Step 2: Deploy Infrastructure

```bash
# Navigate to project directory
cd /Users/v-a.johnson/Documents/EJBCA---Automated-Lab

# Copy and customize Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your settings

# Deploy Azure infrastructure
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
cd ..
```

### Step 3: Deploy Platform (Automated)

```bash
# Run the automated deployment script
./scripts/deploy.sh
```

This script will:
- ✅ Configure kubectl with AKS credentials
- ✅ Install Linkerd service mesh
- ✅ Deploy NGINX Ingress Controller
- ✅ Deploy Prometheus, Grafana, Loki, Tempo, OpenTelemetry
- ✅ Deploy Harbor container registry
- ✅ Deploy JFrog Artifactory
- ✅ Deploy ArgoCD for GitOps
- ✅ Deploy EJBCA CE

### Step 4: Configure DNS

Add these entries to your `/etc/hosts` or configure DNS:

```
<INGRESS_IP>  ejbca.local
<INGRESS_IP>  argocd.local
<INGRESS_IP>  grafana.local
<INGRESS_IP>  prometheus.local
<INGRESS_IP>  harbor.local
<INGRESS_IP>  linkerd.local
<INGRESS_IP>  artifactory.local
```

Get the Ingress IP:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## 🎯 Access the Platform

### EJBCA CE
- **URL**: https://ejbca.local
- **Admin UI**: https://ejbca.local/ejbca/adminweb
- **Public Web**: https://ejbca.local/ejbca/publicweb
- **REST API**: https://ejbca.local/ejbca/ejbca-rest-api/v1
- **ACME**: https://ejbca.local/ejbca/.well-known/acme/directory

### ArgoCD
- **URL**: https://argocd.local
- **Username**: admin
- **Password**: 
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

### Grafana
- **URL**: https://grafana.local
- **Username**: admin
- **Password**: Retrieve from Key Vault or values file

### Prometheus
- **URL**: https://prometheus.local

### Harbor
- **URL**: https://harbor.local
- **Username**: admin
- **Password**: Harbor12345 (change this!)

### Linkerd Dashboard
```bash
linkerd viz dashboard
```

## 🧪 Test EJBCA Features

Run the comprehensive demo script:

```bash
./scripts/demo-scenarios.sh
```

This interactive script demonstrates:
1. **ACME Protocol** - Automated certificate management
2. **REST API** - Programmatic enrollment
3. **SCEP** - Device enrollment
4. **CMP** - Enterprise PKI protocol
5. **EST** - IoT enrollment
6. **OCSP** - Online status checking
7. **CRL** - Revocation lists
8. **Code Signing** - Software certificates
9. **Container Signing** - Image signing
10. **Certificate Transparency** - CT logs

Or run all demos automatically:
```bash
./scripts/demo-scenarios.sh --all
```

## 📊 Technology Stack Overview

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **PKI Core** | Keyfactor EJBCA CE | Certificate Authority |
| **Infrastructure** | Terraform + Azure | Cloud provisioning |
| **Orchestration** | Kubernetes (AKS) | Container platform |
| **Service Mesh** | Linkerd | mTLS & observability |
| **Ingress** | NGINX | Load balancing & routing |
| **GitOps** | ArgoCD | Declarative deployment |
| **CI/CD** | GitHub Actions | Automation pipelines |
| **Config Mgmt** | Ansible | OS configuration |
| **Registries** | Harbor + JFrog | Artifact storage |
| **Security Scan** | Trivy | Vulnerability scanning |
| **Metrics** | Prometheus | Time-series metrics |
| **Logs** | Loki | Log aggregation |
| **Traces** | Tempo | Distributed tracing |
| **Collector** | OpenTelemetry | Telemetry pipeline |
| **Dashboards** | Grafana | Visualization |
| **Secrets** | Azure Key Vault | HSM-backed keys |
| **Storage** | Azure Blob Storage | Persistent storage |
| **Compute VMs** | Windows 2025 + RHEL 9 | Integration testing |

## 🔐 Security Features

- **HSM Integration**: CA keys stored in Azure Key Vault (FIPS 140-2)
- **Service Mesh**: Linkerd provides automatic mTLS between services
- **Network Policies**: Kubernetes network segmentation
- **RBAC**: Fine-grained access control
- **Image Scanning**: Trivy scans all container images
- **Secret Management**: External secrets from Key Vault
- **Audit Logging**: Complete audit trail in Loki
- **Certificate Transparency**: Public CT log submission

## 📁 Project Structure

```
.
├── README.md                       # Main documentation
├── QUICKSTART.md                   # This file
├── terraform/                      # Infrastructure as Code
│   ├── main.tf
│   ├── aks.tf                      # Kubernetes cluster
│   ├── networking.tf               # VNet, subnets, NSGs
│   ├── keyvault.tf                 # Key Vault & secrets
│   ├── storage.tf                  # Storage & PostgreSQL
│   └── compute.tf                  # VMs (Windows & RHEL)
├── ansible/                        # Configuration Management
│   ├── playbooks/
│   │   ├── windows-server-2025.yml
│   │   └── rhel-latest.yml
│   └── inventory/
├── kubernetes/                     # K8s Manifests
│   ├── ejbca/
│   ├── observability/              # Prometheus, Loki, Tempo, OTel
│   ├── ingress-nginx/
│   ├── linkerd/
│   ├── harbor/
│   └── artifactory/
├── helm/                          # Helm Charts
│   └── ejbca-ce/
├── argocd/                        # GitOps Configs
│   ├── applications/
│   └── projects/
├── .github/workflows/             # CI/CD Pipelines
│   ├── terraform-plan.yml
│   ├── docker-build-scan.yml      # Trivy scanning
│   ├── kubernetes-deploy.yml
│   └── security-scan.yml
├── scripts/
│   ├── deploy.sh                  # Main deployment
│   └── demo-scenarios.sh          # Feature demos
├── configs/ejbca/
│   ├── certificate-profiles.json
│   └── ca-hierarchy.yaml
└── docs/
    ├── architecture.md
    └── ejbca-features.md          # Comprehensive guide
```

## 🎓 Learning Resources

### EJBCA Documentation
- [Official Docs](https://doc.primekey.com/ejbca)
- [REST API Reference](https://doc.primekey.com/ejbca/ejbca-operations/ejbca-rest-interface)
- [Protocol Configuration](https://doc.primekey.com/ejbca/ejbca-operations/ejbca-protocols)

### Demo Scenarios
See `docs/ejbca-features.md` for detailed explanation of:
- Certificate profiles (8 types)
- CA hierarchy (Root + 3 Subordinate CAs)
- All protocols (ACME, SCEP, CMP, EST, REST, WS)
- Certificate lifecycle management
- OCSP & CRL configuration
- Advanced features

## 🔧 Common Operations

### Scale EJBCA
```bash
kubectl scale deployment ejbca-ce -n ejbca --replicas=5
```

### View Logs
```bash
# EJBCA logs
kubectl logs -n ejbca -l app.kubernetes.io/name=ejbca-ce -f

# All logs in Loki
kubectl port-forward -n observability svc/loki-gateway 3100:80
```

### Backup Database
```bash
# PostgreSQL automated backups in Azure
az postgres flexible-server backup create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER
```

### Update Configuration
```bash
# Edit Helm values
vim helm/ejbca-ce/values.yaml

# Apply via ArgoCD
kubectl apply -f argocd/applications/ejbca-application.yaml

# Or directly
helm upgrade ejbca-ce ./helm/ejbca-ce -n ejbca
```

### Certificate Operations

```bash
# Issue certificate via REST API
curl -X POST https://ejbca.local/ejbca/ejbca-rest-api/v1/certificate/enroll \
  -H "Content-Type: application/json" \
  -d @certificate-request.json

# Check OCSP status
openssl ocsp -issuer ca.crt -cert server.crt \
  -url http://ejbca.local/ejbca/publicweb/status/ocsp

# Download CRL
curl https://ejbca.local/ejbca/publicweb/webdist/certdist?cmd=crl \
  -o ca.crl
```

## 🐛 Troubleshooting

### EJBCA Not Starting
```bash
# Check pod status
kubectl get pods -n ejbca

# View events
kubectl describe pod -n ejbca ejbca-ce-xxx

# Check database connectivity
kubectl exec -n ejbca ejbca-ce-xxx -- nc -zv postgresql 5432
```

### Certificates Not Issuing
```bash
# Check CA status
# Login to Admin UI → CA Functions → Certificate Authorities

# Check certificate profiles
# CA Functions → Certificate Profiles

# View audit log
kubectl logs -n ejbca -l app=ejbca-ce | grep AUDIT
```

### Monitoring Issues
```bash
# Check Prometheus targets
kubectl port-forward -n observability svc/prometheus-server 9090:80
# Visit http://localhost:9090/targets

# Verify Loki
kubectl port-forward -n observability svc/loki-gateway 3100:80
# Test: curl http://localhost:3100/ready
```

## 🔄 CI/CD Pipeline

The platform includes comprehensive GitHub Actions workflows:

### On Pull Request
- Terraform validation and plan
- Kubernetes manifest validation
- Security scanning (Trivy, tfsec, Checkov)
- Linting (ansible-lint, helm lint)

### On Push to Main
- Docker image build and scan
- Push to Harbor registry
- Deploy to Kubernetes
- Run integration tests

### Scheduled (Daily)
- Security scanning
- Dependency updates
- Certificate expiration checks

## 📞 Support

For issues or questions:
1. Check `docs/troubleshooting.md`
2. Review GitHub Issues
3. Consult EJBCA documentation
4. Check application logs in Grafana/Loki

## 📜 License

MIT License - See LICENSE file

---

**Status**: ✅ Production-Ready Demo Platform  
**Version**: 1.0.0  
**Last Updated**: October 2025

🎉 **Your enterprise PKI platform is ready!** Start with `./scripts/demo-scenarios.sh` to explore all features.

