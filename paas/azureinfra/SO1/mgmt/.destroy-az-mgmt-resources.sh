#!/bin/bash

# Run below to deploy to select OCP cluster instance
CLUSTER_INSTANCE=1
while getopts z: option
do
  case "${option}"
  in
    z) CLUSTER_INSTANCE=${OPTARG};;
  esac
done


#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables_ocp$CLUSTER_INSTANCE.sh


# Run below to deploy OCP Cluster Management resources
export STATENAME="mgmt-prod-shared-${TF_VAR_location_code}"
export TF_CLI_ARGS_init="-backend-config=\"key=foundation/${STATENAME}.tfstate\""

az account set --subscription $MGMT_SUB

cd ./mgmt
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform destroy

cd ..