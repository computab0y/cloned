
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
variable "subnet_default" {
  default     = "10.3.0.0/24"
  description = "OCP Cluster VNet, default subnet address range"
}
variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}
variable "cr_instance" {
  default    = 1
  
}