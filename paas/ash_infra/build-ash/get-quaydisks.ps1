# Connect-AzAccount -Environment AzureCloud -UseDeviceAuthentication
#Set-AzEnvironment -Name azurecloud
# Resource Group Name where Quay VM is stored
write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======START========")

$ResGroupName = "rg-buildocr-1-sbox-uks"
$VMName = "quay"
$subscriptionName="UKSC-DD-ASDT_PREDA-INFRA_SBOX_001"

$LocalDir="c:\preda\images"

Write-Output "Setting AZ environment"
az cloud set -n AzureCloud
$azSubList=(az account list -o tsv)
if ($null -eq $azSubList) {
    Write-Output "run az login to connect to access accounts"
}
else {
    az account set --subscription $subscriptionName
}

#Get the VM object from Public Azure
write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "STOP VM")
az vm deallocate --name $VMName --resource-group $ResGroupName
$quayvm=az vm show --name $VMName --resource-group $ResGroupName | ConvertFrom-Json


$OsDiskName=$quayvm.StorageProfile.OsDisk.Name
$DataDiskName=$quayvm.StorageProfile.DataDisks[0].Name

#Add autocompletion for AZCopy
azcopy completion powershell | Out-String | Invoke-Expression

write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======GET VM DISK OBJECTS========")

if (-not (Test-path -Path $LocalDir)) {
    mkdir -Path $LocalDir 
    write-output "Created $LocalDir"
}

if (-not (Test-path -Path "$LocalDir\datadisk.vhd" -PathType Leaf)) {
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======COPY DATA DISK DISK========")
    $sasExpiryDuration=96400 # 24 hours so the Large Disk has chance to copy
    write-output "Obtaining $DataDiskName SAS"
    $DataDiskSAS =(az disk grant-access --resource-group $ResGroupName --name $DataDiskName --duration-in-seconds $sasExpiryDuration --query [accessSas] -o tsv)
    write-output "Copying $DataDiskName to $LocalDir"
    azcopy copy $DataDiskSAS $LocalDir 
    rename-item -Path "$LocalDir\abcd" -NewName "datadisk.vhd"
    write-output "Revoking SAS access to $DataDiskName"
    az disk revoke-access --resource-group $ResGroupName --name $DataDiskName
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======CALC DATA DISK SHA256========")
    $CalcMd5Hash = get-FileHash "$LocalDir\datadisk.vhd" -Algorithm SHA256
    $CalcMd5Hash| out-file -FilePath "$LocalDir\datadisk-hash.txt"
}
else {
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "$LocalDir\datadisk.vhd exists. skipping")
}
write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======FINISH DATA DISK========")

$sasExpiryDuration=3600 # 1 hour so the Large Disk has change to copy
    
if (-not (Test-path -Path "$LocalDir\OS.vhd" -PathType Leaf)) {
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======COPY OS DISK========")
    write-output "Obtaining $OSDiskName SAS"
    $OSDiskSAS   =(az disk grant-access --resource-group $ResGroupName --name $OSDiskName --duration-in-seconds $sasExpiryDuration --query [accessSas] -o tsv)
    write-output "Copying $OSDiskName to $LocalDir"
    azcopy copy $OSDiskSAS $LocalDir
    rename-item -Path "$LocalDir\abcd" -NewName "OS.vhd"
    write-output "Revoking SAS access to $OSDiskName"
    az disk revoke-access --resource-group $ResGroupName --name $OSDiskName
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======CALC OS DISK SHA256========")
    $CalcMd5Hash = get-FileHash "$LocalDir\OS.vhd" -Algorithm SHA256
    write-output('MD5 Hash: {0}', $CalcMd5Hash)
    $CalcMd5Hash| out-file -FilePath "$LocalDir\OS-hash.txt"       
}
else {
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "$LocalDir\OS.vhd exists. skipping")
}
write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======FINISH OS DISK========")

write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======COMPLETE========")


if (-not (Test-path -Path "$LocalDir\OS-hash.txt" -PathType Leaf)) {
    $CalcMd5Hash = get-FileHash "$LocalDir\OS.vhd" -Algorithm SHA256
    write-output('MD5 Hash: {0}', $CalcMd5Hash)
    $CalcMd5Hash| out-file -FilePath "$LocalDir\OS-hash.txt"
}

if (-not (Test-path -Path "$LocalDir\datadisk-hash.txt" -PathType Leaf)) {
    $CalcMd5Hash = get-FileHash "$LocalDir\datadisk.vhd" -Algorithm SHA256
    $CalcMd5Hash| out-file -FilePath "$LocalDir\datadisk-hash.txt"
}
