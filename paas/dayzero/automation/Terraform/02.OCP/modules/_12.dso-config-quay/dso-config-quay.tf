
terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"  # for offline plugin setup
      version = ">= 1.14.0"
    }
  }
}

provider "kubectl" {
  host                   = "${var.host}"    
  token                  = "${var.token}"  
  load_config_file       = false
  insecure = "${var.tls-insecure}"  
}

resource "null_resource" "create-quay-org" {
  provisioner "local-exec" {
    command = "bash ./modules/_12.dso-config-quay/quay-configure.sh ${var.QUAY_URL} ${var.QUAY_USER} ${var.QUAY_PASSWORD} ${var.EMAIL} ${var.DSO_ORG} ${var.DSO_REPO} ${var.ROBOT_ACCOUNT} ${var.QUAY_TOKEN}"   
    interpreter = ["${var.iac-interpreter}", "-Command"]                          ### UPDATE-REQUIRED - change interpreter to bash
  }
}
