#!/bin/bash

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables.sh

# Run below to deploy OCP Cluster Management resources
export STATENAME="mgmt-prod-shared-${TF_VAR_location_code}"
export TF_CLI_ARGS_init="-backend-config=\"key=foundation/${STATENAME}.tfstate\""

az account set --subscription $MGMT_SUB

cd ./mgmt
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform destroy

cd ..