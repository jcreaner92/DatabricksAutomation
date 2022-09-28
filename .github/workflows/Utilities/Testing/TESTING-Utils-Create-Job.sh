#  .d8888b.  8888888b.               d8888          888    888                        888    d8b                   888             
# d88P  Y88b 888   Y88b             d88888          888    888                        888    Y8P                   888             
# Y88b.      888    888            d88P888          888    888                        888                          888             
#  "Y888b.   888   d88P           d88P 888 888  888 888888 88888b.   .d88b.  88888b.  888888 888  .d8888b  8888b.  888888  .d88b.  
#     "Y88b. 8888888P"           d88P  888 888  888 888    888 "88b d8P  Y8b 888 "88b 888    888 d88P"        "88b 888    d8P  Y8b 
#       "888 888                d88P   888 888  888 888    888  888 88888888 888  888 888    888 888      .d888888 888    88888888 
# Y88b  d88P 888               d8888888888 Y88b 888 Y88b.  888  888 Y8b.     888  888 Y88b.  888 Y88b.    888  888 Y88b.  Y8b.     
#  "Y8888P"  888              d88P     888  "Y88888  "Y888 888  888  "Y8888  888  888  "Y888 888  "Y8888P "Y888888  "Y888  "Y8888  
####################################################################################################################################################################
set -o errexit
set -o nounset
set -o pipefail


echo "Logging in using Azure service principal"
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# az account set -s  $ARM_SUBSCRIPTION_ID
echo 'ClientSecret:                             $ARM_CLIENT_SECRET'
echo 'ClientID:                                 $ARM_CLIENT_ID'
echo 'TenantID:                                 $ARM_TENANT_ID'
echo 'ApplicationID                             $AZURE_DATABRICKS_APP_ID'
echo 'DatabricksWorkspace:                      $DATABRICKS_WORKSPACE'
echo 'Databricks WS RG:                         $RESOURCE_GROUP'
echo 'Token:                                    $(dbkstoken)'
echo 'Host:                                     $(workspaceUrl)'
echo 'WorkspaceID:                              $(wsId)'

# Enable install of extensions without prompt
az config set extension.use_dynamic_install=yes_without_prompt
wsId=$(az resource show --resource-type Microsoft.Databricks/workspaces -g $RESOURCE_GROUP -n "$DATABRICKS_WORKSPACE" --query id -o tsv)
echo "Workspce ID: $wsId"

# Get workspace url e.g. adb-xxxxxxxxxxxxxxxx.x.azuredatabricks.net
workspaceUrl=$(az resource show --resource-type Microsoft.Databricks/workspaces -g "$RESOURCE_GROUP" -n "$DATABRICKS_WORKSPACE" --query properties.workspaceUrl --output tsv)
echo "Workspce URL: $workspaceUrl" # example --> adb-2427722425237209.9.azuredatabricks.net

# token response for the azure databricks app  
token_response=$(az account get-access-token --resource $AZURE_DATABRICKS_APP_ID)
echo "Token response: $token_response"

# Extract accessToken value --> We use 'Here Strings to turn the JSON token response into an Array, and then extract the accessToken'
token=$(jq .accessToken -r <<< "$token_response")
echo "Token: $token"

az_mgmt_resource_endpoint=$(curl -X GET -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=client_credentials&client_id='$ARM_CLIENT_ID'&resource='$MANAGEMENT_RESOURCE_ENDPOINT'&client_secret='$ARM_CLIENT_SECRET https://login.microsoftonline.com/$ARM_TENANT_ID/oauth2/token)
echo "Management Resource Endpoint: $az_mgmt_resource_endpoint"

# Extract the access_token value
mgmt_access_token=$(jq .access_token -r <<< "$az_mgmt_resource_endpoint" )
echo "Management Access Token: $mgmt_access_token"


listClusters=$(curl -X GET -H "Authorization: Bearer $token" -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" -H "X-Databricks-Azure-Workspace-Resource-Id: $wsId" -H 'Content-Type: application/json' https://$workspaceUrl/api/2.0/clusters/list )

echo 'List Clusters'
echo $listClusters



echo 'clusterID'
clusterId=$( jq -r  '.clusters[] | select( .cluster_name | contains("cluster1")) | .cluster_id ' <<< "$listClusters")
echo $clusterId
#"0609-130637-9rhcw0m1"


# Below - The Job ID has hypens 0609-130637-9rhcw0m1 and has issues when you pass it to the api below. It is PARAMOUNT to use double quoutes
# and single quote around the variable so that it evaluates correctly. 

createDatabricksJob=$(curl -X POST -H "Authorization: Bearer $token" -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" -H "X-Databricks-Azure-Workspace-Resource-Id: $wsId" -H 'Content-Type: application/json' -d \
'{
"name": "unittestjob",
"existing_cluster_id": "'$clusterId'" ,
"notebook_task": {"notebook_path": "/Users/ce79c2ef-170d-4f1c-a706-7814efb94898/unittest"}
}' https://$workspaceUrl/api/2.1/jobs/create )



listJobs=$(curl -X GET -H "Authorization: Bearer $token" -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" -H "X-Databricks-Azure-Workspace-Resource-Id: $wsId" -H 'Content-Type: application/json' https://$workspaceUrl/api/2.1/jobs/list )
echo 'List Jobs'
echo $listJobs

jobID=$( jq -r  '.jobs[] | select( .settings.name | contains("unittestjob")) | .job_id ' <<< "$listJobs")
#854685009836639
echo 'List JobID'
echo $jobID


runJob=$(curl -X POST -H "Authorization: Bearer $token" -H "X-Databricks-Azure-SP-Management-Token: $mgmt_access_token" -H "X-Databricks-Azure-Workspace-Resource-Id: $wsId" -H 'Content-Type: application/json' -d \
'{
"job_id": "'$jobID'"
}' https://$workspaceUrl/api/2.1/jobs/run-now )

echo 'List runJob'
echo $runJob

#echo 'Create Secret Scope'
#echo $createDatabricksJob 













