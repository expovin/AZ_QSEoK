# QSEoK Azure cluster deployment scripts

The mechanic to deploy a Kubernetes cluster is a long, boring, error prone task. It is usually a one shot task for a production environment, it doesn't for test and lab purpose. On the other hand leave an environment up and running has costs, even when not in use. These scripts make the boring work to create and deploy a Kubernetes cluster on Azure and destroy it when not needed any more.
In  details the steps it runs are:

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

***AZ_DestroyCluster.sh***
- Destroy all resources belonging to the same RESOURCE_GROUP.

### Disclaimer
These scripts are freely provided to speed up the Azure cluster deployment required by Qlik Sense Enterprise on Kubernetes (AKA QSEoK) for a test or Lab environment. The code are open such that anyone can check it before run. 

The resourses creation may have cost impact, base on your subscription with Microsoft Azure.

The resources deletation **does not ask for any confermation.**

Run them at your own risk.

### System requirements

There are a number of command line tools required. You need them to deploy an Azure cluster, install QSEoK and managing the environment even if you do not use these tools. The CLI required are:

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
 - [helm](https://helm.sh/docs/using_helm/)
       - Tested with versions:
             - Client : {SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
             - Server : {SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
 
 Futhermore you need to own an Azure account with a valid subscription

Indicare le versioni

### Know limits
***Error handling*** Only the AKS enabling task check for the correct component registration. All ather steps assume the task run correctly.

***RESOURCE_GROUP name*** is automatically assigned by Azure. I assumed it is build as "MC_"+RESOURCE_GROUP_NAME+"_"+CLUSTER_NAME+"_"+LOCATION from some empirical tests. Anyway the creation step check for the existence o such RESOURCE_GROUP_NAME, if it does not exist the script just exit. You can find the correct name and replace the variable AZ_DEFAULT_RESOURCE_GROUP value in the config.js file and run the script again

***OS*** these scripts are developed and tested on Linux Operating System. They are bash shell scripts, therefore they should run on any bash console including those on MacOS and bash simulator for Windows. Futhermore some OS may call the CLI command in a different way. This version does not provide the way to change the CLI command name, you should change the name in your OS or create simbolic link.

***IdPs***. Only Auth0 has been tested. Anyway the ***value.yaml*** should work with any IdP

*Any comment, bug or improvement request is wellcome.*


## Configuration
There are two different way to run the Cluster Deployments:
- **Supervised mode** : Requires you to login using your browser. You need to leave the terminal open till the end.
- **Unattended mode** : Requires you to create a server-principal user for logging in. You can even schedule the script to run at a given time. To create the server principal user run into the console the following command

```
az ad sp create-for-rbac --name ClusterAutomation
```

and copy/paste the appId, password and tenant into **config.sh** file

There are two configuration file to fill up before run the creation script, those file are:
- value.yaml
- config.sh

### value.yaml
The ***value.yaml*** file is required to install the QSEoK. You need to fill up the identity provider section. In order to do that you should complete the IdP configuration according to the [Qlik manual]( https://help.qlik.com/en-US/sense/June2019/Subsystems/PlanningQlikSenseDeployments/Content/Sense_Deployment/auth0-setup.htm), once completed you can replace the **clientId** and **secret** values.
Replace **YUOR_SERVER** with the DNS name for your QSEoK cluster. For test and Lab environment you can just add the Server name in your **hosts** file; ***AZ_CreateCluster.sh*** will show the cluster IP when the configuration has completed. 

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
- **QS_LICENSE** : Not used.


