export kv_cert_name="service-mod-gov-uk"
export base_fqdn="service.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 2

export kv_cert_name="foundry-mod-uk"
export base_fqdn="foundry.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 2

export kv_cert_name="foundry-mod-gov-uk"
export base_fqdn="foundry.mod.gov.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 2

export kv_cert_name="service-mod-uk"
export base_fqdn="service.mod.uk"
./add-listener-alt-domain.sh -a $kv_cert_name -b $base_fqdn -z 2