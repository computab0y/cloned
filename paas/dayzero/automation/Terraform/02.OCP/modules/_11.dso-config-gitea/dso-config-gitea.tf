
terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"  # for offline plugin setup
      version = ">= 1.14.0"
    }
 /*   restapi = {
      source = "registry.terraform.io/Mastercard/restapi"
      version = "1.17.0"
    } 
 */
    gitea = {
      source = "registry.terraform.io/Lerentis/gitea"
      version = "0.9.0"
    } 
  }
}

provider "kubectl" {
  host                   = "${var.host}"    
  token                  = "${var.token}"  
  load_config_file       = false
  insecure = "${var.tls-insecure}"  
}

# ********  create gitea namespace 
resource "kubectl_manifest" "create-gitea-namespace" {
    yaml_body = <<YAML

apiVersion: v1
kind: Namespace
metadata:
  name: ${var.gitea-deploy-namespace}
  annotations:
    openshift.io/display-name: '${var.gitea-deploy-namespace}'

YAML
}

# ******** Gitea Config (create deploy instance)
resource "kubectl_manifest" "create-gitea-deploy-instance" {
    yaml_body = <<YAML

apiVersion: gpte.opentlc.com/v1
kind: Gitea
metadata:
  name: "${var.gitea-deploy-instance-name}"
  namespace: "${var.gitea-deploy-namespace}"
spec:
  giteaSsl: ${var.giteaSsl}
  giteaAdminUser: "${var.giteaAdminUser}"
  giteaAdminPassword: "${var.giteaAdminPassword}"
  giteaAdminPasswordLength: ${var.giteaAdminPasswordLength}
  giteaAdminEmail: "${var.giteaAdminEmail}"
  giteaVolumeSize: "${var.giteaVolumeSize}"
  postgresqlImage: "${var.postgresqlImage}"
  postgresqlImageTag: "${var.postgresqlImageTag}"
  postgresqlVolumeSize: "${var.postgresqlVolumeSize}"
  giteaImage: "${var.giteaImage}"
  giteaImageTag: "${var.giteaImageTag}"

YAML
}
provider "gitea" {
  base_url = var.gitea_uri # optionally use GITEA_BASE_URL env var
 # token    = var.gitea_auth_token # optionally use GITEA_TOKEN env var

  # Username/Password authentication is mutally exclusive with token authentication
  username = var.giteaAdminUser # optionally use GITEA_USERNAME env var
  password = var.giteaAdminPassword # optionally use GITEA_PASSWORD env var
  # A file containing the ca certificate to use in case ssl certificate is not from a standard chain
  # cacert_file = var.cacert_file 

  # If running a gitea instance with self signed TLS certificates
  # and you want to disable certificate validation you can deactivate it with this flag
  insecure = true 
}

resource "gitea_repository" "create_gitea_repo" {
  username     = "dso-mgr"
  name         = var.gitea_deploy_repo_name
  private      = true
  issue_labels = "Default"
  license      = "MIT"
  gitignores   = "Go"
}


