 module "gitops-automation" {
    source = "./modules/_00.gitops-automation"
    host = var.host
    token = var.token
    gitea-catalogue-image-path = var.gitea-catalogue-image-path
    redhat-catalogue-image-path = var.redhat-catalogue-image-path
    gitea-dso-namespace = var.gitea-dso-namespace
}

 module "ocp-baseconfig-machineset" {
    source = "./modules/_01.ocp-baseconfig-machineset"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    machineset-app-name = var.machineset-app-name
    machineset-install-source-path = var.machineset-install-source-path
}

 module "ocp-operator-install" {
    source = "./modules/_02.ocp-operator-install"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    pipeline-operator-app-name = var.pipeline-operator-app-name
    pipeline-operator-install-source-path = var.pipeline-operator-install-source-path
    group-sync-operator-app-name = var.group-sync-operator-app-name
    group-sync-operator-install-source-path = var.group-sync-operator-install-source-path
    cluster-logging-operator-app-name = var.cluster-logging-operator-app-name
    cluster-logging-operator-install-source-path = var.cluster-logging-operator-install-source-path
    compliance-operator-app-name = var.compliance-operator-app-name
    compliance-operator-install-source-path = var.compliance-operator-install-source-path
    elasticsearch-operator-app-name = var.elasticsearch-operator-app-name
    elasticsearch-operator-install-source-path = var.elasticsearch-operator-install-source-path
    file-integrity-operator-app-name = var.file-integrity-operator-app-name
    file-integrity-operator-install-source-path = var.file-integrity-operator-install-source-path
    jaeger-operator-app-name = var.jaeger-operator-app-name
    jaeger-operator-install-source-path = var.jaeger-operator-install-source-path
    kiali-operator-app-name = var.kiali-operator-app-name
    kiali-operator-install-source-path = var.kiali-operator-install-source-path
    rhsso-operator-app-name = var.rhsso-operator-app-name
    rhsso-operator-install-source-path = var.rhsso-operator-install-source-path
    odf-operator-app-name = var.odf-operator-app-name
    odf-operator-install-source-path = var.odf-operator-install-source-path
    quay-operator-app-name = var.quay-operator-app-name
    quay-operator-install-source-path = var.quay-operator-install-source-path
    rhacs-operator-app-name = var.rhacs-operator-app-name
    rhacs-operator-install-source-path = var.rhacs-operator-install-source-path
    service-mesh-operator-app-name = var.service-mesh-operator-app-name
    service-mesh-operator-install-source-path = var.service-mesh-operator-install-source-path
}

 module "ocp-baseconfig-storage" {
    source = "./modules/_01.ocp-baseconfig-storage"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    storage-app-name = var.storage-app-name
    storage-install-source-path = var.storage-install-source-path
}

 module "ocp-operator-configure" {
    source = "./modules/_02.ocp-operator-configure"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    group-sync-operator-config-name = var.group-sync-operator-config-name
    group-sync-operator-config-source-path = var.group-sync-operator-config-source-path
    cluster-logging-operator-config-name = var.cluster-logging-operator-config-name
    cluster-logging-operator-config-source-path = var.cluster-logging-operator-config-source-path
    compliance-operator-config-name = var.compliance-operator-config-name
    compliance-operator-config-source-path = var.compliance-operator-config-source-path
    file-integrity-operator-config-name = var.file-integrity-operator-config-name
    file-integrity-operator-config-source-path = var.file-integrity-operator-config-source-path  
    rhsso-operator-config-name = var.rhsso-operator-config-name
    rhsso-operator-config-source-path = var.rhsso-operator-config-source-path
    odf-operator-config-name = var.odf-operator-config-name
    odf-operator-config-source-path = var.odf-operator-config-source-path
    quay-operator-config-name = var.quay-operator-config-name
    quay-operator-config-source-path = var.quay-operator-config-source-path
}

 module "ocp-config-rssso" {
    source = "./modules/_03-ocp-config-rssso"
    keycloak_username = var.keycloak_username
    keycloak_password = var.keycloak_password
    keycloak_url = var.keycloak_url
    sso_realm = var.sso_realm
    master_realm = var.master_realm
    rh-sso-valid_redirect_uris = var.rh-sso-valid_redirect_uris
 }

 module "ocp-config-rhacs" {
    source = "./modules/_05.ocp-config-rhacs"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    rhacs-config-app-name = var.rhacs-config-app-name
    rhacs-config-install-source-path = var.rhacs-config-install-source-path    
 }

 module "ocp-config-quay" {
    source = "./modules/_04.ocp-config-quay"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    quay-config-app-name = var.quay-config-app-name
    quay-config-install-source-path = var.quay-config-install-source-path    
 }
/*
 module "dso-config-gitea" {
    source = "./modules/_11.dso-config-gitea"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL 
    gitea-deploy-namespace = var.gitea-deploy-namespace
    gitea-deploy-instance-name = var.gitea-deploy-instance-name  
    giteaSsl = var.giteaSsl
    giteaAdminUser = var.giteaAdminUser
    giteaAdminPassword = var.giteaAdminPassword
    giteaAdminPasswordLength = var.giteaAdminPasswordLength
    giteaAdminEmail = var.giteaAdminEmail
    giteaVolumeSize = var.giteaVolumeSize
    postgresqlImage = var.postgresqlImage
    postgresqlImageTag = var.postgresqlImageTag
    postgresqlVolumeSize = var.postgresqlVolumeSize
    giteaImage = var.giteaImage
    giteaImageTag = var.giteaImageTag
    gitea_uri = var.gitea_uri
    gitea_auth_token = var.gitea_auth_token
    gitea_deploy_repo_name = var.gitea_deploy_repo_name
 }
*/
 module "dso-config-quay" {
    source = "./modules/_12.dso-config-quay"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    iac-interpreter = var.iac-interpreter  
    QUAY_URL = var.QUAY_URL
    QUAY_USER = var.QUAY_USER
    QUAY_PASSWORD = var.QUAY_PASSWORD
    EMAIL = var.EMAIL
    DSO_ORG = var.DSO_ORG
    DSO_REPO = var.DSO_REPO
    ROBOT_ACCOUNT = var.ROBOT_ACCOUNT 
    QUAY_TOKEN = var.QUAY_TOKEN
 }

 module "dso-config-tekton-chain" {
    source = "./modules/_13.dso-config-tekton-chain"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    verify-deploy-namespace = var.verify-deploy-namespace
    verify-deploy-public-key = var.verify-deploy-public-key   
 }

 module "dso-config-argocd" {
    source = "./modules/_14.dso-config-argocd"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL
    argocd-manager-namespace = var.argocd-manager-namespace
    argocd-managed-namespace = var.argocd-managed-namespace   
 }

 module "dso-install-vault" {
    source = "./modules/_15.dso-install-vault"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL   
 }

 module "dso-configure-vault" {
    source = "./modules/_16.dso-configure-vault"
    host = var.host
    token = var.token
    tls-insecure = var.tls-insecure
    dso-platform-repoURL = var.dso-platform-repoURL   
 }
 