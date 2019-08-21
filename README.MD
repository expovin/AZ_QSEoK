# Azure cluster deployment scripts

introduzione sul perchè uno script per la creazione e distruzione del cluster. Considerazione sui costi.

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


