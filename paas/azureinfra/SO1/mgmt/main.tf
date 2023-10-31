data "azurerm_client_config" "current" {}

data "azurerm_subscription" "mgmt" {
  provider = azurerm.mgmt

}
data "azurerm_subscription" "infra" {
  provider = azurerm.infra

}

resource "azurerm_resource_group" "rg" {
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
  location  = var.resource_group_location
  tags = {
    Owner    = "${var.owner}",
    Solution = "${var.solution}"

  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_dns_zone" "base" {
  name                = var.ocp_base_dns_zone
  resource_group_name = azurerm_resource_group.rg.name
  lifecycle {
    ignore_changes = all
  }

}

resource "azurerm_log_analytics_workspace" "wks" {
  name                = "law-mgmt-${var.op_env}-shared-${var.location_identifier}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018" #(Required) Specifies the Sku of the Log Analytics Workspace. Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, and PerGB2018 (new Sku as of 2018-04-03).
  retention_in_days   = 100         #(Optional) The workspace data retention in days. Possible values range between 30 and 730.
lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags
    ]
    
  }
}
resource "azurerm_monitor_diagnostic_setting" "law-wks" {
   name              = "LAW-Diags-wks"
   target_resource_id = azurerm_log_analytics_workspace.wks.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "Audit"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   metric {
     category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}



# Set Activity Log settings for MGMT Sub
resource "azurerm_monitor_diagnostic_setting" "mgmt-activity" {
   name              = "LAW-Diags-activity-logs"
   target_resource_id = data.azurerm_subscription.mgmt.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "Administrative"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "Security"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "Alert"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "Policy"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   
}
resource "azurerm_monitor_diagnostic_setting" "infra-activity" {
   name              = "LAW-Diags-activity-logs"
   target_resource_id = data.azurerm_subscription.infra.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "Administrative"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "Security"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "Alert"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "Policy"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   
}


resource "azurerm_virtual_network" "ocpmgt" {
  name                = "${var.ocp_vnet_prefix}-${var.op_env}-shared-${var.location_identifier}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.mgmt_vnet_addr_space]
  lifecycle {
    ignore_changes = [tags]
  }
}

resource  "azurerm_subnet" "data" {
  name                = "data"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ocpmgt.name
  address_prefixes     = ["10.1.0.0/24"]
}
  
resource  "azurerm_subnet" "fw" {
  name                = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ocpmgt.name
  address_prefixes     = ["10.1.1.0/24"]
} 
resource  "azurerm_subnet" "bastion" {
  name                = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.ocpmgt.name
  address_prefixes     = ["10.1.3.0/24"]
} 

resource "azurerm_public_ip" "fw" {
  name                = "pip-azfw-mgmt-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = "Production"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags
    ]
    
  }
}

resource "azurerm_monitor_diagnostic_setting" "pip-fw" {
   name              = "LAW-Diags-pip-fw"
   target_resource_id = azurerm_public_ip.fw.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "DDoSProtectionNotifications"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "DDoSMitigationFlowLogs"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "DDoSMitigationReports"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   metric {
     category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "random_id" "key_vault" {
  byte_length = 1
}


resource "azurerm_key_vault" "ocpmgmt" {
  #name                        = substr("kv-prod-shared-${var.location_identifier}-${lower(random_id.key_vault.hex)}",0,24)
  name                         =  "kv-${var.op_env}-shared-${lower(random_id.key_vault.hex)}-${var.location_identifier}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
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
resource "azurerm_monitor_diagnostic_setting" "kv" {
   name              = "LAW-Diags-mgmt"
   target_resource_id = azurerm_key_vault.ocpmgmt.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "AuditEvent"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "AzurePolicyEvaluationDetails"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   metric {
     category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

#Azure Firewall Instance
resource "azurerm_firewall" "fw" {
  name                = "azfw-mgmt-${var.op_env}-shared-${var.location_identifier}"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Premium"
  threat_intel_mode   = "Alert"
  firewall_policy_id  = azurerm_firewall_policy.fw-pol01.id
  depends_on = [
    azurerm_firewall_policy.fw-pol01
  ]

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.fw.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags
    ]
    
  }
}
resource "azurerm_monitor_diagnostic_setting" "fw" {
   name              = "LAW-Diags-fw"
   target_resource_id = azurerm_firewall.fw.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "AzureFirewallApplicationRule"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "AzureFirewallNetworkRule"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   /* log {
     category = "AzureFirewallDnsProxy"
     enabled  = true

     retention_policy {
       days    = 0
       enabled = true
     }
   } */
   metric {
     category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

#Firewall Policy
resource "azurerm_firewall_policy" "fw-pol01" {
  name                    = "pol-fw-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name     = azurerm_resource_group.rg.name
  location                = var.resource_group_location
  sku                     = "Premium"

  # insights {
  #   enabled                            = true
  #   retention_in_days                  = 90
  #   default_log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id
  # }
  intrusion_detection {
    mode                               = "Alert"
  }

}


resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-bastion-${var.op_env}-shared-uks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "AllowBastionHostCommunication"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["8080", "5701"]
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "AllowRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
   security_rule {
    name                       = "AllowSshbound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
   security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "AllowBastionCommunication"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
  security_rule {
    name                       = "AllowGetSessionInformation"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg-bastion" {
   name              = "LAW-Diags-nsg-bastion"
   target_resource_id = azurerm_network_security_group.bastion.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

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

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data-${var.op_env}-shared-${var.location_identifier}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_monitor_diagnostic_setting" "nsg-data" {
   name              = "LAW-Diags-nsg-data"
   target_resource_id = azurerm_network_security_group.data.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

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


resource "azurerm_subnet_network_security_group_association" "bastion-subnet" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# Azure Bastion HAS to be deployed in the same RG as the VNet.
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bast-mgmt-${var.op_env}-shared-${var.location_identifier}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  lifecycle {
    ignore_changes = [tags]
  }
}
resource "azurerm_monitor_diagnostic_setting" "pip-bastion" {
   name              = "LAW-Diags-pip-fw"
   target_resource_id = azurerm_public_ip.bastion.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "DDoSProtectionNotifications"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "DDoSMitigationFlowLogs"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "DDoSMitigationReports"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   metric {
     category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bast-mgmt-${var.op_env}-shared-${var.location_identifier}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_monitor_diagnostic_setting" "bastion" {
   name              = "LAW-Diags-bastion"
   target_resource_id = azurerm_bastion_host.bastion.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.wks.id

   log {
     category = "BastionAuditLogs"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   metric {
     category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}


