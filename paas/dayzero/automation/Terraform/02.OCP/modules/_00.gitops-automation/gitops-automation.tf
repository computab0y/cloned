
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
  insecure = true  # No valid cert and TLS check resulting in x509: certificate signed by unknown authority

}
# ******** INSTALL ARGOCD OPERATOR 
resource "kubectl_manifest" "install-argocd-operator" {
    yaml_body = <<YAML
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: stable
  name: openshift-gitops-operator 
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 
YAML
  depends_on = [kubectl_manifest.install-redhat-catalogue-source]
}

# ********  create gitea namespace 
resource "kubectl_manifest" "create-gitea-namespace" {
    yaml_body = <<YAML

apiVersion: v1
kind: Namespace
metadata:
  name: "${var.gitea-dso-namespace}"
  annotations:
    openshift.io/display-name: '"${var.gitea-dso-namespace}"'

YAML
}
/*
# ******** INSTALL gitea catalogue source 
resource "kubectl_manifest" "install-gitea-catalogue-source" {
    yaml_body = <<YAML

apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-gpte-gitea
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: "${var.gitea-catalogue-image-path}"
  displayName: Red Hat GPTE (Gitea)
YAML
}
*/

# ******** INSTALL redhat catalogue source 
resource "kubectl_manifest" "install-redhat-catalogue-source" {
    yaml_body = <<YAML
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: redhat-operators
  namespace: openshift-marketplace
spec:
  image: "${var.redhat-catalogue-image-path}"
  sourceType: grpc
YAML
}

# ******** INSTALL gitea OPERATOR GROUP
resource "kubectl_manifest" "install-gitea-operator-group" {
    yaml_body = <<YAML

apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: gitea-og
  namespace: "${var.gitea-dso-namespace}"

YAML
  depends_on = [kubectl_manifest.create-gitea-namespace]
}

# ******** INSTALL gitea OPERATOR
resource "kubectl_manifest" "install-gitea-operator" {
    yaml_body = <<YAML

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: gitea-operator
  namespace: openshift-operators
spec:
  channel: stable
  name: gitea-operator
  source: gitea-catalog
  sourceNamespace: openshift-marketplace
YAML
  depends_on = [kubectl_manifest.install-redhat-catalogue-source]
}