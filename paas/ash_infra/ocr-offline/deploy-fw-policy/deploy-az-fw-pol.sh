
#!/bin/bash

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

. ./../../env/env_variables_ocr$CONTAINER_REGISTRY_INSTANCE.sh

pwd


# Run below to deploy OCP Cluster Management resources
export STATENAME="oc-cr-${TF_VAR_cr_instance}-fwpol-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=ocroffline/${STATENAME}.tfstate\""

# Rule priority has to be unique per rule set

#export TF_LOG=INFO

cd ./deploy-fw-policy
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform plan
terraform apply -auto-approve

cd ..
