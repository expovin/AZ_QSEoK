#Setting script Params
###############################################################################################
# The name of the subscription to use
export AZ_SUBSCRIPTION="Visual Studio Professional"

# Timeout in seconds while waiting for some task
export TIME_OUT=300

#Azure resource group name
export AZ_RESOURCE_GROUP_NAME="<YOUR_RESOURCE_GROUP>"

# Azure Location. For the complete list of all locations type "az account list-locations"
export AZ_LOCATION="<YOUR_LOCATION>"    

# Azure Cluster name. You cannot exceed 63 characters and can only contain letters, numbers, or dashes (-).
export AZ_CLUSTER_NAME="<YOUR_CLUSTER_NAME>"

# Number of nodes in your cluster
export AZ_NODE_COUNT=2

# This is the default resource group name Azure will create
export AZ_DEFAULT_RESOURCE_GROUP="MC_"$AZ_RESOURCE_GROUP_NAME"_"$AZ_CLUSTER_NAME"_"$AZ_LOCATION

# Select the VM BOX Size.
# For the complete list of all size visit https://docs.microsoft.com/it-it/azure/virtual-machines/windows/sizes-general
# Check here for restriction with kubernetes https://docs.microsoft.com/en-us/azure/aks/quotas-skus-regions#restricted-vm-sizes
# use Standard_DS2_v2 for QSEoK
export AZ_VM_SIZE="<YOUR_VM_SIZE>"

# Azure AZ_ACCOUNT_NAME Using between 3 - 24 characters in length and use numbers and lower-case letters only
export AZ_ACCOUNT_NAME="<YOUR_ACCOUNT_NAME>"

# Azure Storage SKU type
# For Sku types please visit https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types
export AZ_SKU_TYPES="<YOUR_SKU_TYPE>"

# Copy/Paste here the QSEoK license
export QS_LICENSE="<YOUR_QSEOK_LICENSE>"

###############################################################################################
