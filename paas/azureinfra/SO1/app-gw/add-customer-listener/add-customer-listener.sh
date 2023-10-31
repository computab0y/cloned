#!/bin/bash
set -x

#Params here:

while getopts a:b:c:f:z: option
do
  case "${option}"
  in
    a) app_name=${OPTARG};;
    b) base_fqdn=${OPTARG};;
    c) site_name=${OPTARG};;
    f) backend_address_fqdn=${OPTARG};;
    z) CLUSTER_INSTANCE=${OPTARG};;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ ${#site_name} == 0 ]
then
  site_name="*"
else
  echo "site_name parameter passed ${site_name}"
fi
if [ ${#app_name} == 0  ]
then
  echo "Please set the app identifier using the -a flag."
  exit 1
fi
if [ ${#base_fqdn} == 0  ]
then
  echo "Please set the base domain name using -b flag."
  exit 1
fi
if [ ${#backend_address_fqdn} == 0  ]
then
  echo "Please set the backend host name for the probe using -f flag."
  exit 1
fi
if [ ${#CLUSTER_INSTANCE} == 0  ]
then
  echo "Please select a cluster instance using -z flag."
  exit 1
fi


export probe_protocol='Https' # don't change

export site_fqdn="${site_name}.${base_fqdn}" # don't change

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../../env/env_variables_ocp$CLUSTER_INSTANCE.sh

export OCP_BASE_FQDN="${OCP_INSTANCE}.${TF_VAR_ocp_base_dns_zone}"


#Retrieve the Keyvault name
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
export TF_VAR_shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-shared-')].name" -o tsv)

export KEY_VAULT=`echo $TF_VAR_shrd_kv_name | sed 's/\r//g'`


# Make sure the correct Certificate is assigned to the listener
## Make sure set to the infra subscription
az account set --subscription $INFRA_SUB


# Create the RG where the Customer specific kv will live
app_rg_name="rg-cust-${app_name}-${TF_VAR_op_env}-${TF_VAR_location_code}"
app_rg=$(az group list --query "[?name=='${app_rg_name}'].name" -o tsv)
if [ ${#app_rg} == 0 ]
then
  az group create --location $LOCATION -g $app_rg_name
  
fi

## Create Private DNS Zone

# First, need to obtain the Priv DNS Zone assigned to the cluster so we can obtain records to use in the customer Zone

export OCP_PRIV_ZONE=$(az network private-dns zone list --query "[?name =='${OCP_BASE_FQDN}'].name" -o tsv)
export OCP_PRIV_ZONE_RG=$(az network private-dns zone list --query "[?name == '${OCP_BASE_FQDN}'].resourceGroup" -o tsv)
export OCP_INGRESS_IP=$(az network private-dns record-set list -z $OCP_PRIV_ZONE -g $OCP_PRIV_ZONE_RG --query "[?name == '*.apps'].aRecords[].ipv4Address" -o tsv)
export OCP_VNET_ID=$(az network private-dns link vnet list -g $OCP_PRIV_ZONE_RG -z $OCP_PRIV_ZONE --query [].virtualNetwork.id -o tsv)

export cust_zone=$(az network private-dns zone list --query "[?name =='${base_fqdn}'].name" -o tsv)

if [ ${#cust_zone} == 0 ]
then
  az network private-dns zone create -n $base_fqdn -g $app_rg_name
fi 

# check if the a record exists in the customer zone
export cust_a_records=($(az network private-dns record-set list -z $base_fqdn -g $app_rg_name --query [].name -o tsv))

if [[ ! " ${cust_a_records[*]} " =~ ${site_name} ]]; 
then
  az network private-dns record-set a add-record -z $base_fqdn -g $app_rg_name -a $OCP_INGRESS_IP -n "${site_name}"
fi


export priv_dns_link=$(az network private-dns link vnet list -g $app_rg_name -z $base_fqdn --query "[?name == '${app_name}-network-link'].name" -o tsv)

if [ ${#priv_dns_link} == 0 ]
then
  az network private-dns link vnet create -n "${app_name}-network-link" -e false -g $app_rg_name -z $base_fqdn -v $OCP_VNET_ID
fi

# Get the keyvault id. If it does not exist, create one

cust_kv_name=$(az keyvault list --resource-group $app_rg_name --query "[?starts_with(name,'kv-${app_name}-${TF_VAR_op_env}-')].name" -o tsv)
if [ ${#cust_kv_name} == 0 ]
then
  rand_id=$(echo $RANDOM | md5sum | head -c 4; echo;)
  cust_kv_name="kv-${app_name}-${TF_VAR_op_env}-${rand_id}"
  
  az keyvault create --location $LOCATION --name $cust_kv_name -g $app_rg_name
  # set the log analytics diag settings
fi

# Need to set the access policy to use the AAD SPN allocated to this customer

# should only be one app gw deployed per sub
export APP_GW_NAME=$(az network application-gateway list --query [].name -o tsv)
export APP_GW_RG=$(az network application-gateway list --query [].resourceGroup -o tsv)


export uai_id=$(az identity list -g $APP_GW_RG --query "[?contains(name,'appgw')].principalId" -o tsv)
az keyvault set-policy --name $cust_kv_name --object-id $uai_id --secret-permissions get list --certificate-permissions get list 



listener_secret_name="${OCP_INSTANCE}-tls-${app_name}-cust-cert"

app_kvid=$(az keyvault secret list --vault-name $cust_kv_name --query "[?name=='${listener_secret_name}'].id" -o tsv)

if [ ${#app_kvid} == 0 ]
then
  # create a self-signed 'placeholder' cert to uplaod to the Key Vault
  # https://docs.microsoft.com/en-us/azure/application-gateway/self-signed-certificates
  mkdir -p ssl
  cd ssl
  ###
  openssl genrsa -out rootCA.key 4096
  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem -subj "/C=GB/ST=Wiltshire/L=Corsham/O=PREDA/OU=D2S/CN=$site_fqdn"

  openssl genrsa -out $app_name-ssl.key 4096
  openssl req -new -key $app_name-ssl.key -out $app_name-ssl.csr -subj "/C=GB/ST=Wiltshire/L=Corsham/O=PREDA/OU=D2S/CN=$site_fqdn"

  # Generate self-signed SSL cer

  cat > openssl.cnf<< EOF
    [req]
    req_extensions = v3_req
    distinguished_name = req_distinguished_name
    [req_distinguished_name]
    [ v3_req ]
    basicConstraints = CA:FALSE
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = $site_fqdn
EOF

  openssl x509 -req -in $app_name-ssl.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out $app_name-ssl.cert -days 356 -extensions v3_req -extfile openssl.cnf
  cat $app_name-ssl.key $app_name-ssl.cert > ${app_name}.key.inclprivkey.pem  
  openssl pkcs12 -export -in ${app_name}.key.inclprivkey.pem  -out ${OCP_INSTANCE}-tls-${app_name}.pfx -passout pass:
  secret_value=$(cat ${OCP_INSTANCE}-tls-${app_name}.pfx | base64)
  cd ..

  # Create the secret for the certificate
  az keyvault secret set --vault-name $cust_kv_name --name "${listener_secret_name}" --value "${secret_value}" --query id -o tsv
  app_kvid=$(az keyvault secret list --vault-name $cust_kv_name --query "[?name=='${listener_secret_name}'].id" -o tsv)

fi
export app_gw_ssl_cert=$(az network application-gateway ssl-cert list --gateway-name $APP_GW_NAME -g $APP_GW_RG --query "[?name == '${listener_secret_name}']" -o tsv)

# only update the App gw SSl cert if it does not exist
if [ ${#app_gw_ssl_cert} == 0 ]
then
  az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${listener_secret_name}" --key-vault-secret-id ${app_kvid}
fi

# create probe
export cust_probe_name="${OCP_INSTANCE}-${app_name}-cust-probe"

export cust_probe=$(az network application-gateway probe list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_probe_name}']" -o tsv)
if [ ${#cust_probe} == 0 ]
then
  az network application-gateway probe create -n $cust_probe_name --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --protocol $probe_protocol --host $backend_address_fqdn --match-status-codes '200-399' --path '/' 
fi


# Create Backend pool

export cust_be_setting_name="${OCP_INSTANCE}-${app_name}-cust-beap"
export cust_be_setting=$(az network application-gateway address-pool list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_be_setting_name}']" -o tsv)
if [ ${#cust_be_setting} == 0 ]
then
  az network application-gateway address-pool create -n $cust_be_setting_name --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --servers $backend_address_fqdn
fi

# create http settings

export cust_http_setting_name="${OCP_INSTANCE}-be-${app_name}-${probe_protocol}-cust-st"
export cust_http_setting=$(az network application-gateway http-settings list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_http_setting_name}']" -o tsv)
if [ ${#cust_http_setting} == 0 ]
then
  az network application-gateway http-settings create \
    -n $cust_http_setting_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --port 443 \
    --protocol $probe_protocol \
    --probe $cust_probe_name \
    --path '/'
fi


# Create Listener

export apps_feport_name=$(az network application-gateway frontend-port list  --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query '[?port==`443`].name' -o tsv) # HTTPS - created 
export cust_listener_name="${OCP_INSTANCE}-${app_name}-cust-lstn"
export cust_listener=$(az network application-gateway http-listener list --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME --query "[?name == '${cust_listener_name}']" -o tsv)
if [ ${#cust_listener} == 0 ]
then
  # add a waf policy as well
  az network application-gateway http-listener create \
    --name $cust_listener_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --frontend-port $apps_feport_name \
    --host-names "${site_name}.${base_fqdn}" \
    --ssl-cert $listener_secret_name
fi

# create rewrite rules

# list all rewrtie rules as CLI does not provide ability
# az network application-gateway list --query "[].rewriteRuleSets[].name" -o tsv
export cust_rewrite_route_rule_set_name="${OCP_INSTANCE}-${app_name}-cust-rewrite-set"
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
    --name ${OCP_INSTANCE}-${app_name}-cust-x-xss-protection-rwr \
    --response-headers "X-XSS-Protection=1;mode=block" \
    --sequence 92

   # X-Content type options
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name ${OCP_INSTANCE}-${app_name}-cust-x-content-type-opts-rwr \
    --response-headers "X-Content-Type-Options=nosniff" \
    --sequence 93

    # X-Content type options
  az network application-gateway rewrite-rule create \
    --rule-set-name $cust_rewrite_route_rule_set_name \
    --resource-group $APP_GW_RG \
    --gateway-name $APP_GW_NAME \
    --name ${OCP_INSTANCE}-${app_name}-cust-strict-trans-sec-rwr \
    --response-headers "Strict-Transport-Security=max-age=31536000;includeSubDomains" \
    --sequence 94
fi


# Create routing rules

export cust_route_rule_name="${OCP_INSTANCE}-${app_name}-${probe_protocol}-cust-rqrt"
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


# Create a WAF Policy

export cust_waf_policy_name="pol-appgw-${OCP_INSTANCE}-${app_name}-cust"
export cust_waf_policy=$(az network application-gateway waf-policy list --resource-group $app_rg_name  --query "[?name == '${cust_waf_policy_name}']" -o tsv)
if [ ${#cust_waf_policy} == 0 ] 
then
  az network application-gateway waf-policy create \
    --resource-group $app_rg_name \
    --name $cust_waf_policy_name \
    --location $LOCATION \
    --type OWASP \
    --version 3.2

   az network application-gateway waf-policy update \
    --resource-group $app_rg_name \
    --name $cust_waf_policy_name \
    --set policySettings.state=Enabled
  
fi

az network application-gateway waf-policy update \
    --resource-group $app_rg_name \
    --name $cust_waf_policy_name \
    --set policySettings.state=Enabled policySettings.mode=Prevention

export WAF_POL_ID=$(az network application-gateway waf-policy show -g $app_rg_name  --name ${cust_waf_policy_name}  --query id -o tsv)

# update the firewall policy assigned to the WAF

az network application-gateway http-listener update \
  --resource-group $APP_GW_RG \
  --gateway-name $APP_GW_NAME \
  --name ${cust_listener_name} \
  --waf-policy $WAF_POL_ID

###########################################################
# This section is for creating exclusions for the manged ruleset.  Use below as a template, modifying per the app requirements


# If you want to disable a managed rule outight, do this:

# REQUEST-920-PROTOCOL-ENFORCEMENT search exceptions
az network application-gateway waf-policy managed-rule rule-set update \
  --resource-group $app_rg_name \
  --policy-name $cust_waf_policy_name \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-920-PROTOCOL-ENFORCEMENT \
  --rules 920220



# REQUEST-942-APPLICATION-ATTACK-SQLI search exceptions
# Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector search \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector search \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI \
  --rule-ids 942110


# # REQUEST-942-APPLICATION-ATTACK-SQLI query exceptions
# # Remove first otherwise an error is thrown for duplicate rules
# az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-942-APPLICATION-ATTACK-SQLI 

# az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-942-APPLICATION-ATTACK-SQLI \
#   --rule-ids 942500 942490 942480 942470 942460 942450 942440 942432 942431 942430 942421 942420 942410 942400 942390 942380 942370 942361 942360 942350 942340 942330 942320 942310 942300 942290 942280 942270 942260 942251 942250 942240 942230 942220 942210 942200 942190 942180 942170 942160 942150 942140 942130 942120 942110 942100 

# # REQUEST-942-APPLICATION-ATTACK-SQLI status! exceptions
# # Remove first otherwise an error is thrown for duplicate rules
# az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector status! \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-942-APPLICATION-ATTACK-SQLI 

# az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector status! \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-942-APPLICATION-ATTACK-SQLI \
#   --rule-ids 942120 942130



# # REQUEST-941-APPLICATION-ATTACK-XSS query exceptions
# # Remove first otherwise an error is thrown for duplicate rules
# az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-941-APPLICATION-ATTACK-XSS

# az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-941-APPLICATION-ATTACK-XSS \
#   --rule-ids 941330 941340 

#   # REQUEST-933-APPLICATION-ATTACK-PHP query exceptions
#   # Remove first otherwise an error is thrown for duplicate rules
# az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-933-APPLICATION-ATTACK-PHP

# az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-933-APPLICATION-ATTACK-PHP \
#   --rule-ids 933210

#   # REQUEST-921-PROTOCOL-ATTACK query exceptions
#   # Remove first otherwise an error is thrown for duplicate rules
# az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-921-PROTOCOL-ATTACK

# az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator Equals \
#   --match-variable RequestArgNames \
#   --selector query \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-921-PROTOCOL-ATTACK \
#   --rule-ids 921151

#     # REQUEST-941-APPLICATION-ATTACK-XSS csrf-token exceptions
#   # Remove first otherwise an error is thrown for duplicate rules
# az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator StartsWith \
#   --match-variable RequestCookieNames \
#   --selector csrf-token \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-941-APPLICATION-ATTACK-XSS

# az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $app_rg_name --policy-name $cust_waf_policy_name \
#   --match-operator StartsWith \
#   --match-variable RequestCookieNames \
#   --selector csrf-token \
#   --type OWASP \
#   --version 3.2 \
#   --group-name REQUEST-941-APPLICATION-ATTACK-XSS \
#   --rule-ids 941100
