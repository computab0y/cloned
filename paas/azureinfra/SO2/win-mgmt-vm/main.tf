locals {
  win_vm_name     = "${var.ocp_cluster_instance}win${var.op_env}${var.location_identifier}"
  ocpmgmt_rg_name = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
  win_vm_nic_name = "nic-vm-${var.ocp_cluster_instance}win-${var.op_env}-${var.location_identifier}"
}
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = local.ocpmgmt_rg_name
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

resource "random_password" "password" {
  count            = var.pre_existing_vm ?0:1
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
data "azurerm_shared_image" "win2019" {
  provider            = azurerm.images
  name                = "ace_secure_win2019"
  gallery_name        = "publishing_sig"
  resource_group_name = "asdt-images"
}
resource "azurerm_network_interface" "win_mgmt_vm" {
  count               = var.pre_existing_vm ?0:1
  name                = local.win_vm_nic_name
  location            = data.azurerm_resource_group.ocpmgmt.location
  resource_group_name = local.ocpmgmt_rg_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_windows_virtual_machine" "win_mgmt_vm" {
    depends_on = [
        random_password.password,
        azurerm_network_interface.win_mgmt_vm
    ]
    provider               = azurerm.infra
    count                  = var.pre_existing_vm ?0:1
    name                   = local.win_vm_name
    resource_group_name    = local.ocpmgmt_rg_name
    location               = data.azurerm_resource_group.ocpmgmt.location
    size                   = "Standard_D2S_v5"
    admin_username         = var.vm_user_name
    admin_password         = random_password.password[count.index].result

    identity {
        type              = "SystemAssigned"
    }
    network_interface_ids = [
        azurerm_network_interface.win_mgmt_vm[count.index].id,
    ]
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_id = data.azurerm_shared_image.win2019.id

}


data "azurerm_virtual_machine" "win_mgmt_vm" {
    depends_on = [
        azurerm_windows_virtual_machine.win_mgmt_vm
    ]
    provider               = azurerm.infra
    name                   = var.pre_existing_vm ?var.win_mgmt_vm_name:local.win_vm_name
    resource_group_name    = local.ocpmgmt_rg_name
}


data "azurerm_storage_account" "sa1" {
  provider                 = azurerm.infra
  name                     = var.asset_sa_name
  resource_group_name      = local.ocpmgmt_rg_name
}
data "azurerm_storage_container" "installers" {
  provider              = azurerm.infra
  name                  = "installers"
  storage_account_name  = data.azurerm_storage_account.sa1.name
}

resource "azurerm_storage_blob" "packages" {
  provider               = azurerm.infra
  name                   = "packages.zip"
  storage_account_name   = data.azurerm_storage_account.sa1.name
  storage_container_name = data.azurerm_storage_container.installers.name
  type                   = "Block"
  content_md5            = filemd5("./.tmp/packages.zip")
  source                 = "./.tmp/packages.zip"

}
resource "azurerm_storage_blob" "deploy_script" {
  provider               = azurerm.infra
  name                   = "deploywinvm.ps1"
  storage_account_name   = data.azurerm_storage_account.sa1.name
  storage_container_name = data.azurerm_storage_container.installers.name
  type                   = "Block"
  content_md5            = filemd5("../scripts/deploywinvm.ps1")
  source                 = "../scripts/deploywinvm.ps1"

}

data "azurerm_storage_account_sas" "sa1" {
  connection_string = data.azurerm_storage_account.sa1.primary_connection_string
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

resource "azurerm_virtual_machine_extension" "win_vm_host" {
  depends_on = [
      azurerm_windows_virtual_machine.win_mgmt_vm,
      azurerm_storage_blob.packages
  ]  
  name                 = "provision_win_vm_host"
  virtual_machine_id   = data.azurerm_virtual_machine.win_mgmt_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings = <<SETTINGS
    {
      "fileUris": [
                   "${azurerm_storage_blob.packages.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b",
                   "${azurerm_storage_blob.deploy_script.id}${data.azurerm_storage_account_sas.sa1.sas}&sr=b"
                ]
    }
SETTINGS

protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell.exe ./deploywinvm.ps1"
    }
PROTECTED_SETTINGS

}
output "downloadURI" {
    sensitive = true
  value =  "${azurerm_storage_blob.packages.id}${data.azurerm_storage_account_sas.sa1.sas}"
}