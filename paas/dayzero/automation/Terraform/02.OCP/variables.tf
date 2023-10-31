# ************************  GENERAL
variable "host" {
  type        = string
  sensitive   = true  
}
variable "token" {
  type        = string
  sensitive   = true
}
variable "dso-platform-repoURL" {
  type        = string
  default = "https://gitea-i-dso-gitea.apps.ocp1.ocp.local/dso-mgr/dso-platform.git"   
}
variable "iac-interpreter" {
  type        = string
  default = "PowerShell"   # or bash
}

variable "tls-insecure" {
  type        = string
  default = true     # If the cluster doesnt have valid cert and TLS check resulting in x509: certificate signed by unknown authority
}
# ************************  GITOPS AUTOMATION
variable "gitea-dso-namespace" {
  type        = string
  default = "dso-gitea"   
}

variable "gitea-catalogue-image-path" {
  type        = string
  default = "quay.internal.cloudapp.net/import2/gpte-devops-automation/gitea-catalog:latest"
}
variable "redhat-catalogue-image-path" {
  type        = string
  default = "quay.internal.cloudapp.net/import2/redhat/redhat-operator-index:v4.10"
}
# ************************  MACHINESET INSTALL
variable "machineset-app-name" {
  type        = string
  default = "install-machineset"   
}
variable "machineset-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/00-machinesets/ocp/overlays/ash-sbx"   
}
# ************************  STORAGE INSTALL
variable "storage-app-name" {
  type        = string
  default = "install-storage"   
}
variable "storage-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/01-rh-odf/ocs-cluster/overlays/ash"   
}

# ************************  OPERATOR INSTALL
variable "pipeline-operator-app-name" {
  type        = string
  default = "o-install-pipeline"   
}
variable "pipeline-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/13-pipeline"   
}

variable "group-sync-operator-app-name" {
  type        = string
  default = "o-install-group-sync"   
}
variable "group-sync-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/09-group-sync/instance/overlays/ash-sbx"   
}

variable "cluster-logging-operator-app-name" {
  type        = string
  default = "o-install-cluster-logging"   
}
variable "cluster-logging-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/06-logging/logging-operator/overlays/stable"   
}

variable "compliance-operator-app-name" {
  type        = string
  default = "o-install-compliance"   
}
variable "compliance-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/10-compliance-operator/operator/overlays/release-0.1"   
}

variable "elasticsearch-operator-app-name" {
  type        = string
  default = "o-install-elasticsearch"   
}
variable "elasticsearch-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/06-logging/elasticsearch-operator/overlays/stable"   
}

variable "file-integrity-operator-app-name" {
  type        = string
  default = "o-install-file-integrity"   
}
variable "file-integrity-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/11-file-integrity/operator/overlays/release-0.1"   
}

variable "jaeger-operator-app-name" {
  type        = string
  default = "o-install-jaeger"   
}
variable "jaeger-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/08-servicemesh/smesh-operator/overlays/stable"   
}

variable "kiali-operator-app-name" {
  type        = string
  default = "o-install-kiali"   
}
variable "kiali-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/08-servicemesh/smesh-operator/overlays/stable"   
}

variable "rhsso-operator-app-name" {
  type        = string
  default = "o-install-rhsso"   
}
variable "rhsso-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/03-rh-sso/operator/overlays/stable"   
}

variable "odf-operator-app-name" {
  type        = string
  default = "o-install-odf"   
}
variable "odf-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/01-rh-odf/operator/overlays/ash"   
}

variable "quay-operator-app-name" {
  type        = string
  default = "o-install-quay"   
}
variable "quay-operator-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/02-rh-quay/quay-operator/overlays/stable-3.7"   
}

variable "rhacs-operator-app-name" {
  type        = string
  default = "o-install-rhacs"   
}
variable "rhacs-operator-install-source-path" {
  type        = string
  default = "dso-platform/dayzero/legion/cohorts/openshift/04-rhacs/rhacs-operator/overlays/latest"   
}

variable "service-mesh-operator-app-name" {
  type        = string
  default = "o-install-service-mesh"   
}
variable "service-mesh-operator-install-source-path" {
  type        = string
  default = "dso-platform/dayzero/legion/cohorts/openshift/08-servicemesh/smesh-operator/overlays/stable"   
}

# ************************  OPERATOR CONFIGURE
variable "group-sync-operator-config-name" {
  type        = string
  default = "o-config-group-sync"   
}
variable "group-sync-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/09-group-sync/instance/overlays/ash"   
}

variable "cluster-logging-operator-config-name" {
  type        = string
  default = "o-config-cluster-logging"   
}
variable "cluster-logging-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/06-logging/logging-instance/overlays/default-ocs"   
}

variable "compliance-operator-config-name" {
  type        = string
  default = "o-config-compliance"   
}
variable "compliance-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/10-compliance-operator/instance/overlays/ocp-cis"   
}

variable "file-integrity-operator-config-name" {
  type        = string
  default = "o-config-file-integrity"   
}
variable "file-integrity-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/11-file-integrity/instance/overlays/worker"   
}

variable "rhsso-operator-config-name" {
  type        = string
  default = "o-config-rhsso"   
}
variable "rhsso-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/02-rh-quay/quay-instance/base"   
}

variable "odf-operator-config-name" {
  type        = string
  default = "o-config-odf"   
}
variable "odf-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/01-rh-odf/ocs-cluster/overlays/ash"   
}

variable "quay-operator-config-name" {
  type        = string
  default = "o-config-quay"   
}
variable "quay-operator-config-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/02-rh-quay/quay-bucket-claim/base"   
}

# ************************  RHSSO CONFIGURE
variable "keycloak_username" {
  type        = string
  sensitive   = true 
}
variable "keycloak_password" {
  type        = string
  sensitive   = true
}
variable "keycloak_url" {
  type        = string
  sensitive   = true 
}
variable "master_realm" {
  type        = string
  default = "master2"
}
variable "sso_realm" {
  type        = string
  default = "sso3"
}
variable "rh-sso-valid_redirect_uris" {
  type        = string
  default = "default value"
}

# ************************  RHACS CONFIGURE
variable "rhacs-config-app-name" {
  type        = string
  default = "config-rhacs"   
}
variable "rhacs-config-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/04-rhacs/rhacs-instances/base"   
}

# ************************  QUAY CONFIGURE
variable "quay-config-app-name" {
  type        = string
  default = "config-quay"   
}
variable "quay-config-install-source-path" {
  type        = string
  default = "dayzero/legion/cohorts/openshift/02-rh-quay/quay-instance/base"   
}

# ************************  GITEA CONFIGURE
variable "gitea-deploy-namespace" {
  type        = string
  default = "deploy-gitea"   
}
variable "gitea-deploy-instance-name" {
  type        = string
  default = "deploy-instance"   
}
variable "giteaSsl" {
  type        = bool
  default = true   
}
variable "giteaAdminUser" {
  type        = string
  default = "dso-mgr"   
}
variable "giteaAdminPassword" {
  type        = string
 # default = ""
  sensitive   = true   
}
variable "giteaAdminPasswordLength" {
  type        = number
  default = 32
}
variable "giteaAdminEmail" {
  type        = string
  default = "s.mussa@accenture.com"   
}
variable "giteaVolumeSize" {
  type        = string
  default = "4Gi"   
}
variable "postgresqlImage" {
  type        = string
  # default = "quay.internal.cloudapp.net/quay/oc-mirror/rhel8/postgresql-12"     #ASDK
  default = "registry.redhat.io/rhel8/postgresql-12"    #OCP3
}
variable "postgresqlImageTag" {
  type        = string
  # default = "e4bfb87a"      #ASDK
  default = "latest"    #OCP3    
}
variable "postgresqlVolumeSize" {
  type        = string
  default = "4Gi"   
}
variable "giteaImage" {
  type        = string
  # default = "quay.internal.cloudapp.net/quay/oc-mirror/gpte-devops-automation/gitea"     #ASDK
  default = "quay.io/gpte-devops-automation/gitea"    #OCP3   
}
variable "giteaImageTag" {
  type        = string
  default = "latest"   
}
variable "gitea_uri" {
  type        = string
  default = "https://deploy-instance-deploy-gitea.apps.ocp3.azure.dso.digital.mod.uk"       #OCP3 
}
variable "gitea_auth_token" {
  type        = string
 # default = "" 
  sensitive   = true  
}
variable "gitea_deploy_repo_name" {
  type        = string
  default = "deploy-sample"   
}

# ************************  TEKTON CHAIN (VERIFY) CONFIGURE
variable "verify-deploy-namespace" {
  type        = string
  default = "deploy-sample"   
}
variable "verify-deploy-public-key" {
  type        = string
  default = ""   
}

# ************************  ARGOCD CONFIGURE
variable "argocd-manager-namespace" {
  type        = string
  default = "pen-test-argo"   
}
variable "argocd-managed-namespace" {
  type        = string
  default = "pen-test"   
}

# ************************  QUAY CONFIGURE
variable "QUAY_URL" {
  type        = string
  default = "https://dso-quay-registry-quay-quay-enterprise.apps.ocp3.azure.dso.digital.mod.uk"   
}
variable "QUAY_USER" {
  type        = string
  default = "quayadmin"   
}
variable "QUAY_PASSWORD" {
  type        = string
  # default = ""
  sensitive   = true   
}
variable "EMAIL" {
  type        = string
  default = "quayadmin@example.com"   
}
variable "DSO_ORG" {
  type        = string
  default = "dso-project"   
}
variable "DSO_REPO" {
  type        = string
  default = "dso-sample"   
}
variable "ROBOT_ACCOUNT" {
  type        = string
  default = "dso_pipeline_acc"   
}
variable "QUAY_TOKEN" {
  type        = string
  # default = "" 
  sensitive   = true  
}




