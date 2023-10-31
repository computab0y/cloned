# Requires az cli, azcopy

$instance = 1
$location ="local"
$FQDN = "azurestack.external"
$imagelocation = "e:\images"
$DataDiskSize = 100

## Don't Change below
$region = $location
az cloud register -n AzureStackUser --endpoint-resource-manager "https://management.${region}.${fqdn}" --suffix-storage-endpoint "${region}.${fqdn}" --suffix-keyvault-dns ".vault.${region}.${fqdn}"
az cloud set -n AzureStackUser
az cloud update --profile 2020-09-01-hybrid
    
az login



$resourcegroup = "openshift-offline$instance"
$storageaccountname = "images$instance"
#Import the OpenShift library hosted in Quay

az group create -l $location -n $resourcegroup
$storageaccount = az storage account create --name $storageaccountname --resource-group $resourcegroup --location $location --sku "Standard_LRS" | ConvertFrom-Json
$storageaccountkey = az storage account keys list -g $resourcegroup --account-name $storageaccountname --query "[0].value" -o tsv
$storagecontainername = "quay${instance}"

az storage container create --account-name $storageaccountname --name $storagecontainername

$storageaccount = az storage account show -g $resourcegroup -n $storageaccountname | ConvertFrom-Json
$storageaccountSAS = az storage container generate-sas --account-name $storageaccountname --name $storagecontainername --permissions acdlrw --expiry ((get-date).AddHours(24)).ToString("yyy-MM-dd") --account-key $storageaccountkey -o tsv
$env:AZCOPY_DEFAULT_SERVICE_API_VERSION="2017-11-09"

# Create Managed Disks for the VM using the VHD's copied to the SA

$OSDiskName = "quayosdisk"
$DataDiskName = "quaydatadisk1"
$OSVHDName = "OS.vhd"
$DataDiskVHDName = "datadisk.vhd"
$OSDiskSize = 64

$OSvhdURI = "$($storageaccount.primaryEndpoints.blob)$($storagecontainername)/$OSVHDName"
$DatavhdURI = "$($storageaccount.primaryEndpoints.blob)$($storagecontainername)/$DataDiskVHDName"

azcopy copy "$imagelocation\$OSVHDName" "$($storageaccount.primaryEndpoints.blob)$($storagecontainername)?$($storageaccountSAS)"
azcopy copy "$imagelocation\$DataDiskVHDName" "$($storageaccount.primaryEndpoints.blob)$($storagecontainername)?$($storageaccountSAS)"

az disk create -g $resourcegroup -n $OSDiskName --source $OSvhdURI
az disk create -g $resourcegroup -n $DataDiskName --source $DatavhdURI

# Create new Quay virtual machine 

$subnetName = "Quay-Subnet"

$vnetName = "Openshift-Offline-VNet"
az network vnet create -g $resourcegroup -n $vnetName --address-prefix 10.1.0.0/24 --subnet-name $subnetName --subnet-prefix 10.1.0.0/24

$ipName = "quay${instance}IP"
az network public-ip create -g $resourcegroup -n $ipName
$nsgName = "quayNSG"
#$quayRule1 = New-AzNetworkSecurityRuleConfig -Name Allow_SSH -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
#$quayRule2 = New-AzNetworkSecurityRuleConfig -Name Allow_HTTPS -Description "Allow HTTPS" -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
#$quayRule3 = New-AzNetworkSecurityRuleConfig -Name Allow_HTTP -Description "Allow HTTP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 130 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80
#$quayRule4 = New-AzNetworkSecurityRuleConfig -Name Allow_PG_SQL -Description "Allow PG_SQL" -Access Allow -Protocol Tcp -Direction Inbound -Priority 140 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5432
#$quayRule5 = New-AzNetworkSecurityRuleConfig -Name Allow_Redis -Description "Allow Redis" -Access Allow -Protocol Tcp -Direction Inbound -Priority 150 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 6379
#$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourcegroup -Location $location -Name $nsgName -SecurityRules $quayRule1,$quayRule2,$quayRule3,$quayRule4,$quayRule5 -Force
$nicName = "quay${instance}NIC"
az network nic create -g $resourcegroup --vnet-name $vnetName --subnet $subnetName -n $nicName --public-ip-address $ipName

az vm create -g $resourcegroup -n quay --attach-os-disk $OSDiskName --attach-data-disks $DataDiskName  --os-type linux --nics $nicName --size Standard_DS3_v2