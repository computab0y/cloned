=============================================================================================================
AUTOMATION EXECUTION GUADANCE
=============================================================================================================
# **************** (STEP 0) Env Handed over from Azure

# **************** (STEP 1) Pre Steps before env use. eg. 
        (0) status check 
        (1) disable-operatorhub-default sources by going to
                administration -> cluster settings -> configuration -> operatorHub - sources and disable the once that will be created next
                the once with endpoint registry.redhat.io/redhat/...

                oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

(2) PREP CONTENT IN OFFICIAL FOR IMPEX
OCP3
tbc

IMPEX repo
aws --endpoint https://s3-openshift-storage.apps.ocp3.azure.dso.digital.mod.uk/ s3 cp testfile.txt s3://mimeograph-bucket-935b3ea5-9ecd-485b-b38c-a67be172e183/testfile.txt

(3) TRANSFER CONTENT VIE MICROSOFT
guiadance available (sent to micorsoft)

(4) IMPORT CONTENT
   - put packages per sequence directory
   - be in the seq directoy then oc-mirror ....oc-mirror --from . docker://quay.internal.cloudapp.net:443/import2 --dest-skip-tls --skip-metadata-check
   
   - update ImageContentSourcePolicy_master.yaml (with new data) (need to remove 443 port) and reapply
   - apply CatyalogSource as appropriate  

        Verification
        Verify that the ImageContentSourcePolicy resources were successfully installed:
        $ oc get imagecontentsourcepolicy --all-namespaces
        Verify that the CatalogSource resources were successfully installed:
        $ oc get catalogsource --all-namespaces

(5) add global pull secret to the cluster to pull from quay (if operator cant pull image fro quay)
more info: https://docs.openshift.com/container-platform/4.11/openshift_images/managing_images/using-image-pull-secrets.html#images-update-global-pull-secret_using-image-pull-secrets

        oc get pull-secret -n openshift-config
        - create a dockerconfigjson file (dockerjson_import2) in home from quayaccount - application credentials
        oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=dockerjson_import2
        check
        oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > pull_secret_import2

(6) REMOVE CATALOG SOURCES that are not required or are poting to external url eg. redhat-marketplace



# **************** (STEP 2) Manual preparation of machineset scripts (with new cluster data). ALso Update Storage)(ODF) machine type
    Details of changes tbc
        1. clustername
        2. resource group
        3. subnet
        4. vnetname
        5. network resource group


# [WAIT FOR MANUAL TASK] 20 mins

# **************** SETUP provider plugin before terraform init ====
        DOWNLAOD PROVIDERS
        wget https://github.com/mrparkers/terraform-provider-keycloak/releases/download/v3.10.0/terraform-provider-keycloak_3.10.0_linux_amd64.zip
        wget https://releases.hashicorp.com/terraform-provider-null/3.1.1/terraform-provider-null_3.1.1_linux_amd64.zip
        wget https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.14.0/terraform-provider-kubectl_1.14.0_linux_amd64.zip
        wget https://github.com/Lerentis/terraform-provider-gitea/releases/download/v0.9.0/terraform-provider-gitea_0.9.0_linux_amd64.zip

        mkdir -p ~/.terraform.d/plugins/registry.terraform.io/gavinbunney/kubectl/1.14.0/linux_amd64/;
        mkdir -p ~/.terraform.d/plugins/registry.terraform.io/hashicorp/null/3.1.1/linux_amd64/;
        mkdir -p ~/.terraform.d/plugins/registry.terraform.io/mrparkers/keycloak/3.10.0/linux_amd64/;
        mkdir -p ~/.terraform.d/plugins/registry.terraform.io/lerentis/gitea/0.9.0/linux_amd64/


        unzip th linux pack in /tmp/provider_plugin and Copy the file "terraform-provider-kubectl_v1.14.0", "terraform-provider-keycloak_v3.10.0 ","terraform-provider-null_v3.1.1_x5 " to the relevant plugins directory
        COPY
        cp my_resources/provider_plugin/terraform-provider-kubectl_1.14.0_linux_amd64/terraform-provider-kubectl_v1.14.0 ~/.terraform.d/plugins/registry.terraform.io/gavinbunney/kubectl/1.14.0/linux_amd64/terraform-provider-kubectl_v1.14.0
        cp my_resources/provider_plugin/terraform-provider-null_3.1.1_linux_amd64/terraform-provider-null_v3.1.1_x5 ~/.terraform.d/plugins/registry.terraform.io/hashicorp/null/3.1.1/linux_amd64/terraform-provider-null_v3.1.1_x5
        cp my_resources/provider_plugin/terraform-provider-keycloak_3.10.0_linux_amd64/terraform-provider-keycloak_v3.10.0 ~/.terraform.d/plugins/registry.terraform.io/mrparkers/keycloak/3.10.0/linux_amd64/terraform-provider-keycloak_v3.10.0
        cp my_resources/provider_plugin/terraform-provider-gitea_v0.9.0 ~/.terraform.d/plugins/registry.terraform.io/lerentis/gitea/0.9.0/linux_amd64/terraform-provider-gitea_v0.9.0

        chmod -R 775 ~/.terraform.d/

# **************** UPDATE VARIABLES for all modules ====
# update 02.OCP/variables.tf as appropriate


# **************** TERRAFORM EXECUTION ====
        cd to in 02.OCP directory
        # on inital setup rename .terraform.lock.hcl to .terraform.lock.hcl_OLD & terraform.tfstate to terraform.tfstate_OLD

        LINUX   terraform init -input=false -plugin-dir=/home/adminuser/.terraform.d/plugins
OFF-OCP3      terraform plan -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx" 
-var="keycloak_username=admin" -var="keycloak_password=xxx" -var="keycloak_url=https://keycloak-keycloak.apps.ocp3.azure.dso.digital.mod.uk"

ASDK - OCP2   terraform plan 
-var="host=https://api.ocp2.prod.ocp.local:6443" -var="token=xxxx" 
-var="keycloak_username=admin" -var="keycloak_password=xxx" 
-var="keycloak_url=https://keycloak-keycloak.apps.ocp2.prod.ocp.local"
var.keycloak_password = xxx
var.keycloak_url = xxx
var.host = https://api.ocp2.prod.ocp.local:6443
var.token = xxx
var.giteaAdminPassword = "xxx"
gitea token = "xxx"


# **************** (STEP 3) SETUP GITOPS AUTOMATION (without any install of operators, machineset, storage)
        terraform apply -target="module.<module name>" -var="host=<host name>" -var="<ocp token>"
        eg
        terraform apply -target="module.gitops-automation" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"
        terraform apply -target="module.gitops-automation" -var="host=https://api.ocp2.prod.ocp.local:6443" -var="token=xxx"            
==================

        # ==== POST TERRAFORM EXECUTION ====

        ##### ========== (MANUAL) PATCH gitea on OPERATOR
        # update operator - got to operator, yaml view
        registry.redhat.io/openshift4/ose-kube-rbac-proxy:v4.7.0
        quay.internal.cloudapp.net/quay/oc-mirror/openshift4/ose-kube-rbac-proxy:cbadfac7

        quay.internal.cloudapp.net/import2/openshift4/ose-kube-rbac-proxy:360da9ac

        quay.io/gpte-devops-automation/gitea-operator:v1.3.0
        quay.internal.cloudapp.net/quay/oc-mirror/gpte-devops-automation/gitea-operator:c48171ab
        quay.internal.cloudapp.net/import2/gpte-devops-automation/gitea-operator:c48171ab

        # == delete the below deployment to regenerate with the internal URLs above
        gitea-operator-controller-manager 

        ##### ========== (MANUAL)  Run to setup GITEA instance on operator
        # oc apply -f modules/_00.gitops-automation/my_resources/0.post_Terraform_create_gitea_instance.yaml

        ##### ========== (MANUAL)  create new gitea repo(dso-platform)
        1. Select New Migration in the Create… menu on the top right.
        2. repo name-dso-platform
        3. visibility - private
        4. create repo button
        OCP1 new repo URL - https://gitea-with-admin-dso-gitea.apps.ocp1.azure.dso.digital.mod.uk/dso-mgr/dso-platform.git
        ASDK new repo URL - https://gitea-i-dso-gitea.apps.ocp1.ocp.local/dso-mgr/dso-platform

        ##### ========== (MANUAL)  gitea Mirror/init From GitHub (dso-platform) - unzip the dso-platform package file to home directory
        remove .git files (if exists)
        git init
        git checkout -b main
        git add -A
        git commit -m "first commit"
        OCP1   git remote add origin https://gitea-with-admin-dso-gitea.apps.ocp1.azure.dso.digital.mod.uk/dso-mgr/dso-platform.git
        ASDK   git remote add origin https://gitea-i-dso-gitea.apps.ocp1.ocp.local/dso-mgr/dso-platform.git
        git -c http.sslVerify=false push -u origin main
        add username and password on the prompt to push changes
        dso-mgr  / xxxx

        ##### ========== (MANUAL) Configure github connection to argo
        below may not work if tls certs are not configured. apply manually on argo Checkbox "Skip server verification"
        oc apply -f modules/_00.gitops-automation/my_resources/1.post_Terraform_argo_repo_config.yaml


# **************** (STEP 4) OCP BASE CONFIG (GitOps Machineset)
        terraform apply -target="module.ocp-baseconfig-machineset" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"  

# **************** (STEP 5) MANUAL confirm machineset are up and running 
# [WAIT FOR MANUAL TASK] 20 mins
# check on OCP - compute - machine set - check all machines are up on the this column (machines)

# **************** (STEP 6) GITOPS - OPERATOR INSTALL
        terraform apply -target="module.ocp-operator-install" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"

# **************** (STEP 7) MANUAL check operators are installed 
# [WAIT FOR MANUAL TASK] 20 mins

# **************** (STEP 8) GITOPS - OCP BASE CONFIG (storage setup)
        terraform apply -target="module.ocp-baseconfig-storage" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"     

# **************** (STEP 9) GITOPS - OPERATOR CONFIGURE
        terraform apply -target="module.ocp-operator-configure" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"

# **************** (STEP 10) update quayregistry-config-bundle-data.yaml for storage. 
# [WAIT FOR MANUAL TASK] 20 mins

# **************** (STEP 11) GITOPS - RHSSO CONFIGURE
        terraform apply -target="module.ocp-config-rssso"  
        -var="keycloak_username=admin" -var="keycloak_password=xxx" -var="keycloak_url=https://keycloak-keycloak.apps.ocp3.azure.dso.digital.mod.uk"

# configure ocp by going
administration -> auth -> openidc connect
client id rh-ssoissuer url - https://keycloak-keycloak.apps.ocp2.prod.ocp.local/auth/realms/sso

# **************** (STEP 12) GITOPS - CONFIGURE RHACS & (STEP 10) GITOPS - CONFIGURE QUAY  & (STEP 10) MANUAL - CONFIGURE QUAY SSO INTERATION
        terraform apply -target="module.ocp-config-rhacs" -target="module.ocp-config-quay" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"

# [WAIT FOR MANUAL TASK - CONFIGURE QUAY SSO INTERATION] 20 mins

=============================================================================================================
DSO
=============================================================================================================

# **************** (STEP x)  Gitea Config (create instance) (create admin user) (create New repo. deploy-sample)
terraform apply -target="module.dso-config-gitea" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"

MANUAL TASK NOT MANDATORY- add sample manifest folder in dayzero/automation/Terraform/02.OCP/my_resources/dso-sample1

# [WAIT FOR MANUAL TASK - check gitea config] 20 mins

# **************** (STEP x)  Quay Configure - Create DSO Org

1.setup secret config-bundle-secret through -- oc create secret genric from file config.yaml


# **************** (STEP x)  Quay Configure - create repos (create robot acc & provide permission on repo)
NOTE: this module works for first time setup only where the initial user is not created
terraform apply -target="module.dso-config-quay" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"

# **************** (STEP x)  Quay Configure - IMPEX sample container for verification
# [WAIT FOR MANUAL TASK - check QUAY config] 20 mins

# **************** (STEP x)  TektonChain Configure - IMPEX dso-tool-box container, dso-sample container, SIGNATURE object for verification
tbc

# **************** (STEP x)  TektonChain - verification pipeline implementation (create deploy-sample ns, deplouy tasks, secret, pipeline)
terraform apply -target="module.dso-config-tekton-chain" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"
kind: Secret
apiVersion: v1
metadata:
  name: signing-secrets
data:
  cosign.pub: >-   LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFVVVsazBwZFNlT2s3M08zcENqKzZVcjJpL1VGVgpWQXZudUJlcUhYdndMYUZWR01IWTUrdU9KT3c3NVFDbmUrRVpUYVRvZnc1K1ZRTGswVFVvMW41MTZBPT0KLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==
type: Opaque
COPY
skopeo copy docker://dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/dso-sample:sha256-13f26de43b313dc81caa4e2b07cc25a1346a921418ca7027578040ecf9844def.sig docker://dso-quay-registry-quay-quay-enterprise.apps.ocp2.azure.dso.digital.mod.uk/dso-project/dso-sample:sha256-13f26de43b313dc81caa4e2b07cc25a1346a921418ca7027578040ecf9844def.sig --src-creds dso-project+dso_pipeline_acc:T3GNU95T4ZFJCLK30UJW83VKKG7LHFGDO5OKI542K7R1DXCCHQGZ2O6IK6VZTU9D --dest-creds dso-project+dso_pipeline_acc:6H18P0BFIDVLYLYYNO2GCMPMH91OGHG7F66A1JT6AQB30MWAQIK3Q4TVJC1KMEY4 --src-tls-verify=true --dest-tls-verify=true
VERIFY
cosign login -u dso-project+dso_pipeline_acc -p 6H18P0BFIDVLYLYYNO2GCMPMH91OGHG7F66A1JT6AQB30MWAQIK3Q4TVJC1KMEY4 dso-quay-registry-quay-quay-enterprise.apps.ocp2.azure.dso.digital.mod.uk
cosign verify --key cosign.pub dso-quay-registry-quay-quay-enterprise.apps.ocp2.azure.dso.digital.mod.uk/dso-project/dso-sample:latest

# **************** (STEP x)  TektonChain - execute verification (sample container)
oc create -f dayzero\automation\Terraform\02.OCP\my_resources\various-yaml-scripts\dso-sample\signature-verify\pipeline-run.yaml

# [WAIT FOR MANUAL TASK - check Verification execution outcome] 20 mins

# **************** (STEP x)  Argocd Config (ArgoCd manager Instance) (ArgoCd managed Instance for deploy) (configure comms gitea with argocd)
terraform apply -target="module.dso-config-argocd" -var="host=https://api.ocp3.azure.dso.digital.mod.uk:6443" -var="token=xxx"
terraform apply -target="module.dso-config-argocd" -var="host=https://api.ocp1.azure.dso.digital.mod.uk:6443" -var="token=xxx"

# [WAIT FOR MANUAL TASK - check argocd config] 20 mins

# **************** (STEP x)  Argocd Config deploy argocdapp (sample app)
UPDATE repoURl on 4.app.yaml 
oc apply -f dayzero\automation\Terraform\02.OCP\my_resources\various-yaml-scripts\dso-sample\argocd\4.app.yaml

# **************** (STEP x)  Install Vault
# **************** (STEP x)  confgure Vault


=============================================================================================================
WORK AREA
=============================================================================================================


=============================================================================================================
APPENDIX
=============================================================================================================
PREPARE package dso-platform for export
connect to ocp3 bastian host
cd /tmp
git clone https://github.com/defencedigital/dso-platform.git
cd /tmp/dso-platform/dayzero/automation/Terraform/02.OCP
mv .terraform.lock.hcl terraform.tfstate archive/
terraform init -input=false -plugin-dir=/home/adminuser/.terraform.d/plugins
COPY Providers to repo location (my_resources/provider_plugin/)


ASDK OCP HOST - https://console-openshift-console.apps.ocp1.ocp.local:6443

# ****************************  CONTAINER MOVEMENT COMMANDS
skopeo copy docker://quay.io/gpte-devops-automation/gitea:latest dir:/home/adminuser/dso/cont_impex_1/gitea:latest
To copy and sign an image:
skopeo copy --sign-by dev@example.com containers-storage:example/busybox:streaming docker://example/busybox:gold
# To encrypt an image:
skopeo copy docker://docker.io/library/nginx:1.17.8 oci:local_nginx:1.17.8
openssl genrsa -out private.key 1024
openssl rsa -in private.key -pubout > public.key
skopeo  copy --encryption-key jwe:./public.key oci:local_nginx:1.17.8 oci:try-encrypt:encrypted
# To decrypt an image:
skopeo copy --decryption-key ./private.key oci:try-encrypt:encrypted oci:try-decrypt:decrypted
####### To copy lcoal directory image to quay:
skopeo copy dir:/home/adminuser/dso/cont_impex/vault docker://dso-quay-registry-quay-quay-enterprise.apps.ocp1.azure.dso.digital.mod.uk/dso-project/vault-enterprise2:1.9.2-ent 
skopeo copy docker://hashicorp/vault-enterprise:1.11.1-ent docker://dso-quay-registry-quay-quay-enterprise.apps.ocp3.azure.dso.digital.mod.uk/dso-project/vault-enterprise:1.11.1-ent

# **************************** STEPS BEFORE TERRAFORM EXECUTION (OPTIONAL)
****************** RH_SSO (OPTIONAL - if using client credentials grant)
Client Credentials Grant Setup (recommended)
1. Create a new client using the openid-connect protocol. This client can be created in the master realm if you would like to manage your entire Keycloak instance, or in any other realm if you only want to manage that realm.
2. Update the client you just created:
Set Access Type to confidential.
Set Standard Flow Enabled to OFF.
Set Direct Access Grants Enabled to OFF
Set Service Accounts Enabled to ON.
3. Grant required roles for managing Keycloak via the Service Account Roles tab in the client you created in step 1, see Assigning Roles section below.

# *************** TERRAFORM DEBUG
# set TF_LOG to one of the log levels (in order of decreasing verbosity) TRACE, DEBUG, INFO, WARN or ERROR to change the verbosity of the logs.
run below from terminal
Bash: export TF_LOG="DEBUG"
PowerShell: $env:TF_LOG="DEBUG"

# run below to change location
Bash: export TF_LOG_PATH="tmp/terraform.log"
PowerShell: $env:TF_LOG_PATH="C:\tmp\terraform.log"

# for permanent change apply these environment variables to your .profile, .bashrc


# *************** RUN BELOW TO IMPORT TO QUAY
(1) ensure import org is created in quay
(2) go to quay console QUAY account settings and create application token
(3) create .docker in /home/adminuser, add config.json credentials
(4) from the above token upadte the below
# Update config.json
{
  "auths": {
    "quay.internal.cloudapp.net:443": {
      "auth": "xxx",
      "email": ""
    }
  }
}

PLAN B
vim ${XDG_RUNTIME_DIR}/containers/auth.json
FROM
{
        "auths": {
                "registry.access.redhat.com": {
                        "auth": "Og=="
                }
        }
}
TO
{
  "auths": {
    "quay.internal.cloudapp.net:443": {
      "auth": "xxxx",
      "email": ""
    }
  }
}

RUN THE BELOW
cd /quay/tmp
oc-mirror --from=. docker://quay.internal.cloudapp.net:443/import --dest-skip-tls

#*************************# IMPEX Transfer Steps

See below the steps required to download the media for D2S.

All the artefacts are in an S3 bucket held within the D2S platform. You will need an S3 compatible tool to download.
The example below utilises the AWS CLI, but other tools can be used.


### Setup AWS CLI

Download the AWS CLI from https://aws.amazon.com/cli/ and follow the install instructions.

Configure the AWS CLI by running the `aws configure` command. This will allow you to enter the following credentials to access the bucket.

It will look similar to this. The default region (`eu-west-2`) needs to be set, even though it is not used in the transfer.

$ aws configure
AWS Access Key ID [****************zeA]:
AWS Secret Access Key [****************apa]:
Default region name [eu-west-2]:
Default output format [None]:

Use the following S3 credentials:
Access Key: XXXzeA
Secret Key: XXXcnapa

### Verify Connection

Use the following command to connect to the bucket and list its contents. If this doesn't work as expected, you will get an error.

aws --endpoint https://s3-openshift-storage.apps.ocp3.azure.dso.digital.mod.uk/ s3 ls s3://mimeograph-bucket-935b3ea5-9ecd-485b-b38c-a67be172e183
2022-10-07 15:59:18 2140102656 mirror_seq1_000000.tar
2022-10-07 15:58:54 1947484672 mirror_seq1_000001.tar
2022-10-07 15:59:20 2141218304 mirror_seq1_000002.tar
...
...

### Transfer the Files

Use the following command to sync the files in the bucket to the workstation. Be aware there are a large number of files, so this may take some time depending on your network speed.

aws --endpoint https://s3-openshift-storage.apps.ocp3.azure.dso.digital.mod.uk/ s3 sync s3://mimeograph-bucket-935b3ea5-9ecd-485b-b38c-a67be172e183 .

NOTE: the 'dot' at the end of the command. We are using a UNIX client here, so this means "my present working directory". Adjust to where you want the files to be downloaded to.


### Tidy Up

Once complete, the files will need to be pushed through the usual IMPEX sausage machine to get it in the environment.
Each of the sequence files are sliced into ~2GB chunks.

# ************************** Upgrade OC- mirror
the tar fole is in my_resources

tar -xvf oc-mirror.tar.gz
which oc-mirror
result  /usr/bin/oc-mirror
oc-mirror version 
Client Version: version.Info{Major:"0", Minor:"1", GitVersion:"v0.1.0", GitCommit:"cee7de3cf66602b42116e2faada937ec71384bbd", GitTreeState:"clean", BuildDate:"2022-06-27T10:19:05Z", GoVersion:"go1.17.5", Compiler:"gc", Platform:"linux/amd64"}

cp oc-mirror /usr/bin/oc-mirror
oc-mirror version
Client Version: version.Info{Major:"", Minor:"", GitVersion:"4.11.0-202209130958.p0.g3c1c80c.assembly.stream-3c1c80c", GitCommit:"3c1c80ca6a5a22b5826c88897e7a9e5acd7c1a96", GitTreeState:"clean", BuildDate:"2022-09-13T10:48:59Z", GoVersion:"go1.18.4", Compiler:"gc", Platform:"linux/amd64"}

=================================
====================================
EDB
INstall operator
== configure instance - create cluster

apiVersion: postgresql.k8s.enterprisedb.io/v1
kind: Cluster
metadata:
  name: edb-cluster
  labels:
    app: edb
spec:
  logLevel: info
  storage:
    resizeInUseVolumes: true
    size: 50Gi
  primaryUpdateStrategy: unsupervised
  instances: 3

== apply licence
oc apply -f edb-cluster.yaml -n keycloak

== TO create External Database such as postgreSQL for Keycloak
Connect running pod by using following example command:
Eg: oc exec --stdin --tty "pod name" -- /bin/sh ( primary DB instance)
oc exec --stdin --tty edb-cluster-1 -n keycloak  -- /bin/sh

psql -U postgres
 
Run the command to create DB and credentials(replace XXXX)
----------------------------------------------------------

CREATE USER keycloak WITH PASSWORD 'xxx';
CREATE DATABASE keycloak WITH OWNER=keycloak ENCODING='UTF8';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;

check DB
list database \l
change db
\c keycloak
# list tables
\dt
# describe table
\d realm
# select table
select name from realm;

== create following secret to establish connectivity
apiVersion: v1
kind: Secret
metadata:
    name: keycloak-db-secret
    namespace: keycloak
stringData:
    POSTGRES_DATABASE: keycloak
    POSTGRES_EXTERNAL_ADDRESS: edb-cluster-rw.keycloak.svc.cluster.local
    POSTGRES_EXTERNAL_PORT: '5432'
    POSTGRES_HOST: edb-cluster-rw
    POSTGRES_PASSWORD: xxx
    POSTGRES_SUPERUSER: "true"
    POSTGRES_USERNAME: keycloak
    SSLMODE: disable
type: Opaque

== on rhsso insatnce add the below spec
  externalDatabase:
    enabled: true

== add selectors on services eg. keycloak-postgresql, 