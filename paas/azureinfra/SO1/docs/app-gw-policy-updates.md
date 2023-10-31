
##Application Gateway WAF Policy Access List Update

The current configuration for the WAF is to deny all but allowed IP addresses (and is within the GB region). This is designed as such for allowing teams to perform their commissioning activities until a pentest has been performed.

The Access List is configured by modiying the [variables.tf](./../app-gw/policy-rules/variables.tf) file, locating the variable `app_gw_allow_ips` and adding the IP addresses as required. For example:

```
variable "app_gw_allow_ips" {
  default = [
  "1.2.3.4",       # Jane Doe
  "5.6.7.8",       # Joe Bloggs
  "10.10.10.10/28" # Dev team A IP range
 ]
}
```

In order to keep track of the IP, place a comment by the IP (```#```)

To implement the changes, from a Linux shell, run the following script:

`$ ./app-gw/deploy-az-policy-app-gw.sh -z <env_instance>`

Prior to running, the script, connect to the MGMT subscription via az

`$ az login`

`$ az account set --subscription <Name of the MGMT subscription>`


   - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)