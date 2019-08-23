
source config.sh
echo $AZ_DEFAULT_RESOURCE_GROUP

if [[ "$LOGIN_MODE" == "service-principal" ]] ; then
    az login --service-principal --username $appId --password $password --tenant $tenant
    if [ $? -neq 0 ]; then
        echo "   [ERROR]   Login Error. Check your service-principal credential in the config.sh file. Exit program"
        exit 99
    fi    
else
    az login
fi
echo "    [OK]    You are logged in"
echo "===> Removing all Deployments"
helm del --purge qliksense qliksense-init

echo "===> Remove all resources"
az group delete -g $AZ_DEFAULT_RESOURCE_GROUP --verbose -y

#az aks delete --name qseok-clust-ves --resource-group MC_qseok_ves_qseok-clust-ves_westeurope --yes

if [[ "$LOGIN_MODE" == "service-principal" ]] ; then
    echo "<h1>QSEoK Cluster Distruction</h1>" > $EMAIL_MESSAGE_BODY_FILE
    echo "QSEoK Cluster has been destroyed" >> $EMAIL_MESSAGE_BODY_FILE

    sendEmail -f $EMAIL_SENDER \
        -t $EMAIL_RECIPIENTS \
        -u $EMAIL_SUBJECT_DESTROY \
        -o message-file=$EMAIL_MESSAGE_BODY_FILE \
        -s $EMAIL_SMTP_SERVER \
        -xu $EMAIL_USERNAME \
        -xp $EMAIL_PASSWORD \        
        -v -o tls=yes -o message-content-type=html
else
    ./manage-etc-hosts.sh removeline $HOST_NAME
    echo "   [OK]   Removed host "$HOST_NAME" from /etc/hosts file"
fi


az logout
echo "   [OK]   Logged out from Azure"