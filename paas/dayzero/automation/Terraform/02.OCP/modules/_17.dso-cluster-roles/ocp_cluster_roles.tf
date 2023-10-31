terraform {
  required_version = ">= 0.13"
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl" # for offline plugin setup
      version = ">= 1.14.0"
    }
  }
}
provider "kubectl" {
  host             = var.host
  token            = var.token
  load_config_file = false
  insecure         = var.tls-insecure # If the cluster doesnt have valid cert and TLS check resulting in x509: certificate signed by unknown authority
}

# ******** CREATE ARGOCD APP for ClusterRoles deployment
resource "kubectl_manifest" "CREATE-ARGOCD-APP-for-clusterroles-deployment" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.clusterroles-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}"
    targetRevision: main
    path: "${var.clusterroles-source-path}"
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}

