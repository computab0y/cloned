
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

# ********  create argocd-manager-namespace
resource "kubectl_manifest" "create-argocd-manager-namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.argocd-manager-namespace}
  annotations:
    openshift.io/display-name: '${var.argocd-manager-namespace}'
YAML
}

# ******** CREATE ARGOCD INSTANCE
resource "kubectl_manifest" "create-argocd-inst" {
    yaml_body = <<YAML

apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: ${var.argocd-manager-namespace}-argocd
  namespace: ${var.argocd-manager-namespace}
spec:
  server:
    insecure: true
    route:
      enabled: true
      tls:
        insecureEdgeTerminationPolicy: Redirect
        termination: edge
  rbac:
    defaultPolicy: ''
    policy: |
      g, system:cluster-admins, role:admin
      p, role:argo-admin, applications, *, */*, allow
      p, role:argo-admin, clusters, get, *, allow
      p, role:argo-admin, repositories, get, *, allow
      p, role:argo-admin, repositories, create, *, allow
      p, role:argo-admin, repositories, update, *, allow
      p, role:argo-admin, repositories, delete, *, allow
      g, system:authenticated, role:argo-admin
    scopes: '[groups]'
  dex:
    openShiftOAuth: true
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
  ha:
    enabled: false
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
  tls:
    ca: {}
  redis:
    resources:
      limits:
        cpu: 500m
        memory: 256Mi
      requests:
        cpu: 250m
        memory: 128Mi
  controller:
    processors: {}
    resources:
      limits:
        cpu: '2'
        memory: 2Gi
      requests:
        cpu: 250m
        memory: 1Gi
    sharding: {}
YAML
  depends_on = [kubectl_manifest.create-argocd-manager-namespace]
}

# ******** CREATE SERVICE ACCOUNT ARGOCD
resource "kubectl_manifest" "create-argocd-servacc" {
    yaml_body = <<YAML

apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${var.argocd-manager-namespace}-doer
  namespace: ${var.argocd-manager-namespace}
YAML
  depends_on = [kubectl_manifest.create-argocd-inst]
}


# ******** CREATE argocd-pull-secret
resource "kubectl_manifest" "create-argocd-pull-secret" {
    yaml_body = <<YAML

apiVersion: v1
kind: Secret
metadata:
  name: ${var.argocd-manager-namespace}-robot-pull-secret
  namespace: ${var.argocd-manager-namespace}
data:
  .dockerconfigjson: ewogICJhdXRocyI6IHsKICAgICJkc28tcXVheS1yZWdpc3RyeS1xdWF5LXF1YXktZW50ZXJwcmlzZS5hcHBzLm9jcDIuYXp1cmUuZHNvLmRpZ2l0YWwubW9kLnVrIjogewogICAgICAiYXV0aCI6ICJaSE52TFhCeWIycGxZM1FyWkhOdlgzQnBjR1ZzYVc1bFgyRmpZem8yU0RFNFVEQkNSa2xFVmt4WlRGbFpUazh5UjBOTlVFMUlPVEZQUjBoSE4wWTJOa0V4U2xRMlFWRkNNekJOVjBGUlNVc3pVVFJVVmtwRE1VdE5SVmswIiwKICAgICAgImVtYWlsIjogIiIKICAgIH0KICB9Cn0=
type: kubernetes.io/dockerconfigjson

YAML
  depends_on = [kubectl_manifest.create-argocd-servacc]
}

# ******** Link argocd-pull-secret with SA
resource "kubectl_manifest" "link-argocd-pull-secret" {
    yaml_body = <<YAML

apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
  namespace: ${var.argocd-managed-namespace}
imagePullSecrets:
- name: ${var.argocd-manager-namespace}-robot-pull-secret

YAML
  depends_on = [kubectl_manifest.create-argocd-pull-secret]
}

# ******** create doer role binding
resource "kubectl_manifest" "create-doer-role-binding" {
    yaml_body = <<YAML

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${var.argocd-manager-namespace}-doer-rb
  namespace: ${var.argocd-managed-namespace}
  labels:
    app.kubernetes.io/managed-by: ${var.argocd-manager-namespace}
    app.kubernetes.io/name: ${var.argocd-manager-namespace}-doer
    app.kubernetes.io/part-of: ${var.argocd-manager-namespace}
  annotations:
    argocds.argoproj.io/name: ${var.argocd-manager-namespace}
    argocds.argoproj.io/namespace: ${var.argocd-manager-namespace}
subjects:
  - kind: ServiceAccount
    name: ${var.argocd-manager-namespace}-doer
    namespace: ${var.argocd-manager-namespace}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${var.argocd-manager-namespace}-doer-clusterrole

YAML
  depends_on = [kubectl_manifest.create-argocd-managed-namespace]
}


# ******** Create cluster ROLE ARGOCD
resource "kubectl_manifest" "create-role-for-argocd" {
    yaml_body = <<YAML

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${var.argocd-manager-namespace}-doer-clusterrole
rules:
  - verbs:
      - get
      - list
      - watch
    apiGroups:
      - '*'
    resources:
      - '*'
  - verbs:
      - get
      - list
    nonResourceURLs:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - operators.coreos.com
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - operator.openshift.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - user.openshift.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - config.openshift.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - console.openshift.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - ''
    resources:
      - namespaces
      - persistentvolumeclaims
      - persistentvolumes
      - configmaps
  - verbs:
      - get
      - create
      - list
      - patch
      - update
      - watch
      - delete
      - deletecollection          
    apiGroups:
      - rbac.authorization.k8s.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - storage.k8s.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - machine.openshift.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - machineconfig.openshift.io
    resources:
      - '*'
  - verbs:
      - '*'
    apiGroups:
      - compliance.openshift.io
    resources:
      - scansettingbindings
YAML
}

# ********  create argocd-managed-namespace
resource "kubectl_manifest" "create-argocd-managed-namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: ${var.argocd-managed-namespace}
  annotations:
    openshift.io/display-name: '${var.argocd-managed-namespace}'
  labels:
    argocd.argoproj.io/managed-by: ${var.argocd-manager-namespace}
YAML
  depends_on = [kubectl_manifest.create-argocd-inst]
}



