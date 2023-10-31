data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  provider           = azurerm.mgmt
  name               = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
  
}


#Firewall Policy
data "azurerm_firewall_policy" "fw-pol01" {
  provider                = azurerm.mgmt
  name                    = "pol-fw-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name     = data.azurerm_resource_group.rg.name

}


resource "azurerm_firewall_policy_rule_collection_group" "deploy_rules" {
  provider           = azurerm.mgmt
  name               = "DEPLOY-${var.ocp_cluster_instance}-fwpolicy-rcg"
  firewall_policy_id = data.azurerm_firewall_policy.fw-pol01.id
  priority           = var.rule_priority
  application_rule_collection {
    name     = "DEPLOY-${var.ocp_cluster_instance}-rule-coll"
    priority = var.rule_priority
    action   = "Allow"
    rule {
      name = "DEPLOY-${var.ocp_cluster_instance}-rule-coll_rule1"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${var.subnet_default}"]
      destination_fqdns = [
        "management.microsoft.com",
        "packages.microsoft.com",
        "*.microsoft.com",
        "*.blob.core.windows.net",
        "*.blob.storage.azure.net",
        "*.opinsights.azure.com",
        "*.agentsvc.azure-automation.net"
        ]
    }
    rule {
      name = "DEPLOY-${var.ocp_cluster_instance}-rule-coll_rule2"
     protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${var.subnet_default}"]
      destination_fqdns = [
        "mirror.openshift.com",
        "api.openshift.com",
        "registry.redhat.io",
        "*.quay.io",
        "sso.redhat.com",
        "openshift.org",
        "registry.access.redhat.com"
  
      ]
    }
     rule {
      name = "DEPLOY-${var.ocp_cluster_instance}-rule-coll_rule3"
     protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      source_addresses  = ["${var.subnet_default}"]
      destination_fqdns = [
        "*.github.com",
        "github.com",
        "rpm.releases.hashicorp.com"
        ]
    }
    rule {
      name = "${var.ocp_cluster_instance}-rule_management_host"
      description = "requirements for management server"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${var.subnet_default}"]
      destination_fqdns = [
         "rpm.releases.hashicorp.com",
         "registry.terraform.io",
         "pypi.python.org", # required for pip installs
         "checkpoint-api.hashicorp.com"
        ]
    }
  }
}
