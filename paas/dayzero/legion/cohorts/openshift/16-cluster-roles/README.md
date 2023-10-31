# OpenShift Custom ClusterRoles Deployment

This directory contains the definitions for the deployment of OpenShift ClusterRoles. (currently only develeper-role)

## ArgoCD App deployment

The ArgoCD App has been deployed using the Terraform module in `dayzero/automation/Terraform/02.OCP/modules/_17.dso-cluster-roles` on each of the official environments to automatically update the developer-role.

To update the ArgoCD App, update the required Terraform files then run the below commands

```
$ terraform apply
var.host
  Enter a value: https://api.ocp1.azure.dso.digital.mod.uk:6443  <--- Choose the environment

var.token
  Enter a value: <OCP-Token>
```

Confirm the App deployment, e.g in OCP1
```
# oc -n openshift-gitops get app cluster-roles -o yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-roles
  namespace: openshift-gitops
spec:
  destination:
    server: https://kubernetes.default.svc
  project: default
  source:
    path: dayzero/legion/cohorts/openshift/16-cluster-roles
    repoURL: https://github.com/defencedigital/dso-platform
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## How to update developer-role

1- Create a new branch and update the developer-role.yaml with the needed rules.

2- Create a Pull Request and share with the team for review, then merge to main.

3- ArgoCD should update the clusterRole automatically. Check the Sync status of the ArgoCD App.
```
$ oc -n openshift-gitops get apps
NAME            SYNC STATUS   HEALTH STATUS
cluster-roles   Synced        Healthy
```

## ToDo

Adding any other custom clusterRole to this directory.
