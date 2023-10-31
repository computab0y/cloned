#!/bin/bash
set -x

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

download_files () {
  source_url=$1
  dest_name=$2
  dest_dir=$3
  if [ ! -f $dest_dir/$dest_name ]
  then
    # Check if a redirect is used
    actual_url=$(curl --head --silent --write-out "%{redirect_url}\n" --output /dev/null $source_url)
    if [ ${#actual_url} == 0 ]
    then
      actual_url=$source_url
    fi

    curl $actual_url --output $dest_dir/$dest_name
  fi
}

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR
. ./../env/env_variables_ocp$CLUSTER_INSTANCE.sh

# Create the manifest tar file
PACKAGE_DIR_NAME=.packages
PACKAGE_DIR=$SCRIPT_DIR/$PACKAGE_DIR_NAME

if  [ ! -d $PACKAGE_DIR ]
then 
  mkdir $PACKAGE_DIR
fi
cd $PACKAGE_DIR

declare -A file_list
file_list=(
  ["googlechromestandaloneenterprise64.msi"]="https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"
  ["openshift-client-windows.zip"]="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${TF_VAR_ocp_vers}/openshift-client-windows-${TF_VAR_ocp_vers}.zip"
  ["VSCodeSetup-x64.exe"]=" https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
  ["git-scm-setup.exe"]="https://github.com/git-for-windows/git/releases/download/v2.36.1.windows.1/Git-2.36.1-64-bit.exe"
  ["github-desktop-setup.exe"]="https://central.github.com/deployments/desktop/desktop/latest/win32"
  ["ubuntu.appx"]="https://aka.ms/wslubuntu2004"
)

for file_name in ${!file_list[@]}
do 
  echo ${file_name} ${file_list[${file_name}]}
  download_files ${file_list[${file_name}]} ${file_name} $PACKAGE_DIR
done

cd $SCRIPT_DIR/create-packages
export TF_VAR_source_dir=$PACKAGE_DIR_NAME
terraform init -upgrade
terraform plan
terraform apply -auto-approve

cd $SCRIPT_DIR

STATENAME="${OCP_INSTANCE}-win-mgmt-infra-${TF_VAR_op_env}-${TF_VAR_location_code}"

export TF_CLI_ARGS_init="${TF_CLI_ARGS_init} -backend-config=\"key=foundation/${STATENAME}.tfstate\""

rm .terraform/terraform.tfstate
terraform init -upgrade
terraform plan #-out=tfplan
#terraform show -json tfplan > tfplan.json
terraform apply -auto-approve
cd $SCRIPT_DIR