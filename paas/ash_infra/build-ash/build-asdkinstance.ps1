# Build out a VM to run ASDK in your Azure Sub.

# Run from Azure Cloud Shell
Find-Script Deploy-AzureStackonAzureVM | Install-Module -Force

# Set the correct subscription
get-azsubscription
Set-AzContext -Subscription 357e7522-d1ad-433c-9545-7d8b8d72d61a

Deploy-AzureStackonAzureVM -ResourceGroupName rg-asdk2-uks -Region 'UK South' -VirtualMachineSize 'Standard_E32s_v3' -DeploymentType ADFS