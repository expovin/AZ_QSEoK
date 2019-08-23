# QSEoK Azure cluster deployment scripts

The procedure to deploy a Kubernetes cluster is generally a long, boring, error prone task, which is typically performed once in a production environment, whereas in test and lab is repeated many, many times. Standing up, running, and maintaining these environments have costs, even when not in use. 

These scripts provide automatic lifecycle management of a Kubernetes cluster hosted on Azure, from its configuration, deployment, and decommissioning when no longer needed. 

Below a brief explanation of the macro steps performed by each component/script:

***AZ_CreateCluster.sh***
1. Login into Azure account
2. Set the correct subscription
3. Enable AKS (waiting for the component registration)
4. Create the Resource Group
5. Create the Cluster (this step can take a long time)
6. Get Credentials and Configure kubectl
7. Set the Role Based Access Control (RBAC)
8. Create a Storage Account
9. Create Azure Storage
10. Install QSEoK
      - Add the Qlik repo for HELM and update it
      - Install custom resource definitions used by dynamic engines
      - Install Qlik Sense Engine package
11. Get the cluster IP

When run in Supervised mode the procedure attempt to add a line with the Host and the cluster IP in the hosts file (root password is required).
When run in Unattended mode the procedure will send an email (email section need to fill out) with the cluster IP address

***AZ_DestroyCluster.sh***
- Login into azure account (supervised or unattended mode)
- Purge QSEoK deployments
- Destroy all resources belonging to the same RESOURCE_GROUP.
- Send email when complete or attempt to delete the host line from hosts file (root password is required).

### Disclaimer
These scripts are provided for free, and they aim at automating the deployment of Kubernetes cluster on Azure, and the configuration of a Qlik Sense Enterprise on Kubernetes (AKA QSEoK) on it; it is recommended to use these scripts in non-production contexts. 
The code is available so that anyone can verify its content before running it - run  it at your own risk. Depending on your subscription in Azure, the resources needed to stand up the infrastructure may incur into costs. Caution: the decommissioning script will not require any user confirmation once launched.

### System requirements
You need to provide a Microsoft Azure account, with a valid subscription assigned.

Also, below a list of required command line tools, used to deploy an Azure cluster, install QSEoK and manage the environment:

 - [az](https://docs.microsoft.com/it-it/cli/azure/install-azure-cli?view=azure-cli-latest) 
       - Tested with versions:
             - azure-cli 2.0.71
             - command-modules-nspkg 2.0.3
             - core 2.0.71
             - nspkg 3.0.4
             - telemetry 1.0.3
 - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
       - Tested with versions:
             - Client Version :{Major:"1", Minor:"15", GitVersion:"v1.15.2", GitCommit:"f6278300bebbb750328ac16ee6dd3aa7d3549568", GitTreeState:"clean", BuildDate:"2019-08-05T09:23:26Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
             - Server Version : {Major:"1", Minor:"13", GitVersion:"v1.13.10", GitCommit:"37d169313237cb4ceb2cc4bef300f2ae3053c1a2", GitTreeState:"clean", BuildDate:"2019-08-19T10:44:49Z", GoVersion:"go1.11.13", Compiler:"gc", Platform:"linux/amd64"}
 - [helm](https://github.com/helm/helm)
       - Tested with versions:
             - Client : {SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
             - Server : {SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
 
 Futhermore you need to own an Azure account with a valid subscription

### Know limits
***Error handling*** Only the AKS enabling task check for the correct component registration. All ather steps assume the task run correctly.

***RESOURCE_GROUP name*** is automatically assigned by Azure. I assumed it is build as "MC_"+RESOURCE_GROUP_NAME+"_"+CLUSTER_NAME+"_"+LOCATION from some empirical tests. Anyway the creation step check for the existence o such RESOURCE_GROUP_NAME, if it does not exist the script just exit. You can find the correct name and replace the variable AZ_DEFAULT_RESOURCE_GROUP value in the config.js file and run the script again

***OS*** these scripts are developed and tested on Linux Operating System. They are bash shell scripts, therefore they should run on any bash console including those on MacOS and bash simulator for Windows. Futhermore some OS may call the CLI command in a different way. This version does not provide the way to change the CLI command name, you should change the name in your OS or create simbolic link.

***IdPs***. Only Auth0 has been tested. Anyway the ***value.yaml*** should work with any IdP

*Any comment, bug or improvement request is wellcome.*

## Configuration
The scripts use two configuration files:
- value.yaml
- config.sh

### value.yaml
The ***value.yaml*** file is required to install the QSEoK. 
You need to fill up the identity provider section. In order to do that you should complete the IdP configuration according to the [Qlik manual]( https://help.qlik.com/en-US/sense/June2019/Subsystems/PlanningQlikSenseDeployments/Content/Sense_Deployment/auth0-setup.htm), and then replace the clientIdand secret values. 

Replace **YUOR_SERVER** with the DNS name for your QSEoK cluster. 

For test and Lab environment you can just add the Server name in your hosts file; the cluster creation script will return the cluster IP when the configuration is complete.

### config.sh
The **config.sh** sets the parameters for the Azure cluster:
- **AZ_SUBSCRIPTION** : This is the subscription you want to use to charge from. You can yous either, the subscription name or ID
- **TIME_OUT** : Represent the time (in seconds) waiting the AKS components registration
- **AZ_RESOURCE_GROUP_NAME** : A name of your choice to design the group name where all resource 
- **AZ_LOCATION** : Azure location where deploy your cluster. You can get the location details typing the command  *az account list-locations*  from the console. 
- **AZ_CLUSTER_NAME** : A name of your choice to identify your cluster. You cannot exceed 63 characters and can only contain letters, numbers, or dashes (-).
- **AZ_NODE_COUNT** : The number of nodes (Virtual Machines) in your cluster.
- **AZ_DEFAULT_RESOURCE_GROUP** : Do not change this value unless you meet the problem described in the **know limits** section
- **AZ_VM_SIZE** : Select the Virtual Machines size for each node. You can fine the list of all Azure VM Size [here](https://docs.microsoft.com/it-it/azure/virtual-machines/windows/sizes-general). To run Kubernetes there are some limits described [here](https://docs.microsoft.com/en-us/azure/aks/quotas-skus-regions#restricted-vm-sizes). The minimum size required to run QSEoK is **Standard_DS2_v2**
- **AZ_ACCOUNT_NAME** : A name of your choice for the Account Name. Using between 3 - 24 characters in length and use numbers and lower-case letters only.
- **AZ_SKU_TYPES** :  Sku type for storage. For a complete list of SKU type visiti [here](https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types). It is recomended to use **Standard_LRS** for QSEoK
- **LOGIN_MODE** : Allow you to select between the supervised run (browser-interactive) or the unattended mode (service-principal). In order to run the task from a scheduler, you need to run the unattended mode
      - **appId** : Service Principal appId
      - **password** : Service Principal Password
      - **tenant** : Service Principal tenant
      
- **HOST_NAME** : This host name will be added to the /etc/hosts with the correct cluster ip
- **QS_LICENSE** : Not used.


## Creation Modes
Clusters can be created in two distinct modes: 
- **Supervised mode** : Requires a physical user to sign in using on a browser; you need to leave the terminal open until the end.
- **Unattended mode** :  Allows for an automated sign-in (read: no human intervention, nor need for browser) intended to schedule the script to run autonomously. 

In order to create the server principal user run into the console the following command


```
az ad sp create-for-rbac --name ClusterAutomation
```

and copy/paste the appId, password and tenant into **config.sh** file

***All Email section*** when filled, allow the procedure to send out the email with useful informations (e.g. Procedure completed, Cluster IP Address, next Step to run)
