export kv_cert_name="dev-foundry-mod-uk"
export base_fqdn="dev.foundry.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 1

export kv_cert_name="dev-foundry-mod-gov-uk"
export base_fqdn="dev.foundry.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 1

export kv_cert_name="dev-service-mod-uk"
export base_fqdn="dev.service.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 1

export kv_cert_name="dev-service-mod-gov-uk"
export base_fqdn="dev.service.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 1