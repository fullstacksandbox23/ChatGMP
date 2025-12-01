resource "azurerm_storage_account" "storage" {
  name                             = "${var.project_short_name}storage${terraform.workspace}"
  resource_group_name              = azurerm_resource_group.resourceGroup.name
  location                         = azurerm_resource_group.resourceGroup.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  cross_tenant_replication_enabled = false

  tags = {
    Costcenter  = var.costcenter
    Owner       = var.owner_name
    Environment = terraform.workspace
  }
}


resource "azurerm_storage_share" "applicationData" {
  name               = "${var.project_short_name}-applicationdata-${terraform.workspace}"
  storage_account_id = azurerm_storage_account.storage.id
  quota              = 50 #TBD: increase for production and keep an eye on cost!
}

# Backup:
resource "azurerm_recovery_services_vault" "recoveryServiceVault" {
  name                          = "${var.project_name}-recoveryServiceVault-${terraform.workspace}"
  resource_group_name           = azurerm_resource_group.resourceGroup.name
  location                      = azurerm_resource_group.resourceGroup.location
  sku                           = "Standard"
  storage_mode_type             = "LocallyRedundant"
  immutability                  = "Disabled"
  public_network_access_enabled = true
  soft_delete_enabled           = true


  tags = {
    Costcenter  = var.costcenter
    Owner       = var.owner_name
    Environment = terraform.workspace
  }
}

resource "azurerm_backup_container_storage_account" "backupContainer" {
  resource_group_name = azurerm_resource_group.resourceGroup.name
  recovery_vault_name = azurerm_recovery_services_vault.recoveryServiceVault.name
  storage_account_id  = azurerm_storage_account.storage.id
}

resource "azurerm_backup_policy_file_share" "backupDataPolicy" {
  name                = "${var.project_name}-backupDataPolicy-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  recovery_vault_name = azurerm_recovery_services_vault.recoveryServiceVault.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "04:00"
  }

  retention_daily {
    # 14 weeks:
    count = 98
  }

  # retention_monthly {
  #   count = 12
  #   weekdays = ["Sunday"]
  #   weeks = ["Last"]
  # }

  # retention_yearly {
  #   count = 6
  #   months = ["December"]
  #   days = [31]
  # }
}


resource "azurerm_backup_protected_file_share" "enableApplicationDataBackup" {
  resource_group_name       = azurerm_resource_group.resourceGroup.name
  recovery_vault_name       = azurerm_recovery_services_vault.recoveryServiceVault.name
  source_storage_account_id = azurerm_backup_container_storage_account.backupContainer.storage_account_id
  source_file_share_name    = azurerm_storage_share.applicationData.name
  backup_policy_id          = azurerm_backup_policy_file_share.backupDataPolicy.id
}

