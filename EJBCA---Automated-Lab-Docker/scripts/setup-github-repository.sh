#!/bin/bash

# Comprehensive GitHub Repository Setup Script
# This script configures all aspects of the GitHub repository

set -e

echo "🚀 Setting up comprehensive GitHub repository configuration..."

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
DESCRIPTION="Enterprise PKI Platform with EJBCA CE - Automated Lab Environment demonstrating modern DevOps practices, cloud-native technologies, and enterprise security standards"

# Topics array
TOPICS=(
    "pki" "ejbca" "certificate-authority" "public-key-infrastructure"
    "kubernetes" "terraform" "ansible" "devops" "security"
    "azure" "aks" "helm" "argocd" "gitops" "infrastructure-as-code"
    "automation" "lab-environment" "enterprise-security"
    "certificate-management" "ssl-tls" "cryptography"
    "monitoring" "observability" "linkerd" "nginx"
    "harbor" "artifactory" "prometheus" "grafana"
    "loki" "tempo" "opentelemetry" "security-scanning"
    "vulnerability-management" "secrets-management"
    "key-management" "compliance" "enterprise-pki"
    "cloud-native" "microservices" "service-mesh"
    "container-registry" "ci-cd" "github-actions"
    "automated-deployment" "infrastructure-automation"
    "configuration-management" "security-automation"
    "certificate-lifecycle" "digital-certificates"
    "x509" "ca-hierarchy" "certificate-profiles"
    "keyfactor" "enterprise-grade" "production-ready"
    "scalable" "high-availability" "disaster-recovery"
    "backup-restore" "audit-logging" "compliance-reporting"
)

echo "📝 Updating repository description and topics..."

# Update repository description
gh api repos/$REPO \
  --method PATCH \
  --field description="$DESCRIPTION" \
  --field homepage="https://github.com/$REPO" \
  --field has_issues=true \
  --field has_projects=true \
  --field has_wiki=true \
  --field has_discussions=true \
  --field allow_squash_merge=true \
  --field allow_merge_commit=true \
  --field allow_rebase_merge=true \
  --field delete_branch_on_merge=true \
  --field allow_update_branch=true \
  --field use_squash_pr_title_as_default=true \
  --field web_commit_signoff_required=true \
  --field allow_forking=true

# Add topics
echo "🏷️ Adding repository topics..."
gh api repos/$REPO/topics \
  --method PUT \
  --field names="$(IFS=,; echo "${TOPICS[*]}")"

echo "🛡️ Setting up branch protection..."

# Set up branch protection for main branch
gh api repos/$REPO/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["branch-protection-check","terraform-validate","security-scanning","kubernetes-deploy","ansible-lint"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":2,"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"require_last_push_approval":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field required_linear_history=true \
  --field required_conversation_resolution=true \
  --field require_signed_commits=true \
  --field lock_branch=false \
  --field allow_fork_syncing=true

# Set up branch protection for develop branch
gh api repos/$REPO/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["branch-protection-check","terraform-validate","security-scanning"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"require_last_push_approval":false}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=true \
  --field required_linear_history=false \
  --field required_conversation_resolution=true \
  --field require_signed_commits=false \
  --field lock_branch=false \
  --field allow_fork_syncing=true

echo "🏷️ Creating repository labels..."

# Create labels
LABELS=(
    '{"name":"bug","description":"Something isn'\''t working","color":"d73a4a"}'
    '{"name":"documentation","description":"Improvements or additions to documentation","color":"0075ca"}'
    '{"name":"duplicate","description":"This issue or pull request already exists","color":"cfd3d7"}'
    '{"name":"enhancement","description":"New feature or request","color":"a2eeef"}'
    '{"name":"good first issue","description":"Good for newcomers","color":"7057ff"}'
    '{"name":"help wanted","description":"Extra attention is needed","color":"008672"}'
    '{"name":"invalid","description":"This doesn'\''t seem right","color":"e4e669"}'
    '{"name":"question","description":"Further information is requested","color":"d876e3"}'
    '{"name":"wontfix","description":"This will not be worked on","color":"ffffff"}'
    '{"name":"pki","description":"PKI related issues","color":"1d76db"}'
    '{"name":"ejbca","description":"EJBCA specific issues","color":"0e8a16"}'
    '{"name":"kubernetes","description":"Kubernetes related issues","color":"326ce5"}'
    '{"name":"terraform","description":"Terraform infrastructure issues","color":"7c3aed"}'
    '{"name":"security","description":"Security related issues","color":"b60205"}'
    '{"name":"devops","description":"DevOps process issues","color":"0e8a16"}'
    '{"name":"azure","description":"Azure cloud issues","color":"0078d4"}'
    '{"name":"monitoring","description":"Monitoring and observability","color":"f9d0c4"}'
    '{"name":"ci-cd","description":"CI/CD pipeline issues","color":"fbca04"}'
    '{"name":"priority: high","description":"High priority issue","color":"d73a4a"}'
    '{"name":"priority: medium","description":"Medium priority issue","color":"fbca04"}'
    '{"name":"priority: low","description":"Low priority issue","color":"0e8a16"}'
    '{"name":"status: needs-triage","description":"Issue needs triage","color":"f9d0c4"}'
    '{"name":"status: in-progress","description":"Work in progress","color":"fbca04"}'
    '{"name":"status: blocked","description":"Blocked by external dependency","color":"d73a4a"}'
    '{"name":"status: ready-for-review","description":"Ready for code review","color":"0e8a16"}'
)

for label in "${LABELS[@]}"; do
    gh api repos/$REPO/labels \
      --method POST \
      --field name="$(echo $label | jq -r '.name')" \
      --field description="$(echo $label | jq -r '.description')" \
      --field color="$(echo $label | jq -r '.color')" || true
done

echo "🔧 Enabling security features..."

# Enable security features
gh api repos/$REPO/vulnerability-alerts \
  --method PUT

gh api repos/$REPO/automated-security-fixes \
  --method PUT

echo "📊 Setting up repository insights..."

# Enable repository insights
gh api repos/$REPO/actions/permissions \
  --method PUT \
  --field enabled=true \
  --field allowed_actions="all"

echo "✅ GitHub repository setup completed successfully!"
echo ""
echo "📋 Configuration Summary:"
echo "  ✅ Repository description updated"
echo "  ✅ Topics added ($(echo "${TOPICS[@]}" | wc -w) topics)"
echo "  ✅ Branch protection enabled for main and develop"
echo "  ✅ Repository labels created"
echo "  ✅ Security features enabled"
echo "  ✅ Repository insights enabled"
echo ""
echo "🔗 Repository URL: https://github.com/$REPO"
echo "📊 Insights: https://github.com/$REPO/insights"
echo "🛡️ Security: https://github.com/$REPO/security"
echo ""
echo "🧪 Test the setup by:"
echo "  1. Creating a test issue"
echo "  2. Making a test pull request"
echo "  3. Verifying branch protection works"
