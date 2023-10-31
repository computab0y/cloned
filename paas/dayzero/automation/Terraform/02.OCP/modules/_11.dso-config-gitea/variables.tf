
variable "host" {
  type        = string
  default = "default value"
}
variable "token" {
  type        = string
  default = "default value"
}
variable "dso-platform-repoURL" {
  type        = string
  default = "default value"   
}
variable "tls-insecure" {
  type        = string
  default = "default value"   
}
variable "gitea-deploy-namespace" {
  type        = string
  default = "default value"   
}
variable "gitea-deploy-instance-name" {
  type        = string
  default = "default value"   
}
variable "giteaSsl" {
  type        = bool
  default = true   
}
variable "giteaAdminUser" {
  type        = string
  default = "default value"   
}
variable "giteaAdminPassword" {
  type        = string
  default = "default value"   
}
variable "giteaAdminPasswordLength" {
  type        = number
  default = 0
}
variable "giteaAdminEmail" {
  type        = string
  default = "default value"   
}
variable "giteaVolumeSize" {
  type        = string
  default = "default value"   
}
variable "postgresqlImage" {
  type        = string
  default = "default value"   
}
variable "postgresqlImageTag" {
  type        = string
  default = "default value"   
}
variable "postgresqlVolumeSize" {
  type        = string
  default = "default value"   
}
variable "giteaImage" {
  type        = string
  default = "default value"   
}
variable "giteaImageTag" {
  type        = string
  default = "default value"   
}

variable "gitea_uri" {
  type        = string
  default = "default value"   
}
variable "gitea_auth_token" {
  type        = string
  default = "default value"   
}
variable "gitea_deploy_repo_name" {
  type        = string
  default = "default value"   
}