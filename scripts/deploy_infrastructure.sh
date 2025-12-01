#!/bin/bash

# USE: ./scripts/deploy_infrastructure.sh

# This script is used to deploy the infrastructure from localhost using an OpenTofu container.

# It requires authentication to Azure via a service principle.
# Create the service principle via Azure CLI:
# az ad sp create-for-rbac --name "<name-of-service-principle>" --role="Contributor" --scopes="/subscriptions/<subscription-id>"
# (Note: it needs access to the whole subscription, so the infrastructure can be create in resource groups)
# Also needs "Storage Blob Data Contributor" role assignment to the service principle:
# https://stackoverflow.com/questions/52769758/azure-blob-storage-authorization-permission-mismatch-error-for-get-request-wit
# https://learn.microsoft.com/en-us/azure/storage/blobs/authorize-access-azure-active-directory
# az role assignment create \
#   --role "Storage Blob Data Contributor"
#   --assignee <object_id_of_app*>
#   --scope /subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Storage/storageAccounts/<storage_account_name>/blobServices/default/containers/<container_name>
# * object_id_of_app is not the allplication id.

# create the workspaces manually:
# ./scripts/start_infrastructure.sh # to get into the container
# cp -fR .azure/ ~/.azure
# tofu init \
#         -backend-config="resource_group_name=${AZ_RESOURCE_GROUP_NAME}" \
#         -backend-config="storage_account_name=${AZ_STORAGE_ACCOUNT_NAME}" \
#         -backend-config="container_name=${AZ_CONTAINER_NAME}" \
#         -backend-config="key=${AZ_BACKEND_STATE_KEY}" \
#         -var "azure_tenant_id=${AZURE_TENANT_ID}" \
#         -var "azure_client_id=${AZURE_CLIENT_ID}" \
#         -var "azure_subscription_id=${AZURE_SUBSCRIPTION_ID}"
# tofu workspace new dev
# tofu workspace new stage
# tofu workspace new prod
# tofu init \
#         -backend-config="resource_group_name=${AZ_RESOURCE_GROUP_NAME}" \
#         -backend-config="storage_account_name=${AZ_STORAGE_ACCOUNT_NAME}" \
#         -backend-config="container_name=${AZ_CONTAINER_NAME}" \
#         -backend-config="key=${AZ_BACKEND_STATE_KEY}" \
#         -var "azure_tenant_id=${AZURE_TENANT_ID}" \
#         -var "azure_client_id=${AZURE_CLIENT_ID}" \
#         -var "azure_subscription_id=${AZURE_SUBSCRIPTION_ID}" \
#         -reconfigure

echo "=== Running: deploy_infrastructure ==="

# Initialization:
REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
BRANCH_NAME=$(git branch --show-current)
cd $REPO_ROOT_DIR/infrastructure

echo ""
echo "=== set workspace ==="
if [ "$BRANCH_NAME" == "dev" ]; then
    WORKSPACE=dev
elif [ "$BRANCH_NAME" == "stage" ]; then
    WORKSPACE=stage
elif [ "$BRANCH_NAME" == "main" ]; then
    WORKSPACE=prod
else
    echo "Branch name not recognized"
    exit 1
fi
echo "==> workspace is set to: $WORKSPACE <=="


echo ""
echo "=== use Azure login information from host in container ==="
{
    # try
    az account show --output none
} ||
{
    # catch
    az login --tenant $(grep AZURE_TENANT_ID .env | cut -d '=' -f 2 | tr -d ' "')
    
}
az account set --subscription $(grep AZURE_SUBSCRIPTION_ID .env | cut -d '=' -f 2 | tr -d ' "')
az account get-access-token --resource https://management.azure.com/ --output json > .azure/azure_token.json
cp -fR ~/.azure/* .azure/

echo ""
echo "=== building the tofu container ==="
docker compose build

echo ""
echo "=== tofu - version ==="
docker compose run --rm tofu --version

echo ""
echo "=== tofu - init ==="
docker compose run --rm --entrypoint '/bin/sh -c' tofu 'cp -fR .azure/ ~/.azure &&
tofu init \
        -backend-config="resource_group_name=${AZ_RESOURCE_GROUP_NAME}" \
        -backend-config="storage_account_name=${AZ_STORAGE_ACCOUNT_NAME}" \
        -backend-config="container_name=${AZ_CONTAINER_NAME}" \
        -backend-config="key=${AZ_BACKEND_STATE_KEY}" \
        -var "azure_tenant_id=${AZURE_TENANT_ID}" \
        -var "azure_client_id=${AZURE_CLIENT_ID}" \
        -var "azure_subscription_id=${AZURE_SUBSCRIPTION_ID}"'

echo ""
echo "=== tofu - workspace select ==="
docker compose run --rm -e "WORKSPACE=${WORKSPACE}" --entrypoint '/bin/sh -c' tofu 'cp -fR .azure/ ~/.azure &&
tofu workspace select -or-create \
        -var "azure_tenant_id=${AZURE_TENANT_ID}" \
        -var "azure_client_id=${AZURE_CLIENT_ID}" \
        -var "azure_subscription_id=${AZURE_SUBSCRIPTION_ID}" \
        ${WORKSPACE}'
echo "selected workspace:"
docker compose run --rm tofu workspace show

echo ""
echo "=== tofu - plan ==="
set +e
docker compose run --rm -e "WORKSPACE=${WORKSPACE}" --entrypoint '/bin/sh -c' tofu 'cp -fR .azure/ ~/.azure &&
ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET &&
tofu plan -out=${WORKSPACE}.tfplan \
        -detailed-exitcode \
        -var "azure_tenant_id=${AZURE_TENANT_ID}" \
        -var "azure_client_id=${AZURE_CLIENT_ID}" \
        -var "azure_subscription_id=${AZURE_SUBSCRIPTION_ID}" \
        -var "developer_localhost_object_id=${DEVELOPER_LOCALHOST_OBJECT_ID}" \
        -var "managed_identity_github_actions_object_id=${MANAGED_IDENTITY_GITHUB_ACTIONS_OBJECT_ID}" \
        -var "project_name=${PROJECT_NAME}" \
        -var "project_short_name=${PROJECT_SHORT_NAME}" \
        -var "costcenter=${COSTCENTER}" \
        -var "owner_name=${OWNER_NAME}" \
        -var "second_owner_name=${SECOND_OWNER_NAME}" \
        -var "budget_notification_email=${BUDGET_NOTIFICATION_EMAIL}" \
        -var "owner_object_id=${OWNER_OBJECT_ID}" \
        -var "second_owner_object_id=${SECOND_OWNER_OBJECT_ID}"'
# Comes from ARM_ environment variable, as it is not needed with managed identity in the Github Actions workflow:
# -var "azure_client_secret=${AZURE_CLIENT_SECRET}" \
tofu_plan_exit_code=$?
set -e
echo "tofu_plan_exit_code: $tofu_plan_exit_code"
if [ $tofu_plan_exit_code == 1 ]; then
    echo "=== tofu - plan failed ==="
    tofu_changes_applied=1
elif [ $tofu_plan_exit_code == 0 ]; then
    echo "=== tofu - no changes ==="
    tofu_changes_applied=0
elif [ $tofu_plan_exit_code == 2 ]; then
    echo "=== tofu plan has changes ==="
    echo ""
    echo "=== tofu - approval before apply ==="
    read -p "Apply changes? (Y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        echo "=== tofu - apply ==="
        docker compose run --rm -e "WORKSPACE=${WORKSPACE}" --entrypoint '/bin/sh -c' tofu 'cp -fR .azure/ ~/.azure &&
        ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET &&
        tofu apply -auto-approve ${WORKSPACE}.tfplan'
        tofu_changes_applied=0
    else
        echo "=== tofu - apply not confirmed ==="
        tofu_changes_applied=1
    fi
else
    echo "=== tofu plan failed with unknown output ==="
    tofu_changes_applied=1
fi

echo ""
echo "=== remove the azure login information ==="
rm -rfd .azure/*

echo ""
echo "=== tofu - finished ==="

exit $tofu_changes_applied
