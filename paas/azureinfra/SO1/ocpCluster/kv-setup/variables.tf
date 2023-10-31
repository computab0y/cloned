
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
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


variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}
variable "shrd_kv_name" {
  default = ""
  
}



variable "infra_sub_name" {
  default = ""
}

variable "mgmt_sub_name" {
  default = ""
}

variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}
