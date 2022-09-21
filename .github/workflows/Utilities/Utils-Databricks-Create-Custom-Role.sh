roleNames=$( az role definition list )
Bool_Contains_DBX_Custom_Role_Exists=$( jq -r  ' [ .[].roleName | contains("DBX_Custom_Role_DSToolkit") ] | any ' <<< "$roleNames" )

echo "Does Custom Role Exist: $Bool_Contains_DBX_Custom_Role_Exists "

if [ $Bool_Contains_DBX_Custom_Role_Exists == false ]; then
    echo "Is it..."
    cd .github/workflows/RBAC_Role_Definition
    ls

    updateJson="$(jq --arg param_SubscriptionId "$param_SubscriptionId" '.assignableScopes[0] = "/subscriptions/$4f1bc772-7792-4285-99d9-3463b8d7f994"' DBX_Custom_Role.json)" && echo -E "${contents}" > DBX_Custom_Role.json
    az role definition create \
        --role-definition $updateJson
fi