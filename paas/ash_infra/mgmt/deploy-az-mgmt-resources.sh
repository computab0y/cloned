#!/bin/bash

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables.sh

# Don't change any of the below

IP_ADDR_SPACE=$(echo $TF_VAR_mgmt_vnet_addr_space | awk -F/ '{print $1}')

oct1=$(echo $IP_ADDR_SPACE | awk -F. '{print $1}')
oct2=$(echo $IP_ADDR_SPACE | awk -F. '{print $2}')
oct3=$(echo $IP_ADDR_SPACE | awk -F. '{print $3}')
oct4=$(echo $IP_ADDR_SPACE | awk -F. '{print $4}')
mask=$(echo $IP_ADDR_SPACE | awk -F/ '{print $2}')

subnet_data="$oct1.$oct2.0.$oct4/24"
subnet_azfw="$oct1.$oct2.1.$oct4/24"
subnet_bastion="$oct1.$oct2.3.$oct4/24"

cd $SCRIPT_DIR
# Run below to deploy OCP Cluster Management resources
export STATENAME="mgmt-prod-shared-${TF_VAR_location_code}"
export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""

export TF_VAR_mgmt_subnet_data=$subnet_data
export TF_VAR_mgmt_subnet_azfw=$subnet_azfw
export TF_VAR_mgmt_subnet_bastion=$subnet_bastion

pwd
az account set --subscription $MGMT_SUB

rm .terraform/terraform.tfstate
terraform init --upgrade
terraform plan
terraform apply -auto-approve

cd ..