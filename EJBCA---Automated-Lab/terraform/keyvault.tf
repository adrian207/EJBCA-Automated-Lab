# Azure Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "${substr(var.project_name, 0, 15)}-${local.resource_suffix}-kv"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = var.keyvault_enabled_for_disk_encryption
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.keyvault_soft_delete_retention_days
  purge_protection_enabled    = var.environment == "prod" ? true : false
  sku_name                    = var.keyvault_sku

  # Network ACLs - SECURED
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"             # SECURED: Default deny, explicit allow
    ip_rules                   = ["73.140.169.168"] # SECURED: Your current IP
    virtual_network_subnet_ids = [azurerm_subnet.aks.id, azurerm_subnet.services.id]
  }

  # Enable RBAC authorization
  enable_rbac_authorization = true

  tags = local.common_tags
}

# Key Vault Access Policy for Current User (Terraform)
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Generate Root CA Key in Key Vault
resource "azurerm_key_vault_key" "root_ca" {
  name         = "ejbca-root-ca-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "sign",
    "verify"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P10Y"
    notify_before_expiry = "P45D"
  }

  tags = merge(
    local.common_tags,
    {
      Purpose = "Root CA Private Key"
      Usage   = "EJBCA"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Generate Sub CA Key in Key Vault
resource "azurerm_key_vault_key" "sub_ca" {
  name         = "ejbca-sub-ca-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "sign",
    "verify"
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P5Y"
    notify_before_expiry = "P45D"
  }

  tags = merge(
    local.common_tags,
    {
      Purpose = "Subordinate CA Private Key"
      Usage   = "EJBCA"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store PostgreSQL Admin Password
resource "random_password" "postgresql_admin" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "postgresql_admin_password" {
  name         = "postgresql-admin-password"
  value        = random_password.postgresql_admin.result
  key_vault_id = azurerm_key_vault.main.id

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store EJBCA Superadmin Password
resource "random_password" "ejbca_superadmin" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "ejbca_superadmin_password" {
  name         = "ejbca-superadmin-password"
  value        = random_password.ejbca_superadmin.result
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(
    local.common_tags,
    {
      Application = "EJBCA"
      Purpose     = "Superadmin Credentials"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store EJBCA Database Password
resource "random_password" "ejbca_db" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "ejbca_db_password" {
  name         = "ejbca-db-password"
  value        = random_password.ejbca_db.result
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(
    local.common_tags,
    {
      Application = "EJBCA"
      Purpose     = "Database Credentials"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store Harbor Admin Password
resource "random_password" "harbor_admin" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "harbor_admin_password" {
  name         = "harbor-admin-password"
  value        = random_password.harbor_admin.result
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(
    local.common_tags,
    {
      Application = "Harbor"
      Purpose     = "Admin Credentials"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store ArgoCD Admin Password
resource "random_password" "argocd_admin" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "argocd_admin_password" {
  name         = "argocd-admin-password"
  value        = random_password.argocd_admin.result
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(
    local.common_tags,
    {
      Application = "ArgoCD"
      Purpose     = "Admin Credentials"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Store Windows Admin Password
resource "random_password" "windows_admin" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*()"
}

resource "azurerm_key_vault_secret" "windows_admin_password" {
  name         = "windows-admin-password"
  value        = random_password.windows_admin.result
  key_vault_id = azurerm_key_vault.main.id

  tags = merge(
    local.common_tags,
    {
      Server  = "Windows Server 2025"
      Purpose = "Admin Credentials"
    }
  )

  depends_on = [azurerm_role_assignment.kv_admin]
}

# Certificate for TLS/SSL
resource "azurerm_key_vault_certificate" "wildcard" {
  name         = "wildcard-certificate"
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"]

      key_usage = [
        "digitalSignature",
        "keyEncipherment",
      ]

      subject            = "CN=*.${var.project_name}-${var.environment}.local"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          "*.${var.project_name}-${var.environment}.local",
          "${var.project_name}-${var.environment}.local",
          "*.ejbca.local",
          "ejbca.local"
        ]
      }
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_role_assignment.kv_admin]
}

