
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

# ******** CREATE ARGOCD APP for pipeline-operator-install
resource "kubectl_manifest" "create-argocd-pipeline-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.pipeline-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.pipeline-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}

# ******** CREATE ARGOCD APP for group-sync-operator-install
resource "kubectl_manifest" "create-argocd-group-sync-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.group-sync-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.group-sync-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}

# ******** CREATE ARGOCD APP for cluster-logging-operator-install
resource "kubectl_manifest" "create-argocd-cluster-logging-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.cluster-logging-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.cluster-logging-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}

# ******** CREATE ARGOCD APP for compliance-operator-install
resource "kubectl_manifest" "create-argocd-compliance-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.compliance-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.compliance-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}

# ******** CREATE ARGOCD APP for elasticsearch-operator-install
resource "kubectl_manifest" "create-argocd-elasticsearch-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.elasticsearch-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.elasticsearch-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for file-integrity-operator-install
resource "kubectl_manifest" "create-argocd-file-integrity-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.file-integrity-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.file-integrity-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for jaeger-operator-install
resource "kubectl_manifest" "create-argocd-jaeger-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.jaeger-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.jaeger-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for kiali-operator-install
resource "kubectl_manifest" "create-argocd-kiali-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.kiali-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.kiali-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for rhsso-operator-install
resource "kubectl_manifest" "create-argocd-rhsso-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.rhsso-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.rhsso-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for odf-operator-install
resource "kubectl_manifest" "create-argocd-odf-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.odf-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.odf-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for quay-operator-install
resource "kubectl_manifest" "create-argocd-quay-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.quay-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.quay-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for rhacs-operator-install
resource "kubectl_manifest" "create-argocd-rhacs-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.rhacs-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.rhacs-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
# ******** CREATE ARGOCD APP for service-mesh-operator-install
resource "kubectl_manifest" "create-argocd-service-mesh-operator-install" {
    yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: "${var.service-mesh-operator-app-name}"
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: "${var.dso-platform-repoURL}" 
    targetRevision: main
    path: "${var.service-mesh-operator-install-source-path}"
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-machine-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}