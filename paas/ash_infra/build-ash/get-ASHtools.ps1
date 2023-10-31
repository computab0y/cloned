

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSVersionTable
Uninstall-Module PowershellGet -AllVersions -Force -Confirm:$false
Get-module PowershellGet
Find-module PowershellGet
Install-Module PowershellGet -Force -AllowClobber

Install-Module -Name PowerShellGet -AllowPrerelease -Force

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-Module -Name Az.BootStrapper -Force
Install-AzProfile -Profile 2020-09-01-hybrid -Force
Install-Module -Name AzureStack -RequiredVersion 2.2.0

# Get the tools
# Change directory to the root directory.
cd \

# Download the tools archive.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
invoke-webrequest `
  https://github.com/Azure/AzureStack-Tools/archive/az.zip `
  -OutFile az.zip

# Expand the downloaded files.
expand-archive az.zip `
  -DestinationPath . `
  -Force

# Change to the tools directory.
cd AzureStack-Tools-az