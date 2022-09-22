![Banner](docs/images/MLOps_for_databricks_Solution_Acclerator_logo.JPG)

![image](https://user-images.githubusercontent.com/108273509/191729014-bfcaf55f-8a22-4734-acad-c9c2351d3292.png)

## Table of Contents
- [About This Repository](#About-This-Repository)
- [Details of The Accelerator](#Details-of-The-Accelerator)
- [Databricks as Infrastructure](#Databricks-as-Infrastructure)
- [Continuous Deployment + Branching Strategy](#Continuous-Deployment-+-Branching-Strategy)
- [Prerequisites](#Prerequisites)
- [Under The Hood](#Under-The-Hood)
- [Create Databricks Custom Role On DBX SPN](#Create-Databricks-Custom-Role-On-DBX-SPN)
- [Create Main Service Principal](#Create-Main-Service-Principal)
- [Create Databricks SPN](#Create-Databricks-SPN)
- [Final Snapshot of Github Secrets](#Final-Snapshot-of-Github-Secrets)
- [Update Yaml Pipeline Parameters Files](#Update-Yaml-Pipeline-Parameters-Files)
- [Deploy The Azure Environments](#Deploy-The-Azure-Environments)
- [Run Python Scripts](#Run-Python-Scripts)

---

# About This Repository

This Repository contains an Azure Databricks Continuous Deployment _and_ Continuous Development Framework for delivering Data Engineering/Machine Learning projects based on the below Azure Technologies:

---

| Azure Databricks | Azure Log Analytics | Azure Monitor Service  | Azure Key Vault        |
| ---------------- |:-------------------:| ----------------------:| ----------------------:|

---

Azure Databricks is a powerfull technology, used by Data Engineers and Scientists ubiquitously. However, operationalizing it within a fully automated Continuous Integration and Deployment setup may prove challenging. 

The net effect is a disproportionate amount of the Data Scientist/Engineers time contemplating DevOps matters. This Repositories guiding vision is to automate as much of the infrastructure as possible. [^1]

---

# Details of The Accelerator

- Creation of four environments:
  - Development 
  - UAT
  - PreProduction
  - Production
- Full CI-CD between environments.
- Infrastrusture as Code for interacting with Databricks API and also CLI
- Logging Framework using the [Opensensus Azure Monitor Exporters](https://github.com/census-instrumentation/opencensus-python/tree/master/contrib/opencensus-ext-azure)
- Support for Databricks Development from VS Code IDE using the [Databricks Connect](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/databricks-connect#visual-studio-code) feature.
- Azure Service Principal Authentication
- Azure resource deployment using BICEP
- Examples within Development Framework using the Python SDK for Databricks
- Docker Environment in VS Code (Section 2)

---

# Databricks as Infrastructure
<details open>
<summary>Click Dropdown... </summary>
<br>
There are many ways that a User may create Databricks Jobs, Notebooks, Clusters, Secret Scopes etc.
For example, they may interact with Databricks API/CLI from:
1. Their local VS Code;
2. Within Databricks UI; or 
3. A Yaml Pipeline deployment on a DevOps Agent (Github Actions/Azure DevOps etc.)
 
The programmatic way for which options 1 & 2 allow us to interact the Databricks API is akin to "Continuous **Development**", as opposed to "Continuous **Deployment**". The former is strong on flexibility, however, it is somewhat weak on governance and reproducibility. 

In a nutshell, Continuous **Delivery** is a partly manual process where developers can deploy any changes to customers by simply clicking a button, while continuous **Deployment** emphasizes automating the entire process.
 
Users should be able to deploy the full CI-CD framework within Azure via simply creating the required Service Principals, updating Github Secrets with Service Principal Credentials, and then finally, updating a few JSON parameters with their Azure specific environment. 

As long as the inputs to the parameters files and also secrets provided are correct, there is no need to understand/interact with the Bash scripts within the Utilities folder. 

</details>

---

 # Continuous Deployment + Branching Strategy
<details open>
<summary>Click Dropdown... </summary>
<br>
It is hard to talk about Continuous Deployment without addressing the manner in which that Deployment should look... for example... what branching strategy will be adopted?

The Branching Strategy is configured automatically. It follows a Github Flow paradigm to promote rapid Continuous Integration, with some nuances. (see the link within the footnote which contains the SST Git Flow written by Willie Ayles for the Data Science Toolkit - This provides a narrative explaining the numbers below) [^6] 

<img width="805" alt="image" src="https://user-images.githubusercontent.com/108273509/186166011-527144d5-ebc1-4869-a0a6-83c5538b4521.png">

-   Feature Branch merged to Main Branch: Resource deployment to development environment 
-   Merge Request from Main Branch To Release Branch: Deploy to UAT environment
-   Merge Request Approval from Main Branch to Release Branch: Deploy to PreProduction environment
-   Tag Release Branch with Stable Version: Deploy to Production environment 

</details>

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

# Clone Repository
<details close>
<summary>Click Dropdown... </summary>
<br>

- In your Github account create a new Repository "DatabricksAutomation"
- Click "Import Code"

<img width="904" alt="image" src="https://user-images.githubusercontent.com/108273509/188488093-78b60917-ec8d-4cf4-b59d-5283c9ef2ce9.png">

- Now import the code from this Repository "ciaran28/DatabricksAutomation"

<img width="523" alt="image" src="https://user-images.githubusercontent.com/108273509/188488372-5970bd86-864f-42d4-9761-37aedd4ab282.png">

- Within your VS Code , "View" --> "Command Pallette" --> "Git: Clone" --> Select the Repo you have just created 
</details>

---

# Create Main Service Principal

**Why**: You will need to assign RBAC permissions to Azure Resources created on the fly. See JSON document "RBAC_Assignment" secion.

Steps:
  1. Open the Terminal Window in VSCode. Enter:
```bash
$subid = "<>"  # REPLACE
echo $subid
az ad sp create-for-rbac -n <InsertNameForServicePrincipal> --role Owner --scopes /subscriptions/$subid --sdk-auth
```
  2. Ensure that the Service Principal names are unique within your Tenant. If not unique, you may see the error "Insufficient privileges to complete the operation"
  3. Do Not Delete Output (required in Next Step) [^4]
  4. Create Github Secret titled "AZURE_CREDENTIALS" and paste output from step 2. (Include curly brackets {}) [^5] <br>
  5. For more information on '--sdk-auth' has been deprecated flag [^7] 

---

# Create Databricks Service Principal

**Why**: For those who only need permissions to create resources and interact with the Databricks API (zero trust).
Steps:
1. Open the Terminal Window in VSCode. Enter (copy output to a text file): [^2]
```bash 
az ad sp create-for-rbac -n <InsertNameForServicePrincipal> --role Contributor --scopes /subscriptions/$subid --query "{ARM_TENANT_ID:tenant, ARM_CLIENT_ID:appId, ARM_CLIENT_SECRET:password}"
```
2. Create Github Secrets entitled "ARM_CLIENT_ID", "ARM_CLIENT_SECRET" and "ARM_TENANT_ID". Values are contained within output from step 1. Do not include double quotes for Secret Names and Values. [^3] 
3. In VS Code Terminal retrieve ObjectID of Databricks Service Principal by using the ARM_CLIENT_ID from the previous step:  
```bash 
az ad sp show --id <ARM_CLIENT_ID> --query "{roleBeneficiaryObjID:id}"
```
4. In VSCode Terminal Retrieve your own ObectID:  
```bash
az ad user show --id ciaranh@microsoft.com --query "{roleBeneficiaryObjID:id}"
```

# Final Snapshot of Github Secrets

- Secrets in Github should look exactly like below. The secrets are case sensitive, therefore be very cautious when creating. 

<img width="431" alt="image" src="https://user-images.githubusercontent.com/108273509/188156231-68700283-dc93-4c2d-a739-0eff23b47591.png">


---
# Update Yaml Pipeline Parameters Files

- The Parameters file can be thought of as a quasi ARM Template for Databricks
  - Important: Databricks API is not native to ARM and thus BICEP. This is a distinct disadvantage relative to Terraform which allows us to configure Databricks Workspaces and for example, Clusters, in the same place.
- Now to update the Parameters files with the amendments below. Do it for each environment within _VS Code_ . 
- Parameters files can be found at: /.github/workflows/Pipeline_Param/<environment-file-name>
- The JSON objects are fed to their respective Bash Script, in which the Databricks/API is invoked using a For-Loop. Therefore, the JSON parameters file is flexible, allowing us to add and remove objects at will. 
- Important: When assigning RBACs to Users, it would be easier to use alias' instead of objectIDs, for example ciaranh@microsoft.com. This requires Graph API permissions, which only a Global Admin can assign.

```json

{
    "SubscriptionId": "<>",                   # Enter Your SubID
    

    "Location": "uksouth", 
    "TemplateParamFilePath":"Infrastructure/DBX_CICD_Deployment/Bicep_Params/Development/Bicep.parameters.json",
    "TemplateFilePath":"Infrastructure/DBX_CICD_Deployment/Main_DBX_CICD.bicep",
    "AZURE_DATABRICKS_APP_ID": "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d",
    "MANAGEMENT_RESOURCE_ENDPOINT": "https://management.core.windows.net/",
    "RBAC_Assignments": [          
        {
            "roles": [
                "Key Vault Administrator"
             ],
            "roleBeneficiaryObjID": "<>"        # Your ObjectID Saved In Text File
            "Description": "You Object ID",
            "principalType": "User"
        },
        { 
            "roles": [
                "Key Vault Administrator",
                 "Contributor",
                 "DBX_Custom_Role"
             ],    
            "roleBeneficiaryObjID": "<>"         # Databricks_API_SP ObjectID Saved In Text File
            "Description": "Databricks SPN",
            "principalType": "ServicePrincipal"
        },

    ],
    "Clusters": [                       
        {
            "cluster_name": "dbx-sp-cluster",
            "spark_version": "10.4.x-scala2.12",
            "node_type_id": "Standard_D3_v2",
            "spark_conf": {},
            "autotermination_minutes": 30,
            "runtime_engine": "STANDARD",
            "autoscale": {
                "min_workers": 2,
                "max_workers": 4
            }
        },
        {
            "cluster_name": "dbx-sp-cluster2",
            "spark_version": "10.4.x-scala2.12",
            "node_type_id": "Standard_D3_v2",
            "spark_conf": {},
            "autotermination_minutes": 30,
            "runtime_engine": "STANDARD",
            "autoscale": {
                "min_workers": 2,
                "max_workers": 4
            }
        }
    ],
    "WheelFiles": [                      
            {
                "setup_py_file_path": "src/pipelines/dbkframework/setup.py",
                "wheel_cluster": "dbx-sp-cluster",
                "upload_to_cluster?": true
            }
    ],
    "Git_Configuration": [                        
        {
            "git_username": "ciaran28",           # Uppdate With Your Github Username 
            "git_provider": "gitHub"
        }
    ],
    "Repo_Configuration": [                        
        {
            "url": "https://github.com/ciaran28/DatabricksAutomation", # Change To Your Own Repository
            "provider": "gitHub",
            "path": "DevelopmentFolder"            
        }
    ]
}


```

---

# Deploy The Azure Environments 

- Ensure that all bash '.sh' files within '.github\workflows\Utilities' have not defaulted to 'CRLF' EOL. Instead change this to LF. See the bottom right of VS Code.
  <img width="259" alt="image" src="https://user-images.githubusercontent.com/108273509/188154937-32c97d98-5659-4224-be5c-94a97e090e0f.png">


- Git add, commit and then push to the remote repo from your local VS Code
- In Github you can manually run the pipeline to deploy the evironments to Azure using:
  - .github\workflows\1-DBX-Manual-Full-Env-Deploy.yml

<img width="1172" alt="image" src="https://user-images.githubusercontent.com/108273509/186510528-29448e4d-1a0e-41b9-a37f-0cd89d226d57.png">
  
- Azure Resources created (Production Environment snapshot)
  
<img width="637" alt="image" src="https://user-images.githubusercontent.com/108273509/188148485-86509546-bdd1-413d-b0b3-35f34d2e1722.png">

- Snapshot of completed Github Action deployment 

<img width="810" alt="image" src="https://user-images.githubusercontent.com/108273509/188155303-cfe07a79-0a9d-4a4d-a40a-dea6104b40f1.png">



---
# Run Python Scripts

<img width="752" alt="image" src="https://user-images.githubusercontent.com/108273509/186661417-403d58db-147e-4dd5-966a-868876fb2ee0.png">

---
# Section 2: Interact With Databricks From Local VS Code Using Databricks Connect + Docker Image
---

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
---
# Apendix

[^1]: Test
[^2]: <img width="586" alt="image" src="https://user-images.githubusercontent.com/108273509/186402530-ac8b6962-daf9-4f58-a8a0-b7975d953388.png"> <br>
[^3]: <img width="388" alt="image" src="https://user-images.githubusercontent.com/108273509/186403865-6cb2023e-2a44-44ef-b744-c56d232e235a.png"> <br>
[^4]: <img width="690" alt="image" src="https://user-images.githubusercontent.com/108273509/186394172-20896052-6ae2-4063-9179-1950f5b93b3d.png"> <br>
[^5]: <img width="566" alt="image" src="https://user-images.githubusercontent.com/108273509/186401411-37504ae5-1e43-4317-8b11-d14add6d6924.png"> <br>
[^6]: https://microsofteur.sharepoint.com/teams/MCSMLAISolutionAccelerators/SitePages/Contribution-Guide--How-can-I-contribute-my-work-.aspx?xsdata=MDV8MDF8fDdiODIxYzQxNjQ5NDRlMDQzNWZkMDhkYTc1NmIwMjJlfDcyZjk4OGJmODZmMTQxYWY5MWFiMmQ3Y2QwMTFkYjQ3fDB8MHw2Mzc5NTEzOTk2ODQ4Nzk4Njl8R29vZHxWR1ZoYlhOVFpXTjFjbWwwZVZObGNuWnBZMlY4ZXlKV0lqb2lNQzR3TGpBd01EQWlMQ0pRSWpvaVYybHVNeklpTENKQlRpSTZJazkwYUdWeUlpd2lWMVFpT2pFeGZRPT18MXxNVGs2YldWbGRHbHVaMTlPZWxWNlQwUkpNbGw2VVhST01rVjVXbE13TUZscWFHeE1WMGw0VGxSbmRGcFVWbTFOUkUxNFRtMUpOVTFVVVhsQWRHaHlaV0ZrTG5ZeXx8&sdata=QVcvTGVXVWlUelZ3R2p6MS9BTTVHT0JTWWFDYXBFZW9MMDRuZ0RWYTUxRT0%3D&ovuser=72f988bf-86f1-41af-91ab-2d7cd011db47%2Cciaranh%40microsoft.com&OR=Teams-HL&CT=1660511292416&clickparams=eyJBcHBOYW1lIjoiVGVhbXMtRGVza3RvcCIsIkFwcFZlcnNpb24iOiIyNy8yMjA3MzEwMTAwNSIsIkhhc0ZlZGVyYXRlZFVzZXIiOmZhbHNlfQ%3D%3D#sst-flow
[^7]: https://github.com/azure/login#configure-a-service-principal-with-a-secret
