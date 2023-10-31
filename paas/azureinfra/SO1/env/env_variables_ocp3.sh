#!/bin/bash
set -x

export TF_LOG="ERROR" 
# Name of the cluster instance
export OCP_INSTANCE="ocp3"
export TERRAFORM_STATE_CONTAINER_NAME="tfstatepredmgmt3"

# Identify the iACE Service Offering the cluster is deployed to.
export SERVICE_OFFERING="SO1"

#Operating Environment for the cluster
export TF_VAR_op_env="sbox"  #e.g. prod, preprod, test...

# Version of the OCP instance to install
export TF_VAR_ocp_vers="4.8.36"

# Set if a WAF Access allow list is required
export TF_VAR_waf_access_list_enabled=true

#Resource Group Tags
export TF_VAR_solution="OCP Test"
export TF_VAR_owner="daniel.mcdermott@digital.mod.uk"

#Base FQDN for the cluster. The cluster will use this name when deploying
export TF_VAR_ocp_base_dns_zone="azure.dso.digital.mod.uk"

#Location vars
export TF_VAR_location_code="uks"               #used to generate the resource names - represents location when naming resources
export LOCATION="uksouth"                       #Azure region name for deployment of resources

#VNET Address space for  Central Management 
export TF_VAR_mgmt_vnet_addr_space="10.1.0.0/16"

#VNET Address space for the OCP cluster
export VNET_IP_ADDR_SPACE="10.2.0.0/16"

export PUB_DNS_SUB='UKSC-DD-ASDT_PREDA-MGMT_SBOX_001' # Management Subscription name (SO1 PROD Sub hosts the Public DNS Zone)
export MGMT_SUB='UKSC-DD-ASDT_PREDA-MGMT_SBOX_001 '   # Management Subscription name
export INFRA_SUB='UKSC-DD-ASDT_PREDA-INFRA_SBOX_001'  # Infrastructure Subscription name

az account set --subscription $MGMT_SUB

export TF_VAR_spn_obj_name="UKSC-DD-ASDT_PREDA-INFRA_SBOX_001_1f4c_app0" # Name of the Azure AD SPN used for automation

### Only do this once. Make sure that the versions.tf files also represent the settings below
export STORAGE_ACCOUNT_NAME=$TERRAFORM_STATE_CONTAINER_NAME # storage name must be unique throughout azure. Change so the Account name does not conflict. Ensure ALL versions.tf files have this also set.

# Required for setting the AZ Firewall policy rule priority. Must be different for cluster instances
# export TF_VAR_rule_priority=600

### Do Not Change these Variables ###
export TF_VAR_resource_group_location=$LOCATION
export RESOURCE_GROUP_NAME="rg-tfstate-mgmt-${TF_VAR_location_code}"
export CONTAINER_NAME=terraform-backend
export TF_VAR_infra_sub_name=$INFRA_SUB            # Infrastructure Subscription name
export TF_VAR_mgmt_sub_name=$MGMT_SUB              # Management Subscription name
export TF_VAR_pub_dns_sub_name=$PUB_DNS_SUB        # Management Subscription name (SO1 PROD Sub hosts the Public DNS Zone)
export TF_VAR_resource_group_location=$LOCATION
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE  

STG_KEY=$(az storage account keys list -g ${RESOURCE_GROUP_NAME} -n ${TERRAFORM_STATE_CONTAINER_NAME} --query "[?keyName=='key1'].value" -o tsv)
export TF_CLI_ARGS_init="-backend-config=\"storage_account_name=${TERRAFORM_STATE_CONTAINER_NAME}\" -backend-config=\"resource_group_name=${RESOURCE_GROUP_NAME}\" -backend-config=\"access_key=${STG_KEY}\""

# get the subscription Id's
export TF_VAR_mgmt_sub_id=$(az account show --subscription ${MGMT_SUB} --query id -o tsv )

export TF_VAR_pub_dns_sub_id=$(az account show --subscription ${TF_VAR_pub_dns_sub_name} --query id -o tsv )
# remove the \r from the variable as it breaks TF
export TF_VAR_mgmt_sub_id=$(echo $TF_VAR_mgmt_sub_id | sed -r  's/\r//g')

export TF_VAR_pub_dns_sub_id=$(echo $TF_VAR_pub_dns_sub_id | sed -r  's/\r//g')

az account set --subscription $INFRA_SUB

export TF_VAR_infra_sub_id=$(az account show --subscription ${INFRA_SUB} --query id -o tsv )
export TF_VAR_infra_tenant_id=$(az account show --subscription ${INFRA_SUB} --query tenantId -o tsv )
export TF_VAR_infra_sub_id=$(echo $TF_VAR_infra_sub_id | sed -r  's/\r//g')
export TF_VAR_infra_tenant_id=$(echo $TF_VAR_infra_tenant_id | sed -r  's/\r//g')

az account set --subscription $MGMT_SUB

#Name of cluster Key Vault
export kv_name="kv-sbox-shared-e1-uks"

export lb_internal_ip="10.2.16.9"