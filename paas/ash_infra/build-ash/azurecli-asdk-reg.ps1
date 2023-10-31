#Connect to ASDK

# Make Dir for certs etc
New-Item -Path "c:\" -Name "Certs" -ItemType "directory"
$CertDir="c:\Certs"
#Get the root CA cert for Stack Hub
$label = "AzureStackSelfSignedRootCert" #Valid for ASDK only
Write-Host "Getting certificate from the current user trusted store with subject CN=$label"
$root = Get-ChildItem Cert:\CurrentUser\Root | Where-Object Subject -eq "CN=$label" | select -First 1
  if (-not $root)
  {
      Write-Error "Certificate with subject CN=$label not found"
      return
  }
Write-Host "Exporting certificate"
Export-Certificate -Type CERT -FilePath "$CertDir\root.cer" -Cert $root
Write-Host "Converting certificate to PEM format"
certutil -encode "$CertDir\root.cer" "$CertDir\root.pem"

#Import the root CA certificate to the Az CLI
az --version
cd "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\"
.\python -c "import certifi; print(certifi.where())"
$pemFile = "$CertDir\root.pem"
$pythonCertStore = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\lib\site-packages\certifi\cacert.pem"
$root = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$root.Import($pemFile)
Write-Host "Extracting required information from the cert file"
$md5Hash    = (Get-FileHash -Path $pemFile -Algorithm MD5).Hash.ToLower()
$sha1Hash   = (Get-FileHash -Path $pemFile -Algorithm SHA1).Hash.ToLower()
$sha256Hash = (Get-FileHash -Path $pemFile -Algorithm SHA256).Hash.ToLower()
$issuerEntry  = [string]::Format("# Issuer: {0}", $root.Issuer)
$subjectEntry = [string]::Format("# Subject: {0}", $root.Subject)
$labelEntry   = [string]::Format("# Label: {0}", $root.Subject.Split('=')[-1])
$serialEntry  = [string]::Format("# Serial: {0}", $root.GetSerialNumberString().ToLower())
$md5Entry     = [string]::Format("# MD5 Fingerprint: {0}", $md5Hash)
$sha1Entry    = [string]::Format("# SHA1 Fingerprint: {0}", $sha1Hash)
$sha256Entry  = [string]::Format("# SHA256 Fingerprint: {0}", $sha256Hash)
$certText = (Get-Content -Path $pemFile -Raw).ToString().Replace("`r`n","`n")
$rootCertEntry = "`n" + $issuerEntry + "`n" + $subjectEntry + "`n" + $labelEntry + "`n" + $subjectEntry + "`n" + $labelEntry + "`n" + $serialEntry + "`n" + $md5Entry + "`n" + $sha1Entry + "`n" + $sha256Entry  + "`n" + $certText
Write-Host "Adding the certificate content to Python Cert store"
Add-Content $pythonCertStore $rootCertEntry
Write-Host "Python Cert store was updated to allow the Azure Stack Hub CA root certificate"

# Configure AZCLI with Azure Stack
az cloud register -n AzureStackUser --endpoint-resource-manager "https://management.local.azurestack.external" --suffix-storage-endpoint "local.azurestack.external" --suffix-keyvault-dns ".vault.local.azurestack.external"
az cloud set -n AzureStackUser
az cloud update --profile 2020-09-01-hybrid
az login