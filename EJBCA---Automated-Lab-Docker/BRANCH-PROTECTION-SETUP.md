# GitHub Branch Protection Setup Guide

## 🛡️ Manual Branch Protection Setup

Since GitHub repository rulesets are not available for your repository, follow these steps to manually configure branch protection:

### Step 1: Navigate to Branch Protection Settings
1. Go to: `https://github.com/adrian207/EJBCA---Automated-Lab/settings/branches`
2. Click **"Add rule"**

### Step 2: Configure Main Branch Protection
**Branch name pattern:** `main`

**Enable these options:**
- ✅ **Require a pull request before merging**
  - ✅ **Require approvals:** `2`
  - ✅ **Dismiss stale PR approvals when new commits are pushed**
  - ✅ **Require review from code owners**

- ✅ **Require status checks to pass before merging**
  - ✅ **Require branches to be up to date before merging**
  - **Status checks to require:**
    - `branch-protection-check`
    - `terraform-validate`
    - `security-scanning`
    - `kubernetes-deploy`
    - `ansible-lint`

- ✅ **Require conversation resolution before merging**
- ✅ **Require signed commits**
- ✅ **Require linear history**
- ✅ **Do not allow force pushes**
- ✅ **Do not allow deletions**

### Step 3: Create CODEOWNERS File
Create a `.github/CODEOWNERS` file to define who can approve changes:

```
# Global owners
* @adrian207

# Terraform files require additional review
/terraform/ @adrian207

# Security-sensitive files
**/*secret* @adrian207
**/*key* @adrian207
**/*password* @adrian207
**/*credential* @adrian207

# Documentation
/docs/ @adrian207
*.md @adrian207
```

### Step 4: Test the Protection
After enabling branch protection:
1. Try to push directly to main - it should be blocked
2. Create a pull request instead
3. Verify that status checks are required

## 🔧 Alternative: Use GitHub CLI

If you have GitHub CLI installed, you can use this command:

```bash
gh api repos/adrian207/EJBCA---Automated-Lab/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["branch-protection-check","terraform-validate","security-scanning","kubernetes-deploy","ansible-lint"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":2,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  --field restrictions=null
```

## 📋 Status Check Requirements

Make sure these GitHub Actions workflows are enabled:
- `branch-protection-check` ✅ (Already created)
- `terraform-validate` ✅ (Already exists)
- `security-scanning` ✅ (Already exists)
- `kubernetes-deploy` ✅ (Already exists)
- `ansible-lint` ✅ (Already exists)

## 🚨 Troubleshooting

**If status checks don't appear:**
1. Make sure the GitHub Actions workflows are enabled
2. Run the workflows manually to generate status check names
3. Check that workflows are in `.github/workflows/` directory

**If CODEOWNERS doesn't work:**
1. Make sure the file is in `.github/CODEOWNERS`
2. Verify the usernames are correct
3. Check that users have write access to the repository
