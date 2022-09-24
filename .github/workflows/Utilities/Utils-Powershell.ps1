

$SubscriptionId = "4f1bc772-7792-4285-99d9-3463b8d7f994"
$Git_Configuration = "Ciaran28"
$Repo_ConfigurationURL = "https://github.com/ciaran28/DatabricksAutomation"
$User_ObjID = "3fb6e2d3-7734-43fc-be9e-af8671acf605"
$DBX_SP_ObjID = "02a3f916-b4ea-4207-be62-d6f5d35890e5"

$files = @('Developmenttest.json','UATtest.json')

Foreach($file in $files)
{
    $JsonData = Get-Content .github\workflows\Pipeline_Param\$file -raw | ConvertFrom-Json

    $JsonData.RBAC_Assignments | % {if($_.Description -eq 'You Object ID'){$_.roleBeneficiaryObjID=$User_ObjID}}

    $JsonData.RBAC_Assignments | % {if($_.Description -eq 'Databricks SPN'){$_.roleBeneficiaryObjID=$DBX_SP_ObjID}}

    $JsonData.update | % {
        $JsonData.SubscriptionId = $SubscriptionId                                                                                 
    }

    foreach ($Obj in $JsonData.Git_Configuration)
    {
        ($Obj.git_username = $Git_Configuration )
    }

    foreach ($Obj in $JsonData.Repo_Configuration)
    {
        ($Obj.url = $Repo_ConfigurationURL )
    }

    #echo $JsonData

    $JsonData | ConvertTo-Json -Depth 4  | set-content .github\workflows\Pipeline_Param\$file

}