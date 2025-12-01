
resource "azurerm_user_assigned_identity" "GithubActionsManagedIdentity" {
  name                = "${var.project_name}-githubActionsManagedIdentity-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location

  tags = {
    Costcenter  = var.costcenter
    Owner       = var.owner_name
    Environment = terraform.workspace
  }
}

resource "azurerm_role_assignment" "GithubActionsManagedIdentityRoleResourceGroup" {
  scope                = azurerm_resource_group.resourceGroup.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.GithubActionsManagedIdentity.principal_id
}

resource "azurerm_federated_identity_credential" "GithubActionsManagedIdentityFederatedCredential" {
  parent_id           = azurerm_user_assigned_identity.GithubActionsManagedIdentity.id
  name                = "${var.project_name}-githubActionsFederatedIdentityCredentials-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:fullstacksandbox23/reveal_dtu_learn:environment:${terraform.workspace}"
}



# {
#   identity_id = azurerm_user_assigned_identity.GithubActionsManagedIdentity.id
#   name        = "${var.project_name}-githubActionsManagedIdentityFederatedCredential-${terraform.workspace}"
#   resource_group_name = azurerm_resource_group.resourceGroup.name
#   audience    = "api://AzureADTokenExchange"
#   issuer      = "https://token.actions.githubusercontent.com"
#   subject     = "repo:${var.project_name}:branch:${terraform.workspace}"
# }

# Manual configurations - either in Azure Portal or with azure CLI:
# https://github.com/Azure/login
# https://learn.microsoft.com/da-dk/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp#create-a-user-assigned-managed-identity
# => find managed identity => Azure role assignment => add => resource group => Contributor
# az role assignment create \
#   --role "Contributor" \
#   --assignee <object_id_of_managed_identity> \
#   --scope /subscriptions/<subscription_id>
# https://learn.microsoft.com/da-dk/entra/workload-id/workload-identity-federation-create-trust-user-assigned-managed-identity?pivots=identity-wif-mi-methods-azp#github-actions-deploying-azure-resources
# => find managed identity => add federated credentials => repo settings => environment (dev, stage or prod) => Credential name: ${var.project_name}-githubActionsManagedIdentity-${terraform.workspace}
# in Github: add environment stage/prod with secrets for the managed identity: client_id, subscription_id, and tenant_id - NOTE: No secret needed!
# az identity federated-credential create \
#   --identity-name <identity_name> \
#   --name "<federated_credential_name" \
#   -g <resource_group_name> \
#   --audiences "api://AzureADTokenExchange" \
#   --issuer "https://token.actions.githubusercontent.com" \
#   --subject "repo:<repo_name>:branch:<branch_name>"

# # Giving up on this one - and doing it manually in the portal instead!
# resource "azurerm_role_assignment" "AssigningManagedIdentityAsResourceGroupContributor" {
#   description          = "Allow Github Actions to contribute to ${azurerm_resource_group.resourceGroup.name} in ${var.project_name} in ${terraform.workspace} environment"
#   scope                = azurerm_resource_group.resourceGroup.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.GithubActionsManagedIdentity.principal_id
# }

# # doesn't work in container level - but works in portal on resource group level.
# resource "azurerm_role_assignment" "AssigningManagedIdentityAsFrontendContributor" {
#   description          = "Allow Github Actions to update the frontend container app in ${var.project_name} in ${terraform.workspace} environment"
#   scope                = azurerm_container_app.FrontendContainer.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.GithubActionsManagedIdentity.principal_id
# }

# resource "azurerm_role_assignment" "AssigningManagedIdentityAsBackendContributor" {
#   description          = "Allow Github Actions to update the backend container app in ${var.project_name} in ${terraform.workspace} environment"
#   scope                = azurerm_container_app.BackendContainer.id
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.GithubActionsManagedIdentity.principal_id
# }