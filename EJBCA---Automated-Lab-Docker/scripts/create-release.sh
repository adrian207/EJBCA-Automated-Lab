#!/bin/bash

# GitHub Release Script
# This script creates a new release on GitHub with version information

set -e

VERSION="1.0.0"
RELEASE_DATE="2025-10-26"
REPO="adrian207/EJBCA---Automated-Lab"

echo "🚀 Creating GitHub release v${VERSION}..."

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

# Create release notes
RELEASE_NOTES=$(cat <<EOF
# Release v${VERSION} - Initial Release

**Release Date:** ${RELEASE_DATE}
**Status:** 🟢 Stable

## 🎉 Initial Release

First stable release with complete PKI platform implementation.

## ✨ Features

- **Enterprise PKI Platform**: Full EJBCA CE implementation with CA hierarchy
- **Kubernetes Orchestration**: Complete K8s deployment with Helm charts
- **Infrastructure Automation**: Terraform-managed Azure resources
- **Configuration Management**: Ansible playbooks for OS provisioning
- **GitOps Workflows**: ArgoCD for declarative deployments
- **Monitoring并且 Observability**: Full stack with Prometheus, Grafana, Loki
- **Security**: Comprehensive scanning and compliance checks
- **CI/CD**: GitHub Actions with automated testing and validation

## 📚 Documentation

- Complete architecture design documentation
- API integration guides
- Deployment and operations guides
- Troubleshooting guides
- Security best practices
- System requirements and sizing

## 🛠️ Tools & Technologies

- **EJBCA**: Community Edition (CE) 8.3.0
- **Kubernetes**: v1.28.0+
- **Terraform**: v1.6.0+
- **Ansible**: v2.15.0+
- **Helm**: v3.13.0+
- **Docker**: v24.0.0+
- **Linkerd**: stable-2.14
- **Prometheus/Grafana**: Latest stable
- **ArgoCD**: Latest stable

## 📊 Repository

- Professional README with badges
- Issue templates (bug, feature, documentation)
- Pull request templates
- Code quality rules和金
- 20 comprehensive topics
- Complete metadata

## 📄 License

MIT License

---

## 🔗 Links

- **Documentation**: https://github.com/${REPO}/blob/main/docs/README.md
- **Issues**: https://github.com/${REPO}/issues
- **Releases**: https://github.com/${REPO}/releases

## 👥 Contributors

- **Adrian Johnson**: Lead Developer (adrian207@gmail.com)
EOF
)

# Create the release
gh release create "v${VERSION}" \
  --title "v${VERSION} - Initial Release" \
  --notes "$RELEASE_NOTES" \
  --latest

if [ $? -eq 0 ]; then
    echo "✅ Successfully created release v${VERSION}!"
    echo ""
    echo "🔗 Release URL: https://github.com/${REPO}/releases/tag/v${VERSION}"
else
    echo "❌ Failed to create release"
    echo "The release might already exist. Use: gh release view v${VERSION}"
fi
