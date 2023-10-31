
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
  insecure = "${var.tls-insecure}"  # If the cluster doesnt have valid cert and TLS check resulting in x509: certificate signed by unknown authority
}

# ******** CREATE ARGOCD APP for group-sync-operator-configure
resource "kubectl_manifest" "create-argocd-group-sync-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.group-sync-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.group-sync-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for cluster-logging-operator-configure
resource "kubectl_manifest" "create-argocd-cluster-logging-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.cluster-logging-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.cluster-logging-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for compliance-operator-configure
resource "kubectl_manifest" "create-argocd-compliance-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.compliance-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.compliance-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for file-integrity-operator-configure
resource "kubectl_manifest" "create-argocd-file-integrity-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.file-integrity-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.file-integrity-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for rhsso-operator-configure
resource "kubectl_manifest" "create-argocd-rhsso-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.rhsso-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.rhsso-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for odf-operator-configure
resource "kubectl_manifest" "create-argocd-odf-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.odf-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.odf-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for quay-operator-configure
resource "kubectl_manifest" "create-argocd-quay-operator-configure" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.quay-operator-config-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.quay-operator-config-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}