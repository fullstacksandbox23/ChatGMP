resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = "${var.project_name}-logAnalytics-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku                 = "PerGB2018"
}

resource "azurerm_container_app_environment" "ContainerEnvironment" {
  name                       = "${var.project_name}-containers-${terraform.workspace}"
  location                   = azurerm_resource_group.resourceGroup.location
  resource_group_name        = azurerm_resource_group.resourceGroup.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logAnalytics.id

  tags = {
    Costcenter  = var.costcenter
    Owner       = var.owner_name
    Environment = terraform.workspace
  }
}

resource "azurerm_container_app_environment_storage" "applicationDataConnect" {
  name                         = "${var.project_short_name}-appdataconnect-${terraform.workspace}"
  container_app_environment_id = azurerm_container_app_environment.ContainerEnvironment.id
  account_name                 = azurerm_storage_account.storage.name
  access_key                   = azurerm_storage_account.storage.primary_access_key
  share_name                   = azurerm_storage_share.applicationData.name
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "ChatGMP" {
  name                         = "${var.project_short_name}-chatgmp-${terraform.workspace}"
  container_app_environment_id = azurerm_container_app_environment.ContainerEnvironment.id
  resource_group_name          = azurerm_resource_group.resourceGroup.name
  revision_mode = "Single"

  # Never change the image of the container, as this is done in github actions!
  # TBD: uncomment the lifecycle block, when the infrastructure is deployed and working!
  lifecycle {
    ignore_changes = [template[0].container[0]] # secret, revision_mode, ingress
  }

  template {
    container {
      name  = "chatgmp"
      image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      # Increase if the container side or CPU demands increase!
      cpu    = 0.75 # 0.25    # 0.5
      memory = "1.5Gi" #"0.5Gi" # "1Gi"
      volume_mounts {
        name = "${terraform.workspace}-application-data"
        path = "/data"
      }
    }
    volume {
      name         = "${terraform.workspace}-application-data"
      storage_name = azurerm_container_app_environment_storage.applicationDataConnect.name
      storage_type = "AzureFile"
    }
    min_replicas = terraform.workspace == "dev" || terraform.workspace == "stage" ? 0 : 1
    max_replicas = 10
  }

  ingress {
    target_port                = 80
    external_enabled           = true
    allow_insecure_connections = false # consider adding this
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  tags = {
    Costcenter  = var.costcenter
    Owner       = var.owner_name
    Environment = terraform.workspace
  }
}
