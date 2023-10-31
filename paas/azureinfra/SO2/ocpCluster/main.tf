locals {
  ocpmgmt_rg_name    = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
  mgmt_rg_name       = "rg-mgmt-${var.op_env}-infra-${var.location_identifier}"
  ocpcluster_rg_name = "rg-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}"
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "ocpcluster" {
  name      = local.ocpcluster_rg_name
}

data "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = local.ocpmgmt_rg_name
}

data "azurerm_resource_group" "rg" {
  name      = local.mgmt_rg_name 
}

data "azurerm_key_vault" "ocpmgmt" {

  name                        = var.shrd_kv_name
  resource_group_name         = data.azurerm_resource_group.rg.name
}

data "azurerm_virtual_network" "ocpcluster" {
  name                = var.ocp_vnet_name
  resource_group_name = var.ocp_vnet_name_rg
  #dns_servers         = ["25.25.25.25", "25.26.27.28"]
}

data  "azurerm_subnet" "default" {
  name                 = "subnet1"
  virtual_network_name = data.azurerm_virtual_network.ocpcluster.name
  resource_group_name  = data.azurerm_virtual_network.ocpcluster.resource_group_name 
}

data  "azurerm_subnet" "control_plane_subnet" {
  name                 = "subnet2"
  virtual_network_name = data.azurerm_virtual_network.ocpcluster.name
  resource_group_name  = data.azurerm_virtual_network.ocpcluster.resource_group_name  
}
data  "azurerm_subnet" "compute_subnet" {
  name                 = "subnet4"
  virtual_network_name = data.azurerm_virtual_network.ocpcluster.name
  resource_group_name  = data.azurerm_virtual_network.ocpcluster.resource_group_name  
}

data  "azurerm_subnet" "ingress_subnet" {
  name                 = "subnet3"
  virtual_network_name = data.azurerm_virtual_network.ocpcluster.name
  resource_group_name  = data.azurerm_virtual_network.ocpcluster.resource_group_name  
}


# Storage account to store binaries, scripts etc.

resource "random_id" "storage_account" {
  byte_length = 8
}

resource "azurerm_storage_account" "sa1" {
  provider                 = azurerm.infra
  name                     = substr("${lower(var.ocp_cluster_instance)}mg${lower(random_id.storage_account.hex)}",0,24)
  resource_group_name      = data.azurerm_resource_group.ocpmgmt.name
  location                 = data.azurerm_resource_group.ocpmgmt.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "installers" {
  provider              = azurerm.infra
  name                  = "installers"
  storage_account_name  = azurerm_storage_account.sa1.name
  container_access_type = "private"
  depends_on = [
     azurerm_storage_account.sa1
  ]
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



/* resource "azurerm_monitor_diagnostic_setting" "sa1" {
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
} */


resource "azurerm_storage_account" "vm-diags" {
  provider                 = azurerm.infra
  name                     = substr("${lower(var.ocp_cluster_instance)}vm${lower(random_id.storage_account.hex)}",0,24)
  resource_group_name      = data.azurerm_resource_group.ocpmgmt.name
  location                 = data.azurerm_resource_group.ocpmgmt.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

/* resource "azurerm_monitor_diagnostic_setting" "vm-diags" {
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
} */


/* resource "azurerm_storage_blob" "manifest_secrets" {
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
} */
/* resource "azurerm_storage_blob" "manifest" {
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
} */

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
  location            = data.azurerm_resource_group.ocpmgmt.location
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}

data "azurerm_shared_image" "rhel" {
  provider            = azurerm.images
  name                = "ace_secure_rhel84"
  gallery_name        = "publishing_sig"
  resource_group_name = "asdt-images"
}


resource "azurerm_linux_virtual_machine" "deployhost" {
  name                = "vm-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
  location            = data.azurerm_resource_group.ocpmgmt.location
  size                = "Standard_D2S_v5"
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
     azurerm_network_interface.deployhost
  ]

  admin_ssh_key {
    username   = var.vm_user_name
    public_key = var.pub_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = data.azurerm_shared_image.rhel.id

  /* plan {
    name      = data.azurerm_shared_image.rhel.identifier[0].sku
    publisher = data.azurerm_shared_image.rhel.identifier[0].publisher
    product   = data.azurerm_shared_image.rhel.identifier[0].offer
   } */
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
    tag     = false
    filter  = false
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
                   "${azurerm_storage_blob.genappscert.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b",
                   "${azurerm_storage_blob.genapicert.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b",
                   "${azurerm_storage_blob.tools.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b",
                   "${azurerm_storage_blob.config.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b",
                   "${azurerm_storage_blob.ca-cert.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b",
                   "${azurerm_storage_blob.root-ca.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b"
                ]
    }
SETTINGS

protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "sh install-tools.sh -u ${var.vm_user_name} -v ${var.ocp_vers} -o ${var.ocp_cluster_instance} -s ${base64encode(var.pub_ssh_key)} -n ${data.azurerm_virtual_network.ocpcluster.name} -a ${var.vnet_addr_space} -b ${var.ocp_base_dns_zone} -e ${var.owner} -k ${var.shrd_kv_name} -i ${var.infra_sub_name}  -c ${var.op_env} -l ${var.location_identifier}  -t ${var.infra_tenant_id} -w ${var.infra_sub_id} -d ${var.ocp_vnet_name_rg} -r ${local.ocpcluster_rg_name}"
    }
PROTECTED_SETTINGS

}

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

/* resource "azurerm_virtual_machine_extension" "log" {
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
resource "azurerm_role_assignment" "deployVM-infra-contrib" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_resource_group.ocpcluster.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
}

# below works when the user running the script is an owner / has user access administrator role
#Assign rights to the OCP Cluster RG for the System Assign Identity
resource "azurerm_role_assignment" "deployVM-inframgmt-contrib" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_resource_group.ocpmgmt.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
}

# below works when the user running the script is an owner / has user access administrator role
resource "azurerm_role_assignment" "deployVM-infra-UAM" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_resource_group.ocpcluster.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
}
resource "azurerm_role_assignment" "deployVM-inframgmt-UAM" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_resource_group.ocpmgmt.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_linux_virtual_machine.deployhost.identity.0.principal_id
}

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
} 
*/


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
#   scope                = data.azurerm_resource_group.ocpmgmt.id
#   role_definition_name = "User Access Administrator"
#   principal_id         = data.azuread_service_principal.spn.id
# }

/* #Assign rights to the OCP Cluster RG for the System Assign Identity
resource "azurerm_role_assignment" "spn-inframgmt-contrib" {
  depends_on = [
     azurerm_linux_virtual_machine.deployhost
  ]
  scope                = data.azurerm_resource_group.ocpmgmt.id
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

output "imagedata" {
  value = data.azurerm_shared_image.rhel
}