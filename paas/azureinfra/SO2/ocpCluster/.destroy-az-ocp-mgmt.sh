#!/bin/bash

# Delete the App GW
. ./../app-gw/.destroy-az-app-gw.sh

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables.sh


# Run below to destroy OCP Cluster Management resources
# Things to configure for deployment

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

az account set --subscription $MGMT_SUB
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
export TF_VAR_shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query '[].name' -o tsv)


# Need to add Firewall Rules for deployment

# Rule pririoty has to be unique per rule set
# Take the 2nd Octet, use this as base for the rule. Needs to be an Integer
declare -i intoct2=$oct2
declare -i rule=$(( intoct2 + 20000 ))
export TF_VAR_rule_priority=$rule 



STATENAME="${OCP_INSTANCE}mgmt-infra-prod-uks"

export TF_CLI_ARGS_init="-backend-config=\"key=foundation/${STATENAME}.tfstate\""
export TF_VAR_location_code=uks
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 
export TF_VAR_vnet_addr_space=$VNET_IP_ADDR_SPACE
export TF_VAR_subnet_default=$subnet_default
export TF_VAR_subnet_control_plane=$subnet_control_plane
export TF_VAR_subnet_ingress_subnet=$subnet_ingress_subnet
export TF_VAR_subnet_appgw=$subnet_appgw
export TF_VAR_subnet_compute_subnet=$subnet_compute_subnet
export TF_VAR_pub_ssh_key=$PUBLIC_SSH_KEY
#export TF_VAR_pull_secret=$OCP_PULL_SECRET


cd $SCRIPT_DIR
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform destroy

cd ..

# Need to add Firewall Rules
export STATENAME="$OCP_INSTANCE-az-fw-pol-prod-uks"

export TF_CLI_ARGS_init="-backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""
export TF_VAR_location_code=uks
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 

# Rule priority has to be unique per rule set
# Take the 2nd Octet, use this as base for the rule. Needs to be an Integer
declare -i intoct2=$oct2
declare -i rule=$(( intoct2 + 100 ))
export TF_VAR_rule_priority=$rule 


#export TF_LOG=INFO

cd ./az-firewall-policy
rm .terraform/terraform.tfstate
terraform init --upgrade
terraform destroy

cd ..

