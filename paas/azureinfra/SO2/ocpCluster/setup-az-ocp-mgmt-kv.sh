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


pwd
# Don't change any of the below

#Retrieve the Keyvault name
az account set --subscription $MGMT_SUB
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-shared-')].name" -o tsv)
export TF_VAR_shrd_kv_name=`echo $shrd_kv_name | sed 's/\r//g'`

if [ ${#shrd_kv_name} == 0  ]
then
    echo "Unable to retrieve the Key Vault Name for the Secret. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi



# Deploy OCP mgmt RGs

STATENAME="${OCP_INSTANCE}mgmt-infra-secrets-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 
export TF_VAR_vnet_addr_space=$VNET_IP_ADDR_SPACE
export TF_VAR_subnet_default=$subnet_default
export TF_VAR_subnet_control_plane=$subnet_control_plane
export TF_VAR_subnet_ingress_subnet=$subnet_ingress_subnet
export TF_VAR_subnet_appgw=$subnet_appgw
export TF_VAR_subnet_compute_subnet=$subnet_compute_subnet
export TF_VAR_pub_ssh_key=$PUBLIC_SSH_KEY
#export TF_VAR_pull_secret=$OCP_PULL_SECRET
echo "DEPLOY: Cluster Management KV Secrets (Blank)"
echo "================================"
cd $SCRIPT_DIR/kv-setup
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve
cd $SCRIPT_DIR


