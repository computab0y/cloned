set -x
export MGMT_SUB='UKSC-DD-ASDT_PREDA-MGMT_PROD_001'  # Infrastructure Subscription name
export INFRA_SUB='UKSC-DD-ASDT_PREDA-INFRA_PROD_001' # Management Subscription name

export TF_VAR_op_env="prod"  #e.g. prod, preprod, test...
export TF_VAR_location_code="uks"   


WKS_RG="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
WKS_NAME="law-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
# get the subscription Id's
export TF_VAR_mgmt_sub_id=$(az account show --subscription ${MGMT_SUB} --query id -o tsv )
export TF_VAR_infra_sub_id=$(az account show --subscription ${INFRA_SUB} --query id -o tsv )

WORKSPACE_ID="/subscriptions/${TF_VAR_mgmt_sub_id}/resourcegroups/${WKS_RG}/providers/microsoft.operationalinsights/workspaces/${WKS_NAME}"


az account set --subscription $INFRA_SUB
NIC_IDS=$(az network nic list --query "[].id" -o tsv)

for nic_id in $NIC_IDS 
do
    echo "nic- ${nic_id}"
    az monitor diagnostic-settings create --name NIC-Diagnostics --resource $nic_id --metrics '[{"category": "AllMetrics","enabled": true}]' --workspace $WORKSPACE_ID
done
