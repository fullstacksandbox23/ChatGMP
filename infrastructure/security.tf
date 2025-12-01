resource "azurerm_user_assigned_identity" "chatGMPIdentity" {
  name                = "${var.project_name}-chatGMPIdentity-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location

  tags = {
    Costcenter  = var.costcenter
    Owner       = var.owner_name
    Environment = terraform.workspace
  }
}


resource "azurerm_key_vault" "keyVault" {
  name                        = "${var.project_short_name}-keyVault-${terraform.workspace}"
  location                    = azurerm_resource_group.resourceGroup.location
  resource_group_name         = azurerm_resource_group.resourceGroup.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 30
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.owner_object_id

    certificate_permissions = [
      "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
    ]

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Purge", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]

    storage_permissions = [
      "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
    ]
  }

    access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.second_owner_object_id

    certificate_permissions = [
      "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
    ]

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Purge", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]

    storage_permissions = [
      "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
    ]
  }

  # Allow the apps running terraform to write secrets from the vault for configuring the container apps:
  # - container on developer localhost:
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.developer_localhost_object_id

    certificate_permissions = [
      "Get", "Create", "Delete", "Update", "Purge"
    ]

    key_permissions = [
      "Get", "Create", "Delete", "Update", "Purge"
    ]

    secret_permissions = [
      "Get", "Set", "Delete", "Recover", "Purge"
    ]
  }

  # - github actions managed identity:
  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = var.managed_identity_github_actions_object_id

    certificate_permissions = [
      "Get", "Create", "Delete", "Update", "Purge"
    ]

    key_permissions = [
      "Get", "Create", "Delete", "Update", "Purge"
    ]

    secret_permissions = [
      "Get", "Set", "Delete", "Recover", "Purge"
    ]
  }

  access_policy {
    tenant_id = var.azure_tenant_id
    object_id = azurerm_user_assigned_identity.chatGMPIdentity.principal_id

    certificate_permissions = [
      "Get"
    ]

    key_permissions = [
      "Get"
    ]

    secret_permissions = [
      "Get"
    ]
  }

}
