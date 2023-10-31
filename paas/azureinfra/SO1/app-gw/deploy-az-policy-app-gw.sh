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

export STATENAME="${OCP_INSTANCE}mgmt-policy-appgw-${TF_VAR_op_env}-${TF_VAR_location_code}"
export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""

pwd

cd $SCRIPT_DIR/policy-rules
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve

cd ..

# As the Terrform provider doesn't currently apply exclusions per OWASP rule, we are adding these in via az cli

az account set --subscription $INFRA_SUB

export WAF_RG="rg-ocp${CLUSTER_INSTANCE}mgmt-${TF_VAR_op_env}-${TF_VAR_location_code}"
export WAF_NAME="pol-appgw-ocp${CLUSTER_INSTANCE}-${TF_VAR_op_env}-${TF_VAR_location_code}-001"


# REQUEST-942-APPLICATION-ATTACK-SQLI search exceptions
# Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector search \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector search \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI \
  --rule-ids 942110


# REQUEST-942-APPLICATION-ATTACK-SQLI query exceptions
# Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI 

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI \
  --rule-ids 942500 942490 942480 942470 942460 942450 942440 942432 942431 942430 942421 942420 942410 942400 942390 942380 942370 942361 942360 942350 942340 942330 942320 942310 942300 942290 942280 942270 942260 942251 942250 942240 942230 942220 942210 942200 942190 942180 942170 942160 942150 942140 942130 942120 942110 942100 

# REQUEST-942-APPLICATION-ATTACK-SQLI status! exceptions
# Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector status! \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI 

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector status! \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-942-APPLICATION-ATTACK-SQLI \
  --rule-ids 942120 942130



# REQUEST-941-APPLICATION-ATTACK-XSS query exceptions
# Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-941-APPLICATION-ATTACK-XSS

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-941-APPLICATION-ATTACK-XSS \
  --rule-ids 941330 941340 

  # REQUEST-933-APPLICATION-ATTACK-PHP query exceptions
  # Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-933-APPLICATION-ATTACK-PHP

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-933-APPLICATION-ATTACK-PHP \
  --rule-ids 933210

  # REQUEST-921-PROTOCOL-ATTACK query exceptions
  # Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-921-PROTOCOL-ATTACK

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator Equals \
  --match-variable RequestArgNames \
  --selector query \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-921-PROTOCOL-ATTACK \
  --rule-ids 921151

    # REQUEST-941-APPLICATION-ATTACK-XSS csrf-token exceptions
  # Remove first otherwise an error is thrown for duplicate rules
az network application-gateway waf-policy managed-rule exclusion rule-set remove --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator StartsWith \
  --match-variable RequestCookieNames \
  --selector csrf-token \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-941-APPLICATION-ATTACK-XSS

az network application-gateway waf-policy managed-rule exclusion rule-set add --resource-group $WAF_RG --policy-name $WAF_NAME \
  --match-operator StartsWith \
  --match-variable RequestCookieNames \
  --selector csrf-token \
  --type OWASP \
  --version 3.2 \
  --group-name REQUEST-941-APPLICATION-ATTACK-XSS \
  --rule-ids 941100
