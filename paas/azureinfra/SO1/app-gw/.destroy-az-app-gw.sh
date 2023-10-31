#!/bin/bash

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables.sh

#Retrieve the Keyvault name
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
export TF_VAR_shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query '[].name' -o tsv)

export STATENAME="${OCP_INSTANCE}mgmt-appgw-certs-prod-uks"
export TF_CLI_ARGS_init="-backend-config=\"key=foundation/${STATENAME}.tfstate\""

pwd

#delete App-GW
export STATENAME="${OCP_INSTANCE}mgmt-appgw-prod-uks"
export TF_CLI_ARGS_init="-backend-config=\"key=foundation/${STATENAME}.tfstate\""

rm .terraform/terraform.tfstate
terraform init --upgrade
terraform destroy

#delete certs

cd ./CertGen
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform destroy

cd ..