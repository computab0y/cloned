#!/bin/bash
set -x

#Params here:

while getopts z: option
do
  case "${option}"
  in
    z) CLUSTER_INSTANCE=${OPTARG};;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
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
az account set --subscription $INFRA_SUB
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-infra-${TF_VAR_location_code}"
shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-infra-')].name" -o tsv)
export TF_VAR_shrd_kv_name=`echo $shrd_kv_name | sed 's/\r//g'`

if [ ${#shrd_kv_name} == 0  ]
then
    echo "Unable to retrieve the Key Vault Name for the Secret. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi
az account set --subscription $INFRA_SUB

KEY_VAULT=$shrd_kv_name

export APP_GW_NAME=$(az network application-gateway list --query [].name -o tsv)
export APP_GW_RG=$(az network application-gateway list --query [].resourceGroup -o tsv)

app_secret_name="${OCP_INSTANCE}-tls-app"
api_secret_name="${OCP_INSTANCE}-tls-api"
app_kvid=$(az keyvault secret list --vault-name $KEY_VAULT --query "[?name=='${app_secret_name}'].id" -o tsv)
api_kvid=$(az keyvault secret list --vault-name $KEY_VAULT --query "[?name=='${api_secret_name}'].id" -o tsv)
az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${OCP_INSTANCE}-tls-app" --key-vault-secret-id ${app_kvid}
az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${OCP_INSTANCE}-tls-api" --key-vault-secret-id ${api_kvid}


#az network application-gateway http-listener update --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --name "${OCP_INSTANCE}-apps-https-lstn" --ssl-cert "${OCP_INSTANCE}-tls-app"

#az network application-gateway http-listener update --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --name "${OCP_INSTANCE}-api-https-lstn" --ssl-cert "${OCP_INSTANCE}-tls-api