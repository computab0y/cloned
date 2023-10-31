export kv_cert_name="dev-sb-foundry-mod-uk"
export base_fqdn="dev-sb.foundry.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 3

export kv_cert_name="dev-sb-service-mod-gov-uk"
export base_fqdn="dev-sb.service.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 3

export kv_cert_name="dev-sb-foundry-mod-gov-uk"
export base_fqdn="dev-sb.foundry.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 3

export kv_cert_name="dev-sb-service-mod-uk"
export base_fqdn="dev-sb.service.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 3
