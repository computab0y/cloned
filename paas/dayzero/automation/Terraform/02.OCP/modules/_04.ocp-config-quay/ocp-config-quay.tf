
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

# ******** CREATE ARGOCD APP for quay-config
resource "kubectl_manifest" "create-argocd-quay-config" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.quay-config-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.quay-config-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}

