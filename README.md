![Banner](docs/images/MLOps_for_databricks_Solution_Acclerator_logo.JPG)
---
---
 <br>
 <br>
 
<p align="center">
  <img width="821" alt="image" src="https://user-images.githubusercontent.com/108273509/191785696-e8f52385-38b6-42b1-9e85-a3f6bf38d54b.png">
</p>

## Table of Contents
- [About This Repository](#About-This-Repository)
- [Prerequisites](#Prerequisites)
- [Details of The Accelerator](#Details-of-The-Accelerator)
- [Databricks as Infrastructure](#Databricks-as-Infrastructure)
- [Continuous Deployment + Branching Strategy](#Continuous-Deployment-+-Branching-Strategy)
- [Fork Repository](#Fork-Repository)
- [Create Main Service Principal](#Create-Main-Service-Principal)
- [Create Databricks Service Principal](#Create-Databricks-Service-Principal)
- [Final Snapshot of Github Secrets](#Final-Snapshot-of-Github-Secrets)
- [Retrieve Object Id's](#Retrieve-Object-Ids)
- [Update Yaml Pipeline Parameters Files](#Update-Yaml-Pipeline-Parameters-Files)
- [Deploy The Azure Environments](#Deploy-The-Azure-Environments)
- [Run Machine Learning Scripts](#Run-Machine-Learning-Scripts)

---
---

# About This Repository

This Repository contains an Azure Databricks Continuous Deployment _and_ Continuous Development Framework for delivering Data Engineering/Machine Learning projects based on the below Azure Technologies:



| Azure Databricks | Azure Log Analytics | Azure Monitor Service  | Azure Key Vault        |
| ---------------- |:-------------------:| ----------------------:| ----------------------:|



Azure Databricks is a powerful technology, used by Data Engineers and Scientists ubiquitously. However, operationalizing it within a fully automated Continuous Integration and Deployment setup may prove challenging. 

The net effect is a disproportionate amount of the Data Scientist/Engineers time contemplating DevOps matters. This Repositories guiding vision is to automate as much of the infrastructure as possible.

---
---

# Prerequisites
<details open>
<summary>Click Dropdown... </summary>
<br>
  
- Github Account
- Access to an Azure Subscription
- VS Code installed.
- Docker Desktop Installed (Instructions below)
- Azure CLI Installed (This Accelerator is tested on version 2.39)

</details>

---
---

# Details of The Accelerator

- Creation of four environments:
  - Development 
  - UAT
  - PreProduction
  - Production
- Full CI-CD between environments.
- Infrastructure as Code for interacting with Databricks API and also CLI
- Logging Framework using the [Opensensus Azure Monitor Exporters](https://github.com/census-instrumentation/opencensus-python/tree/master/contrib/opencensus-ext-azure)
- Support for Databricks Development from VS Code IDE using the [Databricks Connect](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/databricks-connect#visual-studio-code) feature.
- Azure Service Principal Authentication
- Azure resource deployment using BICEP
- Examples within Development Framework using the Python SDK for Databricks
- Docker Environment in VS Code (Section 2)

---
---

# Databricks as Infrastructure
<details open>
<summary>Click Dropdown... </summary>

<br>
There are many ways that a User may create Databricks Jobs, Notebooks, Clusters, Secret Scopes etc. <br>
<br>
For example, they may interact with the Databricks API/CLI from:
<br>
1. Their local VS Code <br>
2. Within Databricks UI; or <br>
3. A Yaml Pipeline deployment on a DevOps Agent (Github Actions/Azure DevOps etc.) <br>
<br>
 
The programmatic way for which options 1 & 2 allow us to interact with the Databricks API is akin to "Continuous **Development**", as opposed to "Continuous **Deployment**". The former is strong on flexibility, however, it is somewhat weak on governance and reproducibility. <br>

In a nutshell, Continuous **Development** is a partly manual process where developers can deploy any changes to customers by simply clicking a button, while continuous **Deployment** emphasizes automating the entire process.

</details>

---
---

 # Continuous Deployment + Branching Strategy

It is hard to talk about Continuous Deployment without addressing the manner in which that Deployment should look... for example... what branching strategy will be adopted? <br> 
<br>
The Branching Strategy is configured automatically. It follows a Github Flow paradigm to promote rapid Continuous Integration, with some nuances. (see footnote 1 which contains the SST Git Flow Article written by Willie Ahlers for the Data Science Toolkit - This provides a narrative explaining the numbers below)[^1]

<img width="805" alt="image" src="https://user-images.githubusercontent.com/108273509/186166011-527144d5-ebc1-4869-a0a6-83c5538b4521.png">

-   Feature Branch merged to Main Branch: Resource deployment to Development environment 
-   Merge Request from Main Branch To Release Branch: Deploy to UAT environment
-   Merge Request Approval from Main Branch to Release Branch: Deploy to PreProduction environment
-   Tag Release Branch with Stable Version: Deploy to Production environment 


---
---

# Fork Repository
<details open>
<summary>Click Dropdown... </summary>
<br>
  
- Fork this repository, ensuring the project name is DatabricksAutomation
- In your Forked Repo, click on 'Actions' and then 'Enable'
- Within your VS Code , "View" --> "Command Pallette" --> "Git: Clone" --> Select <yourUserName>/DatabricksAutoamtion
</details>

---
---

# Create Main Service Principal

**Why**: You will need to assign RBAC permissions to Azure Resources created on the fly. See JSON document "RBAC_Assignment" section.

Steps:
Open the Terminal Window in VSCode. Enter:

```ps
echo "Enter Your Azure Subsription ID"
$SubscriptionId = " "
```

```ps
echo "Create The Service Principal - Provide Unique Name: Suggestions - CICD_MainSP_UniqSuffix"
echo "WARNING: DO NOT DELETE OUTPUT"

az ad sp create-for-rbac -n  "InsertName" --role Owner --scopes /subscriptions/$SubscriptionId --sdk-auth
```

Ensure that the Service Principal names are unique within your Tenant. If not unique, you may see the error "Insufficient privileges to complete the operation"

# Secrets
Create Github Secret titled "AZURE_CREDENTIALS" using the output generated from the previous command.

<img width="420" alt="image" src="https://user-images.githubusercontent.com/108273509/192110733-90975739-6f2d-46f3-8fe8-45cb0cf60b20.png">


---
---

# Create Databricks Service Principal

**Why**: For those who only need permissions to create resources and interact with the Databricks API (zero trust).
Steps:

Open the Terminal Window in VSCode. Enter:

```ps
echo "Create The Service Principal - Provide Unique Name: Suggestions - CICD_DBXSP_UniqSuffix"
echo "WARNING: DO NOT DELETE OUTPUT"

az ad sp create-for-rbac -n InsertName --role Contributor --scopes /subscriptions/$SubscriptionId --query "{ARM_TENANT_ID:tenant, ARM_CLIENT_ID:appId, ARM_CLIENT_SECRET:password}"
```

```ps
echo "Save The ARM_CLIENT_ID From Previous Steps Output:"

$DBX_SP_Client_ID = "<>"
```
# Secrets
Create Github Secrets entitled "ARM_CLIENT_ID", "ARM_CLIENT_SECRET" and "ARM_TENANT_ID"  
Do not include double quotes for Secret Names and Values.

---
---

# Final Snapshot of Github Secrets

Secrets in Github should look exactly like below. The secrets are case sensitive, therefore be very cautious when creating. 

<img width="431" alt="image" src="https://user-images.githubusercontent.com/108273509/188156231-68700283-dc93-4c2d-a739-0eff23b47591.png">

---
---
 
# Retrieve Object Ids

**Why**: The Object IDs will be used when assigning RBAC permissions at a later stage. 

1. In VS Code Terminal retrieve ObjectID of Databricks Service Principal by entering:  
```ps
$DBX_SP_ObjID=( az ad sp show --id $DBX_SP_Client_ID --query "{roleBeneficiaryObjID:id}" -o tsv )
```
ERROR: If you are on the old Azure CLI, the command above will return null. Instead use the command below:

```ps
$DBX_SP_ObjID=( az ad sp show --id $DBX_SP_Client_ID --query "{roleBeneficiaryObjID:objectId}" -o tsv )
```
---

2. In VSCode Terminal Retrieve your own ObectID:  
```ps
$User_ObjID=( az ad user show --id ciaranh@microsoft.com --query "{roleBeneficiaryObjID:id}" -o tsv )
```
ERROR: If you are on the old Azure CLI, the command above will return null. Instead use the command below:

```ps
$User_ObjID=( az ad user show --id ciaranh@microsoft.com --query "{roleBeneficiaryObjID:objectId}" -o tsv )
```
---
---
 
# Update Yaml Pipeline Parameters Files

- The Parameters file can be thought of as a quasi ARM Template for Databricks
- Parameters files can be found at: /.github/workflows/Pipeline_Param/<environment-file-name>


We will update the parameters files ( Development.json, UAT.json, PreProduction.json, Production.json). Enter script below into VS Code Powershell Terminal to update files automatically.
  
```ps
echo "Enter Your Git Username... "
  
$Git_Configuration = "Ciaran28"
```
  
  ```ps
echo "Enter Your Git Repo Url... "
  
$Repo_ConfigurationURL = "https://github.com/ciaran28/DatabricksAutomation"
```
  
  
```ps
echo "Update The Parameter Files"
$files = @('Development.json','UAT.json', 'PreProduction.json', 'Production.json' )

Foreach($file in $files)
{
    $JsonData = Get-Content .github\workflows\Pipeline_Param\$file -raw | ConvertFrom-Json

    $JsonData.RBAC_Assignments | % {if($_.Description -eq 'You Object ID'){$_.roleBeneficiaryObjID=$User_ObjID}}

    $JsonData.RBAC_Assignments | % {if($_.Description -eq 'Databricks SPN'){$_.roleBeneficiaryObjID=$DBX_SP_ObjID}}

    $JsonData.update | % {$JsonData.SubscriptionId = $SubscriptionId}

    foreach ($Obj in $JsonData.Git_Configuration)
    {
        ($Obj.git_username = $Git_Configuration )
    }

    foreach ($Obj in $JsonData.Repo_Configuration)
    {
        ($Obj.url = $Repo_ConfigurationURL )
    }

    $JsonData | ConvertTo-Json -Depth 4  | set-content .github\workflows\Pipeline_Param\$file -NoNewline

}
```
---
---
 
# Deploy The Azure Environments 

- Ensure that all bash '.sh' files within '.github\workflows\Utilities' have not defaulted to 'CRLF' EOL. Instead change this to LF. See the bottom right of VS Code.
  <img width="259" alt="image" src="https://user-images.githubusercontent.com/108273509/188154937-32c97d98-5659-4224-be5c-94a97e090e0f.png">


- Git add, commit and then push to the remote repo from your local VS Code
- In Github you can manually run the pipeline to deploy the environments to Azure using:
  - .github\workflows\1-DBX-Manual-Full-Env-Deploy.yml

<img width="1172" alt="image" src="https://user-images.githubusercontent.com/108273509/186510528-29448e4d-1a0e-41b9-a37f-0cd89d226d57.png">
  
- Azure Resources created (Production Environment snapshot)
  
<img width="637" alt="image" src="https://user-images.githubusercontent.com/108273509/188148485-86509546-bdd1-413d-b0b3-35f34d2e1722.png">

- Snapshot of completed Github Action deployment 

<img width="810" alt="image" src="https://user-images.githubusercontent.com/108273509/188155303-cfe07a79-0a9d-4a4d-a40a-dea6104b40f1.png">

---
---

# Run Machine Learning Scripts

<img width="752" alt="image" src="https://user-images.githubusercontent.com/108273509/186661417-403d58db-147e-4dd5-966a-868876fb2ee0.png">

---
---
# Section 2: Interact With Databricks From Local VS Code Using Databricks Connect + Docker Image

In the previous section, we interacted with Databricks API from the DevOps Agent.

But what if we wish to interact with the Databricks environment from our local VS Code? In order to do this we can use "Databricks Connect".

Now... enter Docker. Why are we using this? Configuring the environment set up for Databricks Connect on a Windows machine is a tortuous process, designed to break the will of even the most talented programmer. Instead, we will use a Docker Image which builds a containerized Linux environment within the VS Code Workspace, dealing with all of the environment variables and path dependencies out of the box. 

# Steps

![map01](docs/images/map01.png)
1. Clone the Repository : https://github.com/microsoft/dstoolkit-ml-ops-for-databricks/pulls
2. Install Docker Desktop. Visual Code uses the docker image as a remote container to run the solution.
3. Create .env file in the root folder, and keep the file blank for now. (root folder is the parent folder of the project)
4. In the repo, open the workspace. File: workspace.ode-workspace.

> Once you click the file, you will get the "Open Workspace" button at right bottom corner in the code editor. Click it to open the solution into the vscode workspace.

![workspaceselection](docs/images/workspaceselection.jpg)

5. We need to connect to the [docker image as remote container in vs code](https://code.visualstudio.com/docs/remote/attach-container#_attach-to-a-docker-container). In the code repository, we have ./.devcontainer folder that has required docker image file and docker configuration file. Once we load the repo in the vscode, we generally get the prompt. Select "Reopen in Container". Otherwise we can go to the VS code command palette ( ctrl+shift+P in windows), and select the option "Remote-Containers: Rebuild and Reopen in Containers"

![DockerImageLoad](docs/images/DockerImageLoad.jpg)

6. In the background, it is going to build a docker image. We need to wait for sometime to complete build. the docker image will basically contain the a linux environment which has python 3.7 installed. Please have a look at the configuration file(.devcontainer\devcontainer.json) for more details. 
7. Once it is loaded. we will be able to see the python interpreter is loaded successfully. Incase it does not show, we need to load the interpreter manually. To do that, click on the select python interpreter => Entire workspace => /usr/local/bin/python

![pythonversion](docs/images/pythonversion.jpg)

8. You will be prompted with installing the required extension on the right bottom corner. Install the extensions by clicking on the prompts.

![InstallExtensions](docs/images/InstallExtensions.jpg)

9. Once the steps are completed, you should be able to see the python extensions as below:

![pythonversion](docs/images/pythonversion.jpg)


Note: Should you change the .env file, you will need to rebuild the container for those changes to propogate through. 


## Create the .env file

![map04](docs/images/map04.png)

We need to manually change the databricks host and appI_IK values. Other values should be "as is" from the output of the previous script.

- PYTHONPATH: /workspaces/dstoolkit-ml-ops-for-databricks/src/modules [This is  full path to the module folder in the repository.]
- APPI_IK: connection string of the application insight
- DATABRICKS_HOST: The URL of the databricks workspace.
- DATABRICKS_TOKEN: Databricks Personal Access Token which was generated in the previous step.
- DATABRICKS_ORDGID: OrgID of the databricks that can be fetched from the databricks URL.

![DatabricksORGIDandHOSTID](docs/images/DatabricksORGIDandHOSTID.JPG)

Application Insight Connection String

![AppInsightConnectionString](docs/images/AppInsightConnectionString.jpg)

At the end, our .env file is going to look as below. You can copy the content and change the values according to your environment.

``` conf
PYTHONPATH=/workspaces/dstoolkit-ml-ops-for-databricks/src/modules
APPI_IK=InstrumentationKey=e6221ea6xxxxxxf-8a0985a1502f;IngestionEndpoint=https://northeurope-2.in.applicationinsights.azure.com/
DATABRICKS_HOST=https://adb-7936878321001673.13.azuredatabricks.net
DATABRICKS_TOKEN= <Provide the secret>
DATABRICKS_ORDGID=7936878321001673
```

## Section 5: Configure the Databricks connect

![map05](docs/images/map05.png)

1. In this step we are going to configure the databricks connect for VS code to connect to databricks. Run the below command for that from the docker (VS Code) terminal.

``` bash
$ python "src/tutorial/scripts/local_config.py" -c "src/tutorial/cluster_config.json"
```

>Note: If you get any error saying that "ModelNotFound : No module names dbkcore". Try to reload the VS code window and see if you are getting prompt  right bottom corner saying that configuration file changes, rebuild the docker image. Rebuild it and then reload the window. Post that you would not be getting any error. Also, check if the python interpreter is being selected properly. They python interpreter path should be **/usr/local/bin/python **

![Verify_Python_Interpreter](docs/images/Verify_Python_Interpreter.jpg)

### Verify

1. You will be able to see the message All tests passed.

![databricks-connect-pass](docs/images/databricks-connect-pass.jpg)

## Section 6: Wheel creation and workspace upload

![map06](docs/images/map06.png)

In this section, we will create the private python package and upload it to the databricks environment.

1. Run the below command:

``` bash
python src/tutorial/scripts/install_dbkframework.py -c "src/tutorial/cluster_config.json"
```

Post Execution of the script, we will be able to see the module to be installed.

![cluster-upload-wheel](docs/images/cluster-upload-wheel.jpg)

## Section 7: Using the framework

![map07](docs/images/map07.png)

We have a  pipeline that performs the data preparation, unit testing, logging, training of the model.


![PipelineSteps](docs/images/PipelineSteps.JPG)


### Execution from Local VS Code

To check if the framework is working fine or not, let's execute this file : **src/tutorial/scripts/framework_testing/remote_analysis.py** . It is better to execute is using the interactive window. As the Interactive window can show the pandas dataframe which is the output of the script. Otherwise the script can be executed from the Terminal as well.
To run the script from the interactive window, select the whole script => right click => run the selection in the interactive window.

Post running the script, we will be able to see the data in the terminal.

![final](docs/images/final.jpg)

---
# Apendix
 
[^1]: https://microsofteur.sharepoint.com/teams/MCSMLAISolutionAccelerators/SitePages/Contribution-Guide--How-can-I-contribute-my-work-.aspx?xsdata=MDV8MDF8fDdiODIxYzQxNjQ5NDRlMDQzNWZkMDhkYTc1NmIwMjJlfDcyZjk4OGJmODZmMTQxYWY5MWFiMmQ3Y2QwMTFkYjQ3fDB8MHw2Mzc5NTEzOTk2ODQ4Nzk4Njl8R29vZHxWR1ZoYlhOVFpXTjFjbWwwZVZObGNuWnBZMlY4ZXlKV0lqb2lNQzR3TGpBd01EQWlMQ0pRSWpvaVYybHVNeklpTENKQlRpSTZJazkwYUdWeUlpd2lWMVFpT2pFeGZRPT18MXxNVGs2YldWbGRHbHVaMTlPZWxWNlQwUkpNbGw2VVhST01rVjVXbE13TUZscWFHeE1WMGw0VGxSbmRGcFVWbTFOUkUxNFRtMUpOVTFVVVhsQWRHaHlaV0ZrTG5ZeXx8&sdata=QVcvTGVXVWlUelZ3R2p6MS9BTTVHT0JTWWFDYXBFZW9MMDRuZ0RWYTUxRT0%3D&ovuser=72f988bf-86f1-41af-91ab-2d7cd011db47%2Cciaranh%40microsoft.com&OR=Teams-HL&CT=1660511292416&clickparams=eyJBcHBOYW1lIjoiVGVhbXMtRGVza3RvcCIsIkFwcFZlcnNpb24iOiIyNy8yMjA3MzEwMTAwNSIsIkhhc0ZlZGVyYXRlZFVzZXIiOmZhbHNlfQ%3D%3D#sst-flow
