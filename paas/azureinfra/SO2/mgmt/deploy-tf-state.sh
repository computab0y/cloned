#!/bin/bash

# Run below to deploy to select OCP cluster instance
while getopts z: option
do
  case "${option}"
  in
    z) CLUSTER_INSTANCE=${OPTARG};;
  esac
done

if [ ${#CLUSTER_INSTANCE} == 0  ]
then
  echo "Please select a cluster instance using -z flag."
  exit 1
fi


#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables_ocp$CLUSTER_INSTANCE.sh


#assumes connected to correct sub already VIA AZ CLI
az account set --subscription $INFRA_SUB
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME


# Create the Keyvault used by the infra
STATENAME="${OCP_INSTANCE}-kv-infra-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 

echo "DEPLOY: Cluster Management Resources"
echo "================================"
cd $SCRIPT_DIR
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve
cd ..

