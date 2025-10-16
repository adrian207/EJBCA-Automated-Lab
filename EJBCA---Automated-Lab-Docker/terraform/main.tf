terraform {
  required_version = ">= 1.5.0" # Adjusted for compatibility

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "azurerm" {
    # Uncomment and configure for remote state
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "tfstateejbcapki"
    # container_name       = "tfstate"
    # key                  = "ejbca-platform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = var.environment == "dev" ? true : false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "prod" ? true : false
    }
  }
}

# Data source for current Azure client
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.azure_region

  tags = local.common_tags
}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local variables
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Purpose     = "PKI Platform"
      CreatedDate = timestamp()
    }
  )

  resource_suffix = var.use_random_suffix ? random_string.suffix.result : var.environment
}

