#!/bin/bash

set -x
#Params here:

while getopts u:v:o:s:v:a:b:e:k:m:i:c:l:n:t:w: option
do
  case "${option}"
  in
    u) USER_ACC=${OPTARG};;
    v) OCP_VERSION=${OPTARG};;
    o) OCP_INSTANCE=${OPTARG};;
    s) PUB_SSH_KEY_BASE64=${OPTARG};;
    n) VNET_NAME=${OPTARG};;
    a) VNET_IP_ADDR_SPACE=${OPTARG};;
    b) BASE_DNS_NAME=${OPTARG};;
    e) OWNER=${OPTARG};;
    k) KEY_VAULT=${OPTARG};;
    m) MGMT_SUB=${OPTARG};;
    i) INFRA_SUB=${OPTARG};;
    c) CLUST_ENV=${OPTARG};;
    l) OCP_LOCATION=${OPTARG};;
    t) TENANT_ID=${OPTARG};;
    w) SUB_ID=${OPTARG};;

  esac
done

#Debug
set -x
#Set the SSH timeout to something reasonable
sed -ri "s/ClientAliveCountMax 0/ClientAliveCountMax 20/g" /etc/ssh/sshd_config
sed -ri "s/ClientAliveInterval 180/ClientAliveInterval 6000/g" /etc/ssh/sshd_config
/bin/systemctl restart sshd.service
#set +x
#End Debug

# sed -ri "s/ClientAliveCountMax 20/ClientAliveCountMax 0/g" /etc/ssh/sshd_config
# sed -ri "s/ClientAliveInterval 6000/ClientAliveInterval 180/g" /etc/ssh/sshd_config
#/bin/systemctl restart sshd.service



OCP_PULL_SECRET=$(echo -n $PULL_SECRET_BASE64 | base64 --decode )

PUB_SSH_KEY=$(echo -n $PUB_SSH_KEY_BASE64 | base64 --decode )

# create directory to host ocp tools
WRK_DIR="/home/$USER_ACC"
mkdir $WRK_DIR
mkdir $WRK_DIR/ocp
OCP_DIR="$WRK_DIR/ocp/"
OCP_CLUS_DIR="${OCP_DIR}${OCP_INSTANCE}"
mkdir $OCP_CLUS_DIR

export file_list=( 
  "gen-api-cert.sh" 
  "gen-apps-cert.sh" 
  "install-config.yaml" 
  "zeroSSL.cer" 
  "sectigo-aaa-root.cer" 
  "modify-manifest-secrets.sh" 
  "manifests.tar" 
  )
for i in "${file_list[@]}"
do
   echo "file ${i}"
   #overwrite existing files with updated ones.
   rm -f "${OCP_DIR}${i}"
   cp $i $OCP_DIR
done
set -e
# Update the Root CA bundle
sudo cp "${OCP_DIR}zeroSSL.cer" /etc/pki/ca-trust/source/anchors/
sudo chmod 644 /etc/pki/ca-trust/source/anchors/zeroSSL.cer 
sudo update-ca-trust extract

# Install Azure CLI

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo

# As a precaution - sometimes it does not work! Disable if previously added
set +e
dnf config-manager --set-disabled hashicorp
set -e
sudo dnf install azure-cli -y

#Install Git

sudo dnf install git -y

#Install yq

if [ ! -d usr/bin/yq  ]
then
  VERSION=v4.2.0 
  BINARY=yq_linux_amd64

  wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq 
  chmod +x /usr/bin/yq
fi

# Install Terraform - with dnf

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
set +e
sudo dnf install terraform -y
sudo dnf config-manager --set-disabled hashicorp
set -e


# with yum

# sudo yum install -y yum-utils
# sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# sudo yum -y install terraform

#Explode OpenShift files

cd $OCP_DIR

#IPI 
if [ ! -f /bin/openshift-install ] 
then 
  curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux-${OCP_VERSION}.tar.gz" --output "openshift-install-linux-${OCP_VERSION}.tar.gz"
  tar xvf "openshift-install-linux-${OCP_VERSION}.tar.gz" --directory /bin
  rm "openshift-install-linux-${OCP_VERSION}.tar.gz"
  chmod 755 /bin/openshift-install
fi
#OC CLI
if [ ! -f /usr/bin/oc ]
then
   curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz" --output "openshift-client-linux-${OCP_VERSION}.tar.gz"
   tar xvf "openshift-client-linux-${OCP_VERSION}.tar.gz" --directory /usr/bin
   rm "openshift-client-linux-${OCP_VERSION}.tar.gz"
      chmod +x /usr/bin/oc
   chmod 755 /usr/bin/oc
   chmod +x /usr/bin/kubectl
   chmod 755 /usr/bin/kubectl
fi

#AZ CLI Login. Use VM managed identity!
while true; do 
  az login --identity --allow-no-subscriptions
  # Loop a few times. MSI doesn't seem to work when VM first created.
  if [[ "$?" -eq 0 ]]; then 
    break
  fi
  sleep 120
done

set +e
# If the Subscription cannot be connected to, quit, as other functions will not work
# az account  set --subscription $MGMT_SUB

set -e


#Remove 'non' JSON chars
#Retrieve the SPN secret from Key Vault
export AZURE_SUBSCRIPTIONID=$SUB_ID
export AZURE_TENANTID=$TENANT_ID
export AZURE_APPID=$( az keyvault secret show --name "OCP-SPN-APP-ID" --vault-name "${KEY_VAULT}" --query value -o tsv)
export AZURE_CLIENTSECRET=$( az keyvault secret show --name "OCP-SPN-CLIENT-SECRET" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#AZURE_APPID} == 0 ]
then
    echo "Unable to retrieve OCP-SPN-APP-ID SPN Details, is the secret set?"
    exit 1
fi 
if [ ${#AZURE_CLIENTSECRET} == 0 ]
then
    echo "Unable to retrieve OCP-SPN-CLIENT-SECRET SPN Details, is the secret set?"
    exit 1
fi 

SPN_DETAILS="{\"subscriptionId\":\"${AZURE_SUBSCRIPTIONID}\",\"clientId\":\"${AZURE_APPID}\",\"clientSecret\":\"${AZURE_CLIENTSECRET}\",\"tenantId\":\"${AZURE_TENANTID}\"}"



#Retrieve the Pull Secret secret from Key Vault
export OCP_PULL_SECRET=$( az keyvault secret show --name "OCP-PULL-SECRET" --vault-name "${KEY_VAULT}" --query value)

if [ ${#OCP_PULL_SECRET} == 0 ]
then
    echo "Unable to retrieve OCP_PULL_SECRET Details, is the secret set?"
    exit 1
fi 

#Remove 'non' JSON chars
export OCP_PULL_SECRET=${OCP_PULL_SECRET:1:-1} # remove first and last chars. in the KV, the secret is enclosed in "'s
#Remove 'non' JSON chars
export OCP_PULL_SECRET=$(echo $OCP_PULL_SECRET | sed -r  's|\\\"|\"|g')

#Update the install-config.yaml file

#Update Base DNS
sed -ri "s/^(\s*)(baseDomain\s*:\s*dnsName\s*$)/\1baseDomain: ${BASE_DNS_NAME}/" install-config.yaml

# Replace all references to the OCP instance
sed -ri "s/<ocpName>/${OCP_INSTANCE}/g" install-config.yaml

sed -ri "s/<env>/${CLUST_ENV}/g" install-config.yaml

#Replace the VNET Ip address space (use a different sed separator due to / in ip address)  
sed -ri "s|vnetAddressSpace|${VNET_IP_ADDR_SPACE}|g" install-config.yaml

#Update SSH Public Key
sed -ri "s|sshHere|${PUB_SSH_KEY}|g" install-config.yaml

#Update PullSecret
sed -ri "s|pullSecretHere|${OCP_PULL_SECRET}|g" install-config.yaml

#Copy the install file to the cluster instance directory
cp install-config.yaml $OCP_CLUS_DIR/

#Replace CLuster Instance ref in Apps Cert Generation script
sed -ri "s/<clusterInstanceHere>/${OCP_INSTANCE}/g" gen-apps-cert.sh
sed -ri "s/<clusterInstanceHere>/${OCP_INSTANCE}/g" gen-api-cert.sh

#Replace the owner email for registration
sed -ri "s/<owner-email>/${OWNER}/g" gen-api-cert.sh
sed -ri "s/<owner-email>/${OWNER}/g" gen-apps-cert.sh

#Replace the keyvault 
sed -ri "s/<keyvault>/${KEY_VAULT}/g" gen-api-cert.sh
sed -ri "s/<keyvault>/${KEY_VAULT}/g" gen-apps-cert.sh

#Replace the subscription refs 
sed -ri "s/<management-sub>/${MGMT_SUB}/g" gen-api-cert.sh
sed -ri "s/<management-sub>/${MGMT_SUB}/g" gen-apps-cert.sh

sed -ri "s/<infra-sub>/${INFRA_SUB}/g" gen-api-cert.sh
sed -ri "s/<infra-sub>/${INFRA_SUB}/g" gen-apps-cert.sh

#Replace the environment refs
sed -ri "s/<env>/${CLUST_ENV}/g" gen-api-cert.sh
sed -ri "s/<env>/${CLUST_ENV}/g" gen-apps-cert.sh

#Replace the location refs
sed -ri "s/<location>/${OCP_LOCATION}/g" gen-api-cert.sh
sed -ri "s/<location>/${OCP_LOCATION}/g" gen-apps-cert.sh

#Replace the HOME refs
sed -ri "s/\$HOME/\/home\/${USER_ACC}/g" gen-api-cert.sh
sed -ri "s/\$HOME/\/home\/${USER_ACC}/g" gen-apps-cert.sh
# sed -ri "s/\${HOME}/\/home\/${USER_ACC}/g" gen-api-cert.sh
# sed -ri "s/\${HOME}/\/home\/${USER_ACC}/g" gen-apps-cert.sh

#Replace details in the manifest script
sed -ri "s/<ocp_inst>/${OCP_INSTANCE}/g" modify-manifest-secrets.sh
sed -ri "s/<sub_id>/${AZURE_SUBSCRIPTIONID}/g" modify-manifest-secrets.sh
sed -ri "s/<cli_id>/${AZURE_APPID}/g" modify-manifest-secrets.sh
sed -ri "s/<cli_secret>/${AZURE_CLIENTSECRET}/g" modify-manifest-secrets.sh
sed -ri "s/<tenant_id>/${AZURE_TENANTID}/g" modify-manifest-secrets.sh

#Setup the SPN details for the IPI installer
if [ ! -d $WRK_DIR/.azure ]
then
  mkdir $WRK_DIR/.azure
fi
if [ -f $WRK_DIR/.azure/osServicePrincipal.json ]
then
  rm -r $WRK_DIR/.azure/osServicePrincipal.json
fi
echo $SPN_DETAILS > $WRK_DIR/.azure/osServicePrincipal.json

# Create Installer cmd
install_cmd="nohup openshift-install create cluster --dir=${OCP_CLUS_DIR} > ${OCP_DIR}install-cluster.sh"

cd $OCP_DIR
# explode manifests ## not needed
#tar -xf $OCP_DIR/manifests.tar

bash -c "echo ${install_cmd}"
chmod +x $OCP_DIR/install-cluster.sh
# Make sure $USER_ACC can access the files.
chown $USER_ACC:$USER_ACC -R $WRK_DIR
