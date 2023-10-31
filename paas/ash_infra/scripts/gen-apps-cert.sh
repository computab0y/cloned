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
    exit 1
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


${HOME}/acme.sh/acme.sh --register-account -m <owner-email> --server zerossl --debug

#*APPS Cert
mkdir -p $HOME/certificates
export APPS_CERT=$HOME/certificates/apps-cert
mkdir -p ${APPS_CERT}
${HOME}/acme.sh/acme.sh --issue -d *.${LE_WILDCARD} -d console-openshift-console.${LE_WILDCARD} -d oauth-openshift.${LE_WILDCARD} --dns dns_azure --server zerossl --force
${HOME}/acme.sh/acme.sh --install-cert -d *.${LE_WILDCARD} --cert-file ${APPS_CERT}/cert.pem --key-file ${APPS_CERT}/key.pem --fullchain-file ${APPS_CERT}/almostfullchain.pem --ca-file ${APPS_CERT}/almostca.cer
sleep 10

# Append the Sectio AAA root CA to the Fullchain
cat  $APPS_CERT/almostfullchain.pem  $HOME/ocp/sectigo-aaa-root.cer > $APPS_CERT/fullchain.pem
cat  $APPS_CERT/almostca.cer  $HOME/ocp/sectigo-aaa-root.cer > $APPS_CERT/ca.cer

# Create the pfx with fullchain
cat ${APPS_CERT}/key.pem  ${APPS_CERT}/fullchain.pem  > ${APPS_CERT}/clientfullchain.pem
openssl pkcs12 -export -in ${APPS_CERT}/clientfullchain.pem  -out ${APPS_CERT}/${OCP_CLUSTER_INSTANCE}-app.pfx -passout pass:




SecretValueApp=$(cat ${APPS_CERT}/${OCP_CLUSTER_INSTANCE}-app.pfx | base64)
az account set --subscription $MGMT_SUB
kvid=$(az keyvault secret set --vault-name $KEY_VAULT --name "${OCP_CLUSTER_INSTANCE}-tls-app" --value "${SecretValueApp}" --query id -o tsv)
if [ ${#kvid} == 0  ]
then
    echo "Unable to retrieve the Key Vault ID for the Secret. Please check the certificate has been issued?"
    exit 1
fi

# az account set --subscription $INFRA_SUB
# az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${OCP_CLUSTER_INSTANCE}-tls-app" --key-vault-secret-id ${kvid}

# Change OCP Cluster Certs
set +e #turn off error checking
if [ $? <> 0 ] 
then
    oc create configmap custom-ca --from-file=ca-bundle.crt=${APPS_CERT}/ca.cer -n openshift-config
    oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'
fi
export APP_SEC_NAME="app-certs-001"

$tlsSecret=$(oc get secret $APP_SEC_NAME -n openshift-ingress)
if [ $? == 0 ]
then
    oc create secret tls ${APP_SEC_NAME} --cert=${APPS_CERT}/fullchain.pem --key=${APPS_CERT}/key.pem -n openshift-ingress --dry-run=client -o yaml | oc replace -f - 
else
    oc create secret tls $APP_SEC_NAME --cert=${APPS_CERT}/fullchain.pem --key=${APPS_CERT}/key.pem -n openshift-ingress
    oc patch ingresscontroller.operator default --type=merge -p "{\"spec\":{\"defaultCertificate\": {\"name\":\"$APP_SEC_NAME\"}}}" -n openshift-ingress-operator
fi
cd $HOME
oc get --namespace openshift-ingress-operator ingresscontrollers/default --output jsonpath='{.spec.defaultCertificate}'
