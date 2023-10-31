data "azurerm_client_config" "current" {}

locals {
  ocpmgmt_rg_name = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
  mgmt_rg_name   = "rg-mgmt-${var.op_env}-infra-${var.location_identifier}"
}

resource "random_id" "key_vault" {
  byte_length = 2
}

resource "azurerm_resource_group" "rg" {
  name      = local.mgmt_rg_name
  location  = var.resource_group_location
  tags = {
    Owner    = "${var.owner}",
    Solution = "${var.solution}"

  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_resource_group" "ocpcluster" {
  name      = local.ocpmgmt_rg_name
  location  = var.resource_group_location
  tags = {
    Owner = "${var.owner}",
    Solution = ""
  }
}

resource "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = local.ocpmgmt_rg_name
  location  = var.resource_group_location
  tags = {
    Owner    = "${var.owner}",
    Solution = "${var.solution}"

  }
}

resource "azurerm_key_vault" "ocpmgmt" {

  name                        =  "kv-${var.op_env}-infra-${lower(random_id.key_vault.hex)}-${var.location_identifier}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = local.mgmt_rg_name 
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false
  enabled_for_template_deployment = true
  enabled_for_deployment      = true

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
    ]

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    storage_permissions = [
      "get",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
  }
  lifecycle {
    prevent_destroy = true
    # ignore_changes = all
    
  }
}

resource "azurerm_key_vault_secret" "DNS-SPN-SUBSCRIPTION-ID" {
  name         = "DNS-SPN-SUBSCRIPTION-ID"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "DNS-SPN-TENANT-ID" {
  name         = "DNS-SPN-TENANT-ID"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "DNS-SPN-APP-ID" {
  name         = "DNS-SPN-APP-ID"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "DNS-SPN-CLIENT-SECRET" {
  name         = "DNS-SPN-CLIENT-SECRET"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-PULL-SECRET" {
  name         = "OCP-PULL-SECRET"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-PUB-SSH-KEY" {
  name         = "${var.ocp_cluster_instance}-PUB-SSH-KEY"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-SPN-APP-ID" {
  name         = "OCP-SPN-APP-ID"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-SPN-CLIENT-SECRET" {
  name         = "OCP-SPN-CLIENT-SECRET"
  value        = ""
  key_vault_id = azurerm_key_vault.ocpmgmt.id
  lifecycle {
     ignore_changes = all
  } 
}