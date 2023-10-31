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

IP_ADDR_SPACE=$(echo $VNET_IP_ADDR_SPACE | awk -F/ '{print $1}')

oct1=$(echo $IP_ADDR_SPACE | awk -F. '{print $1}')
oct2=$(echo $IP_ADDR_SPACE | awk -F. '{print $2}')
oct3=$(echo $IP_ADDR_SPACE | awk -F. '{print $3}')
oct4=$(echo $IP_ADDR_SPACE | awk -F. '{print $4}')
mask=$(echo $IP_ADDR_SPACE | awk -F/ '{print $2}')

subnet_default="$oct1.$oct2.0.$oct4/24"
subnet_control_plane="$oct1.$oct2.1.$oct4/24"
subnet_ingress_subnet="$oct1.$oct2.2.$oct4/24"
subnet_appgw="$oct1.$oct2.4.$oct4/24"
subnet_compute_subnet="$oct1.$oct2.16.$oct4/22"


# Rule priority has to be unique per rule set
# Take the 2nd Octet, use this as base for the rule. Needs to be an Integer
declare -i intoct2=$oct2

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

# Retrieve the Public SSH key 
# Public SSH Key for the VM (Look to put into a KV Secret ?)
export PUBLIC_SSH_KEY=$( az keyvault secret show --name "${OCP_INSTANCE}-PUB-SSH-KEY" --vault-name "$TF_VAR_shrd_kv_name" --query value -o tsv)
echo $PUBLIC_SSH_KEY

echo "DEPLOY: Marketplace management"
echo "================================"

# Set up the Market place agreements or third party offer
STATENAME="mktplace-mgmt-infra-${TF_VAR_op_env}-${TF_VAR_location_code}"
export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""
cd $SCRIPT_DIR/mktplace
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve

cd $SCRIPT_DIR

# # Create the manifest tar file
# cd $SCRIPT_DIR/create-manifest
# terraform init -upgrade
# terraform plan
# terraform apply -auto-approve

# cd $SCRIPT_DIR


# Deploy the Firewall rule for the cluster instance
# Run below to deploy OCP Cluster Management resources
export STATENAME="$OCP_INSTANCE-az-fw-pol-deploy-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""


declare -i intoct2=$oct2
declare -i rule=$(( intoct2 * 10000 ))
export TF_VAR_rule_priority=$rule 
export TF_VAR_subnet_default=$subnet_default

#export TF_LOG=INFO
echo "DEPLOY: Cluster Install Firewall Resources"
echo "================================"

cd $SCRIPT_DIR/deploy-fw-policy
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve

cd $SCRIPT_DIR



# Deploy OCP mgmt RGs

STATENAME="${OCP_INSTANCE}mgmt-infra-${TF_VAR_op_env}-${TF_VAR_location_code}"

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
echo "DEPLOY: Cluster Management Resources"
echo "================================"
cd $SCRIPT_DIR
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve
cd ..


# Deploy the Firewall rule for the cluster instance
# Run below to deploy OCP Cluster Management resources
export STATENAME="$OCP_INSTANCE-az-fw-pol-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""


declare -i intoct2=$oct2
declare -i rule=$(( intoct2 * 100 ))
export TF_VAR_rule_priority=$rule 

#export TF_LOG=INFO

# echo "DEPLOY: Cluster Firewall Ruleset"
# echo "================================"
# cd $SCRIPT_DIR/../az-firewall-policy
# pwd
# rm .terraform/terraform.tfstate
# terraform init -upgrade
# terraform plan
# terraform apply -auto-approve

# cd $SCRIPT_DIR


# #Delete the deployment firewall ruleset
# export STATENAME="$OCP_INSTANCE-az-fw-pol-deploy-${TF_VAR_op_env}-${TF_VAR_location_code}"

# export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""
# cd $SCRIPT_DIR/deploy-fw-policy
# pwd
# terraform plan
# terraform destroy -auto-approve

# cd ..