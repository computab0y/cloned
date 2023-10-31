#!/bin/bash
set -x

export TF_LOG="ERROR" 
# Name of the cluster instance
export OCP_INSTANCE="ocp2"
export TERRAFORM_STATE_CONTAINER_NAME="tfstatepredmgmt2"

# Identify the iACE Service Offering the cluster is deployed to.
export SERVICE_OFFERING="SO2"

# Set if a WAF Access allow list is required
export TF_VAR_waf_access_list_enabled=true

# Set if a public domain allow list is required
export TF_VAR_waf_public_domains_enabled=true

#Operating Environment for the cluster
export TF_VAR_op_env="prod"  #e.g. prod, preprod, sbox, test...

# Version of the OCP instance to install
export TF_VAR_ocp_vers="4.10.15"

#Name or the KeyVault - look to automate this.... This will change when the central mgmt workflow is run and the Key Vault is created
# export TF_VAR_shrd_kv_name="kv-prod-shared-aa-uks"

#Resource Group Tags
export TF_VAR_solution="OCP Test"
export TF_VAR_owner="daniel.mcdermott@digital.mod.uk"

#Base FQDN for the cluster. The cluster will use this name when deploying
export TF_VAR_ocp_base_dns_zone="azure.dso.digital.mod.uk"

#Location vars
export TF_VAR_location_code="uks"               #used to generate the resource names - represents location when naming resources
export LOCATION="uksouth"                       #Azure region name for deployment of resources


#VNET Address space for the OCP cluster

export PUB_DNS_SUB='UKSC-DD-ASDT_PREDA-MGMT_PROD_001'# Management Subscription name
export TF_VAR_pub_dns_sub_id='233d13b4-dd1d-4d9a-926d-73332a697e07'
export INFRA_SUB='UKSC-DD-ASDT_PREDA-INFRA_PROD_002' # Infrastructure Subscription name+
export IMAGES_SUB='JFC-ISS-ASDT_Azure-Publishing_iacemodgovuk_Prod' # Golden Images Subscription Name - Prod
# export TF_VAR_spn_obj_name="UKSC-DD-ASDT_PREDA-INFRA_PROD_001_7d04_app_OCIPI0010" # Name of the Azure AD SPN used for automation

az account set --subscription $INFRA_SUB

export TF_VAR_ocp_vnet_name_rg="preda-infra-vnet"
export VNET_NAME=$(az network vnet list --resource-group $TF_VAR_ocp_vnet_name_rg --query [].name -o tsv)

export VNET_IP_ADDR_SPACE=$(az network vnet list --resource-group $TF_VAR_ocp_vnet_name_rg --query [].addressSpace.addressPrefixes[] -o tsv)
export subnet_default=$(az network vnet subnet show -n subnet1 -g $TF_VAR_ocp_vnet_name_rg --vnet-name $VNET_NAME --query addressPrefix -o tsv)
export subnet_control_plane=$(az network vnet subnet show -n subnet2 -g $TF_VAR_ocp_vnet_name_rg --vnet-name $VNET_NAME --query addressPrefix -o tsv)
export subnet_ingress_subnet=$(az network vnet subnet show -n subnet3 -g $TF_VAR_ocp_vnet_name_rg --vnet-name $VNET_NAME --query addressPrefix -o tsv)
export subnet_compute_subnet=$(az network vnet subnet show -n subnet4 -g $TF_VAR_ocp_vnet_name_rg --vnet-name $VNET_NAME --query addressPrefix -o tsv)

export assets_storage_account=$(az storage account list -g rg-${OCP_INSTANCE}mgmt-${TF_VAR_op_env}-${TF_VAR_location_code} --query "[?starts_with(name,'${OCP_INSTANCE}mg')].name" -o tsv)

# Set this if there is a pre-existing VM. Set to false if you want Terraform to create the VM
export TF_VAR_win_mgmt_vm_name=vmocp2win1produks
export TF_VAR_pre_existing_vm=true

### Only do this once. Make sure that the versions.tf files also represent the settings below
export STORAGE_ACCOUNT_NAME=$TERRAFORM_STATE_CONTAINER_NAME # storage name muust be unique throughout azure. Change so the Account name does not conflict. Ensure ALL versions.tf files have this also set.

# Required for setting the AZ Firewall policy rule priority. Must be different for cluster instances
# export TF_VAR_rule_priority=600

### Do Not Change these Variables ###
export TF_VAR_resource_group_location=$LOCATION
export RESOURCE_GROUP_NAME="rg-tfstate-infra-${TF_VAR_location_code}"
export CONTAINER_NAME=terraform-backend
export TF_VAR_infra_sub_name=$INFRA_SUB            # Infrastructure Subscription name
export TF_VAR_images_sub_name=$IMAGES_SUB          # Management Subscription name
export TF_VAR_pub_dns_sub_name=$PUB_DNS_SUB        # Management Subscription name (SO1 PROD Sub hosts the Public DNS Zone)
export TF_VAR_resource_group_location=$LOCATION
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE  
export TF_VAR_ocp_vnet_name=$VNET_NAME

STG_KEY=$(az storage account keys list -g ${RESOURCE_GROUP_NAME} -n ${TERRAFORM_STATE_CONTAINER_NAME} --query "[?keyName=='key1'].value" -o tsv)
export TF_CLI_ARGS_init="-backend-config=\"storage_account_name=${TERRAFORM_STATE_CONTAINER_NAME}\" -backend-config=\"resource_group_name=${RESOURCE_GROUP_NAME}\" -backend-config=\"access_key=${STG_KEY}\""

# get the subscription Id's
export TF_VAR_infra_sub_id=$(az account show --subscription ${INFRA_SUB} --query id -o tsv )
export TF_VAR_images_sub_id=$(az account show --subscription ${IMAGES_SUB} --query id -o tsv )
export TF_VAR_infra_tenant_id=$(az account show --subscription ${INFRA_SUB} --query homeTenantId -o tsv )
# remove the \r from the variable as it breaks TF
export TF_VAR_images_sub_id=$(echo $TF_VAR_images_sub_id | sed -r  's/\r//g')
export TF_VAR_infra_sub_id=$(echo $TF_VAR_infra_sub_id | sed -r  's/\r//g')
export TF_VAR_pub_dns_sub_id=$(echo $TF_VAR_pub_dns_sub_id | sed -r  's/\r//g')
export TF_VAR_infra_tenant_id=$(echo $TF_VAR_infra_tenant_id | sed -r  's/\r//g')

export TF_VAR_asset_sa_name=$assets_storage_account

#Name of MoD-managed Key Vault
export kv_name="kv-prod-infra-1288-uks"

export lb_internal_ip="10.79.30.9"