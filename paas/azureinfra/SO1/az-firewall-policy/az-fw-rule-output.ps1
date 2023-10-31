$rcgName = "ocp1-fwpolicy-rcg"

$rcgs=(az network firewall policy rule-collection-group  show --policy-name pol-fw-prod-shared-uks -g rg-mgmt-prod-shared-uks --name $rcgName -o json)
$rcgObj = $rcgs | ConvertFrom-json

$rcgObj.ruleCollections.Count
$outputColl = @()
foreach ($ruleColl in $rcgObj.ruleCollections) {
  #  $ruleColl.rules
    foreach ($rule in $ruleColl.rules) {
        $target = $null
        #write-output ('FQDN Count: {0}' -f $rule.targetFqdns.Count)
        #write-output ('URLs Count: {0}' -f $rule.targetUrls.Count)
        if ($rule.targetFqdns.Count -gt 0) {
            $target = $rule.targetFqdns
        }
        elseif ($rule.targetUrls.Count -gt 0 ) {
            $target = $rule.targetUrls
        }
        $protoList = $null
        foreach ($proto in $rule.protocols) {
            $protoList = ('{0}port={1}. type={2} | ' -f $protoList, $proto.port, $proto.protocolType )
        }
        $ipList = $null
        foreach ($sourceAddress in $rule.sourceAddresses) {
            $ipList = ('{0}{1} | ' -f $ipList, $sourceAddress)
        }
        $targetList = $null
        foreach ($item in $target) {
            $targetList = ('{0}{1} | ' -f $targetList, $item)
        }
        $ruleOutput = [pscustomobject] @{
            'name'            = $rule.name
            'priority'        = $ruleColl.priority
            'description'     = $rule.description
            'protocols'       = $protoList
            'ruleType'        = $rule.ruleType
            'sourceAddresses' = $ipList
            'target'          = $targetList
        }
        $outputColl += $ruleOutput
    }
}
$outputColl | ConvertTo-Csv -NoTypeInformation  | Out-File -FilePath .\$rcgName.csv -Encoding ascii