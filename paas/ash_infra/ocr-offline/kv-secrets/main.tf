data "azurerm_client_config" "current" {}


data "azurerm_resource_group" "shared_mgmt" {
  provider  = azurerm.mgmt
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
}

 data "azurerm_key_vault" "buildcrhost" {
  provider             = azurerm.mgmt
  name                 = var.shrd_kv_name
  resource_group_name  = data.azurerm_resource_group.shared_mgmt.name
 }

resource "azurerm_key_vault_secret" "OCP-PULL-SECRET" {
  name         = "OCP-PULL-SECRET"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCR1-PUB-SSH-KEY" {
  name         = "OCR-${var.cr_instance}-PUB-SSH-KEY"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-SPN-APP-ID" {
  name         = "OCP-SPN-APP-ID"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "OCP-SPN-CLIENT-SECRET" {
  name         = "OCP-SPN-CLIENT-SECRET"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "RH-USERNAME" {
  name         = "RH-USERNAME"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "RH-PASSWORD" {
  name         = "RH-PASSWORD"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "RH-REPO-USER" {
  name         = "RH-REPO-USER"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "RH-REPO-SECRET" {
  name         = "RH-REPO-SECRET"
  # description = "Redhat pull se"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-GH-PAT" {
  name         = "BUILD-GH-PAT"
  # description = "GitHub Personal Access token used to access repos. needed to copy to the bootstrap Quay VM"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-PGSQL-ADMIN-PW" {
  name         = "BUILD-PGSQL-ADMIN-PW"
  # description = "PostgreSQL container admins pw"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-PGSQL-PW" {
  name         = "BUILD-PGSQL-PW"
  # description = "PostgreSQL container password"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-pgSQL-USER" {
  name         = "BUILD-pgSQL-USER"
  # description = "PostgreSQL container user name"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-quay-email" {
  name         = "BUILD-quay-email"
  # description = "Quay Container registered email address"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-quay-password" {
  name         = "BUILD-quay-password"
  # description = "Quay Container password"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-quay-username" {
  name         = "BUILD-quay-username"
  # description = "Quay Container username"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_key_vault_secret" "BUILD-REDIS-PW" {
  name         = "BUILD-REDIS-PW"
  # description = "Redis Cache password used for Quay"
  value        = ""
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  lifecycle {
     ignore_changes = all
  } 
}

