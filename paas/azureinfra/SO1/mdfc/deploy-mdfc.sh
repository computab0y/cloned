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


# Run below to enable MS Defender for Cloud services

export STATENAME="ms-def-cloud-prod-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="-backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""

#export TF_LOG=INFO

cd ./mdfc
rm /.terraform/terraform.tfstate
terraform init --upgrade
terraform plan
terraform apply -auto-approve

cd ..
