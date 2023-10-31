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
export APP_GW_NAME="<app-gw>"
export APP_GW_RG="<resource-group>"
export KEY_VAULT="<keyvault>"
export MGMT_SUB="<management-sub>"
export INFRA_SUB="<infra-sub>"

export PATH=$PATH:$HOME/ocp
# Check KUBECONFIG Env variable exists - if not, set it
#AZ CLI Login. Use VM managed identity!
az login --identity --allow-no-subscriptions
export OCP_TOKEN=$(az keyvault secret show --name "${OCP_CLUSTER_INSTANCE}-OC-CERT-SPN" --vault-name "${KEY_VAULT}" --query value -o tsv)

export LE_API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
if [ ${#OCP_TOKEN} == 0  ]
then
    if [ -f  $HOME/.kube/config ] 
    then
         export KUBECONFIG=~/.kube/config
    # Check if the kubeconfig file from the IPI installer exists, if so, assume first time cert generation
    elif [ ! -f $HOME/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig.orig ]
    then
       export KUBECONFIG=$HOME/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig
    
    elif  [ ! -f $HOME/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig ]
    then
       # Otherwise, prompt how to set up the variable
       echo "KUBECONFIG Env variable not set."
       echo "run export KUBECONFIG=kubeconfig (to store kubeconfig in current directory"
       echo "Obtain the login token/cli command from https://oauth-openshift.${LE_WILDCARD}/oauth/token/display"
       echo "Then re-run the script"

       exit 1
    fi
else
    oc login "${LE_API}:6443" --token=$OCP_TOKEN
fi

#export LE_WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
export LE_WILDCARD=$(echo $LE_API | sed 's/api/apps/')

if [ ${#LE_API} == 0  ]
then
    echo "Unable to retrieve API fqdn. Are you logged in to OC ?"
    exit 1
fi

if [ ${#LE_WILDCARD} == 0  ]
then
    echo "Unable to retrieve Config via OC CLI. Are you logged in to OC ?"
    exit 1
fi


#Retrieve the SPN secret from Key Vault
export AZUREDNS_SUBSCRIPTIONID=$(az keyvault secret show --name "DNS-SPN-SUBSCRIPTION-ID" --vault-name "${KEY_VAULT}" --query value -o tsv)
export AZUREDNS_TENANTID=$(az keyvault secret show --name "DNS-SPN-TENANT-ID" --vault-name "${KEY_VAULT}" --query value -o tsv)
export AZUREDNS_APPID=$(az keyvault secret show --name "DNS-SPN-APP-ID" --vault-name "${KEY_VAULT}" --query value -o tsv)
export AZUREDNS_CLIENTSECRET=$(az keyvault secret show --name "DNS-SPN-CLIENT-SECRET" --vault-name "${KEY_VAULT}" --query value -o tsv)


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

# az account  set --subscription $MGMT_SUB
$HOME/acme.sh/acme.sh --register-account -m <owner-email> --server zerossl

#API Cert
mkdir -p $HOME/certificates
export API_CERT=$HOME/certificates/api-cert
mkdir -p ${API_CERT}

# If timeouts occur, check https://help.zerossl.com/hc/en-us/articles/1500002453722
$HOME/acme.sh/acme.sh --issue -d ${LE_API} --dns dns_azure --server zerossl  --force
$HOME/acme.sh/acme.sh --install-cert -d ${LE_API} --cert-file ${API_CERT}/cert.pem --key-file ${API_CERT}/key.pem --fullchain-file ${API_CERT}/almostfullchain.pem --ca-file ${API_CERT}/almostca.cer
sleep 10

# Append the Sectio AAA root CA to the Fullchain
cat  $API_CERT/almostfullchain.pem  $HOME/ocp/sectigo-aaa-root.cer > $API_CERT/fullchain.pem
cat  $API_CERT/almostca.cer  $HOME/ocp/sectigo-aaa-root.cer > $API_CERT/ca.cer

# Create the pfx with fullchain
cat ${API_CERT}/key.pem  ${API_CERT}/fullchain.pem  > ${API_CERT}/clientfullchain.pem
openssl pkcs12 -export -in ${API_CERT}/clientfullchain.pem  -out ${API_CERT}/${OCP_CLUSTER_INSTANCE}-api.pfx -passout pass:
SecretValueApi=$(cat ${API_CERT}/${OCP_CLUSTER_INSTANCE}-api.pfx | base64)
secret_name="${OCP_CLUSTER_INSTANCE}-tls-api"
kvsetid=$(az keyvault secret set --vault-name $KEY_VAULT --name "${secret_name}" --value "${SecretValueApi}" --query id -o tsv)
kvid=$(az keyvault secret list --vault-name $KEY_VAULT --query "[?name=='${secret_name}'].id" -o tsv)
if [ ${#kvsetid} == 0  ]
then
    echo "Unable to set the Key Vault Secret. Please check the certificate has been issued?"
    exit 1
fi



# Change OCP Cluster Certs
export API_SEC_NAME="api-certs-001"
if [ ${#OCP_TOKEN} == 0  ]
then
    az account set --subscription $INFRA_SUB
    az network application-gateway ssl-cert create --resource-group $APP_GW_RG --gateway-name $APP_GW_NAME -n "${secret_name}" --key-vault-secret-id ${kvid}
    
    set +e #turn off error checking
    $configmap=$(oc get configmap custom-ca -n openshift-config)
    if [ $? <> 0 ] 
    then
        oc create configmap custom-ca --from-file=ca-bundle.crt=${API_CERT}/ca.cer -n openshift-config
        oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'
    else
        oc apply configmap custom-ca --from-file=ca-bundle.crt=${API_CERT}/ca.cer -n openshift-config
    fi


    tlsSecret=$(oc get secret $API_SEC_NAME -n openshift-config)
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


    if [ -d $HOME/ocp/${OCP_CLUSTER_INSTANCE}/auth ]
    then
        cd $HOME/ocp/$OCP_CLUSTER_INSTANCE/auth
        if [ ! -f ./kubeconfig.orig ]
        then
            cp kubeconfig kubconfig.orig
        fi

    # fix the IPI created kubeconfig so it uses the new certificate,  only if the directory exists!
        if [ ! -f $HOME/ocp/${OCP_CLUSTER_INSTANCE}/auth/kubeconfig.orig ]
        then
            # use yq to change the value for the CA as it's easier
            yq eval -i ".clusters.[0].cluster.certificate-authority-data = \"$API_CERT/ca.cer\"" ./kubeconfig
            #..then use sed to change the name 
            sed -ri "s/certificate-authority-data/certificate-authority/g" ./kubeconfig
        fi
    fi
else
    tlsSecret=$(oc get secret $API_SEC_NAME -n openshift-config)
    if [ $? == 0 ]
    then
        oc create secret tls ${API_SEC_NAME} --cert=${API_CERT}/fullchain.pem --key=${API_CERT}/key.pem -n openshift-config --dry-run=client -o yaml | oc replace -f - 
    else
        oc create secret tls ${API_SEC_NAME}  --cert=${API_CERT}/fullchain.pem --key=${API_CERT}/key.pem -n openshift-config
        oc patch apiserver cluster --type merge --patch="{\"spec\": {\"servingCerts\": {\"namedCertificates\": [ { \"names\": [  \"$LE_API\"  ], \"servingCertificate\": {\"name\": \"${API_SEC_NAME}\" }}]}}}"
    fi
fi
