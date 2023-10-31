data "azurerm_client_config" "current" {}

# Enable Microsoft Defender for DNS
resource "azurerm_security_center_subscription_pricing" "dns-mgmt" {
  provider      = azurerm.mgmt
  tier          = "Standard"
  resource_type = "Dns"
}

resource "azurerm_security_center_subscription_pricing" "dns-infra" {
  provider  = azurerm.infra
  tier          = "Standard"
  resource_type = "Dns"
}

