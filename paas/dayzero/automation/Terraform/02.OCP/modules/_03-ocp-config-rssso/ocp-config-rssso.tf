terraform {
  required_version = ">= 0.13"
  required_providers {
    keycloak = {
      source = "registry.terraform.io/mrparkers/keycloak"
      version = ">= 3.10.0"
    }

  }
}

# Usage (password grant)
provider "keycloak" {
    //realm   = "${var.master_realm}"
    client_id     = "admin-cli"
    username      = "${var.keycloak_username}"                  
    password      = "${var.keycloak_password}"                  
    url           = "${var.keycloak_url}/auth"                  
  #  initial_login = false
    tls_insecure_skip_verify = true
}

#******** CREATE REALM SSO
 resource "keycloak_realm" "realm_sso" {
  realm  = "${var.sso_realm}"
  enabled = true
  display_name      = "${var.sso_realm}"
  display_name_html = "<strong>Red Hat</strong> Single Sign On"
  login_with_email_allowed = true
  login_theme = "keycloak"
  default_signature_algorithm = "RS256"
}
/*
#******** CREATE REALM MASTER               *************** This is for testing and should not be created on prod
 resource "keycloak_realm" "realm_master" {
  realm   = "${var.master_realm}"
  enabled = true
  display_name      = "${var.master_realm}"
  display_name_html = "<strong>Red Hat</strong> Single Sign On"
  login_with_email_allowed = true
  default_signature_algorithm = "RS256"
}
*/

#******** rh-sso - configure OTP for admin users on sso realm
resource "keycloak_required_action" "required_action_sso" {
  realm_id = "${var.sso_realm}"
  alias    = "CONFIGURE_TOTP"
  enabled  = true
  name     = "Configure OTP"
  default_action  = true
  depends_on = [keycloak_realm.realm_sso]
}

#******** rh-sso - configure OTP for admin users on master realm
resource "keycloak_required_action" "required_action_master" {
  realm_id = "${var.master_realm}"
  alias    = "CONFIGURE_TOTP"
  enabled  = true
  name     = "Configure OTP"
  default_action  = true
#  depends_on = [keycloak_realm.realm_master]
}
#******** rh-sso - create sso-admins group on master realm
resource "keycloak_group" "group_sso-admins_in_master" {
  realm_id = "${var.master_realm}"
  name     = "sso-admins"
#  depends_on = [keycloak_realm.realm_master] 
}
#******** rh-sso - create engineering-admin group on sso realm
resource "keycloak_group" "group_engineering-admin_in_sso" {
  realm_id = "${var.sso_realm}"
  name     = "engineering-admin"
  depends_on = [keycloak_realm.realm_sso]
}

#******** rh-sso - create admin users in master realm
resource "keycloak_user" "user_semirm-admin_in_Master" {
  realm_id   = "${var.master_realm}"
  username   = "semirm-admin"
  enabled    = true
  email      = "semir.mussa@digital.mod.uk"
  first_name = "Semir"
  last_name  = "Mussa"
  initial_password {
    value     = "Change-Me!"
    temporary = true
  }
  depends_on = [keycloak_required_action.required_action_master]
}
#******** rh-sso - add user to sso-admins group on master
resource "keycloak_user_groups" "user_groups_semirm-admin" {
  realm_id = "${var.master_realm}"
  user_id = keycloak_user.user_semirm-admin_in_Master.id
  group_ids  = [
    keycloak_group.group_sso-admins_in_master.id
  ]
  depends_on = [keycloak_group.group_sso-admins_in_master]
}
#******** rh-sso - add user mussas to engineering -admin group on sso realm
resource "keycloak_user" "user_mussas_in_sso" {
  realm_id   = "${var.sso_realm}"
  username   = "mussas"
  depends_on = [keycloak_realm.realm_sso]
}
resource "keycloak_user_groups" "user_groups_mussas" {
  realm_id = "${var.sso_realm}"
  user_id = keycloak_user.user_mussas_in_sso.id
  group_ids  = [
    keycloak_group.group_engineering-admin_in_sso.id
  ]
  depends_on = [keycloak_group.group_sso-admins_in_master]
}

#******** rh-sso - create admin users in master realm
resource "keycloak_user" "user_hawkerd-admin_in_Master" {
  realm_id   = "${var.master_realm}"
  username   = "hawkerd-admin"
  enabled    = true
  email      = "dhawker@digital.mod.uk"
  first_name = "Dan"
  last_name  = "hawker"
  initial_password {
    value     = "Change-Me!"
    temporary = true
  }
  depends_on = [keycloak_required_action.required_action_master]
}
#******** rh-sso - add user to sso-admins group on master
resource "keycloak_user_groups" "user_groups_hawkerd-admin" {
  realm_id = "${var.master_realm}"
  user_id = keycloak_user.user_hawkerd-admin_in_Master.id
  group_ids  = [
    keycloak_group.group_sso-admins_in_master.id
  ]
  depends_on = [keycloak_group.group_sso-admins_in_master]
}

#******** rh-sso - create admin users in master realm
resource "keycloak_user" "user_paulsow-admin_in_Master" {
  realm_id   = "${var.master_realm}"
  username   = "paulsow-admin"
  enabled    = true
  email      = "paul.sowerby@digital.mod.uk"
  first_name = "paul"
  last_name  = "sowerby"
  initial_password {
    value     = "Change-Me!"
    temporary = true
  }
  depends_on = [keycloak_required_action.required_action_master]
}
#******** rh-sso - add user to sso-admins group on master
resource "keycloak_user_groups" "user_groups_paulsow-admin" {
  realm_id = "${var.master_realm}"
  user_id = keycloak_user.user_paulsow-admin_in_Master.id
  group_ids  = [
    keycloak_group.group_sso-admins_in_master.id
  ]
  depends_on = [keycloak_group.group_sso-admins_in_master]
}

#******** rh-sso - create admin users in master realm
resource "keycloak_user" "user_raybryan-admin_in_Master" {
  realm_id   = "${var.master_realm}"
  username   = "raybryan-admin"
  enabled    = true
  email      = "ray.bryan@digital.mod.uk"
  first_name = "ray"
  last_name  = "bryan"
  initial_password {
    value     = "Change-Me!"
    temporary = true
  }
  depends_on = [keycloak_required_action.required_action_master]
}
#******** rh-sso - add user to sso-admins group on master
resource "keycloak_user_groups" "user_groups_raybryan-admin" {
  realm_id = "${var.master_realm}"
  user_id = keycloak_user.user_raybryan-admin_in_Master.id
  group_ids  = [
    keycloak_group.group_sso-admins_in_master.id
  ]
  depends_on = [keycloak_group.group_sso-admins_in_master]
}

#******** rh-sso - create admin users in master realm
resource "keycloak_user" "user_satinderk-admin_in_Master" {
  realm_id   = "${var.master_realm}"
  username   = "satinderk-admin"
  enabled    = true
  email      = "satinder.khela@digital.mod.uk"
  first_name = "satinder"
  last_name  = "khela"
  initial_password {
    value     = "Change-Me!"
    temporary = true
  }
  depends_on = [keycloak_required_action.required_action_master]
}
#******** rh-sso - add user to sso-admins group on master
resource "keycloak_user_groups" "user_groups_satinderk-admin" {
  realm_id = "${var.master_realm}"
  user_id = keycloak_user.user_satinderk-admin_in_Master.id
  group_ids  = [
    keycloak_group.group_sso-admins_in_master.id
  ]
  depends_on = [keycloak_group.group_sso-admins_in_master]
}

#******** rh-sso - create dummy users in master realm
resource "keycloak_user" "user_with_initial_password_in_sso" {
  realm_id   = "${var.sso_realm}"
  username   = "test103"
  enabled    = true

  email      = "test103@domain.com"
  first_name = "test"
  last_name  = "103"
  initial_password {
    value     = "Change-Me!"
    temporary = true
  }
  depends_on = [keycloak_required_action.required_action_sso]
}

# ******** Create a RH-SSO Client & set RH-SSO client to confidential
resource "keycloak_openid_client" "openid_client_rhsso" {
  realm_id            = "${var.sso_realm}"
  client_id           = "rh-sso"
  name                = "rh-sso"
  enabled             = true
  access_type         = "CONFIDENTIAL"
  standard_flow_enabled = true
  direct_access_grants_enabled = true
#  backchannel_logout_session_required = true
  valid_redirect_uris = [
    "${var.rh-sso-valid_redirect_uris}"
  ]
  full_scope_allowed = true 
  depends_on = [keycloak_realm.realm_sso]
}

# ******** Create a RHACS Client (OpenID client) & set RHACS client to confidential
resource "keycloak_openid_client" "openid_client_rhacs" {
  realm_id            = "${var.sso_realm}"
  client_id           = "rhacs"
  name                = "rhacs"
  enabled             = true
  access_type         = "CONFIDENTIAL"
  standard_flow_enabled = true
#  direct_access_grants_enabled = true
#  backchannel_logout_session_required = true
  valid_redirect_uris = [
    "https://central-stackrox.apps.ocp3.azure.dso.digital.mod.uk/sso/providers/oidc/callback",      ### UPDATE-REQUIRED
    "https://central-stackrox.apps.ocp3.azure.dso.digital.mod.uk/auth/response/oidc"              ### UPDATE-REQUIRED
  ]
  full_scope_allowed = true
  depends_on = [keycloak_realm.realm_sso] 
}

 #******** rh-sso - create Quay client & set Quay client to confidential
resource "keycloak_openid_client" "openid_client_quay" {
  realm_id            = "${var.sso_realm}"
  client_id           = "quay"
  name                = "quay"
  enabled             = true
  access_type         = "CONFIDENTIAL"
  standard_flow_enabled = true
#  direct_access_grants_enabled = true
#  backchannel_logout_session_required = true
  valid_redirect_uris = [
    "https://dso-quay-registry-quay-quay-enterprise.apps.ocp3.azure.dso.digital.mod.uk/oauth2/redhatsso/callback"   ### UPDATE-REQUIRED
  ]
  full_scope_allowed = true
  depends_on = [keycloak_realm.realm_sso] 
}

#******** rh-sso - create sonarqube client & set sonarqube client to public
resource "keycloak_openid_client" "openid_client_sonarqube" {
  realm_id            = "${var.sso_realm}"
  client_id           = "sonarqube"
  name                = "sonarqube"
  enabled             = true
  access_type         = "PUBLIC"
  standard_flow_enabled = true
  direct_access_grants_enabled = true
#  backchannel_logout_session_required = true
  root_url = "https://sonarqube-https-dso-tooling-sonar.apps.ocp3.azure.dso.digital.mod.uk"   ### UPDATE-REQUIRED
    
  valid_redirect_uris = [
    "https://sonarqube-https-dso-tooling-sonar.apps.ocp3.azure.dso.digital.mod.uk/oauth2/callback/*",   ### UPDATE-REQUIRED
    "https://sonarqube-edb-dso-tooling-sonar.apps.ocp3.azure.dso.digital.mod.uk/oauth2/callback/*"
  ]
  admin_url = "https://sonarqube-https-dso-tooling-sonar.apps.ocp3.azure.dso.digital.mod.uk"   ### UPDATE-REQUIRED

  web_origins = [
    "https://sonarqube-https-dso-tooling-sonar.apps.ocp3.azure.dso.digital.mod.uk",   ### UPDATE-REQUIRED
    "https://sonarqube-edb-dso-tooling-sonar.apps.ocp3.azure.dso.digital.mod.uk"      ### UPDATE-REQUIRED
  ] 
  full_scope_allowed = true
  depends_on = [keycloak_realm.realm_sso] 
}

 #******** rh-sso - create vault client & set vault client to confidential
resource "keycloak_openid_client" "openid_client_vault" {
  realm_id            = "${var.sso_realm}"
  client_id           = "vault"
  name                = "vault"
  enabled             = true
  access_type         = "CONFIDENTIAL"
  standard_flow_enabled = true
  direct_access_grants_enabled = true
#  backchannel_logout_session_required = true
  root_url = "https://vault-default.apps.ocp3.azure.dso.digital.mod.uk/"   ### UPDATE-REQUIRED 
  valid_redirect_uris = [
    "https://localhost:8250/oidc/callback",   ### UPDATE-REQUIRED
    "https://vault-dso-tooling-vault.apps.ocp3.azure.dso.digital.mod.uk/ui/vault/auth/oidc/oidc/callback",    ### UPDATE-REQUIRED
    "https://vault-dso-tooling-vault.apps.ocp3.azdso.digital.mod.uk/ui/vault/auth/oidc/oidc/callback/*ure."     ### UPDATE-REQUIRED
  ]
  admin_url = "https://vault-default.apps.ocp3.azure.dso.digital.mod.uk/"   ### UPDATE-REQUIRED
  web_origins = [
    "https://vault-default.apps.ocp3.azure.dso.digital.mod.uk"   ### UPDATE-REQUIRED
  ] 
  full_scope_allowed = true
  depends_on = [keycloak_realm.realm_sso] 
}

# ******** rhacs - rh-sso - vault - define mappers
resource "keycloak_openid_group_membership_protocol_mapper" "group_membership_mapper" {
  realm_id        = "${var.sso_realm}"
  client_id  = keycloak_openid_client.openid_client_vault.id
  name            = "Groups Mapper"
  add_to_id_token = true
  add_to_access_token = true
  add_to_userinfo = true
  claim_name = "groups"
  depends_on = [keycloak_openid_client.openid_client_vault]
}

