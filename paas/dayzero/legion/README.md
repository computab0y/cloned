
# Legion

Build your own legion using composable, adaptable cloud native cohorts.

Legion is a suite of Kustomize defined Kubernetes resources which define the baseline tools and applications initialy deployed to an OpenShift cluster. Each cohort can be deployed either manually using the `kubectl` or `oc` command-line tools, automagically using a GitOps workflow.

## Cohorts

Just like a Roman legion of old, your legion is built up of single units of capability called cohorts.

Below is a table of currently available cohorts. Additional information about each Cohort and its capability is described in each cohort directory.

| Name | Description |
| ----------- | ----------- |
| OpenShift Container Storage | Installs the OCS Operator and deploys StorageCluster Services |
| Red Hat Quay | Installs the Quay Operator and deploys QuayRegistry and all Services |
| OpenShift GitOps Operator | Installs the GitOps Operator and enables the use of GitOps workflows (based on ArgoCD) within OpenShift |
| OpenShift Logging | Installs the Logging Operator and deploys all Logging Services |
