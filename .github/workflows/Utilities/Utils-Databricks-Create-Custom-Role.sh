roleNames=$( az role definition list )
Bool_Contains_DBX_Custom_Role_Exists=$( jq -r  ' [ .[].roleName | contains("DBX_Custom_Role") ] | any ' <<< "$roleNames" )

echo "Does Custome Role Exist: $Bool_Contains_DBX_Custom_Role_Exists "

if [[ ! $Bool_Contains_DBX_Custom_Role_Exists ]]; then

    cd .github/workflows/RBAC_Role_Definition
    ls

    updateJson="$(jq --arg param_SubscriptionId "$param_SubscriptionId" '.assignableScopes[0] = "/subscriptions/$param_SubscriptionId"' DBX_Custom_Role.json)" && echo -E "${contents}" > DBX_Custom_Role.json
    az role definition create \
        --role-definition "DBX_Custom_Role.json"
fi