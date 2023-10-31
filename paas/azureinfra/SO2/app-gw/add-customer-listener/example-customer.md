# service.mod.gov.uk

```bash
export app_name='mod-svv'             # used to generate resource group / resources.  8 chars or less
export base_fqdn='service.mod.gov.uk' # base domain name hosting the service(s)
export site_name="*"                # suggest leaving as * so all sub domains auto route to the OpenShift load balancer
export backend_address_fqdn="home.service.mod.gov.uk" # use this to probe an actual service

./azureinfra/SO2/app-gw/add-customer-listener/add-customer-listener.sh -a $app_name -b $base_fqdn -f $backend_address_fqdn -z 4 -c "$(printf "${site_name}")" # need to pass vars that use * with this paramater

```