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
. ./../env/env_variables_ocr$CLUSTER_INSTANCE.sh

case $SERVICE_OFFERING in
    SO1)
        az account set --subscription $MGMT_SUB;
        ENV_ID="shared"
        ;;
    SO2)
        az account set --subscription $INFRA_SUB;
        ENV_ID="infra"
        ;;
    *)
        echo "SERVICE_OFFERING variable not set.  Must be SO1 or SO2"
        exit 1
        ;;
esac
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-${ENV_ID}-${TF_VAR_location_code}"

shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-${ENV_ID}-')].name" -o tsv)
export TF_VAR_shrd_kv_name=`echo $shrd_kv_name | sed 's/\r//g'`

if [ ${#shrd_kv_name} == 0  ]
then
    echo "Unable to retrieve the Key Vault Name for the Secret. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi
pwd

SSH_KEY_FILE=./../../azureinfra/ssh-keys/ocr-${TF_VAR_cr_instance}-priv-key.ssh
if [ -f $SSH_KEY_FILE ]
then
    az keyvault secret set --vault-name $shrd_kv_name --name ocr-${TF_VAR_cr_instance}-priv-ssh-key --file $SSH_KEY_FILE --encoding ascii
else 
    echo "$SSH_KEY_FILE not found. Make sure it is located in ../../ssh-keys directory."
fi