# Get the Azure Stack Hub PowerShell Module
# Creds for logging into ERCS (AzureStackAdmin on ASDK)
$Creds = Get-Credential
$Session = New-PSSession -ComputerName "AzS-ERCS01" -ConfigurationName PrivilegedEndpoint -Credential $Creds -SessionOption (New-PSSessionOption -Culture en-US -UICulture en-US)
$SpObject = Invoke-Command -Session $Session -ScriptBlock {New-GraphApplication -Name "openshiftoffline" -GenerateClientSecret}
$AzureStackInfo = Invoke-Command -Session $Session -ScriptBlock {Get-AzureStackStampInformation}
$Session | Remove-PSSession
$ArmEndpoint = $AzureStackInfo.TenantExternalEndpoints.TenantResourceManager
$GraphAudience = "https://graph." + $AzureStackInfo.ExternalDomainFQDN + "/"
$TenantID = $AzureStackInfo.AADTenantID
$securePassword = $SpObject.ClientSecret | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SpObject.ClientId, $securePassword
$SpSignin = Connect-AzAccount -Environment "AzureStackUser" -ServicePrincipal -Credential $credential -TenantId $TenantID
$SpObject