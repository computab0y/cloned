#!/bin/bash

# Requirements:
# az cli 
# oc cli

# check acme.sh documentation: https://github.com/acmesh-official/acme.sh
set -ex

cert_hostname=<ssl cert hostname > # e.g. api.ocp1.azure.dso.digital.mod.uk

aad_app_id=<app-id>                 # provided by platform team
aad_app_id_pw=<password-or-cert>    # provided by platform team
aad_app_id_tenant=<tenant>          # provided by platform team
ssl_owner_email=<owner-email>       # email address for ssl cert expiry notifications
OCP_TOKEN=<OCP TOKEN>               # use a service principal for automation purposes. 
# https://access.redhat.com/solutions/2972601

# 1.	If the service account does not exist yet, create it
# oc create serviceaccount ${SERVICE_ACCOUNT} -n ${NAMESPACE}
# 2.	Get the authentication token for a service account
# oc sa get-token -n ${NAMESPACE} ${SERVICE_ACCOUNT}
# 3.	To test authentication as that user to the API using the token you can use.
# oc get user '~' --token=$(oc sa get-token -n ${NAMESPACE} ${SERVICE_ACCOUNT})
# 4.	Do not forget to grant any required permissions to the service account.
# 5.	Login with the service account token, you can run
# TOKEN=$(oc sa get-token -n ${NAMESPACE} ${SERVICE_ACCOUNT})
# oc login --token=${TOKEN}
# or create a kubeconfig using that token
# oc n ${NAMESPACE} sa create-kubeconfig ${SERVICE_ACCOUNT} > ${SERVICE_ACCOUNT}.kubeconfig

ACME_CA='zerossl' # change to CA supporting acme API.  default is zeroSSL. 
DNS_PROVIDER='dns_aws' # e.g. dns_azure, dns_aws ...
KEY_VAULT=<key vault name>       # Created by platform team. e.g. stores SSL Cert
ssl_secret_name=<keyvault secret name> # provided by platform team


cd $HOME
if [ ! -d $HOME/acme.sh ]
then
    git clone https://github.com/neilpang/acme.sh
fi
cd acme.sh

#AZ CLI Login. Use VM managed identity!
az login --service-principal -u $aad_app_id -p $aad_app_id_pw --tenant $aad_app_id_tenant --allow-no-subscriptions

export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')

if [ ${#LE_API} == 0  ]
then
    echo "Unable to retrieve API fqdn. Are you logged in to OC ?"
    exit 1
fi
oc login "${LE_API}:6443" --token=$OCP_TOKEN


$HOME/acme.sh/acme.sh --register-account -m <owner-email> --server $ACME_CA 

#API Cert
mkdir -p $HOME/certificates
export SSL_CERT=$HOME/certificates/ssl-cert
mkdir -p ${SSL_CERT}

cp ./sectigo-aaa-root.cer ${SSL_CERT}
# ZeroSSL
# If timeouts occur, check https://help.zerossl.com/hc/en-us/articles/1500002453722
$HOME/acme.sh/acme.sh --issue -d *.${cert_hostname} -d home.${cert_hostname} --dns $DNS_PROVIDER --server $ACME_CA  --force
$HOME/acme.sh/acme.sh --install-cert -d *.${cert_hostname} -d home.${cert_hostname} --cert-file ${SSL_CERT}/cert.pem --key-file ${SSL_CERT}/key.pem --fullchain-file ${SSL_CERT}/almostfullchain.pem --ca-file ${SSL_CERT}/almostca.cer
sleep 10

# Append the Sectio AAA root CA to the Fullchain - for zeroSSL
cat  $SSL_CERT/almostfullchain.pem  $HOME/ocp/sectigo-aaa-root.cer > $SSL_CERT/fullchain.pem
cat  $SSL_CERT/almostca.cer  $SSL_CERT/sectigo-aaa-root.cer > $SSL_CERT/ca.cer

# Create the pfx with fullchain
cat ${SSL_CERT}/key.pem  ${SSL_CERT}/fullchain.pem  > ${SSL_CERT}/clientfullchain.pem

pfx_name="${ssl_secret_name}.pfx"
openssl pkcs12 -export -in ${SSL_CERT}/clientfullchain.pem  -out ${SSL_CERT}/${pfx_name} -passout pass:
SecretValuePfx=$(cat ${SSL_CERT}/${pfx_name} | base64)

kvsetid=$(az keyvault secret set --vault-name $KEY_VAULT --name "${ssl_secret_name}" --value "${SecretValuePfx}" --query id -o tsv)
kvid=$(az keyvault secret list --vault-name $KEY_VAULT --query "[?name=='${ssl_secret_name}'].id" -o tsv)
if [ ${#kvid} == 0  ]
then
    echo "Unable to retrieve the Key Vault ID for the Secret. Please check the certificate has been issued?"
    exit 1
fi

# Change OCP Cluster Certs
set +e #turn off error checking
export TLS_SEC_NAME=$ssl_secret_name
export TLS_SEC_NAMESPACE="<your namespace>"

tlsSecret=$(oc get secret $TLS_SEC_NAME -n $TLS_SEC_NAMESPACE)
if [ $? == 0 ]
then
    oc create secret tls ${TLS_SEC_NAME} --cert=${SSL_CERT}/fullchain.pem --key=${SSL_CERT}/key.pem -n $TLS_SEC_NAMESPACE --dry-run=client -o yaml | oc replace -f - 
else
    oc create secret tls ${TLS_SEC_NAME}  --cert=${SSL_CERT}/fullchain.pem --key=${SSL_CERT}/key.pem -n $TLS_SEC_NAMESPACE
fi


