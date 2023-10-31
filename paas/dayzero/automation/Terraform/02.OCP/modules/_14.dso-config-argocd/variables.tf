variable "host" {
  type        = string
  default = "default value"
}
variable "token" {
  type        = string
  default = "default value"
}
variable "iac-interpreter" {
  type        = string
  default = "default value"   # or bash
}
variable "dso-platform-repoURL" {
  type        = string
  default = "default value"   
}
variable "tls-insecure" {
  type        = string
  default = "default value"   
}
variable "argocd-manager-namespace" {
  type        = string
  default = "default value"   
}
variable "argocd-managed-namespace" {
  type        = string
  default = "default value"   
}