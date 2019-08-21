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

Usate questo tool così com'è. Attenzione per lo script di creazione ai costi delle risorse e allo script di cancellazione a risorse nello stesso RESOURCE_GROUP.
Non mi assumo nessuna responsabilità

### System requirements
Command line tools 
 az
 kubectl
 helm

Indicare le versioni

### Versione attuale
***v1.0*** Prima versione. Limiti conosciuti

## Configurazione
 Ci sono 2 file da configurare 
 *** config.sh *** Impostazione del cluster su Azure
 *** value.yaml *** Impostazione parametri IdP per il deployment QSEoK seguire le istruzioni riportate [qui]( https://help.qlik.com/en-US/sense/June2019/Subsystems/PlanningQlikSenseDeployments/Content/Sense_Deployment/auth0-setup.htm)


