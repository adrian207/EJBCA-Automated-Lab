# Repository Rulesets and Configuration

This directory contains comprehensive rulesets and configuration files to ensure code quality, security, and consistency across the EJBCA Automated Lab repository.

## 📋 Configuration Files

### Code Quality & Linting

- **`.yamllint.yml`** - YAML linting rules for Kubernetes, Ansible, Helm, and ArgoCD files
- **`.tflint.hcl`** - Terraform linting configuration with Azure-specific rules
- **`.shellcheckrc`** - Shell script linting configuration
- **`.markdownlint.yml`** - Markdown documentation linting rules
- **`.ansible-lint.yml`** - Ansible playbook linting configuration

### Pre-commit Hooks

- **`.pre-commit-config.yaml`** - Comprehensive pre-commit hooks configuration including:
  - General file checks (trailing whitespace, file size, etc.)
  - YAML/JSON validation
  - Terraform formatting and validation
  - Shell script linting
  - Security scanning with detect-secrets
  - Kubernetes manifest validation
  - Helm chart linting
  - Ansible linting
  - Dockerfile linting
  - Markdown linting
  - Python code formatting (if applicable)

### Editor Configuration

- **`.editorconfig`** - Cross-editor configuration for consistent formatting
- **`.gitignore`** - Comprehensive ignore patterns for various file types and tools

### Security

- **`.secrets.baseline`** - Baseline for detect-secrets to prevent credential leaks
- **`.github/ruleset.yml`** - GitHub repository rules for branch protection and PR requirements

## 🚀 Setup Instructions

### 1. Install Pre-commit Hooks

```bash
# Install pre-commit
pip install pre-commit

# Install the hooks
pre-commit install

# Run on all files (optional)
pre-commit run --all-files
```

### 2. Install Additional Tools (Optional)

```bash
# YAML linting
pip install yamllint

# Terraform linting
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Shell script linting
# On Ubuntu/Debian
sudo apt install shellcheck
# On macOS
brew install shellcheck

# Ansible linting
pip install ansible-lint

# Markdown linting
npm install -g markdownlint-cli
```

### 3. IDE Integration

Most modern IDEs will automatically pick up the `.editorconfig` file. For additional integration:

- **VS Code**: Install extensions for YAML, Terraform, Shell, and Markdown linting
- **IntelliJ/PyCharm**: Enable inspections for the respective file types
- **Vim/Neovim**: Configure plugins to use the linting tools

## 🔧 Customization

### Modifying Rules

Each configuration file can be customized based on your team's preferences:

1. **YAML**: Edit `.yamllint.yml` to adjust line length, indentation, or disable specific rules
2. **Terraform**: Modify `.tflint.hcl` to add/remove rules or change severity levels
3. **Shell**: Update `.shellcheckrc` to disable specific warnings or change output format
4. **Pre-commit**: Add/remove hooks in `.pre-commit-config.yaml`

### Adding New Rules

To add new linting rules:

1. Add the tool configuration file (e.g., `.eslintrc.js` for JavaScript)
2. Add the corresponding hook to `.pre-commit-config.yaml`
3. Update this README with the new configuration

## 📊 CI/CD Integration

These rulesets are designed to work with the existing GitHub Actions workflows:

- **`terraform-plan.yml`** - Uses `.tflint.hcl` for Terraform validation
- **`security-scan.yml`** - Uses `.secrets.baseline` for secret detection
- **`kubernetes-deploy.yml`** - Uses YAML linting for manifest validation

## 🛠️ Troubleshooting

### Common Issues

1. **Pre-commit hooks failing**: Check that all required tools are installed
2. **YAML linting errors**: Verify indentation and syntax in YAML files
3. **Terraform validation errors**: Run `terraform fmt` and `terraform validate`
4. **Shell script errors**: Use `shellcheck` to identify specific issues

### Getting Help

- Check the tool-specific documentation for detailed configuration options
- Review the GitHub Actions logs for CI/CD issues
- Consult the team's coding standards document

## 📝 Contributing

When adding new configuration files:

1. Follow the existing naming conventions
2. Include comprehensive comments explaining the rules
3. Update this README with the new configuration
4. Test the configuration with sample files
5. Ensure compatibility with existing CI/CD pipelines

## 🔄 Maintenance

These rulesets should be reviewed and updated periodically:

- **Monthly**: Check for tool updates and new features
- **Quarterly**: Review rule effectiveness and team feedback
- **Annually**: Major version updates and rule consolidation

---

For questions or issues with these rulesets, please create an issue in the repository or contact the platform team.
