#!/bin/bash
set -ex

export OCP_CLUSTER_INSTANCE="<clusterInstanceHere>"



cd $HOME
if [ ! -d $HOME/acme.sh ]
then
    git clone https://github.com/neilpang/acme.sh
fi
cd acme.sh


# Ensure the App ID has DNS Zone Contributor rights to the DNS Zone

export APP_GW_NAME="appgw-${OCP_CLUSTER_INSTANCE}-<env>-<location>"
export APP_GW_RG="rg-${OCP_CLUSTER_INSTANCE}mgmt-<env>-<location>"
export KEY_VAULT="<keyvault>"
export MGMT_SUB="<management-sub>"
export INFRA_SUB="<infra-sub>"

export PATH=$PATH:$HOME/ocp


# Check KUBECONFIG Env variable exists - if not, set it
if [  -z ${KUBECONFIG} ]
then
    # Check if the kubeconfig file from the IPI installer exists, if so, assume first time cert generation
    if [ -f /home/adminuser/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig ]
    then
       export KUBECONFIG=/home/adminuser/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig
    else
       # Otherwise, prompt how to set up the variable
       echo "KUBECONFIG Env variable not set."
       echo "run export KUBECONFIG=kubeconfig (to store kubeconfig in current directory"
       echo "Obtain the login token/cli command from https://oauth-openshift.${LE_WILDCARD}/oauth/token/display"
       echo "Then re-run the script"

       exit 1
    exit 1
    fi
fi

export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export LE_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')


if [ ${#LE_API} == 0  ]
then
    echo "Unable to retrieve API fqdn. Are you logged in to OC ?"
    exit 1
fi

#AZ CLI Login. Use VM managed identity!
az login --identity
az account  set --subscription $MGMT_SUB

#Retrieve the SPN secret from Key Vault
export AZUREDNS_SUBSCRIPTIONID=$(az account show --query id -o tsv)
export AZUREDNS_TENANTID=$(az account show --query homeTenantId -o tsv)
export AZUREDNS_APPID=$( az keyvault secret show --name "DNS-SPN-APP-ID" --vault-name "${KEY_VAULT}" --query value -o tsv)
export AZUREDNS_CLIENTSECRET=$( az keyvault secret show --name "DNS-SPN-CLIENT-SECRET" --vault-name "${KEY_VAULT}" --query value -o tsv)


if [ ${#AZUREDNS_SUBSCRIPTIONID} == 0  ]
then
    echo "Unable to retrieve AZUREDNS_SUBSCRIPTIONID. Are you logged in to Azure ?"
    exit 1
fi
if [ ${#AZUREDNS_TENANTID} == 0  ]
then
    echo "Unable to retrieve AZUREDNS_TENANTID. Is the variable set?"
fi
if [ ${#AZUREDNS_APPID} == 0  ]
then
    echo "Unable to retrieve AZUREDNS_APPID. Is the variable set?"
    exit 1
fi
if [ ${#AZUREDNS_CLIENTSECRET} == 0  ]
then
    echo "Unable to retrieve AZUREDNS_CLIENTSECRET. Is the variable set?"
    exit 1
fi

 az account  set --subscription $MGMT_SUB

${HOME}/acme.sh/acme.sh --register-account -m <owner-email> --server zerossl



#API Cert
mkdir -p $HOME/certificates
export API_CERT=$HOME/certificates/api-cert
mkdir -p ${API_CERT}

# If timeouts occur, check https://help.zerossl.com/hc/en-us/articles/1500002453722
${HOME}/acme.sh/acme.sh --issue -d ${LE_API} --dns dns_azure --server zerossl  --force
${HOME}/acme.sh/acme.sh --install-cert -d ${LE_API} --cert-file ${API_CERT}/cert.pem --key-file ${API_CERT}/key.pem --fullchain-file ${API_CERT}/almostfullchain.pem --ca-file ${API_CERT}/almostca.cer
sleep 10

# Append the Sectio AAA root CA to the Fullchain
cat  $API_CERT/almostfullchain.pem  $HOME/ocp/sectigo-aaa-root.cer > $API_CERT/fullchain.pem
cat  $API_CERT/almostca.cer  $HOME/ocp/sectigo-aaa-root.cer > $API_CERT/ca.cer

# Create the pfx with fullchain
cat ${API_CERT}/key.pem  ${API_CERT}/fullchain.pem  > ${API_CERT}/clientfullchain.pem
openssl pkcs12 -export -in ${API_CERT}/clientfullchain.pem  -out ${API_CERT}/${OCP_CLUSTER_INSTANCE}-api.pfx -passout pass:



SecretValueApi=$(cat ${API_CERT}/${OCP_CLUSTER_INSTANCE}-api.pfx | base64)

kvid=$(az keyvault secret set --vault-name $KEY_VAULT --name "${OCP_CLUSTER_INSTANCE}-tls-api" --value "${SecretValueApi}" --query id -o tsv)
if [ ${#kvid} == 0  ]
then
    echo "Unable to retrieve the Key Vault ID for the Secret. Please check the certificate has been issued?"
    exit 1
fi


az account set --subscription $INFRA_SUB
az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${OCP_CLUSTER_INSTANCE}-tls-api" --key-vault-secret-id ${kvid}


# Change OCP Cluster Certs
set +e #turn off error checking
$configmap=$(oc get configmap custom-ca -n openshift-config)
if [ $? <> 0 ] 
then
    oc create configmap custom-ca --from-file=ca-bundle.crt=${API_CERT}/ca.cer -n openshift-config
    oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'
else
    oc apply configmap custom-ca --from-file=ca-bundle.crt=${API_CERT}/ca.cer -n openshift-config
fi
export API_SEC_NAME="api-certs-001"

$tlsSecret=$(oc get secret $API_SEC_NAME -n openshift-config)
if [ $? == 0 ]
then
    oc create secret tls ${API_SEC_NAME} --cert=${API_CERT}/fullchain.pem --key=${API_CERT}/key.pem -n openshift-config --dry-run=client -o yaml | oc replace -f - 
else
    oc create secret tls ${API_SEC_NAME}  --cert=${API_CERT}/fullchain.pem --key=${API_CERT}/key.pem -n openshift-config
    oc patch apiserver cluster --type merge --patch="{\"spec\": {\"servingCerts\": {\"namedCertificates\": [ { \"names\": [  \"$LE_API\"  ], \"servingCertificate\": {\"name\": \"${API_SEC_NAME}\" }}]}}}"
fi

cd $HOME
oc get --namespace openshift-ingress-operator ingresscontrollers/default --output jsonpath='{.spec.defaultCertificate}'
oc get --namespace openshift-config apiserver cluster --output jsonpath='{.spec}'

# Need to modify the Kubeconfig with the correct CA cert...

cd $HOME/ocp/$OCP_CLUSTER_INSTANCE/auth

if [ ! -d ./kubeconfig.orig ]
then
  cp kubeconfig kubconfig.orig
fi

# fix the IPI created kubeconfig so it uses the new certificate

if [ -f /home/adminuser/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig ]
then
    # use yq to change the value for the CA as it's easier
    yq eval -i ".clusters.[0].cluster.certificate-authority-data = \"$API_CERT/ca.cer\"" ./kubeconfig
    #..then use sed to change the name 
    sed -ri "s/certificate-authority-data/certificate-authority/g" ./kubeconfig
fi

