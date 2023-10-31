#!/bin/bash
set -x

###This script will create/update a domain in the Application Gateway using the Certificate stored in Key Vault.
###Kyle Wood
###2022-11-24

#Params here:
while getopts a:b:c:z: option
do
  case "${option}"
  in
    a) kv_cert_name=${OPTARG};;
    b) base_fqdn=${OPTARG};;
    c) site_name=${OPTARG};;

    z) CLUSTER_INSTANCE=${OPTARG};;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ ${#kv_cert_name} == 0  ]
then
  echo "Please set the key vault certificate name using -b flag."
  exit 1
fi
if [ ${#base_fqdn} == 0  ]
then
  echo "Please set the base domain name using -c flag."
  exit 1
fi
if [ ${#site_name} == 0 ]
then
  site_name="*"
else
  echo "site_name parameter passed ${site_name}"
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

#Don't change
export site_fqdn="${site_name}.${base_fqdn}"
export probe_protocol='Https'
export probe_address="oauth-openshift.apps.${OCP_INSTANCE}.azure.dso.digital.mod.uk"
export probe_path='/readyz'

# Set to the infra subscription
az account set --subscription $INFRA_SUB

# Should only be one app gw deployed per sub
export APP_GW_NAME=$(az network application-gateway list --query [].name -o tsv)
export APP_GW_RG=$(az network application-gateway list --query [].resourceGroup -o tsv)

# Need to set the access policy to use the AAD SPN allocated to this customer
export uai_id=$(az identity list -g $APP_GW_RG --query "[?contains(name,'appgw')].principalId" -o tsv)
az keyvault set-policy --name $kv_name --object-id $uai_id --secret-permissions get list --certificate-permissions get list 

# Get ID of Certificate from Key Vault
versionedId=$(az keyvault certificate show -n ${kv_cert_name} --vault-name $kv_name --query "sid" -o tsv)
unversionedId=$(echo $versionedId | cut -d'/' -f-5)

if [ ${#unversionedId} == 0  ]
then
  echo "Certificate '${kv_cert_name}' not found in Key Vault '${kv_name}'"
  exit 1
fi

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

# Create probe
export cust_probe_name="${kv_cert_name}-probe"

export cust_probe=$(az network application-gateway probe list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_probe_name}']" -o tsv)
if [ ${#cust_probe} == 0 ]
then
  az network application-gateway probe create -n $cust_probe_name --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --protocol $probe_protocol --host $probe_address --match-status-codes '200-403' --path $probe_path --port 443 --interval 30 --timeout 30 --threshold 3
fi

# Create Backend pool
export cust_be_setting_name="${kv_cert_name}-pool"
export cust_be_setting=$(az network application-gateway address-pool list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_be_setting_name}']" -o tsv)
if [ ${#cust_be_setting} == 0 ]
then
  az network application-gateway address-pool create -n $cust_be_setting_name --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --servers $lb_internal_ip
fi

# Create Backend settings
export cust_http_setting_name="${kv_cert_name}-be"
export cust_http_setting=$(az network application-gateway http-settings list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_http_setting_name}']" -o tsv)
if [ ${#cust_http_setting} == 0 ]
then
  az network application-gateway http-settings create -n $cust_http_setting_name --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --port 443 --protocol $probe_protocol --probe $cust_probe_name --path '/'
fi

# Create Listener
export apps_feport_name=$(az network application-gateway frontend-port list  --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query '[?port==`443`].name' -o tsv) # HTTPS - created 
export cust_listener_name="${kv_cert_name}-lstn"
export cust_listener=$(az network application-gateway http-listener list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_listener_name}']" -o tsv)
if [ ${#cust_listener} == 0 ]
then
  az network application-gateway http-listener create \
    --name $cust_listener_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --frontend-port $apps_feport_name \
    --host-names $site_fqdn \
    --ssl-cert "${kv_cert_name}"

else
  #Update certificate
  az network application-gateway http-listener update \
    --name $cust_listener_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --ssl-cert "${kv_cert_name}"
fi

# Create rewrite rules
export cust_rewrite_route_rule_set_name="${kv_cert_name}-rewrite"
export cust_rewrite_route_rule_set=$(az network application-gateway rewrite-rule set list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name ==  '${cust_rewrite_route_rule_set_name}']" -o tsv)
if [ ${#cust_rewrite_route_rule_set} == 0 ]
then
  # Set correct client IP address in header
  az network application-gateway rewrite-rule set create \
    --name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \

  # XSS protection
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name x-xss-protection-rwr \
    --response-headers "X-XSS-Protection=1;mode=block" \
    --sequence 92

   # X-Content type options
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name x-content-type-opts-rwr \
    --response-headers "X-Content-Type-Options=nosniff" \
    --sequence 93

    # Strict transport security
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name strict-trans-sec-rwr \
    --response-headers "Strict-Transport-Security=max-age=31536000;includeSubDomains" \
    --sequence 94

   # X-Frame options
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name x-frame-opts-rwr \
    --response-headers "X-Frame-Options=ALLOW" \
    --sequence 95

   # X-Forward IP
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name x-forward-ip-rwr \
    --response-headers "X-Forwarded-For={var_client_ip}" \
    --sequence 96
fi

# Create routing rules
export cust_route_rule_name="${kv_cert_name}-rules"
export cust_route_rule=$(az network application-gateway rule list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_route_rule_name}']" -o tsv)

if [ ${#cust_route_rule} == 0 ]
then
  # Need to get a list of exisiting priorites. We need to assign on and want to make sure it is unique
  export priority_arr=($(az network application-gateway rule list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[].priority" -o tsv))
  for i in {100..2000}
  do
    if [[ ! " ${priority_arr[*]} "  =~ $i  ]]; 
    then 
      export rule_priority=$i;
      break 
    fi
  done

  az network application-gateway rule create \
    -n $cust_route_rule_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --address-pool $cust_be_setting_name \
    --http-listener $cust_listener_name \
    --http-settings $cust_http_setting_name \
    --rewrite-rule-set $cust_rewrite_route_rule_set_name \
    --priority $rule_priority
fi