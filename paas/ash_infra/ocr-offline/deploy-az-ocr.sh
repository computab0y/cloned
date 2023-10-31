#!/bin/bash
set -x
# Run below to deploy OC Offline Registry for offine deployments
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

. ./../env/env_variables_ocr$CONTAINER_REGISTRY_INSTANCE.sh

pwd

export TF_VAR_data_disk_lun=10
# Don't change any of the below

IP_ADDR_SPACE=$(echo $CR_VNET_IP_ADDR_SPACE | awk -F/ '{print $1}')

oct1=$(echo $IP_ADDR_SPACE | awk -F. '{print $1}')
oct2=$(echo $IP_ADDR_SPACE | awk -F. '{print $2}')
oct3=$(echo $IP_ADDR_SPACE | awk -F. '{print $3}')
oct4=$(echo $IP_ADDR_SPACE | awk -F. '{print $4}')
mask=$(echo $IP_ADDR_SPACE | awk -F/ '{print $2}')

subnet_default="$oct1.$oct2.0.$oct4/24"

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
    echo "Unable to retrieve the Key Vault Name for the Secrets. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi

# Retrieve the Public SSH key 
# Public SSH Key for the VM (Look to put into a KV Secret ?)
export PUBLIC_SSH_KEY=$( az keyvault secret show --name "OCR-${TF_VAR_cr_instance}-PUB-SSH-KEY" --vault-name "$TF_VAR_shrd_kv_name" --query value -o tsv)
if [ ${#PUBLIC_SSH_KEY} == 0  ]
then
    echo "Unable to retrieve the Public SSH Key for the VM. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi

#Retrieve the GitHub PAT from Key Vault
export BUILD_GH_PAT=$( az keyvault secret show --name "BUILD-GH-PAT" --vault-name "${shrd_kv_name}" --query value -o tsv)

if [ ${#BUILD_GH_PAT} == 0 ]
then
    echo "Unable to retrieve BUILD-GH-PAT Details, is the secret set?"
    exit 1
fi 

# Get the archive of the dso-tools repo so we can upload with our image
curl -H "Authorization: token ${BUILD_GH_PAT}" --location --remote-header-name --remote-name https://github.com/defencedigital/dso-platform/archive/refs/heads/main.zip 
mv dso-platform-main.zip $SCRIPT_DIR/../scripts


# Create the manifest tar file
cd $SCRIPT_DIR/create-manifest
terraform init -upgrade
terraform plan
terraform apply -auto-approve

# Deploy the Firewall rule for the cluster instance
# Run below to deploy OCP Cluster Management resources
export STATENAME="oc-cr-${TF_VAR_cr_instance}-fwpol-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=ocroffline/${STATENAME}.tfstate\""


declare -i intoct2=$oct2
declare -i rule=$(( intoct2 * 101 ))
export TF_VAR_rule_priority=$rule 
export TF_VAR_subnet_default_ocr=$subnet_default
export TF_VAR_subnet_default=$subnet_default

#export TF_LOG=INFO

# cd $SCRIPT_DIR/deploy-fw-policy
# pwd
# rm .terraform/terraform.tfstate
# terraform init -upgrade
# terraform plan
# terraform apply -auto-approve

# cd $SCRIPT_DIR



# Deploy Offline OCP CR VM

STATENAME="openshift-offline-cr-${TF_VAR_cr_instance}-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=ocroffline/${STATENAME}.tfstate\""
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 
export TF_VAR_vnet_addr_space_cr=$CR_VNET_IP_ADDR_SPACE
export TF_VAR_subnet_default_ocr=$subnet_default

export TF_VAR_pub_ssh_key=$PUBLIC_SSH_KEY
#export TF_VAR_pull_secret=$OCP_PULL_SECRET

cd $SCRIPT_DIR
pwd
rm .terraform/terraform.tfstate
terraform init -upgrade
#terraform plan
terraform apply -auto-approve
cd ..


# #Delete the deployment firewall ruleset
# export STATENAME="oc-cr-fwpol-${TF_VAR_op_env}-${TF_VAR_location_code}"

# export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=ocroffline/${STATENAME}.tfstate\""
# cd $SCRIPT_DIR/deploy-fw-policy
# pwd
# terraform plan
# terraform destroy -auto-approve

# cd ..