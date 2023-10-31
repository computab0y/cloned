variable "asset_sa_name" {
    default = ""
  
}
variable "ocp_vers" {
  default = "4.8.13"
}
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}
variable "resource_group_name_suffix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default = "uksouth"
  description   = "Location of the resource group."
}

variable "location_identifier" {
  default       = "uks"
  description   = "TLA for location"
}
variable "infra_sub_id" {
  default     = ""
}
variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}
variable "win_mgmt_vm_name" {
    default = ""
  
}
variable "pre_existing_vm" {
    type = bool
    default = false
}
variable "images_sub_id" {
  default     = ""
}

variable "infra_tenant_id" {
  default     = ""
}

variable "ocp_vnet_name" {
  default       = "vnet"
  description   = "VNet name"
}
variable "ocp_vnet_name_rg" {
  default       = "preda-infra-vnet"
  description   = "VNet rg name"
}
variable "vm_user_name" {
  default = "sysadmin"
}