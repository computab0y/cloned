data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "build_cr" {
  provider  = azurerm.infra
  name      = "rg-buildocr-${var.cr_instance}-${var.op_env}-${var.location_identifier}"
  location  = var.resource_group_location
  tags = {
    Owner    = "${var.owner}",
    Solution = "${var.solution}"

  }
}


data "azurerm_resource_group" "shared_mgmt" {
  provider  = azurerm.mgmt
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
}

data "azurerm_firewall" "fw" {
  provider            = azurerm.mgmt
  name                = "azfw-mgmt-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}

# We need to setup some rules so the VM Extension provisioning will work
data "azurerm_firewall_policy" "fw-pol01" {
  provider             = azurerm.mgmt
  name                 = "pol-fw-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name  = data.azurerm_resource_group.shared_mgmt.name

}
data "azurerm_log_analytics_workspace" "log" {
  provider            = azurerm.mgmt
  name                = "law-mgmt-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}

resource "azurerm_virtual_network" "build_cr" {
  name                = "${var.ocp_vnet_prefix}-buildcr-${var.cr_instance}-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.build_cr.location
  resource_group_name = azurerm_resource_group.build_cr.name
  address_space       = [var.vnet_addr_space_cr]
  #dns_servers         = ["25.25.25.25", "25.26.27.28"]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

resource  "azurerm_subnet" "default" {
  name                = "default"
  resource_group_name  = azurerm_resource_group.build_cr.name
  virtual_network_name = azurerm_virtual_network.build_cr.name
  address_prefixes     = [var.subnet_default_ocr]
}

# Create Peering links
resource "azurerm_virtual_network_peering" "mgmt_to_spoke" {
  provider                  = azurerm.mgmt
  name                      = "${data.azurerm_virtual_network.shared_mgmt.name}-to-${azurerm_virtual_network.build_cr.name}"
  resource_group_name       = data.azurerm_resource_group.shared_mgmt.name
  virtual_network_name      = data.azurerm_virtual_network.shared_mgmt.name
  remote_virtual_network_id = azurerm_virtual_network.build_cr.id
}

resource "azurerm_virtual_network_peering" "spoke_to_mgmt" {
  name                      = "${azurerm_virtual_network.build_cr.name}-to-${data.azurerm_virtual_network.shared_mgmt.name}"
  resource_group_name       = azurerm_resource_group.build_cr.name
  virtual_network_name      = azurerm_virtual_network.build_cr.name
  remote_virtual_network_id = data.azurerm_virtual_network.shared_mgmt.id
}

resource "azurerm_network_security_group" "default" {
  name                = "nsg-ocp-buildcr-${var.cr_instance}-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.build_cr.location
  resource_group_name = azurerm_resource_group.build_cr.name
}

resource "azurerm_monitor_diagnostic_setting" "nsg-default" {
   name              = "LAW-Diags-nsg-default"
   target_resource_id = azurerm_network_security_group.default.id
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id

   log {
     category = "NetworkSecurityGroupEvent"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "NetworkSecurityGroupRuleCounter"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
  depends_on = [
    azurerm_subnet.default,
    azurerm_network_security_group.default,
    azurerm_subnet_route_table_association.ocp_default
  ]
}

resource "azurerm_route_table" "inet" {
  name                          = "internetEgress"
  location                      = azurerm_resource_group.build_cr.location
  resource_group_name           = azurerm_resource_group.build_cr.name
  disable_bgp_route_propagation = false

  route {
    name           = "internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.fw.ip_configuration.0.private_ip_address
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_subnet_route_table_association" "ocp_default" {
  subnet_id      = azurerm_subnet.default.id
  route_table_id = azurerm_route_table.inet.id
  depends_on = [
    azurerm_subnet.default,
    azurerm_route_table.inet
  ]
}


data "azurerm_virtual_network" "shared_mgmt" {
  provider = azurerm.mgmt
  name = "${var.ocp_vnet_prefix}-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}

 data "azurerm_key_vault" "buildcrhost" {
  provider             = azurerm.mgmt
  name                 = var.shrd_kv_name
  resource_group_name  = data.azurerm_resource_group.shared_mgmt.name
 }

# Storage account to store binaries, scripts etc.

resource "random_id" "storage_account" {
  byte_length = 8
}

resource "azurerm_storage_account" "sa2" {
  provider                 = azurerm.infra
  name                     = substr("${lower(var.ocp_cluster_instance)}cr${lower(random_id.storage_account.hex)}",0,24)
  resource_group_name      = azurerm_resource_group.build_cr.name
  location                 = azurerm_resource_group.build_cr.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "scripts" {
  provider              = azurerm.infra
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.sa2.name
  container_access_type = "private"
  depends_on = [
     azurerm_storage_account.sa2
  ]
}

resource "azurerm_monitor_diagnostic_setting" "sa2" {
   name              = "LAW-Diags-stg-scripts"
   target_resource_id = azurerm_storage_account.sa2.id
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id

   metric {
     category = "Transaction"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
}
resource "azurerm_monitor_diagnostic_setting" "sa2-blob" {
   name              = "LAW-Diags-stg-scripts-blob"
   target_resource_id = "${azurerm_storage_account.sa2.id}/blobServices/default/"
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id
   log {
    category = "StorageRead"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "StorageWrite"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "StorageDelete"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "Transaction"
    retention_policy {
      enabled = false
    }
  }
}


resource "azurerm_storage_account" "vm-diags" {
  provider                 = azurerm.infra
  name                     = substr("${lower(var.ocp_cluster_instance)}vmc${lower(random_id.storage_account.hex)}",0,24)
  resource_group_name      = azurerm_resource_group.build_cr.name
  location                 = azurerm_resource_group.build_cr.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "vm-diags" {
   name              = "LAW-Diags-stg-vm-diags"
   target_resource_id = azurerm_storage_account.vm-diags.id
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id

   metric {
     category = "Transaction"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
}
resource "azurerm_monitor_diagnostic_setting" "vm-diags-blob" {
   name              = "LAW-Diags-stg-vm-diags-blob"
   target_resource_id = "${azurerm_storage_account.vm-diags.id}/blobServices/default/"
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id
     log {
    category = "StorageRead"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "StorageWrite"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  log {
    category = "StorageDelete"
    enabled = true
    retention_policy {
      enabled = false
    }
  }
  metric {
    category = "Transaction"
    retention_policy {
      enabled = false
    }
  }
}


resource "azurerm_storage_blob" "prep_cluster_config" {
  provider               = azurerm.infra
  name                   = "prep-cluster-config.sh"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/prep-cluster-config.sh")
  source                 = "../scripts/prep-cluster-config.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

resource "azurerm_storage_blob" "bootstrap" {
  provider               = azurerm.infra
  name                   = "configure-bootstrap.sh"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/configure-bootstrap.sh")
  source                 = "../scripts/configure-bootstrap.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "buildquay" {
  provider               = azurerm.infra
  name                   = "build-quay.sh"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/build-quay.sh")
  source                 = "../scripts/build-quay.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "manifest" {
  provider               = azurerm.infra
  name                   = "manifests.tar"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("./manifests.tar")
  source                 = "manifests.tar"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

resource "azurerm_storage_blob" "config" {
  provider               = azurerm.infra
  name                   = "install-config.yaml"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/install-config.yaml")
  source                 = "../scripts/install-config.yaml"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "mirror" {
  provider               = azurerm.infra
  name                   = "openshift-mirror.sh"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/openshift-mirror.sh")
  source                 = "../scripts/openshift-mirror.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "apply_catalog" {
  provider               = azurerm.infra
  name                   = "apply-catalog.sh"
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/apply-catalog.sh")
  source                 = "../scripts/apply-catalog.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

resource "azurerm_storage_blob" "dso_scripts" {
  provider               = azurerm.infra
  name                   = var.dso_script_name
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/${var.dso_script_name}")
  source                 = "../scripts/${var.dso_script_name}"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "dso_tools" {
  provider               = azurerm.infra
  name                   = var.dso_tools_name
  storage_account_name   = azurerm_storage_account.sa2.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/${var.dso_tools_name}")
  source                 = "../scripts/${var.dso_tools_name}"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

#Linux Host creation
resource "azurerm_network_interface" "buildcrhost" {
  name                = "nic-quay-${var.cr_instance}-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.build_cr.location
  resource_group_name = azurerm_resource_group.build_cr.name
  depends_on = [
    azurerm_subnet_network_security_group_association.default
  ]

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nic-buildcrhost" {
   name              = "LAW-Diags-stg-vm-diags-blob"
   target_resource_id = azurerm_network_interface.buildcrhost.id
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id
  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
    }
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_managed_disk" "buildcr_data" {
  name                 = "quay-${var.cr_instance}-${var.op_env}-${var.location_identifier}-disk1"
  location             = azurerm_resource_group.build_cr.location
  resource_group_name  = azurerm_resource_group.build_cr.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "buildcr-data" {
  depends_on = [
    azurerm_managed_disk.buildcr_data,
    azurerm_linux_virtual_machine.buildcrhost
  ]
  managed_disk_id    = azurerm_managed_disk.buildcr_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.buildcrhost.id
  lun                = var.data_disk_lun
  caching            = "ReadWrite"
}

resource "azurerm_linux_virtual_machine" "buildcrhost" {
  name                = "quay"
  resource_group_name = azurerm_resource_group.build_cr.name
  location            = azurerm_resource_group.build_cr.location
  size                = "Standard_D4s_v3"
  admin_username      = var.vm_user_name
  boot_diagnostics {
    storage_account_uri  = azurerm_storage_account.vm-diags.primary_blob_endpoint
  }
  identity {
    type              = "SystemAssigned"
  }
  network_interface_ids = [
    azurerm_network_interface.buildcrhost.id,
  ]
  depends_on = [
     azurerm_network_interface.buildcrhost,
     azurerm_storage_account.vm-diags
  ]

  admin_ssh_key {
    username   = var.vm_user_name
    public_key = var.pub_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "center-for-internet-security-inc"
    offer     = "cis-rhel-8-l2"
    sku       = "cis-rhel8-l2"
    version   = "latest"
  }
  plan {
    name = "cis-rhel8-l2"
    publisher = "center-for-internet-security-inc"
    product = "cis-rhel-8-l2"
   }
}
data "azurerm_storage_account_sas" "sa2" {
  connection_string = azurerm_storage_account.sa2.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "8760h")

  permissions {
    read    = true
    write   = true
    delete  = false
    list    = false
    add     = true
    create  = true
    update  = false
    process = false
  }
}
resource "azurerm_virtual_machine_extension" "buildcrhost" {
  name                 = "deployBuildCRHost"
  virtual_machine_id   = azurerm_linux_virtual_machine.buildcrhost.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  depends_on = [
     azurerm_linux_virtual_machine.buildcrhost,
     azurerm_storage_blob.buildquay,
     azurerm_storage_blob.config,
     azurerm_storage_blob.mirror
  ]

  settings = <<SETTINGS
    {
      "fileUris": [
                   "${azurerm_storage_blob.prep_cluster_config.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.bootstrap.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.buildquay.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.manifest.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.config.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.mirror.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.dso_tools.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                    "${azurerm_storage_blob.dso_scripts.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
                   "${azurerm_storage_blob.apply_catalog.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b"
                ]
    }
SETTINGS

protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "sh build-quay.sh -u ${var.vm_user_name} -v ${var.ocp_vers} -o ${var.ocp_cluster_instance} -s ${base64encode(var.pub_ssh_key)} -a ${var.vnet_addr_space_cr} -b ${var.ocp_base_dns_zone} -e ${var.owner} -k ${var.shrd_kv_name} -i ${var.infra_sub_name} -m ${var.mgmt_sub_name} -c ${var.op_env} -l ${var.location_identifier} -d ${var.data_disk_lun}"
    }
PROTECTED_SETTINGS

}


resource "azurerm_virtual_machine_extension" "log" {
  name                       = "OmsAgentForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.buildcrhost.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.12"
  auto_upgrade_minor_version = true
  depends_on = [
     azurerm_linux_virtual_machine.buildcrhost,
     azurerm_virtual_machine_extension.buildcrhost
  ]

  settings = <<SETTINGS
    {
        "workspaceId": "${data.azurerm_log_analytics_workspace.log.workspace_id}"
    }
SETTINGS

  protected_settings = <<PROTECTEDSETTINGS
    {
        "workspaceKey": "${data.azurerm_log_analytics_workspace.log.primary_shared_key}"
    }
PROTECTEDSETTINGS
}


# assign rights to the Key Vault
/* resource "azurerm_role_assignment" "kv" {
  depends_on = [
     azurerm_linux_virtual_machine.buildcrhost
  ]
  scope                = data.azurerm_key_vault.buildcrhost.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.buildcrhost.identity.0.principal_id
} */



resource "azurerm_key_vault_access_policy" "buildcrhost" {
  depends_on = [
     azurerm_linux_virtual_machine.buildcrhost
  ]
  provider     = azurerm.mgmt
  key_vault_id = data.azurerm_key_vault.buildcrhost.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.buildcrhost.identity.0.principal_id

  key_permissions = [
    "Get","List",
  ]

  secret_permissions = [
    "Get","List",
  ]
}



/* data "azuread_service_principal" "spn" {
  display_name = var.spn_obj_name
}

# below works when the user running the script is an owner / has user access administrator role
 resource "azurerm_role_assignment" "spn-inframgmt-UAM" {
   depends_on = [
      azurerm_linux_virtual_machine.buildcrhost
   ]
   lifecycle {
     ignore_changes = all
   }
   scope                = azurerm_resource_group.buildcrhost.id
   role_definition_name = "User Access Administrator"
   principal_id         = data.azuread_service_principal.spn.id
}


 */
