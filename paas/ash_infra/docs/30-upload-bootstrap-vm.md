# Create Bootstrap VM on ASH / ASDK

Once the bootstrap VM has been created in Public Azure, and the VHD images have been obtained, the offline bootstrap VM can be created on ASH or ASDK.

On the ASH / ASDK instance:
1. copy [create-rhquay.ps1](./../build-ash/create-rhquay.ps1).ps1 to a Windows system that has access to ASH / ASDK.
2. Edit create-rhquay.ps1

```pwsh
$instance = 1                 # if deploying multiple Quay repos, increment
$location ="local"            # leave for ASDK
$FQDN = "azurestack.external" # Leave for ASDK
$imagelocation = "e:\images"  # location on local system where the VHD files are located
$DataDiskSize = 100           # make sure this matches the size of the data disk created for the bootstrap VM in step 0
```
   3. Run create-rhquay.ps1. This will:
   -  Connect to ASH/ASDk via az login. It will prompt you to authenticate.
   -  Create a Resource Group on ASH/ASDK
   -  Create a Storage Account / Container to store the importd VHD files
   -  Copy the imported VHD files to the storage account
   -  Create the VNet, Nics, VM using the VHD for the disks
  
4.  Once the VM has been created, you can connect to it via SSH using the public IP address assigned.  The username and SSH key passphrase is the same as used when the initial VM was created in Azure.

# New Instructions

1. Log into asdk-vm using Bastion, user name azurestackadmin@azurestack.local. Install Google Chrome.

2. Connect to ASDK admin portal: https://adminportal.local.azurestack.external

3. All services -> Offers -> Create offer
   - Display name = default
   - Resource Group, create new "offers-and-plans"
   - Next: base plans -> Create new plan, "default-plan", RG create new "offers-and-plans"
   - Next: services -> All bar Subscriptions
   - Next: Quotas -> All default
   - Create
4. All services -> User subscriptions -> Add -> "ocp", "cloudadmin@azurestack.local" -> Create

5. Connect to ASDK user portal: https://portal.local.azurestack.external

   - All services -> Subscriptions -> ocp -> Settings -> Resource Providers -> Register each one
   - Copy Subscription ID.

6. Copy create-serviceprincipal.ps1 code to PowerShell ISE on VM and run. 
   - User: cloudadmin@azurestack.local.
   - Copy output.
   - Copy Application Name, add as Owner to Subscription in Azure portal

7. Run PowerShell ISE **as Admistrator** on VM. Copy azurecli-asdk-reg.ps1 code and run. This registeres the ASDK Certificate with Azure CLI.

8. Copy create-rhquay.ps1 code to PowerShell ISE on VM. Update $imagelocation and run. This will create Resource Group, Storage Account, upload disk images and creates Virtual Machine.

9. Start -> Windows Administrative Tools -> DNS Manager, asdk-vm -> Conditional Forwarder, New Conditional Forwarder (this is asdk-vm DNS)

     - DNS Domain: "ocp.local"
     - Go to Azure admin portal -> Dashboard -> Region Management/local -> Properties, copy External DNS IP addresses in as separate rows, delete IPv6 rows, OK
     - In DNS Manager, right click DNS -> Connect to DNS Server, change to The following computer: "azs-dc01" (this is ASDK DNS)
     - Add External DNS IP addresses as before, save
     - Add another Conditional forwarder -> DNS Domain: "internal.cloudapp.net"
     - Add External DNS IP addresses as before, save

10. In DNS manager Right-click asdk-vm & azs-dc-01, clear cache & update server data files

11. In Azure portal, create new Resource Group "dns"
     - Create two DNS Zones: internal.cloudapp.net, ocp.local
     - internal.cloudapp.net -> Add record set "quay", quay VM public IP

12. Restart quay vm

13. Open CMD window
   - ping quay.internal.cloudapp.net to test

14. Open Mobia Xterm -> SSH -> Quay VM Public IP
   - user = adminuser
   - SSH Key & Passphrase from Key Vault in public Azure  
   - ping quay.internal.cloudapp.net to test