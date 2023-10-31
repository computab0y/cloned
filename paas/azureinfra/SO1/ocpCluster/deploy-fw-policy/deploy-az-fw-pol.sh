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


# Run below to deploy OCP Cluster Management resources
export STATENAME="$OCP_INSTANCE-az-fw-pol-deploy-prod-uks"

export TF_CLI_ARGS_init="-backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""
export TF_VAR_location_code=uks
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 
# Rule priority has to be unique per rule set

#export TF_LOG=INFO

cd ./deploy-az-fw-policy
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform plan
terraform apply -auto-approve

cd ..
