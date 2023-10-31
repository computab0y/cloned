
variable "host" {
  type        = string
  default = "default value"
}
variable "token" {
  type        = string
  default = "default value"
}
variable "keycloak_username" {
  type        = string
  default = "default value"
}
variable "keycloak_password" {
  type        = string
  default = "default value"
}
variable "keycloak_url" {
  type        = string
  default = "default value"
}
variable "master_realm" {
  type        = string
  default = "default value"
}
variable "sso_realm" {
  type        = string
  default = "default value"
}
variable "master_realm" {
  type        = string
  default = "default value"
}
variable "rh-sso-valid_redirect_uris" {
  type        = string
 # default = "https://oauth-openshift.apps.ocp1.azure.dso.digital.mod.uk/oauth2callback/rh-sso"   # official-ocp1
  default = "https://oauth-openshift.apps.ocp2.prod.ocp.local/oauth2callback/rh-sso"   # asdk-ocp2
}



/*
data "keycloak_realm" "realm_master" {
  realm = "default value"
}
data "keycloak_realm" "realm_sso" {
  realm = "default value"
}

realm_master = master
realm_sso = sso
group_sso-admins = sso-admins
group_engineering-admin = engineering-admin
admin_user_username   = "semirm-admin"
admin_user_enabled    = true
admin_user_email      = "semir.mussa@digital.mod.uk"
admin_user_first_name = "Semir"
admin_user_last_name  = "Mussa"
admin_user_pass_value     = "Change-Me!"
admin_user_pass_temporary = true
*/