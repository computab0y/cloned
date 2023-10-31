#!/bin/bash

set -x

ocp_instance="ocp1"
region="local"
ash_fqdn='azurestack.external'
base_domain='ocp.local'
base_domain_rg='DNS'
image_account_name='images2'
PUB_SSH_KEY=''

export sub_id=""
export cli_id="" # Get the CLient ID bu going into the portal, clicking on the App ID via IAM and copy the app id
export cli_secret=""

if [ ! -f ./Certificates.pem ]
then 
  sudo cp /var/lib/waagent/Certificates.pem ./
  sudo chmod 666 Certificates.pem
  # TODO: will need to modify the pem file on ASDK due to the additional Private key and Bag entries that errors the IPI
fi

# makes sure the corect version of OC -is set - it's the version set to use the local registry
sudo cp /quay/offline-images/openshift-install /usr/bin
sudo chmod 755 /usr/bin/openshift-install

cat Certificates.pem ./ssl/rootCA.pem > ca_bundle.pem
# add spaces to the start of each line for formatting
sed -i -e 's/^/    /' ca_bundle.pem

#just in case - modify perms for the bundle file
sudo chmod 766 ca_bundle.pem

# these vars should be setup as env variables to be used on the ASH subscription

export tenant_id="adfs"

if [ ${#sub_id} == 0 ]
then
  echo "The SubscriptionID hasn't been defined. Please set sub_id, cli_id and cli_secret"
  exit 1
fi

rhcos_image=$(find /quay/offline-images/ -name *.vhd -printf "%f\n")

mirror_address='quay.internal.cloudapp.net/quay/openshift4'
ash_region=$region
rg_name="${ocp_instance}-cluster"

pull_secret=$(<$HOME/pull-secret.json)

ca_trust_bundle=$(<$HOME/ca_bundle.pem)

if [ ${#PUB_SSH_KEY} == 0 ]
then
  echo "The PUB_SSH_KEY variable has not been set.  Please modify the script"
  exit 1
fi

chmod +w $HOME/install-config.yaml
cat > $HOME/install-config.yaml<< EOF
apiVersion: v1
baseDomain: ${base_domain}
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    azure:
      osDisk:
        diskSizeGB: 512
        diskType: ""
      type: Standard_DS3_v2
  replicas: 5
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform:
    azure:
      osDisk:
        diskSizeGB: 1024
        diskType: ""
      type: Standard_DS4_v2
  replicas: 3
imageContentSources:
- mirrors:
  - ${mirror_address}
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ${mirror_address}
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
metadata:
  creationTimestamp: null
  name: ${ocp_instance}
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  azure:
    baseDomainResourceGroupName: ${base_domain_rg}
    cloudName: AzureStackCloud
    outboundType: Loadbalancer
    region: ${ash_region}
    resourceGroupName: ${rg_name}
    armEndpoint: https://management.${ash_region}.${ash_fqdn}
    clusterOSimage: https://${image_account_name}.blob.${ash_region}.${ash_fqdn}/rhcos/${rhcos_image}  
pullSecret: '${pull_secret}'
sshKey: ${PUB_SSH_KEY}
additionalTrustBundle: |
${ca_trust_bundle}
EOF




# Create the Resource Group
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt

AshUser_env=$(az cloud show -n AzureStackUser)
if [ ${#AshUser_env} == 0 ]
then
  az cloud register -n AzureStackUser --endpoint-resource-manager "https://management.${region}.${ash_fqdn}" --suffix-storage-endpoint "${region}.${ash_fqdn}" --suffix-keyvault-dns ".vault.${region}.${ash_fqdn}"
fi
az cloud set -n AzureStackUser
az cloud update --profile 2020-09-01-hybrid
az login
az group create -l $region -g $rg_name

az group create -l $region -g $base_domain_rg

# az create the dns zone


rm -r $HOME/.azure
mkdir $HOME/.azure
echo "{\"subscriptionId\":\"${sub_id}\",\"clientId\":\"${cli_id}\",\"clientSecret\":\"${cli_secret}\",\"tenantId\":\"adfs\"}" > $HOME/.azure/osServicePrincipal.json



chmod +w $HOME/install-config.yaml
chmod +w $HOME/prep-cluster-config.sh
mkdir $HOME/ocp/$ocp_instance

cp $HOME/install-config.yaml $HOME/ocp/


cp $HOME/ocp/install-config.yaml $HOME/ocp/$ocp_instance/
openshift-install version
openshift-install create manifests --dir $HOME/ocp/$ocp_instance/


cp -r $HOME/ocp/manifests $HOME/ocp/$ocp_instance
cd $HOME/ocp/$ocp_instance/manifests

quay_release=$(openshift-install version | grep 'release image' | awk '{  print $3 }')
oc adm release extract $quay_release --credentials-requests --cloud=azure

grep -l "release.openshift.io/feature-gate" * | xargs rm -f


res_prefix=$(grep 'infrastructureName: ' $HOME/ocp/$ocp_instance/manifests/cluster-infrastructure-02-config.yml | awk '{ print $2 }')
rg=$(grep 'resourceGroupName: ' $HOME/ocp/$ocp_instance/manifests/cluster-infrastructure-02-config.yml | awk '{ print $2 }')



sed -ri "s/<subscription-id>/${sub_id}/g" *.yaml
sed -ri "s/<client-id>/${cli_id}/g" *.yaml
sed -ri "s/<client-secret>/${cli_secret}/g" *.yaml
sed -ri "s/<tenant>/${tenant_id}/g" *.yaml
sed -ri "s/<infra-id>/${res_prefix}/g" *.yaml
sed -ri "s/<resource-group>/${rg}/g" *.yaml
sed -ri "s/<region>/${region}/g" *.yaml

