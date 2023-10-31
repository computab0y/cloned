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
  name               = "DEPLOY-build-cr-${var.cr_instance}-fwpolicy-rcg"
  firewall_policy_id = data.azurerm_firewall_policy.fw-pol01.id
  priority           = var.rule_priority
  application_rule_collection {
    name     = "DEPLOY-build-cr-${var.cr_instance}-rule-coll"
    priority = var.rule_priority
    action   = "Allow"
    rule {
      name = "DEPLOY-build-cr-${var.cr_instance}-rule-coll_rule1"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${var.subnet_default}"]
      destination_fqdns = [
        "management.azure.com",
        "packages.microsoft.com",
        "*.microsoft.com",
        "*.blob.core.windows.net",
        "*.blob.storage.azure.net",
        "*.opinsights.azure.com",
        "*.agentsvc.azure-automation.net",
        "*.vault.azure.net"
        ]
    }
    rule {
      name = "DEPLOY-build-cr-${var.cr_instance}-rule-coll_rule2"
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
        "registry.connect.redhat.com",
        "developers.redhat.com",
        "access.cdn.redhat.com",
        "api.openshift.com",
        "registry.redhat.io",
        "*.quay.io",
        "quay.io",
        "sso.redhat.com",
        "openshift.org",
        "registry.access.redhat.com",
        "subscription.rhsm.redhat.com",
        "cdn.redhat.com",
        "rhcos-redirector.apps.art.xq1c.p1.openshiftapps.com",
        "art-rhcos-ci.s3.amazonaws.com",
        "storage.googleapis.com",
        "*.amazonaws.com"
      ]
    }
     rule {
      name = "DEPLOY-build-cr-${var.cr_instance}-rule-coll_rule3"
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
        "raw.githubusercontent.com",
        "objects.githubusercontent.com",
        "rpm.releases.hashicorp.com",
        "pypi.python.org",
        "pypi.org",
        "files.pythonhosted.org"
        ]
    }
    rule {
      name = "DEPLOY-build-cr-${var.cr_instance}-rule_allow_ocpclusters"
      description = "allow access to other ocp clusters"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["${var.subnet_default}"]
      destination_fqdns = [
         "*.azure.dso.digital.mod.uk"
        ]
    }
  }
}
