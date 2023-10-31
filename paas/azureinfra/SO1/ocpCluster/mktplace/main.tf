data "azurerm_client_config" "current" {}

#Linux Host creation
resource "azurerm_marketplace_agreement" "center-for-internet-security-inc" {
  publisher = "center-for-internet-security-inc"
  offer     = "cis-rhel-8-l2"
  plan      = "cis-rhel8-l2"
  lifecycle {
    ignore_changes = [
      publisher,
      offer,
      plan
    ]
  }
  
}
