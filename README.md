# Enterprise PKI Platform - EJBCA CE Automated Lab

A professional-grade PKI (Public Key Infrastructure) platform demonstrating Keyfactor EJBCA Community Edition with modern DevOps practices, cloud-native technologies, and enterprise security standards.

## 🏗️ Architecture Overview

This platform demonstrates a production-ready PKI infrastructure with:

- **PKI Core**: Keyfactor EJBCA CE (Certificate Authority)
- **Infrastructure**: Terraform-managed Azure resources (AKS, Key Vault, Storage)
- **Orchestration**: Kubernetes with Helm charts
- **Service Mesh**: Linkerd for secure service-to-service communication
- **Ingress**: NGINX Ingress Controller
- **GitOps**: ArgoCD for declarative deployments
- **CI/CD**: GitHub Actions with security scanning
- **Configuration Management**: Ansible for OS provisioning
- **Artifact Management**: Harbor Registry & JFrog Artifactory
- **Security Scanning**: Trivy for vulnerability detection
- **Observability**: Loki for logs, OpenTelemetry for traces
- **Cloud Integration**: Azure Key Vault & Storage

## 📋 Prerequisites

- Azure subscription with appropriate permissions
- kubectl (v1.28+)
- Terraform (v1.6+)
- Ansible (v2.15+)
- Helm (v3.12+)
- Docker (v24+)
- Azure CLI (v2.50+)
- Git

## 🚀 Quick Start

```bash
# 1. Clone and initialize
git clone <repository-url>
cd EJBCA---Automated-Lab

# 2. Configure Azure credentials
az login
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# 3. Deploy infrastructure
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 4. Configure kubectl
az aks get-credentials --resource-group ejbca-platform-rg --name ejbca-aks-cluster

# 5. Deploy platform components
cd ../kubernetes
./deploy.sh

# 6. Access EJBCA
kubectl get ingress -n ejbca
```

## 📁 Project Structure

```
.
├── README.md                                    # This file
└── EJBCA---Automated-Lab/                      # Main project directory
    ├── docs/                                   # Comprehensive documentation
    │   ├── ANALYSIS-REPORT.md
    │   ├── BASTION-SETUP-GUIDE.md
    │   ├── DYNAMIC-IP-SOLUTIONS.md
    │   ├── SECURITY-FIXES-CHECKLIST.md
    │   └── ejbca-features.md
    ├── terraform/                              # Infrastructure as Code
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── aks.tf
    │   ├── networking.tf
    │   ├── keyvault.tf
    │   ├── storage.tf
    │   └── compute.tf
    ├── ansible/                                # Configuration Management
    │   ├── playbooks/
    │   │   ├── windows-server-2025.yml
    │   │   ├── rhel-latest.yml
    │   │   └── common-setup.yml
    │   └── inventory/
    ├── kubernetes/                             # K8s Manifests
    │   ├── observability/
    │   ├── ingress-nginx/
    │   ├── linkerd/
    │   ├── harbor/
    │   └── artifactory/
    ├── helm/                                   # Helm Charts
    │   └── ejbca-ce/
    ├── argocd/                                 # GitOps Configurations
    │   ├── applications/
    │   └── projects/
    ├── .github/                                # CI/CD Pipelines
    │   └── workflows/
    ├── scripts/                                # Utility Scripts
    │   ├── deploy.sh
    │   ├── demo-scenarios.sh
    │   ├── apply-security-fixes.sh
    │   └── update-my-ip.sh
    └── configs/                                # Application Configs
        └── ejbca/
```

## 🎯 EJBCA CE Features Demonstrated

### 1. **Certificate Authority Management**
- Root CA and Sub CA hierarchy
- Multiple certificate profiles
- End entity profiles
- Certificate issuance workflows

### 2. **Protocol Support**
- ACME (Automated Certificate Management Environment)
- EST (Enrollment over Secure Transport)
- SCEP (Simple Certificate Enrollment Protocol)
- CMP (Certificate Management Protocol)
- Web Services API (SOAP/REST)

### 3. **Certificate Lifecycle**
- Issuance and enrollment
- Renewal and revocation
- CRL (Certificate Revocation List) generation
- OCSP (Online Certificate Status Protocol) responder

### 4. **Advanced Features**
- HSM integration (Azure Key Vault)
- Certificate transparency logging
- Custom certificate extensions
- Publisher for certificate distribution
- Key recovery and archival

### 5. **Administration**
- Role-based access control (RBAC)
- Audit logging
- Administrator approval workflows
- Backup and restore procedures

## 🔒 Security Features

- **Network Security**: Linkerd mTLS between services
- **Secret Management**: Azure Key Vault integration
- **Image Scanning**: Trivy in CI/CD pipeline
- **Ingress Security**: TLS termination with NGINX
- **RBAC**: Kubernetes RBAC and EJBCA role-based access

## 📊 Observability

- **Logging**: Loki for centralized log aggregation
- **Tracing**: OpenTelemetry for distributed tracing
- **Metrics**: Prometheus metrics exposure
- **Dashboards**: Grafana for visualization

## 🔄 GitOps Workflow

1. Code changes pushed to GitHub
2. GitHub Actions validates and tests
3. Trivy scans for vulnerabilities
4. Artifacts published to Harbor/Artifactory
5. ArgoCD detects changes and syncs
6. Kubernetes applies configurations

## 🛠️ Deployment Scenarios

### Development
- Single node with minimal resources
- In-cluster databases
- Development certificates

### Staging
- Multi-node cluster
- External managed databases
- Valid staging certificates

### Production
- High-availability configuration
- Azure-managed services (Database, Key Vault)
- Production-grade certificates
- Disaster recovery setup

## 📖 Documentation

- [QUICKSTART Guide](EJBCA---Automated-Lab/QUICKSTART.md) - Fast track deployment
- [EJBCA Features Guide](EJBCA---Automated-Lab/docs/ejbca-features.md) - Complete feature demos
- [Security Analysis Report](EJBCA---Automated-Lab/docs/ANALYSIS-REPORT.md) - Performance & security analysis
- [Implementation Guide](EJBCA---Automated-Lab/IMPLEMENTATION-GUIDE.md) - Detailed setup steps
- [Azure Bastion Setup](EJBCA---Automated-Lab/docs/BASTION-SETUP-GUIDE.md) - Secure VM access
- [Dynamic IP Solutions](EJBCA---Automated-Lab/docs/DYNAMIC-IP-SOLUTIONS.md) - IP management options
- [Security Fixes Checklist](EJBCA---Automated-Lab/docs/SECURITY-FIXES-CHECKLIST.md) - Security improvements

## 👤 Author

**Adrian Johnson**  
📧 Email: adrian207@gmail.com  
💼 Enterprise PKI & Cloud Infrastructure Specialist

## 🤝 Contributing

This is a demonstration lab environment. Feel free to adapt and extend for your use case.

## 📝 License

MIT License - See LICENSE file for details

## 🔗 References

- [Keyfactor EJBCA CE Documentation](https://doc.primekey.com/ejbca)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Linkerd Documentation](https://linkerd.io/docs/)

## ⚠️ Important Notes

- This is a lab/demo environment - adapt security settings for production
- Review all default passwords and credentials before deployment
- Ensure compliance with your organization's security policies
- Back up CA keys and certificates securely

---

**Status**: 🚧 Active Development | **Version**: 1.0.0 | **Last Updated**: October 2025

