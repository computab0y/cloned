data "azurerm_client_config" "current" {}


# RG to deploy the App GW to
data "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
}

#Shared management RG, hosting DNS Zone and Key Vault
data "azurerm_resource_group" "shared_mgmt" {
  provider  = azurerm.mgmt
  name      = "rg-mgmt-${var.op_env}-shared-${var.location_identifier}"
}

data "azurerm_dns_zone" "base" {
  provider            = azurerm.mgmt
  name                = var.ocp_base_dns_zone
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}
 data "azurerm_key_vault" "ocpmgmt" {
   provider                    = azurerm.mgmt
   name                        = var.shrd_kv_name
   resource_group_name         = data.azurerm_resource_group.shared_mgmt.name
 }

 data "azurerm_key_vault_certificate" "apps" {
    provider                   = azurerm.mgmt
    name                       = "${var.ocp_cluster_instance}-selfsign-app"
    key_vault_id               = data.azurerm_key_vault.ocpmgmt.id
 }
  data "azurerm_key_vault_certificate" "api" {
    provider                   = azurerm.mgmt
    name                       = "${var.ocp_cluster_instance}-selfsign-api"
    key_vault_id               = data.azurerm_key_vault.ocpmgmt.id
 }

# VNet where App GW is deployed to
data "azurerm_virtual_network" "ocpcluster" {
  name                = "${var.ocp_vnet_prefix}-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name

}

# Subnet where App GW is deployed to

data  "azurerm_subnet" "appgw" {
  name                = "appgw"
  resource_group_name  = data.azurerm_resource_group.ocpmgmt.name
  virtual_network_name = data.azurerm_virtual_network.ocpcluster.name

}

data "azurerm_log_analytics_workspace" "log" {
  provider            = azurerm.mgmt
  name                = "law-mgmt-${var.op_env}-shared-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.shared_mgmt.name
}

resource "azurerm_log_analytics_solution" "agw" {
  provider              = azurerm.mgmt
  solution_name         = "AzureAppGatewayAnalytics"
  location              = data.azurerm_resource_group.shared_mgmt.location
  resource_group_name   = data.azurerm_resource_group.shared_mgmt.name
  workspace_resource_id = data.azurerm_log_analytics_workspace.log.id
  workspace_name        = data.azurerm_log_analytics_workspace.log.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureAppGatewayAnalytics"
  }
}

# Create a user assigned identity. Used by App GW to retrieve Certs used by TLS rule from KeyVault
resource "azurerm_user_assigned_identity" "appgw" {
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
  location            = data.azurerm_resource_group.ocpmgmt.location

  name = "uai-${var.ocp_cluster_instance}-appgw-api"
}

/* # assign rights to the Key Vault
resource "azurerm_role_assignment" "appgw" {
  scope                = data.azurerm_key_vault.ocpmgmt.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
} */
resource "azurerm_key_vault_access_policy" "appgw" {
  provider     = azurerm.mgmt
  key_vault_id = data.azurerm_key_vault.ocpmgmt.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw.principal_id
  depends_on = [
     azurerm_user_assigned_identity.appgw
  ]

  key_permissions = [
    "Get","List",
  ]

  secret_permissions = [
    "Get","List",
  ]
}

# Public IP used by App GW.
resource "azurerm_public_ip" "appgw" {
  provider            = azurerm.infra
  name                = "appgw-${var.ocp_cluster_instance}-pip"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
  location            = data.azurerm_resource_group.ocpmgmt.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Local variables used by TF script
locals {
  backend_address_pool_apps_name           = "${var.ocp_cluster_instance}-apps-beap"
  backend_address_pool_api_name            = "${var.ocp_cluster_instance}-api-beap"
  apps_http_frontend_port_name             = "${var.ocp_cluster_instance}-apps-http-feport"
  apps_https_frontend_port_name            = "${var.ocp_cluster_instance}-apps-https-feport"
  api_https_frontend_port_name             = "${var.ocp_cluster_instance}-api-https-feport"
  frontend_ip_configuration_name           = "${var.ocp_cluster_instance}-feip"
  apps_http_setting_name                   = "${var.ocp_cluster_instance}-be-app-http-st"
  api_https_setting_name                   = "${var.ocp_cluster_instance}-be-api-https-st"
  apps_https_setting_name                  = "${var.ocp_cluster_instance}-be-apps-https-st"
  api_https_listener_name                  = "${var.ocp_cluster_instance}-api-https-lstn"
  apps_https_listener_name                 = "${var.ocp_cluster_instance}-apps-https-lstn"
  apps_http_listener_name                  = "${var.ocp_cluster_instance}-apps-http-lstn"
  apps_http_request_routing_rule_name      = "${var.ocp_cluster_instance}-apps-http-rqrt"
  apps_https_request_routing_rule_name     = "${var.ocp_cluster_instance}-apps-https-rqrt"
  api_https_request_routing_rule_name      = "${var.ocp_cluster_instance}-api-https-rqrt"
  apps_http_redirect_configuration_name    = "${var.ocp_cluster_instance}-apps-http-rdrcfg"
  apps_https_redirect_configuration_name   = "${var.ocp_cluster_instance}-apps-https-rdrcfg"
  api_https_redirect_configuration_name    = "${var.ocp_cluster_instance}-api-https-rdrcfg"
  rewrite_rule_header_ip_fwd_name          = "${var.ocp_cluster_instance}-x-forward-ip-rwr"
  rewrite_rule_header_x_xss_prot_name      = "${var.ocp_cluster_instance}-x-xss-protection-rwr"
  rewrite_rule_header_x_cont_typ_opts_name = "${var.ocp_cluster_instance}-x-content-type-opts-rwr"
  rewrite_rule_header_x_frame_opts_name    = "${var.ocp_cluster_instance}-x-frame-opts-rwr"
  rewrite_rule_header_strict_tr_sec_name   = "${var.ocp_cluster_instance}-strict-trans-sec-rwr"
  rewrite_set_apps                         = "${var.ocp_cluster_instance}-apps-rewrite-set"
  rewrite_set_api                          = "${var.ocp_cluster_instance}-api-rewrite-set"
  diag_appgw_logs = [
    "ApplicationGatewayAccessLog",
    "ApplicationGatewayPerformanceLog",
    "ApplicationGatewayFirewallLog",
  ]
  diag_appgw_metrics = [
    "AllMetrics",
  ]
}

#Create WAF Policy to be assigned to the App GW. 
data "azurerm_web_application_firewall_policy" "wafpol" {
  provider            = azurerm.infra
  name                = "pol-appgw-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}-001"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
}


resource "azurerm_application_gateway" "network" {
  provider            = azurerm.infra
  name                = "appgw-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}"
  resource_group_name = data.azurerm_resource_group.ocpmgmt.name
  location            = data.azurerm_resource_group.ocpmgmt.location
  firewall_policy_id  = data.azurerm_web_application_firewall_policy.wafpol.id
  depends_on = [
     azurerm_public_ip.appgw
  ]

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }
  zones = ["1", "2", "3"]
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = data.azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.apps_https_frontend_port_name
    port = 443
  }
  frontend_port {
    name = local.api_https_frontend_port_name
    port = 6443
  }


  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name  = local.backend_address_pool_apps_name
    fqdns = ["console-openshift-console.apps.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"]
  }

  backend_address_pool {
    name  = local.backend_address_pool_api_name
    fqdns = ["api.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"]
    
  }
  ssl_certificate {
    name                = "${var.ocp_cluster_instance}-selfsign-app"
    key_vault_secret_id = data.azurerm_key_vault_certificate.apps.secret_id
  }
  ssl_certificate {
    name                = "${var.ocp_cluster_instance}-selfsign-api"
    key_vault_secret_id = data.azurerm_key_vault_certificate.api.secret_id
  }
  
 
  #Apps HTTPs settings
  probe {
    name                                      = "${var.ocp_cluster_instance}-apps-https-probe"
    interval                                  = 30
    timeout                                   = 30
    protocol                                  = "Https"
    host                                      = "oauth-openshift.apps.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"
    path                                      = "/"
    unhealthy_threshold                       = 3  
    pick_host_name_from_backend_http_settings = false
    minimum_servers = 0
    match {
       status_code = [ "200-403" ]
     }
  }

  backend_http_settings {
    name                                = local.apps_https_setting_name
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 20
    pick_host_name_from_backend_address = false
    probe_name                          = "${var.ocp_cluster_instance}-apps-https-probe"    
  }

  http_listener {
    name                           = local.apps_https_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.apps_https_frontend_port_name
    protocol                       = "Https"
    host_names                     = [ "*.apps.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}" ]
    ssl_certificate_name           = data.azurerm_key_vault_certificate.apps.name
  }
  rewrite_rule_set {
    name = local.rewrite_set_apps
    rewrite_rule {
      rule_sequence = 100
      name         = local.rewrite_rule_header_ip_fwd_name
      request_header_configuration {
        header_name   = "X-Forwarded-For"
        header_value  = "{var_client_ip}"
        
      }
    }
    rewrite_rule {
      rule_sequence  = 92
      name           = local.rewrite_rule_header_x_xss_prot_name
      response_header_configuration {
        header_name   = "X-XSS-Protection"
        header_value  = "1;mode=block"
      }
    }
    rewrite_rule {
      rule_sequence  = 93
      name           = local.rewrite_rule_header_x_cont_typ_opts_name
      response_header_configuration {
        header_name   = "X-Content-Type-Options"
        header_value  = "nosniff"
      }
    }
    /* rewrite_rule {
      rule_sequence  = 94
      name           = local.rewrite_rule_header_x_frame_opts_name
      response_header_configuration {
        header_name   = "X-Frame-Options"
        header_value  = "DENY"
      }
    } */
    rewrite_rule {
      rule_sequence  = 94
      name           = local.rewrite_rule_header_strict_tr_sec_name
      response_header_configuration {
        header_name   = "Strict-Transport-Security"
        header_value  = "max-age=31536000;includeSubDomains"
      }
    }
  }
  rewrite_rule_set {
    name = local.rewrite_set_api
    rewrite_rule {
      rule_sequence  = 92
      name           = local.rewrite_rule_header_x_xss_prot_name
      response_header_configuration {
        header_name   = "X-XSS-Protection"
        header_value  = "1;mode=block"
      }
    }
    rewrite_rule {
      rule_sequence  = 93
      name           = local.rewrite_rule_header_x_cont_typ_opts_name
      response_header_configuration {
        header_name   = "X-Content-Type-Options"
        header_value  = "nosniff"
      }
    }
    rewrite_rule {
      rule_sequence  = 94
      name           = local.rewrite_rule_header_x_frame_opts_name
      response_header_configuration {
        header_name   = "X-Frame-Options"
        header_value  = "DENY"
      }
    }
    rewrite_rule {
      rule_sequence  = 94
      name           = local.rewrite_rule_header_strict_tr_sec_name
      response_header_configuration {
        header_name   = "Strict-Transport-Security"
        header_value  = "max-age=31536000;includeSubDomains"
      }
    }
  }
  request_routing_rule {
    name                       = local.apps_https_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.apps_https_listener_name
    backend_address_pool_name  = local.backend_address_pool_apps_name
    backend_http_settings_name = local.apps_https_setting_name
    rewrite_rule_set_name      = local.rewrite_set_apps

  }
  #API HTTPs settings
  probe {
    name                                      = "${var.ocp_cluster_instance}-api-https-probe"
    interval                                  = 30
    timeout                                   = 30
    protocol                                  = "Https"
    port                                      = 6443
    host                                      = "api.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}"
    path                                      = "/readyz"
    unhealthy_threshold                       = 3  
    pick_host_name_from_backend_http_settings = false
    minimum_servers = 0
    match {
       status_code = [ "200-399" ]
     }
  }

  backend_http_settings {
    name                                = local.api_https_setting_name
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 6443
    protocol                            = "Https"
    request_timeout                     = 20
    pick_host_name_from_backend_address = false
    probe_name                          = "${var.ocp_cluster_instance}-api-https-probe"    
  }

  http_listener {
    name                           = local.api_https_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.api_https_frontend_port_name
    protocol                       = "Https"
    host_names                     = [ "api.${var.ocp_cluster_instance}.${data.azurerm_dns_zone.base.name}" ]
    ssl_certificate_name           = data.azurerm_key_vault_certificate.api.name
  }

  request_routing_rule {
    name                       = local.api_https_request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.api_https_listener_name
    backend_address_pool_name  = local.backend_address_pool_api_name
    backend_http_settings_name = local.api_https_setting_name
    rewrite_rule_set_name      = local.rewrite_set_api
  }
  ssl_policy {
    policy_type = "Custom"
    min_protocol_version = "TLSv1_2"
    cipher_suites = [
      "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
      "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"

    ]
  }
  lifecycle {
    ignore_changes = [
    # #  backend_address_pool,
    # #  backend_http_settings,
    # # frontend_port,
      http_listener,
    # #  probe,
    #  # request_routing_rule,
    #  # url_path_map,
     ssl_certificate,
    #  # redirect_configuration,
    #   autoscale_configuration
    ]
  }
  
}
resource "azurerm_monitor_diagnostic_setting" "fw" {
   name              = "LAW-Diags-fw"
   target_resource_id = azurerm_application_gateway.network.id
   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log.id
   depends_on = [
     azurerm_application_gateway.network
   ]

   log {
     category = "ApplicationGatewayAccessLog"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "ApplicationGatewayPerformanceLog"
     enabled  = true

     retention_policy {
       enabled = true
     }
   }
   log {
     category = "ApplicationGatewayFirewallLog"
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



