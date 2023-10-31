data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "ocpcluster" {
  name      = "rg-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}"
  location  = var.resource_group_location
  tags = {
    Owner = "${var.owner}",
    Solution = ""
  }
}

resource "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
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

resource "azurerm_virtual_network" "ocpcluster" {
  name                = "${var.ocp_vnet_prefix}-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.ocpmgmt.location
  resource_group_name = azurerm_resource_group.ocpmgmt.name
  address_space       = [var.vnet_addr_space]
  #dns_servers         = ["25.25.25.25", "25.26.27.28"]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

resource  "azurerm_subnet" "default" {
  name                = "default"
  resource_group_name  = azurerm_resource_group.ocpmgmt.name
  virtual_network_name = azurerm_virtual_network.ocpcluster.name
  address_prefixes     = [var.subnet_default]
}
resource  "azurerm_subnet" "appgw" {
  name                = "appgw"
  resource_group_name  = azurerm_resource_group.ocpmgmt.name
  virtual_network_name = azurerm_virtual_network.ocpcluster.name
  address_prefixes     = [var.subnet_appgw]
  depends_on           = [azurerm_subnet.default]  

}

resource  "azurerm_subnet" "control_plane_subnet" {
  name                 = "control_plane_subnet"
  resource_group_name  = azurerm_resource_group.ocpmgmt.name
  virtual_network_name = azurerm_virtual_network.ocpcluster.name
  address_prefixes     = [var.subnet_control_plane]
  depends_on           = [azurerm_subnet.appgw]  
}
resource  "azurerm_subnet" "compute_subnet" {
  name                 = "compute_subnet"
  resource_group_name  = azurerm_resource_group.ocpmgmt.name
  virtual_network_name = azurerm_virtual_network.ocpcluster.name
  address_prefixes     = [var.subnet_compute_subnet]
  depends_on           = [azurerm_subnet.control_plane_subnet] 
}

resource  "azurerm_subnet" "ingress_subnet" {
  name                 = "ingress_subnet"
  resource_group_name  = azurerm_resource_group.ocpmgmt.name
  virtual_network_name = azurerm_virtual_network.ocpcluster.name
  address_prefixes     = [var.subnet_ingress_subnet]
  depends_on           = [azurerm_subnet.compute_subnet] 
}

# Create Peering links
resource "azurerm_virtual_network_peering" "mgmt_to_spoke" {
  provider                  = azurerm.mgmt
  name                      = "${data.azurerm_virtual_network.shared_mgmt.name}-to-${azurerm_virtual_network.ocpcluster.name}"
  resource_group_name       = data.azurerm_resource_group.shared_mgmt.name
  virtual_network_name      = data.azurerm_virtual_network.shared_mgmt.name
  remote_virtual_network_id = azurerm_virtual_network.ocpcluster.id
}

resource "azurerm_virtual_network_peering" "spoke_to_mgmt" {
  name                      = "${azurerm_virtual_network.ocpcluster.name}-to-${data.azurerm_virtual_network.shared_mgmt.name}"
  resource_group_name       = azurerm_resource_group.ocpmgmt.name
  virtual_network_name      = azurerm_virtual_network.ocpcluster.name
  remote_virtual_network_id = data.azurerm_virtual_network.shared_mgmt.id
}

resource "azurerm_network_security_group" "ingress_subnet" {
  name                = "nsg-${var.ocp_cluster_instance}-ingress-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.ocpmgmt.location
  resource_group_name = azurerm_resource_group.ocpmgmt.name
}
resource "azurerm_monitor_diagnostic_setting" "nsg-ingress_subnet" {
   name              = "LAW-Diags-nsg-ingress_subnet"
   target_resource_id = azurerm_network_security_group.ingress_subnet.id
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

resource "azurerm_network_security_group" "default" {
  name                = "nsg-${var.ocp_cluster_instance}-data-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.ocpmgmt.location
  resource_group_name = azurerm_resource_group.ocpmgmt.name
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

resource "azurerm_network_security_group" "compute_subnet" {
  name                = "nsg-${var.ocp_cluster_instance}-compute-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.ocpmgmt.location
  resource_group_name = azurerm_resource_group.ocpmgmt.name
  security_rule {
    name                       = "AllowHttpsInbound-int"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  ## This rule breaks the install until the ingress nodes are available
  # security_rule {
  #   name                       = "DenyInbound-LB"
  #   priority                   = 120
  #   direction                  = "Inbound"
  #   access                     = "Deny"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "AzureLoadBalancer"
  #   destination_address_prefix = "*"
  # }
  security_rule {
    name                       = "AllowHttpInbound-int"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg-compute_subnet" {
   name              = "LAW-Diags-nsg-compute_subnet"
   target_resource_id = azurerm_network_security_group.compute_subnet.id
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

resource "azurerm_network_security_group" "control_plane_subnet" {
  name                = "nsg-${var.ocp_cluster_instance}-control-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.ocpmgmt.location
  resource_group_name = azurerm_resource_group.ocpmgmt.name
  security_rule {
    name                       = "AllowAPIInbound-int"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowAPIInbound-LB"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefixes = ["10.2.1.5","10.2.1.6","10.2.1.7"]
  }
  security_rule {
    name                       = "AllowMachineConfigInbound-int"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22623"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DenyInbound-LB"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}
resource "azurerm_monitor_diagnostic_setting" "nsg-control_plane_subnet" {
   name              = "LAW-Diags-nsg-control_plane_subnet"
   target_resource_id = azurerm_network_security_group.control_plane_subnet.id
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

resource "azurerm_subnet_network_security_group_association" "ingress_subnet" {
  subnet_id                 = azurerm_subnet.ingress_subnet.id
  network_security_group_id = azurerm_network_security_group.ingress_subnet.id
  depends_on = [
    azurerm_subnet.ingress_subnet,
    azurerm_network_security_group.ingress_subnet
  ]
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.default.id
  depends_on = [
    azurerm_subnet.default,
    azurerm_network_security_group.default
  ]
}

resource "azurerm_subnet_network_security_group_association" "compute_subnet" {
  subnet_id                 = azurerm_subnet.compute_subnet.id
  network_security_group_id = azurerm_network_security_group.compute_subnet.id
  depends_on = [
    azurerm_subnet.compute_subnet,
    azurerm_network_security_group.compute_subnet
  ]
}
resource "azurerm_subnet_network_security_group_association" "control_plane_subnet" {
  subnet_id                 = azurerm_subnet.control_plane_subnet.id
  network_security_group_id = azurerm_network_security_group.control_plane_subnet.id
  depends_on = [
    azurerm_subnet.control_plane_subnet,
    azurerm_network_security_group.control_plane_subnet
  ]
}
data "azurerm_virtual_network" "shared_mgmt" {
  provider = azurerm.mgmt
  name = "${var.ocp_vnet_prefix}-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}

 data "azurerm_key_vault" "ocpmgmt" {
  provider             = azurerm.mgmt
  name                 = var.shrd_kv_name
  resource_group_name  = data.azurerm_resource_group.shared_mgmt.name
 }

# Only requred for environment hosting the public DNS zone
 /* data "azurerm_dns_zone" "ocp-basedomain" {
  provider             = azurerm.mgmt
  name                 = "${var.ocp_base_dns_zone}"
  resource_group_name  = data.azurerm_resource_group.shared_mgmt.name
   
 } */


resource "azurerm_route_table" "inet" {
  name                          = "internetEgress"
  location                      = azurerm_resource_group.ocpmgmt.location
  resource_group_name           = azurerm_resource_group.ocpmgmt.name
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
resource "azurerm_subnet_route_table_association" "ocp_control_plane_subnet" {
  subnet_id      = azurerm_subnet.control_plane_subnet.id
  route_table_id = azurerm_route_table.inet.id
  depends_on = [
    azurerm_subnet.control_plane_subnet,
    azurerm_route_table.inet
  ]
}
resource "azurerm_subnet_route_table_association" "ocp_compute_subnet" {
  subnet_id      = azurerm_subnet.compute_subnet.id
  route_table_id = azurerm_route_table.inet.id
  depends_on = [
    azurerm_subnet.compute_subnet,
    azurerm_route_table.inet
  ]
}
resource "azurerm_subnet_route_table_association" "ingress_subnet" {
  subnet_id      = azurerm_subnet.ingress_subnet.id
  route_table_id = azurerm_route_table.inet.id
  depends_on = [
    azurerm_subnet.ingress_subnet,
    azurerm_route_table.inet
  ]
}


# Storage account to store binaries, scripts etc.

resource "random_id" "storage_account" {
  byte_length = 8
}

resource "azurerm_storage_account" "sa1" {
  provider                 = azurerm.infra
  name                     = substr("${lower(var.ocp_cluster_instance)}mg${lower(random_id.storage_account.hex)}",0,24)
  resource_group_name      = azurerm_resource_group.ocpmgmt.name
  location                 = azurerm_resource_group.ocpmgmt.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "scripts" {
  provider              = azurerm.infra
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.sa1.name
  container_access_type = "private"
  depends_on = [
     azurerm_storage_account.sa1
  ]
}
resource "azurerm_storage_container" "etcd" {
  provider              = azurerm.infra
  name                  = "etcd"
  storage_account_name  = azurerm_storage_account.sa1.name
  container_access_type = "private"
  depends_on = [
     azurerm_storage_account.sa1
  ]
  lifecycle {
     ignore_changes = all
  } 
}
resource "azurerm_storage_container" "auditlogs" {
  provider              = azurerm.infra
  name                  = "auditlogs"
  storage_account_name  = azurerm_storage_account.sa1.name
  container_access_type = "private"
  depends_on = [
     azurerm_storage_account.sa1
  ]
  lifecycle {
    ignore_changes = all
  }
}
resource "azurerm_storage_container" "dbbackup" {
  provider              = azurerm.infra
  name                  = "dbbackup"
  storage_account_name  = azurerm_storage_account.sa1.name
  container_access_type = "private"
  depends_on = [
     azurerm_storage_account.sa1
  ]
  lifecycle {
    ignore_changes = all
  }
}



resource "azurerm_monitor_diagnostic_setting" "sa1" {
   name              = "LAW-Diags-stg-scripts"
   target_resource_id = azurerm_storage_account.sa1.id
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id

   metric {
     category = "Transaction"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
}
resource "azurerm_monitor_diagnostic_setting" "sa1-blob" {
   name              = "LAW-Diags-stg-scripts-blob"
   target_resource_id = "${azurerm_storage_account.sa1.id}/blobServices/default/"
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
  name                     = substr("${lower(var.ocp_cluster_instance)}vm${lower(random_id.storage_account.hex)}",0,24)
  resource_group_name      = azurerm_resource_group.ocpmgmt.name
  location                 = azurerm_resource_group.ocpmgmt.location
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


resource "azurerm_storage_blob" "manifest_secrets" {
  provider               = azurerm.infra
  name                   = "modify-manifest-secrets.sh"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/modify-manifest-secrets.sh")
  source                 = "../scripts/modify-manifest-secrets.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "manifest" {
  provider               = azurerm.infra
  name                   = "manifests.tar"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("./manifests.tar")
  source                 = "manifests.tar"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

resource "azurerm_storage_blob" "genappscert" {
  provider               = azurerm.infra
  name                   = "gen-apps-cert.sh"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/gen-apps-cert.sh")
  source                 = "../scripts/gen-apps-cert.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "genapicert" {
  provider               = azurerm.infra
  name                   = "gen-api-cert.sh"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/gen-api-cert.sh")
  source                 = "../scripts/gen-api-cert.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "tools" {
  provider               = azurerm.infra
  name                   = "install-tools.sh"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/install-tools.sh")
  source                 = "../scripts/install-tools.sh"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "config" {
  provider               = azurerm.infra
  name                   = "install-config.yaml"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/install-config.yaml")
  source                 = "../scripts/install-config.yaml"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}
resource "azurerm_storage_blob" "ca-cert" {
  provider               = azurerm.infra
  name                   = "zeroSSL.cer"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/zeroSSL.cer")
  source                 = "../scripts/zeroSSL.cer"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

resource "azurerm_storage_blob" "root-ca" {
  provider               = azurerm.infra
  name                   = "sectigo-aaa-root.cer"
  storage_account_name   = azurerm_storage_account.sa1.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/sectigo-aaa-root.cer")
  source                 = "../scripts/sectigo-aaa-root.cer"

  depends_on = [
     azurerm_storage_container.scripts
  ]
}

#Linux Host creation
resource "azurerm_network_interface" "deployhost" {
  name                = "nic-vm-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
  location            = azurerm_resource_group.ocpmgmt.location
  resource_group_name = azurerm_resource_group.ocpmgmt.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nic-deployhost" {
   name              = "LAW-Diags-stg-vm-diags-blob"
   target_resource_id = azurerm_network_interface.deployhost.id
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

resource "azurerm_linux_virtual_machine" "deployhost" {
  name                = "vm-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
  resource_group_name = azurerm_resource_group.ocpmgmt.name
  location            = azurerm_resource_group.ocpmgmt.location
  size                = "Standard_F2"
  admin_username      = var.vm_user_name
  boot_diagnostics {
    storage_account_uri  = azurerm_storage_account.vm-diags.primary_blob_endpoint
  }
  identity {
    type              = "SystemAssigned"
  }
  network_interface_ids = [
    azurerm_network_interface.deployhost.id,
  ]
  depends_on = [
     azurerm_network_interface.deployhost,
     azurerm_virtual_network_peering.spoke_to_mgmt,
     azurerm_virtual_network_peering.mgmt_to_spoke,
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
data "azurerm_storage_account_sas" "sa1" {
  connection_string = azurerm_storage_account.sa1.primary_connection_string
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
resource "azurerm_virtual_machine_extension" "deployhost" {
  name                 = "deployOCPMgmtHost"
  virtual_machine_id   = azurerm_linux_virtual_machine.deployhost.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  depends_on = [
     azurerm_linux_virtual_machine.deployhost,
     azurerm_storage_blob.genappscert,
     azurerm_storage_blob.genapicert,
     azurerm_storage_blob.tools,
     azurerm_storage_blob.config,
     azurerm_storage_blob.ca-cert,
     azurerm_storage_blob.root-ca
  ]

  settings = <<SETTINGS
    {
      "fileUris": [
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/gen-apps-cert.sh${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/gen-api-cert.sh${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/install-tools.sh${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/install-config.yaml${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/zeroSSL.cer${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/manifests.tar${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/modify-manifest-secrets.sh${data.azurerm_storage_account_sas.sa1.sas}",
                   "https://${azurerm_storage_account.sa1.name}.blob.core.windows.net/scripts/sectigo-aaa-root.cer${data.azurerm_storage_account_sas.sa1.sas}"
                ]
    }
SETTINGS

protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "sh install-tools.sh -u ${var.vm_user_name} -v ${var.ocp_vers} -o ${var.ocp_cluster_instance} -s ${base64encode(var.pub_ssh_key)} -n ${azurerm_virtual_network.ocpcluster.name} -a ${var.vnet_addr_space} -b ${var.ocp_base_dns_zone} -e ${var.owner} -k ${var.shrd_kv_name} -i ${var.infra_sub_name} -m ${var.mgmt_sub_name} -c ${var.op_env} -l ${var.location_identifier} -t ${var.infra_tenant_id} -w ${var.infra_sub_id}"
    }
PROTECTED_SETTINGS

}


resource "azurerm_virtual_machine_extension" "log" {
  name                       = "OmsAgentForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.deployhost.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.12"
  auto_upgrade_minor_version = true
  depends_on = [
     azurerm_linux_virtual_machine.deployhost,
     azurerm_virtual_machine_extension.deployhost
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

# below works when the user running the script is an owner / has user access administrator role
#Assign rights to the OCP Cluster RG for the System Assign Identity
/* resource "azurerm_role_assignment" "deployVM-infra-contrib" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = azurerm_resource_group.ocpcluster.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
} */

# below works when the user running the script is an owner / has user access administrator role
#Assign rights to the OCP Cluster RG for the System Assign Identity
/* resource "azurerm_role_assignment" "deployVM-inframgmt-contrib" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = azurerm_resource_group.ocpmgmt.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
} */

# below works when the user running the script is an owner / has user access administrator role
/* resource "azurerm_role_assignment" "deployVM-infra-UAM" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = azurerm_resource_group.ocpcluster.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
}
resource "azurerm_role_assignment" "deployVM-inframgmt-UAM" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = azurerm_resource_group.ocpmgmt.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
} */

# Only requred for environment hosting the public DNS zone
/* #Assign rights to the DNS Zone for the System Assign Identity
resource "azurerm_role_assignment" "deployVM-mgmt-DNS" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_dns_zone.ocp-basedomain.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
} */

/* # assign rights to the Key Vault
resource "azurerm_role_assignment" "kv" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_key_vault.ocpmgmt.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
} */
resource "azurerm_key_vault_access_policy" "kv" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  provider     = azurerm.mgmt
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id

  key_permissions = [
    "Get","List","Create","Update",
  ]

  secret_permissions = [
    "Get","List","Set",
  ]
}



/* data "azuread_service_principal" "spn" {
  display_name = var.spn_obj_name
} */

# below works when the user running the script is an owner / has user access administrator role
# resource "azurerm_role_assignment" "spn-inframgmt-UAM" {
#   depends_on = [
#      azurerm_linux_virtual_machine.deployhost
#   ]
#   lifecycle {
#     ignore_changes = all
#   }
#   scope                = azurerm_resource_group.ocpmgmt.id
#   role_definition_name = "User Access Administrator"
#   principal_id         = data.azuread_service_principal.spn.id
# }

/* #Assign rights to the OCP Cluster RG for the System Assign Identity
resource "azurerm_role_assignment" "spn-inframgmt-contrib" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = azurerm_resource_group.ocpmgmt.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.spn.id
} */

# Only applicable for environment where the DNS zone is hosted
/* resource "azurerm_role_assignment" "spn-mgmt-DNS" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_dns_zone.ocp-basedomain.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = data.azuread_service_principal.spn.id
} */