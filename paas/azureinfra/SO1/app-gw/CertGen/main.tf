data "azurerm_client_config" "current" {}


#Shared management RG, hosting DNS Zone and Key Vault
data "azurerm_resource_group" "shared_mgmt" {
  provider  = azurerm.mgmt
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
}

data "azurerm_dns_zone" "base" {
  provider            = azurerm.mgmt
  name                = var.ocp_base_dns_zone
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}
 data "azurerm_key_vault" "ocpmgmt" {
   provider                    = azurerm.mgmt
   name                        = var.shrd_kv_name
   resource_group_name         = data.azurerm_resource_group.shared_mgmt.name
 }


#Create a self-signed cert for *.apps as a placeholder
resource "azurerm_key_vault_certificate" "apps" {
  name         = "${var.ocp_cluster_instance}-selfsign-app"
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["console-openshift-console.apps.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}",
                     "*.apps.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}" 
        ]
      }

      subject            = "CN=console-openshift-console.apps.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"
      validity_in_months = 12
    }
  }
}
#Create a self-signed cert for api as a placeholder
resource "azurerm_key_vault_certificate" "api" {
  name         = "${var.ocp_cluster_instance}-selfsign-api"
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["api.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"]
      }

      subject            = "CN=api.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"
      validity_in_months = 12
    }
  }
}
