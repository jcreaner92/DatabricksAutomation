roleNames=$( az role definition list )
Bool_Contains_DBX_Custom_Role_Exists=$( jq -r  ' [ .[].roleName | contains("DBX_Custom_Role_DSToolkit") ] | any ' <<< "$roleNames" )

echo "Does Custom Role Exist: $Bool_Contains_DBX_Custom_Role_Exists "

if [ $Bool_Contains_DBX_Custom_Role_Exists == false ]; then
    echo "Is it..."
    cd .github/workflows/RBAC_Role_Definition
    ls

    echo $param_SubscriptionId
    updateJson=$(jq -r --arg param_SubscriptionId "$param_SubscriptionId" ' .assignableScopes[0] = "/subscriptions/$param_SubscriptionId" ' DBX_Custom_Role.json) && echo -E "${updateJson}" > DBX_Custom_Role.json
    updateJson=$(echo $updateJson | jq -r )
    echo $updateJson
    az role definition create \
        --role-definition "$updateJson"
fi

#contents="$(jq '.assignableScopes[] = "/subscriptions/4f1bc772-7792-4285-99d9-3463b8d7f994"' DBX_Custom_Role.json)" && echo -E "${contents}" > DBX_Custom_Role.json
#trial=$(echo $contents | jq -r )
#az role definition create --role-definition "$trial"