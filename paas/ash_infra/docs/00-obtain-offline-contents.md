# Building the VM with offline content
Witin the ash_infra folder, there are a number of directories

- **build_ash**: hosts scripts and tools usually run on the ASH infra, or used to genertae the collateral to move onto the ASH infra (e.g. the VHD's)
- **docs**: various build docs
- **env**: hosts the paramter files for each environment. Build scripts can call on these to set specific params in one place
- **ocr-offline**- hosts the scripts and terraform to build the VM with the offline container registry, rhcos image and other tools required on the disconnected infra.
- **scripts**: central location for the scripts used by the deployment
  
# Building the Offline Container Registry VM  

1. Edit the settings param file to match the environment

```export TF_VAR_cr_instance=1``` determines the name of the resource group
```export TF_VAR_data_disk_size=100``` specify the siz in GiB of the data disk.  This may need to grow as more operators / config data is uploaded.
```export CR_VNET_IP_ADDR_SPACE="10.250.0.0/24"``` determines the address space.  Make sure if deploying multiple VM's (for testing), that the address spaces are non overlapping.  These VNets are peered with the Vnet that hosts the firewall.

2. Run the following ( **-z 1** indicates ):
   ```./ash_infra/ocr-offline/deploy-az-ocr.sh -z 1```
   This will create a resource group e.g. rg-buildocr-1-sbox-uks, vnet, vVM, managed disks, UDR and NSGs

# Obtain contents to copy to high side

1.  Modify the following script from within the ash_infra folder:
    ``` ./build-ash/get-quaydisks.ps1```
2. Modify the following parameters within the script to match the VM deployed to Azure
```
$ResGroupName = 'rg-buildocr-1-sbox-uks'
$VMName = 'quay'
$subscriptionName='UKSC-DD-ASDT_PREDA-INFRA_SBOX_001'
$LocalDir='c:\preda\images' replace with the external HDD drive letter and folder of your choice
```


3. From a PowerShell session where you have attached the external HDD, run the following script from within the ash_infra folder:
 ``` ./build-ash/get-quaydisks.ps1```

If prompted, login to the correct AAD tenant for the environment you have deployed to.