#!/bin/bash
exec 1>/root/quay_mirror.log 2>&1
set -x
echo $(date +"%T")
export LOCAL_SECRET_JSON=$1
export PRODUCT_REPO=$2
export RELEASE_NAME=$3
export OCP_RELEASE=$4
export ARCHITECTURE=$5
export LOCAL_REGISTRY=$6
export LOCAL_REPOSITORY=$7
export LOCAL_USER=$8
export OPENSHIFT_MINOR=$(echo $OCP_RELEASE | cut -d '.' -f 1,2)
echo $(date +"%T")
oc adm release mirror -a $LOCAL_SECRET_JSON --from=quay.io/$PRODUCT_REPO/$RELEASE_NAME:$OCP_RELEASE-$ARCHITECTURE --to=$LOCAL_REGISTRY/$LOCAL_REPOSITORY --to-release-image=$LOCAL_REGISTRY/$LOCAL_REPOSITORY:$OCP_RELEASE-$ARCHITECTURE --dry-run
echo $(date +"%T")
oc adm release mirror -a $LOCAL_SECRET_JSON --from=quay.io/$PRODUCT_REPO/$RELEASE_NAME:$OCP_RELEASE-$ARCHITECTURE --to=$LOCAL_REGISTRY/$LOCAL_REPOSITORY --to-release-image=$LOCAL_REGISTRY/$LOCAL_REPOSITORY:$OCP_RELEASE-$ARCHITECTURE
echo $(date +"%T")
# We need this so that the local registry is used rather than public.
oc adm release extract -a $LOCAL_SECRET_JSON --command=openshift-install "$LOCAL_REGISTRY/$LOCAL_REPOSITORY:$OCP_RELEASE-$ARCHITECTURE"
echo $(date +"%T")
mv -f openshift-install /quay/offline-images
chmod 755 /quay/offline-images/openshift-install
echo $(date +"%T")
#oc adm catalog mirror registry.redhat.io/redhat/redhat-operator-index:v$OPENSHIFT_MINOR $LOCAL_REGISTRY/$LOCAL_REPOSITORY -a $LOCAL_SECRET_JSON --index-filter-by-os='linux/amd64'
mkdir -p /quay/oc-mirror
chmod 777 /quay/oc-mirror

mkdir -p /quay/tmp
chmod 777 /quay/tmp
export TMPDIR=/quay/tmp


mkdir -p ~/.docker
cp /home/${LOCAL_USER}/pull-secret.json  ~/.docker/config.json
mkdir -p $XDG_RUNTIME_DIR/containers
cp /home/${LOCAL_USER}/pull-secret.json $XDG_RUNTIME_DIR/containers/auth.json

cd /quay/oc-mirror
oc-mirror --config=/home/${LOCAL_USER}/imageset-config.yaml docker://quay.internal.cloudapp.net/quay/oc-mirror --dest-skip-tls  --skip-missing --continue-on-error
echo $(date +"%T")
echo "===OC MIRROR COMPLETE==="

# DSO Containers

# Set the Quay Username password
QUAY_CREDS=$(cat /home/$LOCAL_USER/pull-secret.json | jq -r .auths | jq -r '.["quay.internal.cloudapp.net"].auth' | base64 --decode -w0 | tr -d '\n')



export image_list=( 
    "vault-enterprise:1.9.2-ent"
    "tekton-chain:v0.10.0"
    "dso-chain:latest"
    "anchore-engine:v1.1.0" 
  )

for i in "${image_list[@]}"
do
   echo "processing image: ${i}"
   podman pull dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/${i}
   podman push dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/${i} quay.internal.cloudapp.net/quay/${i} --creds $QUAY_CREDS --tls-verify=false
done

echo "===CONTAINER MIRROR COMPLETE==="
echo "====PROCESS COMPLETE. END ====="
