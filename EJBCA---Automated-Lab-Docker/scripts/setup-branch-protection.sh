#!/bin/bash

# GitHub Branch Protection Setup Script
# This script sets up branch protection for the main branch

echo "🛡️ Setting up GitHub branch protection for main branch..."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    echo "Or follow the manual setup guide in BRANCH-PROTECTION-SETUP.md"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"

# Set up branch protection for main branch
echo "🔧 Configuring branch protection rules..."

gh api repos/adrian207/EJBCA---Automated-Lab/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["branch-protection-check","terraform-validate","security-scanning","kubernetes-deploy","ansible-lint"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":2,"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"require_last_push_approval":true}' \
  --field restrictions=null \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false

if [ $? -eq 0 ]; then
    echo "✅ Branch protection successfully configured!"
    echo ""
    echo "📋 Protection rules enabled:"
    echo "  - Requires pull request before merging"
    echo "  - Requires 2 approvals"
    echo "  - Requires status checks to pass"
    echo "  - Requires code owner reviews"
    echo "  - Requires linear history"
    echo "  - Blocks force pushes and deletions"
    echo ""
    echo "🧪 Test the protection by trying to push directly to main"
else
    echo "❌ Failed to configure branch protection"
    echo "Please check your permissions and try the manual setup"
fi
