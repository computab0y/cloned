param(
     [Parameter()]
     [string]$LocalDir = "e:\images"
 )



$hashArray =@()
$files = get-childitem -Path $LocalDir -Recurse
foreach ($file in $files ){
    write-output('Calculating hash for: {0}' -f $file)
    $sha256Hash = get-FIleHash $file.FullName -Algorithm SHA256
    $hashArray += $sha256Hash
}
$hashArray| out-file -FilePath "$LocalDir\sha256-hashes.txt"