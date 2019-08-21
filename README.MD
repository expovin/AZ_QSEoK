# QSEoK Azure cluster deployment scripts

The mechanic to deploy a Kubernetes cluster is a long, boring, error prone task. It is usually a one shot task for a production environment, it doesn't for test and lab purpose. On the other hand leave an environment up and running has costs, even when not in use. These scripts make the boring work to create and deploy a Kubernetes cluster on Azure and destroy it when not needed any more.
In  details the steps it runs are:
1. Login into Azure account
2. Set the correct subscription

### Disclaimer
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


