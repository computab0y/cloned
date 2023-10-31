#!/bin/bash
set -x

###This script will update an existing Listener with a Certificate from Key Vault
###Kyle Wood
###2022-12-14

#Params here:
while getopts a:b:z: option
do
  case "${option}"
  in
    a) kv_cert_name=${OPTARG};;
    b) listener_name=${OPTARG};;

    z) CLUSTER_INSTANCE=${OPTARG};;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ ${#kv_cert_name} == 0  ]
then
  echo "Please set the key vault certificate name using -a flag."
  exit 1
fi
if [ ${#listener_name} == 0  ]
then
  echo "Please set the listener name using -b flag."
  exit 1
fi
if [ ${#CLUSTER_INSTANCE} == 0  ]
then
  echo "Please select a cluster instance using -z flag."
  exit 1
fi

# Import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../../env/env_variables_ocp$CLUSTER_INSTANCE.sh

# Set to the infra subscription
az account set --subscription $INFRA_SUB

# Should only be one app gw deployed per sub
export APP_GW_NAME=$(az network application-gateway list --query [].name -o tsv)
export APP_GW_RG=$(az network application-gateway list --query [].resourceGroup -o tsv)
export uai_id=$(az identity list -g $APP_GW_RG --query "[?contains(name,'appgw')].principalId" -o tsv)

# Need to set the access policy to use the AAD SPN allocated to this customer
az keyvault set-policy --name $kv_name --object-id $uai_id --secret-permissions get list --certificate-permissions get list 

# Get ID of Certificate from Key Vault
versionedId=$(az keyvault certificate show -n ${kv_cert_name} --vault-name $kv_name --query "sid" -o tsv)
unversionedId=$(echo $versionedId | cut -d'/' -f-5)

if [ ${#unversionedId} == 0  ]
then
  echo "Certificate '${kv_cert_name}' not found in Key Vault '${kv_name}'"
  exit 1
fi

# Set to the infra subscription
az account set --subscription $INFRA_SUB

# Create working dir
if [ -d "working" ]
    then rm -Rf working
fi
mkdir working
cp root-ca.cer working
cd working

# Download from Key Vault
az keyvault secret download --file cert-kv.pfx --encoding base64 --name $kv_cert_name --vault-name $kv_name

# Decrypt
openssl pkcs12 -in cert-kv.pfx -out cert-temp.pem -nodes -password pass:""

# Remove everything that isn't the Certificate or Private Key
sed -nie '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p;/-BEGIN PRIVATE KEY-/,/-END PRIVATE KEY-/p' cert-temp.pem

# Combine with root ca
cat cert-temp.pem root-ca.cer > cert-full.pem

# Encrypt and add default password
openssl pkcs12 -export -out cert-output.pfx -in cert-full.pem -password pass:"password"

# Get existing Certificate from App Gateway
export app_gw_ssl_cert=$(az network application-gateway ssl-cert list --gateway-name $APP_GW_NAME -g $APP_GW_RG --query "[?name == '${kv_cert_name}']" -o tsv)

# Update Certificate
if [ ${#app_gw_ssl_cert} == 0 ]
then
  az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${kv_cert_name}" --cert-file "cert-output.pfx" --cert-password "password"
else
  az network application-gateway ssl-cert update --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${kv_cert_name}" --cert-file "cert-output.pfx" --cert-password "password"
fi

#Tidy Up
cd ..
rm -Rf working

# Update Listener
export cust_listener=$(az network application-gateway http-listener list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${listener_name}']" -o tsv)
if [ ${#cust_listener} == 0 ]
then
  echo "Listener '${listener_name}' not found in Application Gateway '${APP_GW_NAME}'"
  exit 1
else
  az network application-gateway http-listener update \
    --name $listener_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --ssl-cert "${kv_cert_name}"
fi