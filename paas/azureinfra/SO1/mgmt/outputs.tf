output "firewall_ip" {
    value = "${azurerm_firewall.fw.ip_configuration.0.private_ip_address}"
}

output "kv_name" {
    value = "${azurerm_key_vault.ocpmgmt.name}"
}