
source config.sh
echo $AZ_DEFAULT_RESOURCE_GROUP

az group delete -g $AZ_DEFAULT_RESOURCE_GROUP --verbose -y
