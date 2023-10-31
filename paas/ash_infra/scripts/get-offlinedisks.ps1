# Connect-AzAccount -Environment AzureCloud -UseDeviceAuthentication
# az login

#Set-AzEnvironment -Name azurecloud
# Resource Group Name where Quay VM is stored
write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======START========")
$ResGroupName = "rg-buildcr-2-prod-uks"
$VMName = "quay"
$subscriptionName="Labs"

$LocalDir="I:\images"


#Get the VM object from Public Azure
write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "STOP VM")
$quayVM=get-azvm -ResourceGroupName $ResGroupName -Name $VMName
$quayVM | stop-azvm -Force

$OsDiskName=$quayvm.StorageProfile.OsDisk.Name
$DataDiskName=$quayvm.StorageProfile.DataDisks[0].Name
$DataDiskLUN=$quayvm.StorageProfile.DataDisks[0].Lun


#Add autocompletion for AZCopy
azcopy completion powershell | Out-String | Invoke-Expression


Write-Output "Setting AZ environment"
az cloud set -n AzureCloud
$azSubList=(az account list -o tsv)
if ($azSubList -eq $null) {
    Write-Output "run az login to connect to access accounts"
}
else {
    az account set --subscription $subscriptionName
    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======GET VM DISK OBJECTS========")
    $OSDisk   = Get-AzDisk -ResourceGroupName $ResGroupName -DiskName $OsDiskName
    $DataDisk = Get-AzDisk -ResourceGroupName $ResGroupName -DiskName $DataDiskName


    if (-not (Test-path -Path $LocalDir)) {
        mkdir -Path $LocalDir 
        write-output "Created $LocalDir"
    }
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
    if (-not (Test-path -Path "$LocalDir\datadisk.vhd" -PathType Leaf)) {
        write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======COPY DATA DISK DISK========")
        $sasExpiryDuration=172800 # 12 hours so the Large Disk has change to copy
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

    write-output ('{0}:{1}'-f $(get-date -Format "yyyy-MM-dd hh:mm:ss"), "=======COMPLETE========")
}