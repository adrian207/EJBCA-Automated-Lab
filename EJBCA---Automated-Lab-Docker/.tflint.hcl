plugin "azurerm" {
  enabled = true
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "terraform" {
  enabled = true
  version = "0.2.2"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# Azure-specific rules
rule "azurerm_resource_missing_tags" {
  enabled = true
  tags = ["Environment", "Project", "Owner"]
}

rule "azurerm_resource_tag" {
  enabled = true
}

rule "azurerm_virtual_machine_os_disk" {
  enabled = true
}

rule "azurerm_virtual_machine_os_profile" {
  enabled = true
}
