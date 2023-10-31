$filename = "$($PSScriptRoot)\packages.zip"
$destDir  = "c:\sources"


if ( -not (Test-Path -Path $destDir -PathType Container)) {
    New-Item $destDir -ItemType Directory
}


Expand-Archive -Path $filename -DestinationPath $destDir -Force

if ( Test-Path -Path "$destDir\openshift-client-windows.zip" -PathType Leaf) {
    Expand-Archive -Path "$destDir\openshift-client-windows.zip" -DestinationPath C:\Windows -force
}

if ( Test-Path -Path "$destDir\ubuntu.appx" -PathType Leaf) {
    Rename-Item "$destDir\ubuntu.appx" "$destDir\ubuntu.zip"
    Expand-Archive -Path "$destDir\ubuntu.zip" -DestinationPath "$destDir\ubuntu" -Force
    #Add-AppxPackage 
}
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
$appxName = Get-ChildItem -Name "$destdir\ubuntu\*x64.appx"
$appxPath = "$destdir\ubuntu\$appxName"

DISM.EXE /Online /Add-ProvisionedAppxPackage /PackagePath:$appxPath /SkipLicense

MsiExec.exe /i "$destDir\googlechromestandaloneenterprise64.msi" /qn