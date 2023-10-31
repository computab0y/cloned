
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}

variable "ocp_vnet_prefix" {
  default       = "vnet"
  description   = "VNet prefix"
}


variable "mgmt_vnet_addr_space" {
  default       = "10.1.0.0/16"
  description   = "Address space for the Central Management VNet"
}

variable "mgmt_subnet_data" {
  default     = "10.1.0.0/24"
  description = ""
}
variable "mgmt_subnet_azfw" {
  default     = "10.1.1.0/24"
  description = ""
}
variable "mgmt_subnet_bastion" {
  default     = "10.1.3.0/24"
  description = ""
}


variable "owner" {
  default       = ""
  description   = "Resource owner"
}

variable "solution" {
  default = ""
}


variable "resource_group_location" {
  default = "uksouth"
  description   = "Location of the resource group."
}

variable "location_identifier" {
  default       = "uks"
  description   = "TLA for location"
}

variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}

variable "ocp_base_dns_zone" {
  default     = ""
  description = "Base domain for the OCP cluster. Will create a DNS zone of this name"
}

variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}