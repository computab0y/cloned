data "azurerm_client_config" "current" {}


# RG to deploy the App GW to
data "azurerm_resource_group" "ocpmgmt" {
  provider  = azurerm.infra
  name      = "rg-${var.ocp_cluster_instance}mgmt-${var.op_env}-${var.location_identifier}"
}

#Create WAF Policy to be assigned to the App GW. 
resource "azurerm_web_application_firewall_policy" "wafpol" {
  provider            = azurerm.infra
  name                = "pol-appgw-${var.ocp_cluster_instance}-${var.op_env}-${var.location_identifier}-001"
  resource_group_name = var.ocp_vnet_name_rg
  location            = data.azurerm_resource_group.ocpmgmt.location


   dynamic "custom_rules" {
    for_each =  var.waf_access_list_enabled ? [1]: []
#Rule to allow IP address list specified in Variable var.app_gw_allow_ips.
    content{
        name      = "DenyUnKnownIps"
        priority  = 5
        rule_type = "MatchRule"

        match_conditions {
          match_variables {
            variable_name = "RemoteAddr"
          }

          operator           = "IPMatch"
          negation_condition = true
          match_values       = var.app_gw_allow_ips
        }

        dynamic "match_conditions" {
          for_each =  (var.waf_access_list_enabled && var.waf_public_domains_enabled) ? [1]: []
          content {
          match_variables {
            variable_name = "RequestHeaders"
            selector      = "Host"
          }

          operator           = "Equal"
          negation_condition = true
          match_values       = var.app_gw_public_domains
          }
        }

        action = "Block"
    }
    
  }

  
  policy_settings {
    # Set to Prevent, otherwise rules would only log and not apply.
    enabled                     = true
    mode                        = "Prevention" # Prevention or Detection
    request_body_check          = false
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
      managed_rule_set {
        type    = "OWASP"
        version = "3.2"
        rule_group_override {
          rule_group_name = "REQUEST-941-APPLICATION-ATTACK-XSS"
          disabled_rules  = [
            "941130",
            "941330"
          ]
        }
        rule_group_override {
          rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
          disabled_rules  = [
            "942450",
            "942430",
            "942370",
            "942330",
            "942210",
            "942220",
            "942120",
            "942130",
            "942150",
            "942200",
            "942410",
            "942440",
            "942340",
            "942260",
            "942100"
          ]
        }
        rule_group_override {
          rule_group_name = "REQUEST-931-APPLICATION-ATTACK-RFI"
          disabled_rules  = [
            "931100",
            "931120",
            "931130"
          ]
        }
        rule_group_override {
          rule_group_name = "REQUEST-930-APPLICATION-ATTACK-LFI"
          disabled_rules  = [
            "930100",
            "930110",
            "930120",
            "930130"
          ]
        }
        rule_group_override {
          rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
          disabled_rules  = [
            "920300",
            "920330",
            "920230",
            "920420",
            "920440"
          ]
        }
         rule_group_override {
          rule_group_name = "REQUEST-932-APPLICATION-ATTACK-RCE"
          disabled_rules  = [
            "932110",
            "932160"
          ]
        }
      }
      managed_rule_set {
        type    = "Microsoft_BotManagerRuleSet"
        version = "0.1"

      }
  }
}



