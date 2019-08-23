#!/bin/bash

startTimeScript=`date +%s`
###################################################################
# Setting the environments
source config.sh

echo "------------------------------------------------------------"
echo "SUBSCRIPTION = "$AZ_SUBSCRIPTION
echo "TIME_OUT = "$TIME_OUT "sec."
echo "RESOURCE_GROUP_NAME = "$AZ_RESOURCE_GROUP_NAME
echo "LOCATION = "$AZ_LOCATION
echo "CLUSTER_NAME"=$AZ_CLUSTER_NAME
echo "NUMBER_OF_NODES = "$AZ_NODE_COUNT
echo "DEFAULT_RESOURCE_GROUP = "$AZ_DEFAULT_RESOURCE_GROUP
echo "VM_SIZE = "$AZ_VM_SIZE
echo "ACCOUNT_NAME = "$AZ_ACCOUNT_NAME
echo "SKU_TYPES = "$AZ_SKU_TYPES
echo "LOGIN_MODE="$LOGIN_MODE
echo "------------------------------------------------------------"

####################################################################

source Helper.sh

#Login into Azure account and select the correct subscriptions
echo "*** 1) Make sure you are logged in to Azure"
if [[ "$LOGIN_MODE" == "service-principal" ]] ; then
    az login --service-principal --username $appId --password $password --tenant $tenant
    if [ $? -neq 0 ]; then
        echo "   [ERROR]   Login Error. Check your service-principal credential in the config.sh file. Exit program"
        exit 99
    fi    
else
    az login
fi

echo "   [OK]   Logged in Azure account"



echo "*** 2) Enable AKS for your Azure account"
az account set --subscription "$AZ_SUBSCRIPTION"
if [ $? -eq 0 ]; then
    echo "   [OK]   " $AZ_SUBSCRIPTION "subscription selected"
else
    echo "   [ERROR]   while selecting subscription" $AZ_SUBSCRIPTION ". Exit program"
    exit 101
fi


az provider register -n Microsoft.ContainerService
az provider register -n Microsoft.Compute
echo "   [OK]   Provider registred, checking when ready"

ready=0
isContainerServiceReady=0
isComputeReady=0
counter=1

while [ $ready -eq 0 ]
do
   echo -n "."
   counter=$(( $counter + 1 ))

   #Timeout escaping the script with error
   if [[ $counter -gt $TIME_OUT ]] ; then              
       echo "Timeout while waiting provider registation status ready"
       exit 100
   fi

   #Checking Microsoft.ContainerService and Microsoft.Compute registration status
   ContainerService=$(az provider show -n Microsoft.ContainerService | grep registrationState | awk '{print $2}' | awk -F'"' '{print $2}')
   Compute=$(az provider show -n Microsoft.Compute | grep registrationState | awk '{print $2}' | awk -F'"' '{print $2}')
   if [[ "$ContainerService" == "Registered" && $isContainerServiceReady -eq 0 ]] ;  then
       isContainerServiceReady=1
       echo " "
       echo "   [OK]   Microsoft.ContainerService registration suceed!"
   fi

   if [[ "$Compute" == "Registered"  && $isComputeReady -eq 0 ]] ;  then
       isComputeReady=1
       echo " "
       echo "   [OK]   Microsoft.Compute registration suceed!"
   fi   

   if [[ $isComputeReady -eq 1 && $isContainerServiceReady -eq 1 ]] ; then
       echo "   [OK]   Both component registration suceed. go to next step"
       ready=1
   fi
done


echo "*** 3) Create a Resource Group"
az group create --name $AZ_RESOURCE_GROUP_NAME --location $AZ_LOCATION
if [ $? -eq 0 ]; then
    echo "   [OK]   Resource group "$AZ_RESOURCE_GROUP_NAME" has been created in "$AZ_LOCATION
else
    echo "   [ERROR]   while selecting resource group" $AZ_RESOURCE_GROUP_NAME "in region $AZ_LOCATION. Exit program"
    exit 101
fi


echo "*** 4) Create the Cluster"
echo "***    This command will take around 15-20 minutes to run. You can also monitor progress in the Azure Portal."
az aks create \
    --resource-group $AZ_RESOURCE_GROUP_NAME \
    --name $AZ_CLUSTER_NAME \
    --node-count $AZ_NODE_COUNT \
    --generate-ssh-keys \
    --node-vm-size $AZ_VM_SIZE
if [ $? -eq 0 ]; then
    echo "   [OK]   Cluster creation complete"
else
    echo "   [ERROR]   while selecting Cluster Exit program"
    exit 101
fi



echo "*** 5) Get Credentials and Configure kubectl"
az aks get-credentials --resource-group=$AZ_RESOURCE_GROUP_NAME --name=$AZ_CLUSTER_NAME --overwrite-existing
if [ $? -eq 0 ]; then
    echo "   [OK]   Credential acquired"
else
    echo "   [ERROR]   while getting credential. Exit Program"
    exit 101
fi



echo "*** 6) Role Based Access Control (RBAC)"
kubectl create -f ./rbac-config.yaml
echo "   [OK]   Service account for Tiller created and binded it to the ClusterRole"
helm init --upgrade --service-account tiller --wait
if [ $? -eq 0 ]; then
    echo "   [OK]   HELM initialized"
else
    echo "   [ERROR]   while initializing HELM. Exit Program"
    exit 101
fi

echo "Looking for resource group "$AZ_DEFAULT_RESOURCE_GROUP
foundResourceGroup=$(az group list -o table | grep $AZ_DEFAULT_RESOURCE_GROUP | wc -l)
if [[  $foundResourceGroup -eq 1 ]] ;  then
    echo "   [OK]   Resource group found"
else 
    echo "   [OK]   [WARNING] Default Resource group not found. Please insert the name"
    exit 101
fi


echo "*** 7) Create a Storage Account"
az storage account create -g $AZ_DEFAULT_RESOURCE_GROUP -n $AZ_ACCOUNT_NAME --sku $AZ_SKU_TYPES
if [ $? -eq 0 ]; then
    echo "   [OK]   Storage Account created"
else
    echo "   [ERROR]   while creating Storage account. Exit Program"
    exit 101
fi


echo "*** 8) Azure Storage"
kubectl create clusterrole system:azure-cloud-provider --verb=get,create --resource=secrets
if [ $? -eq 0 ]; then
    echo "   [OK]   Cluster role that can create secrets created"
else
    echo "   [ERROR]   while creating custom role. Exit Program"
    exit 101
fi


kubectl create clusterrolebinding system:azure-cloud-provider --clusterrole=system:azure-cloud-provider --serviceaccount=kube-system:persistent-volume-binder
if [ $? -eq 0 ]; then
    echo "   [OK]   Cluster role binded"
else
    echo "   [ERROR]   while creating cluster binding. Exit Program"
    exit 101
fi



kubectl apply -f azure-sc.yaml
echo "   [OK]   Class Storage Created"

echo "*** 9) Install QSEoK"
helm repo add qlik https://qlik.bintray.com/stable
if [ $? -eq 0 ]; then
    echo "   [OK]   Add Qlik stable repo to helm"
else
    echo "   [ERROR]   while adding Qlik Stable repo to HELM. Exit Program"
    exit 101
fi


helm repo update
echo "   [OK]   Update helm repos"
helm install --name qliksense-init qlik/qliksense-init
if [ $? -eq 0 ]; then
    echo "   [OK]   Custom resource definitions used by dynamic engines installed"
else
    echo "   [ERROR]   while installing custom resource definition. Exit Program"
    exit 101
fi


helm install -n qliksense qlik/qliksense -f ./values.yaml
if [ $? -eq 0 ]; then
    echo "   [OK]   Qlik Sense Engine package installed"
else
    echo "   [ERROR]   while installing qliksense. Exit Program"
    exit 101
fi



echo "*** 10) Getting the cluster IP"
ready=0
cluster_ip="<none>"

while [[ $ready -eq 0 ]]
do
    echo -n "."
    cluster_ip=$(kubectl get services | grep LoadBalancer | awk '{print $4}')    
    if valid_ip $cluster_ip; then 
        ready=1
    fi    
done
echo " "
echo "   [OK]   Your cluster IP is "$cluster_ip" replace it in your hosts file"
az logout
echo "   [OK]   Logged out from Azure"

endTimeScript=`date +%s`
runtimeScript=$((endTimeScript-startTimeScript))

if [[ "$LOGIN_MODE" == "service-principal" ]] ; then
    #If the process is unattended send the email with the IP Address and the config file
    echo "<h1>QSEoK Cluster Creation</h1>" > $EMAIL_MESSAGE_BODY_FILE
    echo "QSEoK deployment and installation is complete in $runtimeScript. You need to add this line in your file /etc/hosts" >> $EMAIL_MESSAGE_BODY_FILE
    echo "<b>$HOST_NAME     $cluster_ip</b>" >> $EMAIL_MESSAGE_BODY_FILE
    echo " " >> $EMAIL_MESSAGE_BODY_FILE
    echo "Point your browser to <a href='https://$HOST_NAME/console'>https://$HOST_NAME/console</a> you need to login using the Auth0 application user" >> $EMAIL_MESSAGE_BODY_FILE
    echo "Once signed in, apply the license as reported below" >> $EMAIL_MESSAGE_BODY_FILE
    echo "<b>$QS_LICENSE</b>" >> $EMAIL_MESSAGE_BODY_FILE


    sendEmail -f $EMAIL_SENDER \
        -t $EMAIL_RECIPIENTS \
        -u $EMAIL_SUBJECT_CREATE \
        -o message-file=$EMAIL_MESSAGE_BODY_FILE \
        -s $EMAIL_SMTP_SERVER \
        -xu $EMAIL_USERNAME \
        -xp $EMAIL_PASSWORD \        
        -v -o tls=yes -o message-content-type=html
else
    # If the process is Supervised try to add the new hots in the /etc/host file
    echo "  Removing the hostname from /etc/hosts file"
    ./manage-etc-hosts.sh removeline $HOST_NAME
    echo "   Add the new entry to /etc/hosts file"
    ./manage-etc-hosts.sh addline $HOST_NAME $cluster_ip    
fi


echo ""
echo "type --> watch kubectl get pods <-- to check the pods' status"
echo



echo "..."
echo "Script ended in $runtimeScript. Installation complete"
