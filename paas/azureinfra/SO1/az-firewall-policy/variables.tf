
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}

variable "ocp_vnet_prefix" {
  default       = "vnet"
  description   = "VNet prefix"
}


variable "location_identifier" {
  default       = "uks"
  description   = "TLA for location"
}

variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}

variable "rule_priority" {
  default = 600
  
}
variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}