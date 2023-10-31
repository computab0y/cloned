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



# Run below to deploy OCP Cluster Management resources
export STATENAME="$OCP_INSTANCE-az-fw-pol-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=fwpolicy/${STATENAME}.tfstate\""
export TF_VAR_ocp_cluster_instance=$OCP_INSTANCE 
# Rule pririoty has to be unique per rule set

IP_ADDR_SPACE=$(echo $VNET_IP_ADDR_SPACE | awk -F/ '{print $1}')

oct1=$(echo $IP_ADDR_SPACE | awk -F. '{print $1}')
oct2=$(echo $IP_ADDR_SPACE | awk -F. '{print $2}')
oct3=$(echo $IP_ADDR_SPACE | awk -F. '{print $3}')
oct4=$(echo $IP_ADDR_SPACE | awk -F. '{print $4}')
mask=$(echo $IP_ADDR_SPACE | awk -F/ '{print $2}')

subnet_default="$oct1.$oct2.0.$oct4/24"
subnet_control_plane="$oct1.$oct2.1.$oct4/24"
subnet_ingress_subnet="$oct1.$oct2.2.$oct4/24"
subnet_appgw="$oct1.$oct2.4.$oct4/24"
subnet_compute_subnet="$oct1.$oct2.16.$oct4/22"

declare -i intoct2=$oct2
declare -i rule=$(( intoct2 * 100 ))
export TF_VAR_rule_priority=$rule 

export TF_LOG=INFO

#cd ./az-firewall-policy
rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan
terraform apply -auto-approve

#cd ..
