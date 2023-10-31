# Azure Firewall Policy Rule Update

As the OCP platform evolves, access to external endpoints will change. 

These rules are managed by a Terrform workflow located [here](./../az-firewall-policy/).

The rules are managed directly within the [main.tf](./../az-firewall-policy/main.tf) file.

Rules belong to an application rule collection, which in turn belong to a rule collection group.

```rule``` blocks contain the configuration data.

A rule can use either FQDN's or URL's, HTTP, HTTP or a combination.

## FQDN Rules

FQDN rules are faster to process than URL rules, as the communication flow does not require TLS termination for HTTPS requests.

Here is an example of creating a rule using FQDN's

```
# Leave a comment to describe the rule
rule {
      name = "${var.ocp_cluster_instance}-rule_azmonitor-telemetry-https"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      destination_fqdns = [
        "dc.applicationinsights.azure.com",
        "dc.applicationinsights.microsoft.com",
        "dc.services.visualstudio.com",
        "*.in.applicationinsights.azure.com",
        "live.applicationinsights.azure.com",
        "rt.applicationinsights.microsoft.com",
        "rt.services.visualstudio.com"
      
        ]
    }
```

## URL Rules

Here is an example of creating a rule using URL's

```
# Leave a comment to describe the rule
rule {
      name = "${var.ocp_cluster_instance}-rule_azmonitor-config-https"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${data.azurerm_virtual_network.ocpcluster.address_space[0]}"]
      terminate_tls = true
      destination_urls = [
        "management.core.windows.net",
        "management.azure.com",
        "login.windows.net",
        "login.microsoftonline.com",
        "secure.aadcdn.microsoftonline-p.com",
        "auth.gfx.ms",
        "login.live.com",
        "globalcdn.nuget.org",
        "packages.nuget.org",
        "api.nuget.org/v3/index.json",
        "nuget.org",
        "api.nuget.org",
        "dc.services.vsallin.net"
        ]
    }
```

## Updating the Azure Firewall policy

To implement the changes, from a Linux shell, run the following script:

`$ ./az-firewall-policy/deploy-az-fw-pol.sh -z <env_instance>`

Prior to running, the script, connect to the MGMT subscription via az cli

`$ az login`

`$ az account set --subscription <Name of the MGMT subscription>`


   - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)