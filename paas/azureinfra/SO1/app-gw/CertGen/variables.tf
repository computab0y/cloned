
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}
variable "location_identifier" {
  default       = "uks"
  description   = "TLA for location"
}

variable "ocp_base_dns_zone" {
  default       = ""
  description = "Base Azure DNS zone name for the OCP cluster"
}

variable "op_env" {
  default     = "prod"
  description = "Operating environment for the resources"
  
}
variable "shrd_kv_name" {
  default = ""
  
}
variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}