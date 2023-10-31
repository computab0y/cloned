data "azurerm_client_config" "current" {}


#Shared management RG, hosting DNS Zone and Key Vault
data "azurerm_resource_group" "shared_mgmt" {
  provider  = azurerm.dns
  name      = "rg-mgmt-prod-shared-${var.location_identifier}"
}
data "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
}


data "azurerm_dns_zone" "base" {
  provider            = azurerm.dns
  name                = var.ocp_base_dns_zone
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}

data "azurerm_public_ip" "appgw" {
  provider            = azurerm.infra
  name                = "appgw-${var.ocp_cluster_instance}-pip"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
}

resource "azurerm_dns_a_record" "api" {
  provider            = azurerm.dns
  name                = "api.${var.ocp_cluster_instance}"
  zone_name           = data.azurerm_dns_zone.base.name
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
  ttl                 = 300
  records             = ["${data.azurerm_public_ip.appgw.ip_address}"]
}

resource "azurerm_dns_a_record" "apps" {
  provider            = azurerm.dns
  name                = "*.apps.${var.ocp_cluster_instance}"
  zone_name           = data.azurerm_dns_zone.base.name
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
  ttl                 = 300
  records             = ["${data.azurerm_public_ip.appgw.ip_address}"]
}