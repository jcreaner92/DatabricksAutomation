az config set extension.use_dynamic_install=yes_without_prompt

echo "ClientID: $ARM_CLIENT_ID"
echo "Client Secret: $ARM_CLIENT_SECRET"
echo "Tenant ID: $ARM_TENANT_ID"

echo "Logging in using Azure service priciple"
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

### Remove This In Time
DATABRICKS_ORDGID=$(az databricks workspace list -g $param_ResourceGroupName --query "[].workspaceId" -o tsv)
dbx_workspace_name=$(az databricks workspace list -g $param_ResourceGroupName --query "[].name" -o tsv)
DATABRICKS_INSTANCE="$(az databricks workspace list -g $param_ResourceGroupName --query "[].workspaceUrl" -o tsv)"
workspace_id=$(az databricks workspace list -g $param_ResourceGroupName --query "[].id" -o tsv)
azKeyVaultName=$(az keyvault list -g $param_ResourceGroupName --query "[].name" -o tsv)
DATABRICKS_TOKEN=$(az keyvault secret show --name "dbkstoken" --vault-name $azKeyVaultName --query "value")


### Creation Of Important Environment Variables For Later Steps
echo "DATABRICKS_ORDGID=$DATABRICKS_ORDGID" >> $GITHUB_ENV
echo "Workspace ID Set As Env Variable: $DATABRICKS_ORDGID"

echo "workspace_id=$workspace_id" >> $GITHUB_ENV
echo "Workspace ID Set As Env Variable: $workspace_id"

echo "DATABRICKS_INSTANCE=$DATABRICKS_INSTANCE" >> $GITHUB_ENV
echo "Workspace URL Set As Env Variable: $DATABRICKS_INSTANCE"

echo "DATABRICKS_HOST=https://$DATABRICKS_INSTANCE" >> $GITHUB_ENV
echo "Workspace URL Set As Env Variable: $DATABRICKS_HOST"

echo "DATABRICKS_TOKEN=$DATABRICKS_TOKEN" >> $GITHUB_ENV
echo "Workspace URL Set As Env Variable: $DATABRICKS_TOKEN"


echo "Testing Python Path For Uploading Wheel File"
echo "PYTHONPATH=src/modules" >> $GITHUB_ENV


# token response for the azure databricks app  
token_response=$(az account get-access-token --resource $param_AZURE_DATABRICKS_APP_ID)
token=$(jq .accessToken -r <<< "$token_response")
echo "token=$token" >> $GITHUB_ENV
echo "Token Set As Env Variable: $token"

az_mgmt_resource_endpoint=$(curl -X GET -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=client_credentials&client_id='$ARM_CLIENT_ID'&resource='$param_MANAGEMENT_RESOURCE_ENDPOINT'&client_secret='$ARM_CLIENT_SECRET https://login.microsoftonline.com/$ARM_TENANT_ID/oauth2/token)
echo "Management Resource Endpoint: $az_mgmt_resource_endpoint"

# Extract the access_token value
mgmt_access_token=$(jq .access_token -r <<< "$az_mgmt_resource_endpoint" )
echo "mgmt_access_token=$mgmt_access_token" >> $GITHUB_ENV
echo "Management Access Set As Env Variable: $mgmt_access_token"



### Remove
listClusters=$(curl -X GET -H "Authorization: Bearer $token" -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" -H "X-Databricks-Azure-Workspace-Resource-Id: $workspace_id" -H 'Content-Type: application/json' https://$DATABRICKS_INSTANCE/api/2.0/clusters/list )
DATABRICKS_CLUSTER_ID=$( jq -r  '.clusters[] | select( .cluster_name | contains("dbz-sp-cluster2")) | .cluster_id ' <<< "$listClusters")
echo "DATABRICKS_CLUSTER_ID=$DATABRICKS_CLUSTER_ID" >> $GITHUB_ENV
echo "Workspace ID Set As Env Variable: $DATABRICKS_CLUSTER_ID"
###
