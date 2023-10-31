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

#Retrieve the Keyvault name
az account set --subscription $MGMT_SUB
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
export TF_VAR_shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-shared-')].name" -o tsv)


export STATENAME="${OCP_INSTANCE}mgmt-dns-records-${TF_VAR_op_env}-${TF_VAR_location_code}"
export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""

pwd

cd $SCRIPT_DIR/dns-records
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve

cd ..

export KEY_VAULT=`echo $TF_VAR_shrd_kv_name | sed 's/\r//g'`


# Make sure the correct Certificate is assigned to the listener
## Make sure set to the infra subscription
az account set --subscription $INFRA_SUB

export APP_GW_NAME="appgw-${OCP_INSTANCE}-${TF_VAR_op_env}-${TF_VAR_location_code}"
export APP_GW_RG="rg-${OCP_INSTANCE}mgmt-${TF_VAR_op_env}-${TF_VAR_location_code}"

app_secret_name="${OCP_INSTANCE}-tls-app"
api_secret_name="${OCP_INSTANCE}-tls-api"
app_kvid=$(az keyvault secret list --vault-name $KEY_VAULT --query "[?name=='${app_secret_name}'].id" -o tsv)
api_kvid=$(az keyvault secret list --vault-name $KEY_VAULT --query "[?name=='${api_secret_name}'].id" -o tsv)
az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${OCP_INSTANCE}-tls-app" --key-vault-secret-id ${app_kvid}
az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${OCP_INSTANCE}-tls-api" --key-vault-secret-id ${api_kvid}


az network application-gateway http-listener update --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --name "${OCP_INSTANCE}-apps-https-lstn" --ssl-cert "${OCP_INSTANCE}-tls-app"

az network application-gateway http-listener update --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --name "${OCP_INSTANCE}-api-https-lstn" --ssl-cert "${OCP_INSTANCE}-tls-api"
## Make sure set to the MGMT subscription - leave things as we find them...
az account set --subscription $MGMT_SUB

