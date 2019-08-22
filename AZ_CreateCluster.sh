#!/bin/bash

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

#Login into Azure account and select the correct subscriptions
echo "*** 1) Make sure you are logged in to Azure"
if [[ "$LOGIN_MODE" == "service-principal" ]] ; then
    az login --service-principal --username $appId --password $password --tenant $tenant
    if [ $? -neq 0 ]; then
        echo "   [ERROR]   Login Error. Check your service-principal credential in the config.sh file. Exit program"
        exit 99
    fi    
else
    #az login
fi

echo "   [OK]   Logged in Azure account"



echo "*** 2) Enable AKS for your Azure account"
az account set --subscription "$AZ_SUBSCRIPTION"
echo "===>" $AZ_SUBSCRIPTION "subscription selected"

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
echo "   [OK]   Resource group "$AZ_RESOURCE_GROUP_NAME" has been created in "$AZ_LOCATION

echo "*** 4) Create the Cluster"
echo "***    This command will take around 15-20 minutes to run. You can also monitor progress in the Azure Portal."
az aks create \
    --resource-group $AZ_RESOURCE_GROUP_NAME \
    --name $AZ_CLUSTER_NAME \
    --node-count $AZ_NODE_COUNT \
    --generate-ssh-keys \
    --node-vm-size $AZ_VM_SIZE

echo "   [OK]   Cluster creation complete"

echo "*** 5) Get Credentials and Configure kubectl"
az aks get-credentials --resource-group=$AZ_RESOURCE_GROUP_NAME --name=$AZ_CLUSTER_NAME --overwrite-existing
echo "   [OK]   Credential acquired"

echo "*** 6) Role Based Access Control (RBAC)"
kubectl create -f ./rbac-config.yaml
echo "   [OK]   Service account for Tiller created and binded it to the ClusterRole"
helm init --upgrade --service-account tiller --wait
echo "   [OK]   HELM initialized"

echo "Looking for resource group "$AZ_DEFAULT_RESOURCE_GROUP
foundResourceGroup=$(az group list -o table | grep $AZ_DEFAULT_RESOURCE_GROUP | wc -l)
if [[  $foundResourceGroup -eq 1 ]] ;  then
    echo "   [OK]   Resource group found"
else 
    echo "   [OK]   [WARNING] Default Resource group not found. Please insert the name"
fi


echo "*** 7) Create a Storage Account"
az storage account create -g $AZ_DEFAULT_RESOURCE_GROUP -n $AZ_ACCOUNT_NAME --sku $AZ_SKU_TYPES
echo "   [OK]   Storage Account created"

echo "*** 8) Azure Storage"
kubectl create clusterrole system:azure-cloud-provider --verb=get,create --resource=secrets
echo "   [OK]   Cluster role that can create secrets created"

kubectl create clusterrolebinding system:azure-cloud-provider --clusterrole=system:azure-cloud-provider --serviceaccount=kube-system:persistent-volume-binder
echo "   [OK]   Cluster role binded"

kubectl apply -f azure-sc.yaml
echo "   [OK]   Class Storage Created"

echo "*** 9) Install QSEoK"
helm repo add qlik https://qlik.bintray.com/stable
echo "   [OK]   Add Qlik stable repo to helm"

helm repo update
echo "   [OK]   Update helm repos"
helm install --name qliksense-init qlik/qliksense-init
echo "   [OK]   Custom resource definitions used by dynamic engines installed"

helm install -n qliksense qlik/qliksense -f ./values.yaml
echo "   [OK]   Qlik Sense Engine package installed"


echo "*** 10) Getting the cluster IP"
ready=0
cluster_ip="<none>"
loadBalancingRow=$(kubectl get services | grep LoadBalancer | awk '{print $4}' | wc -l)
# <pending>
while [[  "$cluster_ip" == "<pending>" ]]
do
    echo -n "."
    cluster_ip=$(kubectl get services | grep LoadBalancer | awk '{print $4}')    
    #loadBalancingRow=$(kubectl get services | grep LoadBalancer | awk '{print $4}' | wc -l)
    #echo "loadBalancingRow="$loadBalancingRow
done

echo "   [OK]   Your cluster IP is "$cluster_ip" replace it in your hosts file"

echo ""
echo "type --> watch kubectl get pods <-- to check the pods' status"
echo

echo "..."
echo "Script ended. Installation complete"