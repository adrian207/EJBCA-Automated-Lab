# Enterprise PKI Platform - EJBCA CE Automated Lab

**Version:** 1.0.0 | **Release Date:** 2025-10-26 | **Status:** 🟢 Stable

[![Build Status](https://github.com/adrian207/EJBCA---Automated-Lab/workflows/Terraform%20Plan/badge.svg)](https://github.com/adrian207/EJBCA---Automated-Lab/actions)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/adrian207/EJBCA---Automated-Lab/releases)
[![Release Date](https://img.shields.io/badge/release-2025--10--26-blue.svg)](https://github.com/adrian207/EJBCA---Automated-Lab/releases)
[![Security Scan](https://github.com/adrian207/EJBCA---Automated-Lab/workflows/Security%20Scanning/badge.svg)](https://github.com/adrian207/EJBCA---Automated-Lab/actions)
[![Kubernetes Deploy](https://github.com/adrian207/EJBCA---Automated-Lab/workflows/Kubernetes%20Deployment/badge.svg)](https://github.com/adrian207/EJBCA---Automated-Lab/actions)
[![Branch Protection](https://github.com/adrian207/EJBCA---Automated-Lab/workflows/Branch%20Protection%20Check/badge.svg)](https://github.com/adrian207/EJBCA---Automated-Lab/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/terraform-v1.6+-blue.svg)](https://terraform.io/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-v1.28+-blue.svg)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/docker-v24+-blue.svg)](https://docker.com/)
[![Azure](https://img.shields.io/badge/azure-cloud-blue.svg)](https://azure.microsoft.com/)

**🏢 Enterprise-Grade PKI Platform with Modern DevOps Practices**

A comprehensive PKI (Public Key Infrastructure) platform demonstrating Keyfactor EJBCA Community Edition with cloud-native technologies, enterprise security standards, and automated deployment pipelines.

## 👤 Author

**Adrian Johnson**  
📧 Email: adrian207@gmail.com  
💼 Enterprise PKI & Cloud Infrastructure Specialist  
🔗 LinkedIn: [Adrian Johnson](https://linkedin.com/in/adrian-johnson)  
🐦 Twitter: [@adrian207](https://twitter.com/adrian207)

---

## 🏗️ Architecture Overview

This platform demonstrates a production-ready PKI infrastructure with:

### Core Components
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

### 🎯 Key Features

- ✅ **Enterprise PKI**: Full EJBCA CE functionality with CA hierarchy
- ✅ **Cloud-Native**: Kubernetes orchestration with Helm charts
- ✅ **GitOps**: ArgoCD for declarative deployments
- ✅ **Security First**: Comprehensive security scanning and compliance
- ✅ **Observability**: Full monitoring stack with Prometheus, Grafana, Loki
- ✅ **Infrastructure as Code**: Terraform for Azure resource management
- ✅ **Configuration Management**: Ansible for OS provisioning
- ✅ **CI/CD**: Automated testing, security scanning, and deployment
- ✅ **High Availability**: Multi-node Kubernetes cluster
- ✅ **Disaster Recovery**: Backup and restore procedures

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
git clone https://github.com/adrian207/EJBCA---Automated-Lab.git
cd EJBCA---Automated-Lab

# 2. Configure Azure credentials
az login
export ARM_SUBSCRIPTION_ID="your-subscription-id"

# 3. Deploy infrastructure
cd EJBCA---Automated-Lab-Docker/terraform
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
EJBCA---Automated-Lab-Docker/
├── 📁 ansible/                    # Ansible playbooks for OS provisioning
├── 📁 argocd/                     # ArgoCD applications and configurations
├── 📁 configs/                    # EJBCA configuration files
├── 📁 docker/                     # Docker Compose configurations
├── 📁 docs/                       # Comprehensive documentation
├── 📁 helm/                       # Helm charts for EJBCA
├── 📁 kubernetes/                 # Kubernetes manifests and configurations
├── 📁 scripts/                    # Deployment and utility scripts
├── 📁 terraform/                  # Infrastructure as Code
├── 📁 .github/                    # GitHub Actions workflows and templates
├── 📄 README.md                   # This file
├── 📄 QUICKSTART.md               # Quick start guide
├── 📄 IMPLEMENTATION-GUIDE.md     # Detailed implementation guide
└── 📄 RULESETS-README.md          # Repository rulesets documentation
```

## 🔧 Deployment Options

### 1. **Kubernetes/AKS** (Recommended for Production)
- Full cloud-native deployment
- High availability and scalability
- Complete observability stack
- GitOps with ArgoCD

### 2. **Docker Compose** (Cost-Optimized)
- 60-78% cost savings vs AKS
- Single-node deployment
- Perfect for development and testing
- Azure VM-based architecture

### 3. **Hybrid Deployment**
- Mix of cloud and on-premises
- Flexible architecture options
- Cost optimization strategies

## 📊 Monitoring & Observability

### Metrics & Monitoring
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alerting and notifications

### Logging
- **Loki**: Log aggregation and storage
- **Fluent Bit**: Log collection and forwarding

### Tracing
- **OpenTelemetry**: Distributed tracing
- **Tempo**: Trace storage and querying

## 🔒 Security Features

- **Secret Management**: Azure Key Vault integration
- **Vulnerability Scanning**: Trivy for container images
- **Security Policies**: OPA Gatekeeper for Kubernetes
- **Network Security**: Network policies and service mesh
- **Compliance**: SOC 2, ISO 27001 alignment

## 📚 Documentation

- **[Architecture Design](docs/ARCHITECTURE-DESIGN.md)**: Detailed system architecture
- **[API Integration Guide](docs/API-INTEGRATION-GUIDE.md)**: EJBCA API usage
- **[Deployment Guide](docs/DEPLOYMENT-OPERATIONS-GUIDE.md)**: Operational procedures
- **[Security Guide](docs/SECURITY-FIXES-CHECKLIST.md)**: Security best practices
- **[Troubleshooting](docs/TROUBLESHOOTING-GUIDE.md)**: Common issues and solutions
- **[System Requirements](docs/SYSTEM-REQUIREMENTS-SIZING.md)**: Resource requirements

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

### Code Quality
- Pre-commit hooks for code quality
- Comprehensive linting rules
- Security scanning
- Automated testing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/adrian207/EJBCA---Automated-Lab/issues)
- **Discussions**: [GitHub Discussions](https://github.com/adrian207/EJBCA---Automated-Lab/discussions)
- **Email**: adrian207@gmail.com

## 🙏 Acknowledgments

- Keyfactor for EJBCA Community Edition
- The Kubernetes community
- Azure team for cloud services
- Open source contributors

---

**⭐ Star this repository if you find it helpful!**

[![GitHub stars](https://img.shields.io/github/stars/adrian207/EJBCA---Automated-Lab?style=social)](https://github.com/adrian207/EJBCA---Automated-Lab/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/adrian207/EJBCA---Automated-Lab?style=social)](https://github.com/adrian207/EJBCA---Automated-Lab/network)
[![GitHub watchers](https://img.shields.io/github/watchers/adrian207/EJBCA---Automated-Lab?style=social)](https://github.com/adrian207/EJBCA---Automated-Lab/watchers)
