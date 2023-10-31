#!/bin/bash

# ON WSL systems, we need to mount the USB devices (for flash drives)
# make sure you are using wsl2 https://docs.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2
# install the following (assuming Ubuntu 20.04 lts):
# sudo apt update
# sudo apt upgrade
# sudo apt install linux-tools-virtual hwdata
# sudo update-alternatives --install /usr/local/bin/usbip usbip `ls /usr/lib/linux-tools/*/usbip | tail -n1` 20
# make sure wsl is upto date. (from admin powershell session,: wsl --update; wsl --shutdown)
# https://docs.microsoft.com/en-us/windows/wsl/connect-usb
export BASE_DIR=/mnt/e
exec 1>$BASE_DIR/quay_mirror.log 2>&1
set -x

# Run below to deploy OC Offline Registry for offine deployments
while getopts z: option
do
  case "${option}"
  in
    z) CONTAINER_REGISTRY_INSTANCE=${OPTARG};;
  esac
done


if [ ${#CONTAINER_REGISTRY_INSTANCE} == 0 ]
then
    echo "Please specify an instance using the -z flag (e.g. -z 1)"
    exit 1
fi

#import global Variables
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
echo $SCRIPT_DIR

. ./../env/env_variables_ocr$CONTAINER_REGISTRY_INSTANCE.sh

az account set --subscription $MGMT_SUB
RESOURCE_GROUP_NAME="rg-mgmt-${TF_VAR_op_env}-shared-${TF_VAR_location_code}"
shrd_kv_name=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query "[?starts_with(name,'kv-${TF_VAR_op_env}-shared-')].name" -o tsv)
export TF_VAR_shrd_kv_name=`echo $shrd_kv_name | sed 's/\r//g'`

if [ ${#shrd_kv_name} == 0  ]
then
    echo "Unable to retrieve the Key Vault Name for the Secrets. Please check the Key Vault has been created or that your Azure account has access"
    exit 1
fi


echo $(date +"%T")
export OCP_PULL_SECRET=$( az keyvault secret show --name "OCP-PULL-SECRET" --vault-name "${TF_VAR_shrd_kv_name}" --query value -o tsv)
echo $OCP_PULL_SECRET > $BASE_DIR/pull-secret.json
export OCP_VERSION=$TF_VAR_ocp_vers
export LOCAL_SECRET_JSON=$BASE_DIR/pull-secret.json
export PRODUCT_REPO='openshift-release-dev'
export RELEASE_NAME='ocp-release'
export OCP_RELEASE=$OCP_VERSION
export ARCHITECTURE='x86_64'
export LOCAL_REGISTRY=quay.internal.cloudapp.net
export LOCAL_REPOSITORY=quay/openshift4
export REMOVABLE_MEDIA_PATH=$BASE_DIR/mirror

export OPENSHIFT_MINOR=$(echo $OCP_RELEASE | cut -d '.' -f 1,2)

mkdir -p $BASE_DIR/mirror

cd $BASE_DIR
#OC CLI
if [ ! -f /usr/bin/oc ]
then
   curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz" --output "openshift-client-linux-${OCP_VERSION}.tar.gz"
   sudo tar xvf "openshift-client-linux-${OCP_VERSION}.tar.gz" --directory /usr/bin
   rm "openshift-client-linux-${OCP_VERSION}.tar.gz"
   sudo chmod 755 /usr/bin/oc
   sudo chmod 755 /usr/bin/kubectl
fi



cat > $BASE_DIR/imageset-config.yaml<< EOF
apiVersion: mirror.openshift.io/v1alpha1
kind: ImageSetConfiguration
archiveSize: 4 
mirror:
#  ocp:
#    channels:
#      - name: stable-${OPENSHIFT_MINOR}
#        versions:
#          - '${OCP_VERSION}' cs-operator
 additionalImages:
   - name: registry.redhat.io/ubi8/ubi:latest
 operators:
   - catalog: registry.redhat.io/redhat/redhat-operator-index:v${OPENSHIFT_MINOR}
     headsOnly: false
     packages:
       - name: rhacs-operator 
         channels:
         - name: stable
         startingVersion: 3.69.0
       - name: openshift-pipelines-operator-rh 
       - name: elasticsearch-operator 
       - name: ocs-operator 
       - name: quay-operator 
       - name: openshift-gitops-operator 
       - name: jaeger-product 
       - name: compliance-operator 
       - name: cluster-logging 
       - name: kiali-ossm 
       - name: servicemeshoperator 
       - name: file-integrity-operator 
       - name: rhsso-operator 
       - name: node-healthcheck-operator
       - name: node-maintenance-operator
   - catalog: registry.redhat.io/redhat/certified-operator-index:v${OPENSHIFT_MINOR}
     headsOnly: false
     packages:
       - name: cloud-native-postgresql
         channels:
         - name: stable
storageConfig:
 local:
   path: $BASE_DIR
EOF

mkdir -p $BASE_DIR/tmp
#export TMPDIR=$BASE_DIR/tmp

echo $(date +"%T")
#oc adm release mirror -a $LOCAL_SECRET_JSON --from=quay.io/$PRODUCT_REPO/$RELEASE_NAME:$OCP_RELEASE-$ARCHITECTURE --to=$LOCAL_REGISTRY/$LOCAL_REPOSITORY --to-release-image=$LOCAL_REGISTRY/$LOCAL_REPOSITORY:$OCP_RELEASE-$ARCHITECTURE --dry-run
echo $(date +"%T")
#oc adm release mirror -a ${LOCAL_SECRET_JSON} --to-dir=${REMOVABLE_MEDIA_PATH} quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}

echo $(date +"%T")
# We need this so that the local registry is used rather than public.
echo $(date +"%T")
# At the disconnected side, run:
## oc image mirror -a ${LOCAL_SECRET_JSON} --from-dir=${REMOVABLE_MEDIA_PATH}/mirror "file://openshift/release:${OCP_RELEASE}*" ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} 
echo $(date +"%T")
#oc adm catalog mirror registry.redhat.io/redhat/redhat-operator-index:v$OPENSHIFT_MINOR $LOCAL_REGISTRY/$LOCAL_REPOSITORY -a $LOCAL_SECRET_JSON --index-filter-by-os='linux/amd64'
mkdir -p $BASE_DIR/oc-mirror

if [ ! -f /bin/oc-mirror ] 
then 
  #curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/oc-mirror.tar.gz" --output "oc-mirror.tar.gz"
  curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.10.23/oc-mirror.tar.gz" --output "oc-mirror.tar.gz"
  sudo tar xvf "oc-mirror.tar.gz" --directory /bin
  rm  -f "oc-mirror.tar.gz"
  sudo chmod 755 /bin/oc-mirror
fi


mkdir -p ~/.docker
cp $BASE_DIR/pull-secret.json  ~/.docker/config.json
mkdir -p $XDG_RUNTIME_DIR/containers
cp $BASE_DIR/pull-secret.json $XDG_RUNTIME_DIR/containers/auth.json

cd $BASE_DIR
oc-mirror --config=$BASE_DIR/imageset-config.yaml file://mirror --dest-skip-tls  --skip-missing --continue-on-error --log-level info
echo $(date +"%T")
echo "===MIRROR COMPLETE==="


# export image_list=( 
#     "buildah" 
#     "sonarqube"
#     "vault-enterprise" 
#   )

# for i in "${image_list[@]}"
# do
#    echo "processing image: ${i}"
#    podman pull dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/${i}
#    podman push dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/${i} quay.internal.cloudapp.net/quay/${i} --creds $QUAY_CREDS --tls-verify=false
# done

# echo "===MIRROR COMPLETE==="
