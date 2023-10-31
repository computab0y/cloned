data "azurerm_client_config" "current" {}



data "azurerm_resource_group" "shared_mgmt" {
  provider  = azurerm.mgmt
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
}

 data "azurerm_key_vault" "ocpmgmt" {
  provider             = azurerm.mgmt
  name                 = var.shrd_kv_name
  resource_group_name  = data.azurerm_resource_group.shared_mgmt.name
 }

resource "azurerm_key_vault_secret" "DNS-SPN-SUBSCRIPTION-ID" {
  name         = "DNS-SPN-SUBSCRIPTION-ID"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "DNS-SPN-TENANT-ID" {
  name         = "DNS-SPN-TENANT-ID"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "DNS-SPN-APP-ID" {
  name         = "DNS-SPN-APP-ID"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "DNS-SPN-CLIENT-SECRET" {
  name         = "DNS-SPN-CLIENT-SECRET"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-PULL-SECRET" {
  name         = "OCP-PULL-SECRET"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-PUB-SSH-KEY" {
  name         = "${var.ocp_cluster_instance}-PUB-SSH-KEY"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-SPN-APP-ID" {
  name         = "OCP-SPN-APP-ID"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-SPN-CLIENT-SECRET" {
  name         = "OCP-SPN-CLIENT-SECRET"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  }
}
 resource "azurerm_key_vault_secret" "OCP-SPN-CLIENT-TENANTID" {
  name         = "OCP-SPN-CLIENT-TENANTID"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  }   
}
resource "azurerm_key_vault_secret" "OCP-SPN-CLIENT-TENANTID" {
  name         = "${var.ocp_cluster_instance}-OC-CERT-SPN"
  #description  = "OCP service principal token used for certificate renewals"
  value        = ""
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  }   
}