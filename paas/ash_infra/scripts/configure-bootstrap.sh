ash_region=''
ash_fqdn=''
export region=${ash_region}
export fqdn=${ash_fqdn}

if [ ${#ash_region} == 0 ] 
then
  echo "is the ash_region variable set (e.g. export ash_region='local'"
  exit 1
fi
if [ ${#ash_fqdn} == 0 ] 
then
  echo "is the ash_fqdn variable set (e.g. export ash_fqdn='azurestack.external'"
  exit 1
fi

export quay_dir='/quay'

sudo cp /var/lib/waagent/Certificates.pem /etc/pki/ca-trust/source/anchors/
sudo chmod 644 /etc/pki/ca-trust/source/anchors/Certificates.pem
sudo update-ca-trust extract

export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
sudo cp /var/lib/waagent/Certificates.pem .
sudo chmod 777 Certificates.pem
echo ' ensure the Certificates.pem file is formatted correctly (remove PRIVATE Keys and extraneous information)'

unzip dso-tools.zip

# Delete the pull-secrets used to provision on public Azure. No need for the disconnected environments

rm -f pull-secret-raw.json

if [ -f pull-secret-local.json ]
then
  cp pull-secret-local.json pull-secret.json
fi


AshUser_env=$(az cloud show -n AzureStackUser)
if [ ${#AshUser_env} == 0 ]
then
  az cloud register -n AzureStackUser --endpoint-resource-manager "https://management.${region}.${fqdn}" --suffix-storage-endpoint "${region}.${fqdn}" --suffix-keyvault-dns ".vault.${region}.${fqdn}"
fi
az cloud set -n AzureStackUser
az cloud update --profile 2020-09-01-hybrid
az login

# echo "Extracting ${quay_dir}/offline-images/*.vhd.gz"
# sudo gzip -d $quay_dir/offline-images/*.vhd.gz


export resourcegroup="openshift-offline"
export storageaccountname="images"
storageaccountkey=$(az storage account keys list -g $resourcegroup --account-name $storageaccountname --query "[0].value" -o tsv)

storagecontainername="rhcos"
az storage container create --account-name $storageaccountname --name $storagecontainername --account-key $storageaccountkey

expDate=$(date -d "+1 days" '+%Y-%m-%d')
storageaccountSAS=$(az storage container generate-sas --account-name $storageaccountname --name $storagecontainername --permissions acdlrw --expiry $expDate --account-key $storageaccountkey -o tsv)

rhcos=$(ls $quay_dir/offline-images/*.vhd)

az storage blob upload --account-name $storageaccountname --account-key $storageaccountkey -c $storagecontainername -f $rhcos -n $(basename $rhcos)
az storage container set-permission --name $storagecontainername --account-name $storageaccountname --public-access container --account-key $storageaccountkey --auth-mode key
az storage container show-permission --name $storagecontainername --account-name $storageaccountname --account-key $storageaccountkey --auth-mode key

 az keyvault create --location $region --name ocpInfra -g $resourcegroup
