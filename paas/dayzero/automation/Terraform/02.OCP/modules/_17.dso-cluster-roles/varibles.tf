variable "host" {
  type    = string
}
variable "token" {
  type    = string
  sensitive = true
}
variable "dso-platform-repoURL" {
  type    = string
  default = "https://github.com/defencedigital/dso-platform"
}
variable "clusterroles-app-name" {
  type    = string
  default = "cluster-roles"
}
variable "clusterroles-source-path" {
  type    = string
  default = "dayzero/legion/cohorts/openshift/16-cluster-roles"
}
variable "tls-insecure" {
  type    = string
  default = "false"
}

