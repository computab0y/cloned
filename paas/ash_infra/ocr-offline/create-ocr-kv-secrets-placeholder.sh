#!/bin/bash
set -x
# Run below to deploy OC Offline Registry for offine deployments
while getopts z: option
do
  case "${option}"
  in
    z) CONTAINER_REGISTRY_INSTANCE=${OPTARG};;
  esac
done


if [ ${#CONTAINER_REGISTRY_INSTANCE} == 0 ]
then
    echo "Please specify an instance using the -z flag (e.g. -z 1)"
    exit 1
fi

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR

. ./../env/env_variables_ocr$CONTAINER_REGISTRY_INSTANCE.sh

pwd

#Retrieve the Keyvault name
az account set --subscription $MGMT_SUB
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-shared-')].name" -o tsv)
export TF_VAR_shrd_kv_name=`echo $shrd_kv_name | sed 's/\r//g'`

if [ ${#shrd_kv_name} == 0  ]
then
    echo "Unable to retrieve the Key Vault Name for the Secrets. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi

# Deploy the Firewall rule for the cluster instance
# Run below to deploy OCP Cluster Management resources
export STATENAME="oc-cr-${TF_VAR_cr_instance}-kv-secrets-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=ocroffline/${STATENAME}.tfstate\""

#export TF_LOG=INFO

cd $SCRIPT_DIR/kv-secrets
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve

cd $SCRIPT_DIR

