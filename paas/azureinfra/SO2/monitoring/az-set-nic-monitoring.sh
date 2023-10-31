set -x
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

WKS_RG="asdt-audit"
WKS_NAME=$(az monitor log-analytics workspace list -g asdt-audit --query [].name -o tsv)
# get the subscription Id's
export TF_VAR_infra_sub_id=$(az account show --subscription ${INFRA_SUB} --query id -o tsv )

WORKSPACE_ID="/subscriptions/${TF_VAR_infra_sub_id}/resourcegroups/${WKS_RG}/providers/microsoft.operationalinsights/workspaces/${WKS_NAME}"


az account set --subscription $INFRA_SUB
NIC_IDS=$(az network nic list --query "[].id" -o tsv)

for nic_id in $NIC_IDS 
do
    echo "nic- ${nic_id}"
    az monitor diagnostic-settings create --name NIC-Diagnostics --resource $nic_id --metrics '[{"category": "AllMetrics","enabled": true}]' --workspace $WORKSPACE_ID
done
