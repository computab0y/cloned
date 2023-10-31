
variable "ocp_vers" {
  default = "4.8.13"
}
variable "ocp_cluster_instance" {
  default       = ""
  description   = "OCP Cluster instance name."
}
variable "mgmt_sub_id" {
  default     = ""
}

variable "infra_sub_id" {
  default     = ""
}