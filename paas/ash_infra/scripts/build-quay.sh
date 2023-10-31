#!/bin/bash

set -x
#Params here:

while getopts u:v:o:s:v:a:b:e:k:m:i:c:l:d: option
do
  case "${option}"
  in
    u) USER_ACC=${OPTARG};;
    v) OCP_VERSION=${OPTARG};;
    o) OCP_INSTANCE=${OPTARG};;
    s) PUB_SSH_KEY_BASE64=${OPTARG};;
    a) VNET_IP_ADDR_SPACE=${OPTARG};;
    b) BASE_DNS_NAME=${OPTARG};;
    e) OWNER=${OPTARG};;
    k) KEY_VAULT=${OPTARG};;
    m) MGMT_SUB=${OPTARG};;
    i) INFRA_SUB=${OPTARG};;
    c) CLUST_ENV=${OPTARG};;
    l) OCP_LOCATION=${OPTARG};;
    d) DATA_DISK_LUN=${OPTARG};;

  esac
done

#Debug
set -x
#Set the SSH timeout to something reasonable
sed -ri "s/ClientAliveCountMax 0/ClientAliveCountMax 20/g" /etc/ssh/sshd_config
sed -ri "s/ClientAliveInterval 180/ClientAliveInterval 6000/g" /etc/ssh/sshd_config
#set +x
#End Debug

# Install firewalld
systemctl stop iptables
systemctl disable iptables
yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld

#Install tmux
yum install tmux -y


export HOSTNAME=$(hostname -A | cut -d ' ' -f 1)

ARTIFACT_LOCATION="quay"
export QUAY=/$ARTIFACT_LOCATION
export OPENSHIFT_MINOR=$(echo $OCP_VERSION | cut -d '.' -f 1,2)

export OPENSHIFT_VERSION=$OCP_VERSION

# Mount Data disk


  
pvcreate /dev/disk/azure/scsi1/lun$DATA_DISK_LUN
vgcreate quayvg /dev/disk/azure/scsi1/lun$DATA_DISK_LUN
lvcreate -l 100%FREE -n quaylv quayvg
mkfs.xfs /dev/mapper/quayvg-quaylv
mkdir $QUAY
echo "/dev/mapper/quayvg-quaylv    $QUAY    xfs    defaults    0    2" >> /etc/fstab
mount $QUAY




# create directory to host ocp tools
WRK_DIR="/home/$USER_ACC"
mkdir $WRK_DIR
mkdir $WRK_DIR/ocp
OCP_DIR="$WRK_DIR/ocp/"
OCP_CLUS_DIR="${OCP_DIR}${OCP_INSTANCE}"
#mkdir $OCP_CLUS_DIR

# List of files that are required to be copied to the User directory
export file_list=( 
    "install-config.yaml" 
    "openshift-mirror.sh"
    "configure-bootstrap.sh" 
    "prep-cluster-config.sh" 
    "manifests.tar"
    "apply-catalog.sh"
    "dso-platform-main.zip"
    "dso-script.zip"
  )

for i in "${file_list[@]}"
do
   echo "file ${i}"
   #overwrite existing files with updated ones.
   rm -f "${WRK_DIR}/${i}"
   cp $i "$WRK_DIR/"
done

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

if [ ! -f /bin/opm ] 
then 
  curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/opm-linux-${OCP_VERSION}.tar.gz" --output "opm-linux-${OCP_VERSION}.tar.gz"
  tar xvf "opm-linux-${OCP_VERSION}.tar.gz" --directory /bin
  rm  -f "opm-linux-${OCP_VERSION}.tar.gz"
  chmod 755 /bin/opm
fi

if [ ! -f /bin/oc-mirror ] 
then 
  #curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/oc-mirror.tar.gz" --output "oc-mirror.tar.gz"
  curl "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.10.23/oc-mirror.tar.gz" --output "oc-mirror.tar.gz"
  tar xvf "oc-mirror.tar.gz" --directory /bin
  rm  -f "oc-mirror.tar.gz"
  chmod 755 /bin/oc-mirror
fi
# # experimental
# if [ ! -f /bin/mirror-registry ] 
# then 
#   curl -L "https://developers.redhat.com/content-gateway/rest/mirror2/pub/openshift-v4/clients/mirror-registry/latest/mirror-registry.tar.gz" --output "mirror-registry.tar.gz"
#   tar xvf "mirror-registry.tar.gz" --directory /bin
#   rm  -f "mirror-registry.tar.gz"
#   chmod 755 /bin/mirror-registry.tar.gz
# fi

set -e

# Install Azure CLI

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo

sudo dnf install azure-cli-2.29.2-1.el7 -y

#Install Git

sudo dnf install git -y

#Install zip unzip tools
sudo dnf install zip unzip -y

#Install yq

if [ ! -d usr/bin/yq  ]
then
  VERSION=v4.2.0 
  BINARY=yq_linux_amd64

  wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq 
  chmod 755 /usr/bin/yq
fi

# Install grpcurl

if [ ! -d usr/bin/grpcurl  ]
then
  VERSION=1.8.6
  BINARY=grpcurl_${VERSION}_linux_x86_64.tar.gz

  wget https://github.com/fullstorydev/grpcurl/releases/download/v${VERSION}/${BINARY} -O ${BINARY}
  tar xvf ${BINARY} --directory /usr/bin
  rm -f ${BINARY}
  chmod 755 /usr/bin/grpcurl
fi

#Explode OpenShift files

cd $OCP_DIR
# explode manifests
tar -xf $WRK_DIR/manifests.tar


#AZ CLI Login. Use VM managed identity!
while true; do 
  az login --identity --allow-no-subscriptions
  # Loop a few times. MSI doesn't seem to work when VM first created.
  if [[ "$?" -eq 0 ]]; then 
    break
  fi
  sleep 120
done

set -e
# If the Subscription cannot be connected to, quit, as other functions will not work
#az account  set --subscription $MGMT_SUB

set +e


#Remove 'non' JSON chars
#Retrieve the SPN secret from Key Vault
export AZURE_SUBSCRIPTIONID=$(az account show --query id -o tsv)
export AZURE_TENANTID=$(az account show --query homeTenantId -o tsv)
export AZURE_APPID=$( az keyvault secret show --name "DNS-SPN-APP-ID" --vault-name "${KEY_VAULT}" --query value -o tsv)
export AZURE_CLIENTSECRET=$( az keyvault secret show --name "DNS-SPN-CLIENT-SECRET" --vault-name "${KEY_VAULT}" --query value -o tsv)
export RH_USERNAME=$( az keyvault secret show --name "RH-USERNAME" --vault-name "${KEY_VAULT}" --query value -o tsv)
export RH_PASSWORD=$( az keyvault secret show --name "RH-PASSWORD" --vault-name "${KEY_VAULT}" --query value -o tsv)
export RH_REPO_USER=$( az keyvault secret show --name "RH-REPO-USER" --vault-name "${KEY_VAULT}" --query value -o tsv)
export RH_REPO_SECRET=$( az keyvault secret show --name "RH-REPO-SECRET" --vault-name "${KEY_VAULT}" --query value -o tsv)


if [ ${#AZURE_APPID} == 0 ]
then
    echo "Unable to retrieve AZURE_APPID SPN Details, is the secret set?"
    exit 1
fi 
if [ ${#AZURE_CLIENTSECRET} == 0 ]
then
    echo "Unable to retrieve AZURE_CLIENTSECRET SPN Details, is the secret set?"
    exit 1
fi 
if [ ${#RH_USERNAME} == 0 ]
then
    echo "Unable to retrieve RH-USERNAME Details, is the secret set?"
    exit 1
fi 
if [ ${#RH_PASSWORD} == 0 ]
then
    echo "Unable to retrieve RH-PASSWORD Details, is the secret set?"
    exit 1
fi 
if [ ${#RH_REPO_USER} == 0 ]
then
    echo "Unable to retrieve RH-REPO-USER Details, is the secret set?"
    exit 1
fi 
if [ ${#RH_REPO_SECRET} == 0 ]
then
    echo "Unable to retrieve RH-REPO-SECRET Details, is the secret set?"
    exit 1
fi 
SPN_DETAILS="{\"subscriptionId\":\"${AZURE_SUBSCRIPTIONID}\",\"clientId\":\"${AZURE_APPID}\",\"clientSecret\":\"${AZURE_CLIENTSECRET}\",\"tenantId\":\"${AZURE_TENANTID}\"}" >> $WRK_DIR/.azure/osServicePrincipal.json

#Retrieve the Pull Secret secret from Key Vault
export OCP_PULL_SECRET=$( az keyvault secret show --name "OCP-PULL-SECRET" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#OCP_PULL_SECRET} == 0 ]
then
    echo "Unable to retrieve OCP_PULL_SECRET Details, is the secret set?"
    exit 1
fi 

#Retrieve the Redis secret from Key Vault
export BUILD_REDIS_PW=$( az keyvault secret show --name "BUILD-REDIS-PW" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#BUILD_REDIS_PW} == 0 ]
then
    echo "Unable to retrieve BUILD_REDIS_PW Details, is the secret set?"
    exit 1
fi 

#Retrieve the PG SQL user secret from Key Vault
export BUILD_PGSQL_USER=$( az keyvault secret show --name "BUILD-pgSQL-USER" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#BUILD_PGSQL_USER} == 0 ]
then
    echo "Unable to retrieve BUILD_PGSQL_USER Details, is the secret set?"
    exit 1
fi 

#Retrieve the PG SQL password secret from Key Vault
export BUILD_PGSQL_PW=$( az keyvault secret show --name "BUILD-PGSQL-PW" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#BUILD_PGSQL_PW} == 0 ]
then
    echo "Unable to retrieve BUILD_PGSQL_PW Details, is the secret set?"
    exit 1
fi 

#Retrieve the PG SQL Admin password secret from Key Vault
export BUILD_PGSQL_ADMIN_PW=$( az keyvault secret show --name "BUILD-PGSQL-ADMIN-PW" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#BUILD_PGSQL_ADMIN_PW} == 0 ]
then
    echo "Unable to retrieve BUILD_PGSQL_ADMIN_PW Details, is the secret set?"
    exit 1
fi 

#Retrieve the Build Quay username secret from Key Vault
export quay_username=$( az keyvault secret show --name "BUILD-quay-username" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#quay_username} == 0 ]
then
    echo "Unable to retrieve BUILD-quay-username Details, is the secret set?"
    exit 1
fi 

#Retrieve the Build Quay username secret from Key Vault
export quay_password=$( az keyvault secret show --name "BUILD-quay-password" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#quay_password} == 0 ]
then
    echo "Unable to retrieve quay_password Details, is the secret set?"
    exit 1
fi 

#Retrieve the Build Quay email username secret from Key Vault
export quay_email=$( az keyvault secret show --name "BUILD-quay-email" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#quay_email} == 0 ]
then
    echo "Unable to retrieve quay_email Details, is the secret set?"
    exit 1
fi 

#Retrieve the GitHub PAT from Key Vault
export BUILD_GH_PAT=$( az keyvault secret show --name "BUILD-GH-PAT" --vault-name "${KEY_VAULT}" --query value -o tsv)

if [ ${#BUILD_GH_PAT} == 0 ]
then
    echo "Unable to retrieve BUILD-GH-PAT Details, is the secret set?"
    exit 1
fi 

#Remove 'non' JSON chars
export OCP_PULL_SECRET=$(echo $OCP_PULL_SECRET | sed -r  's|\\\"|\"|g')


# Generate root CA for self-signed

if [ ! -d /home/$USER_ACC/ssl ]
then
  mkdir /home/$USER_ACC/ssl

  openssl genrsa -out /home/$USER_ACC/ssl/rootCA.key 4096
  openssl req -x509 -new -nodes -key /home/$USER_ACC/ssl/rootCA.key -sha256 -days 1024 -out /home/$USER_ACC/ssl/rootCA.pem -subj "/C=GB/ST=Reading/L=TVP/O=Microsoft/OU=CSU/CN=$HOSTNAME"

  openssl genrsa -out /home/$USER_ACC/ssl/ssl.key 4096
  openssl req -new -key /home/$USER_ACC/ssl/ssl.key -out /home/$USER_ACC/ssl/ssl.csr -subj "/C=GB/ST=Reading/L=TVP/O=Microsoft/OU=CSU/CN=$HOSTNAME"

  # Generate self-signed SSL cer

  cat > /home/$USER_ACC/ssl/openssl.cnf<< EOF
    [req]
    req_extensions = v3_req
    distinguished_name = req_distinguished_name
    [req_distinguished_name]
    [ v3_req ]
    basicConstraints = CA:FALSE
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = $HOSTNAME
    DNS.2 = $(hostname)
    DNS.3 = $(hostname -f)
    DNS.4 = $(hostname).internal.cloudapp.net
    IP.1 = $(ifconfig eth0 | grep "inet " | awk '{print $2}')
EOF

  openssl x509 -req -in /home/$USER_ACC/ssl/ssl.csr -CA /home/$USER_ACC/ssl/rootCA.pem -CAkey /home/$USER_ACC/ssl/rootCA.key -CAcreateserial -out /home/$USER_ACC/ssl/ssl.cert -days 356 -extensions v3_req -extfile /home/$USER_ACC/ssl/openssl.cnf

  mkdir -p /etc/containers/certs.d/$(echo -n $HOSTNAME)/
  cp -f /home/$USER_ACC/ssl/rootCA.pem /etc/containers/certs.d/$(echo -n $HOSTNAME)/ca.crt
  cp -f /home/$USER_ACC/ssl/rootCA.pem /etc/pki/ca-trust/source/anchors/rootCA.pem
  /bin/update-ca-trust extract
fi

# https://access.redhat.com/documentation/en-us/red_hat_quay/3.6/html/deploy_red_hat_quay_for_proof-of-concept_non-production_purposes/getting_started_with_red_hat_quay#using_podman

# Register for access to the public repo
/sbin/subscription-manager register --username=$RH_USERNAME --password="$RH_PASSWORD" --auto-attach
sleep 5
/sbin/subscription-manager refresh
sleep 10
/sbin/subscription-manager repos --enable="rhocp-$OPENSHIFT_MINOR-for-rhel-8-x86_64-rpms"
/bin/yum -y install podman git java-1.8.0-openjdk-devel
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
/bin/yum -y install terraform
/bin/yum -y install skopeo

/bin/podman login registry.redhat.io --username $RH_USERNAME --password $RH_PASSWORD

# Setup postgres / Redis
# Firewall rules
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --permanent --add-port=5433/tcp
firewall-cmd --permanent --add-port=6379/tcp
firewall-cmd --reload


# iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# iptables -A INPUT -p tcp --dport 443 -j ACCEPT
# iptables -A INPUT -p tcp --dport 5432 -j ACCEPT
# iptables -A INPUT -p tcp --dport 5433 -j ACCEPT
# iptables -A INPUT -p tcp --dport 6379 -j ACCEPT
# service iptables save
# service iptables reload

podman container exists postgresql-quay
if [ $? -ne 0 ]
then 
    mkdir -p $QUAY/postgres-quay
    setfacl -m u:26:-wx $QUAY/postgres-quay
    /bin/podman run -d --restart=always --name postgresql-quay -e POSTGRESQL_USER=$BUILD_PGSQL_USER -e POSTGRESQL_PASSWORD=$BUILD_PGSQL_PW -e POSTGRESQL_DATABASE=quay -e POSTGRESQL_ADMIN_PASSWORD=$BUILD_PGSQL_ADMIN_PW -p 5432:5432 -v $QUAY/postgres-quay:/var/lib/pgsql/data:Z registry.redhat.io/rhel8/postgresql-10:1
fi

podman container exists redis
if [ $? -ne 0 ]
then
 /bin/podman run -d --restart=always --name redis -p 6379:6379 -e REDIS_PASSWORD=$BUILD_REDIS_PW registry.redhat.io/rhel8/redis-5:1
fi

podman container exists quay
if [ $? -ne 0 ]
then
    #Wait for these to come up
    sleep 5
    #/bin/podman run --rm -it --name quay_config -p 80:8080 -p 443:8443 registry.redhat.io/quay/quay-rhel8:v3.6.1 config secret
    mkdir $QUAY/config
    mkdir $QUAY/storage
    setfacl -m u:1001:-wx $QUAY/storage
    cp /home/$USER_ACC/ssl/ssl.cert $QUAY/config/
    cp /home/$USER_ACC/ssl/ssl.key $QUAY/config/
    #This needs tidying
    chmod 777 $QUAY/config/ssl.*
    cat > $QUAY/config/config.yaml<< EOF
AUTHENTICATION_TYPE: Database
AVATAR_KIND: local
BITTORRENT_FILENAME_PEPPER: 92abeb42-38f4-4c47-ba0c-daa1d97f4282
BUILDLOGS_REDIS:
    host: $HOSTNAME
    password: $BUILD_REDIS_PW
    port: 6379
DATABASE_SECRET_KEY: 59fde473-f7ba-459d-9667-6c11c02f65a3
DB_CONNECTION_ARGS: {}
DB_URI: postgresql://$BUILD_PGSQL_USER:$BUILD_PGSQL_PW@$HOSTNAME/quay
DEFAULT_TAG_EXPIRATION: 2w
DISTRIBUTED_STORAGE_CONFIG:
    default:
        - LocalStorage
        - storage_path: /datastorage/registry
DISTRIBUTED_STORAGE_DEFAULT_LOCATIONS: []
DISTRIBUTED_STORAGE_PREFERENCE:
    - default
FEATURE_ACI_CONVERSION: false
FEATURE_ACTION_LOG_ROTATION: false
FEATURE_ANONYMOUS_ACCESS: true
FEATURE_APP_REGISTRY: false
FEATURE_APP_SPECIFIC_TOKENS: true
FEATURE_BITBUCKET_BUILD: false
FEATURE_BLACKLISTED_EMAILS: false
FEATURE_BUILD_SUPPORT: false
FEATURE_CHANGE_TAG_EXPIRATION: true
FEATURE_DIRECT_LOGIN: true
FEATURE_EXTENDED_REPOSITORY_NAMES: true
FEATURE_FIPS: false
FEATURE_GITHUB_BUILD: false
FEATURE_GITHUB_LOGIN: false
FEATURE_GITLAB_BUILD: false
FEATURE_GOOGLE_LOGIN: false
FEATURE_INVITE_ONLY_USER_CREATION: false
FEATURE_MAILING: false
FEATURE_NONSUPERUSER_TEAM_SYNCING_SETUP: false
FEATURE_PARTIAL_USER_AUTOCOMPLETE: true
FEATURE_PROXY_STORAGE: false
FEATURE_REPO_MIRROR: false
FEATURE_REQUIRE_TEAM_INVITE: true
FEATURE_RESTRICTED_V1_PUSH: true
FEATURE_SECURITY_NOTIFICATIONS: false
FEATURE_SECURITY_SCANNER: false
FEATURE_SIGNING: false
FEATURE_STORAGE_REPLICATION: false
FEATURE_TEAM_SYNCING: false
FEATURE_USER_CREATION: false
FEATURE_USER_INITIALIZE: true
FEATURE_USER_LAST_ACCESSED: true
FEATURE_USER_LOG_ACCESS: false
FEATURE_USER_METADATA: false
FEATURE_USER_RENAME: false
FEATURE_USERNAME_CONFIRMATION: true
FRESH_LOGIN_TIMEOUT: 10m
GITHUB_LOGIN_CONFIG: {}
GITHUB_TRIGGER_CONFIG: {}
GITLAB_TRIGGER_KIND: {}
GPG2_PRIVATE_KEY_FILENAME: signing-private.gpg
GPG2_PUBLIC_KEY_FILENAME: signing-public.gpg
LDAP_ALLOW_INSECURE_FALLBACK: false
LDAP_EMAIL_ATTR: mail
LDAP_UID_ATTR: uid
LDAP_URI: ldap://localhost
LOG_ARCHIVE_LOCATION: default
LOGS_MODEL: database
LOGS_MODEL_CONFIG: {}
MAIL_DEFAULT_SENDER: support@quay.io
MAIL_PORT: 587
MAIL_USE_AUTH: false
MAIL_USE_TLS: false
PREFERRED_URL_SCHEME: https
REGISTRY_TITLE: Project Quay
REGISTRY_TITLE_SHORT: Project Quay
REPO_MIRROR_INTERVAL: 30
REPO_MIRROR_TLS_VERIFY: true
SEARCH_MAX_RESULT_PAGE_COUNT: 10
SEARCH_RESULTS_PER_PAGE: 10
SECRET_KEY: 6d6e6998-d7d7-4cc9-aa01-f7b4c95f7594
SECURITY_SCANNER_INDEXING_INTERVAL: 30
SERVER_HOSTNAME: $HOSTNAME
SETUP_COMPLETE: true
SUPER_USERS:
    - chris
TAG_EXPIRATION_OPTIONS:
    - 0s
    - 1d
    - 1w
    - 2w
    - 4w
TEAM_RESYNC_STALE_TIME: 30m
TESTING: false
USE_CDN: false
USER_EVENTS_REDIS:
    host: $HOSTNAME
    password: $BUILD_REDIS_PW
    port: 6379
USER_RECOVERY_TOKEN_LIFETIME: 30m
USERFILES_LOCATION: default
EOF
    /bin/podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U postgres'
    /bin/podman run --restart=always -p 443:8443  -p 80:8080 --name quay --sysctl net.core.somaxconn=4096 --sysctl net.core.somaxconn=4096 -v $QUAY/config:/conf/stack:Z -v $QUAY/storage:/datastorage:Z -d registry.redhat.io/quay/quay-rhel8:v3.7.4-3
    #Wait for Quay to come up
    sleep 120

    export ACCESS_TOKEN=$(curl -X POST -k  https://$HOSTNAME/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "'"${quay_username}"'", "password":"'"${quay_password}"'", "email": "'"${quay_email}"'", "access_token": true}' | jq '.access_token' | tr -d '"')
    if [ ${#ACCESS_TOKEN} == 0 ]
    then
        echo "Cannot retrieve access token for the local Quay CR.  Has the pod started?"
        echo "check the logs from podman: podman logs: "
        echo " podman logs --tail 50 quay"
        echo "It could be that name resolution is not working within the pod"
        exit 1
    fi 
    # create systemd files for the containers
    export pod_list=( 
        "postgresql-quay" 
        "redis"
        "quay" 
      )

    for i in "${pod_list[@]}"
    do
      echo "processing pod for systemctl: ${i}"
      podman generate systemd --name $i > /etc/systemd/system/${i}.service
      systemctl enable $i
    done

    #Create repository
    curl -X POST -k https://$HOSTNAME/api/v1/repository -d '{"repo_kind": "image", "namespace": "'"${quay_username}"'", "visibility": "public", "repository": "openshift4", "description": "Openshift Disconnected Image Library"}' -H "Authorization: Bearer $ACCESS_TOKEN" -H 'Content-Type: application/json'
   

fi



# Make sure $USER_ACC can access the files.
chown $USER_ACC:$USER_ACC -R $WRK_DIR

OCP_RELEASE=$OPENSHIFT_VERSION
OCP_RELEASE_MAJOR=$OPENSHIFT_MINOR
LOCAL_REGISTRY=$HOSTNAME
LOCAL_REPOSITORY="${quay_username}/openshift4"
PRODUCT_REPO='openshift-release-dev'
LOCAL_SECRET_JSON="/home/$USER_ACC/pull-secret.json"
LOCAL_OCR_SECRET_JSON="/home/$USER_ACC/pull-secret-local.json"
RELEASE_NAME='ocp-release'
ARCHITECTURE='x86_64'
export COMPRESSED_VHD_URL=$(openshift-install coreos print-stream-json | jq -r '.architectures.x86_64.artifacts.azurestack.formats."vhd.gz".disk.location')
/usr/bin/pip3.6 install certifi --user
/usr/bin/pip3 install yq --user
cd $QUAY
mkdir offline-images
cd offline-images

file_ct=$(find /quay/offline-images/ -name azure-cli-2.34.1-1.el7.x86_64.rpm | wc -l)
if [ $file_ct == 0 ]
then
  curl -s -O -L "https://packages.microsoft.com/yumrepos/azure-cli/azure-cli-2.34.1-1.el7.x86_64.rpm"
fi

file_ct=$(find /quay/offline-images/ -name *.vhd | wc -l)
if [ $file_ct == 0 ]
then
  curl -s -O -L $COMPRESSED_VHD_URL
  echo "Extracting ${QUAY}/offline-images/*.vhd.gz"
  sudo gzip -d $QUAY/offline-images/*.vhd.gz
fi

# create the pull secret json files if they don't exist
if [ ! -f "/home/$USER_ACC/pull-secret-raw.json" ]
then
    if [ ${#ACCESS_TOKEN} == 0 ]
    then
    export ACCESS_TOKEN=$(curl -X POST -k  https://$HOSTNAME/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "'"${quay_username}"'", "password":"'"${quay_password}"'", "email": "'"${quay_email}"'", "access_token": true}' | jq '.access_token' | tr -d '"')
        if [ ${#ACCESS_TOKEN} == 0 ]
        then
            echo "Cannot retrieve access token for the local Quay CR.  Has the pod started?"
            echo "check the logs from podman: podman logs: "
            echo " podman logs --tail 50 quay"
            echo "It could be that name resolution is not working within the pod"
            exit 1
        fi
    fi 
    export B64CREDS=$(echo -n "${quay_username}:${quay_password}" | base64 -w0)
    echo $OCP_PULL_SECRET > /home/$USER_ACC/pull-secret-raw.json
    jq '.auths."'"$HOSTNAME"'".auth="'"$B64CREDS"'" | .auths."'"$HOSTNAME"'".email="'"${quay_email}"'"' /home/$USER_ACC/pull-secret-raw.json > $LOCAL_SECRET_JSON
    cat  >$LOCAL_OCR_SECRET_JSON<<EOF
{
  "auths": {
    "$HOSTNAME": {
      "auth": "$B64CREDS",
      "email": ""
    }
  }
}
EOF
fi

mkdir -p $XDG_RUNTIME_DIR/containers
cp /home/$USER_ACC/pull-secret.json $XDG_RUNTIME_DIR/containers/auth.json

### MIRROR CONFIG ###
cat > /home/$USER_ACC/imageset-config.yaml<< EOF
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
   - name: quay.io/gpte-devops-automation/gitea:latest
 operators:
   - catalog: registry.redhat.io/redhat/redhat-operator-index:v${OPENSHIFT_MINOR}
     headsOnly: false
     packages:
       - name: rhacs-operator
         startingVersion: 3.71.0
       - name: openshift-pipelines-operator-rh 
         startingVersion: 1.7.2
       - name: elasticsearch-operator
         startingVersion: 5.4.3
       - name: ocs-operator 
         startingVersion: 4.8.12
       - name: odf-operator 
         startingVersion: 4.10.5
       - name: quay-operator
         startingVersion: 3.7.4
       - name: openshift-gitops-operator
         startingVersion: 1.5.4 
       - name: jaeger-product
         startingVersion: 1.30.2 
       - name: compliance-operator
         startingVersion: 0.1.53
       - name: cluster-logging 
         startingVersion: 5.4.3
       - name: kiali-ossm 
         startingVersion: 1.48.1
       - name: servicemeshoperator 
         startingVersion: 2.1.2
       - name: file-integrity-operator 
         startingVersion: 0.1.24
       - name: rhsso-operator 
         startingVersion: 7.6.0
       - name: node-healthcheck-operator
         startingVersion: 0.2.0
       - name: node-maintenance-operator
         startingVersion: 4.10.0
       - name: amq-streams
         startingVersion: 2.1.0
       - name: service-registry-operator
         startingVersion: 2.0.6
       - name: ansible-automation-platform-operator
         startingVersion: 2.2.0
   - catalog: registry.redhat.io/redhat/certified-operator-index:v${OPENSHIFT_MINOR}
     headsOnly: false
     packages:
       - name: cloud-native-postgresql
         channels:
         - name: stable
   - catalog: quay.io/gpte-devops-automation/gitea-catalog:latest
     headsOnly: false
     packages:
       - name: gitea-operator
         startingVersion: 1.3.0
   - catalog: registry.redhat.io/redhat/community-operator-index:v${OPENSHIFT_MINOR}
     headsOnly: false
     packages:
       - name: group-sync-operator
         startingVersion: 0.0.20
storageConfig:
 local:
   path: /home/$USER_ACC/ocp 
 registry:
   imageURL: $HOSTNAME/quay/oc-mirror
   skipTLS: true 
EOF

chown $USER_ACC:$USER_ACC -R $WRK_DIR
chmod -R +w $WRK_DIR
#1=LOCAL_SECRET_JSON 2=PRODUCT_REPO 3=RELEASE_NAME 4=OCP_RELEASE 5=ARCHITECTURE 6=LOCAL_REGISTRY 7=LOCAL_REPOSITORY 

# Assume that if the log exists, the quay repo has already been set up / being setup
if [ ! -f '/root/quay_mirror.log' ];
then
   echo "tmux new-session -d -s quay-mirror "nohup bash /home/$USER_ACC/openshift-mirror.sh $LOCAL_SECRET_JSON $PRODUCT_REPO $RELEASE_NAME $OCP_RELEASE $ARCHITECTURE $LOCAL_REGISTRY $LOCAL_REPOSITORY $USER_ACC""
   tmux new-session -d -s quay-mirror "nohup bash /home/$USER_ACC/openshift-mirror.sh $LOCAL_SECRET_JSON $PRODUCT_REPO $RELEASE_NAME $OCP_RELEASE $ARCHITECTURE $LOCAL_REGISTRY $LOCAL_REPOSITORY $USER_ACC"

fi


