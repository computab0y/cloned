export kv_cert_name="sb-service-mod-gov-uk"
export base_fqdn="sb.service.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 4

export kv_cert_name="sb-service-mod-uk"
export base_fqdn="sb.service.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 4

export kv_cert_name="sb-foundry-mod-gov-uk"
export base_fqdn="sb.foundry.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 4

export kv_cert_name="sb-foundry-mod-uk"
export base_fqdn="sb.foundry.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 4