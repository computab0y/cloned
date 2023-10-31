# Enabling external domains on D2S

Customer applications may (will) want to use a different domain name for their service and will need to use an SSL certificate to encrypt client/server communications.  As the Azure Application Gateway is a Layer 7 proxy / WAF, (terminating the TLS session, inspecting the payload and re-encrypting), there is an element of initial setup required to enable this.

** In order to make it more autono

|Step        |Responsibility | Description |
|:-----------|:-|:---------------|
|1|D2S Platform Team| Request an Azure AD Application Registration (SPN). This request goes to the CES Service Desk|
|2|D2S Platform Team| Run [**add-customer-listener.sh**](./../app-gw/add-customer-listener/add-customer-listener.sh) using specific parameters for the customer app |
|3|D2S Platform Team | Create the cert requests|
|4|D2S Platform Team | Create the Secret to store the TLS cert in OpenShift|
|5|D2S Platform Team | Create the ingress route on OpenShift|
|6|D2S Platform Team | Update the certificate secret on the dedicated Azure Key Vault|

## /add-customer-listener.sh/

The purpose of this script is to create the necessary configuration on the app gw and the key vault to support the hosting of the ssl cert.

To run the command, make sure you are authenticated to the correct Azure AD tenant. [Cluster info](./../../../cluster-info.md) will give details.

```bash
export app_name='mod-svc'             # used to generate resource group / resources.  8 chars or less
export base_fqdn='service.mod.gov.uk' # base domain name hosting the service(s)
export site_name="*"                # suggest leaving as * so all sub domains auto route to the OpenShift load balancer
export backend_address_fqdn="home.service.mod.gov.uk" # use this to probe an actual service

./azureinfra/SO2/app-gw/add-customer-listener/add-customer-listener.sh -a $app_name -b $base_fqdn -f $backend_address_fqdn -z 3 -c "$(printf "${site_name}")" # need to pass vars that use * with this parameter

```

It is recommended to sotre the parameters / command line used in the following file: [example-customer.md](./../app-gw/add-customer-listener/example-customer.md)

### High level steps

- Obtain internal load balancer IP address that points to the ingress proxy on the cluster. 
- Create a Resource Group to host WAF Policy, Key Vault and Private DNS Zone
- Create Private DNS Zone for the Domain Name that will be served. This is linked to the Cluster / App GW Vnet
- Create an A record on the Private DNS zone (typically will be * - wildcard entry), IP address is load balancer IP address obtained in first step. 
- Create a Key Vault. Ensures that SSL certs are only available to that team
- App GW managed user identity is added to the key vault access policy (get, list on secrets and certificates). This allows the App GW to periodically check for new certificates added to the Key Vault.
- Generate a self-signed TLS placeholder cert to add to the key vault
- Create SSL Cert on the App GW, pointing to the Key Vault
- Create probe on the App GW, using provided backend host name parameter
- Create backend address pool, using provided backend host name parameter
- Create http setting, using newly created probe, https as the protocol
- Create a listener, specifying provided domain as the hostname and ssl cert previously created
- Create rewrite rules to ensure security options are set in response headers
- Create routing rules, using previously created backend pool, http listener, http settings, rewrite rule. It needs to have a unique priority, so the script calculates this
- Create a WAF Policy. Assign it to the Listener
- (Optional) - create exception rules for the WAF policy. Edit these per the requirements for the service


