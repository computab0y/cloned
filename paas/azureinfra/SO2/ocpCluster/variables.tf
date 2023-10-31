
variable "ocp_vers" {
  default = "4.8.13"
}
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}

variable "vnet_addr_space" {
  default       = "10.3.0.0/16"
  description   = "Address space for the OCP cluster instance VNet"
}

variable "subnet_default" {
  default     = "10.3.0.0/24"
  description = "OCP Cluster VNet, default subnet address range"
}
variable "subnet_appgw" {
  default     = "10.3.4.0/24"
  description = "OCP Cluster VNet, App GW subnet address range"
}
variable "subnet_control_plane" {
  default     = "10.3.1.0/24"
  description = "OCP Cluster VNet, Master node subnet address range"
}
variable "subnet_compute_subnet" {
  default     = "10.3.16.0/22"
  description = "OCP Cluster VNet, Worker node subnet address range"
}
variable "subnet_ingress_subnet" {
  default     = "10.3.2.0/24"
  description = "OCP Cluster VNet, Ingress subnet address range"
}

variable "ocp_vnet_name" {
  default       = "vnet"
  description   = "VNet name"
}
variable "ocp_vnet_name_rg" {
  default       = "preda-infra-vnet"
  description   = "VNet rg name"
}

variable "owner" {
  default       = ""
  description   = "Resource owner"
}

variable "solution" {
  default = ""
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

variable "ocp_base_dns_zone" {
    default     = ""
  description = "Base Azure DNS zone name for the OCP cluster"
}

variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}
variable "shrd_kv_name" {
  default = ""
  
}

variable "pub_ssh_key" {
  default = ""
}

variable "vm_user_name" {
  default = "sysadmin"
}
variable "rule_priority" {
  default = 20000
}

variable "infra_sub_name" {
  default = ""
}

variable "image_sub_name" {
  default = ""
}
variable "spn_obj_name" {
  default = ""
}
variable "images_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}
variable "infra_tenant_id" {
  default     = ""
}