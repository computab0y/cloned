# OpenShift GitOps Cohort

This directory contains kustomize definitions for the installation of OpenShift GitOps, a Red Hat supported implementation of ArgoCD on Kubernetes.

OpenShift GitOps is deployed using a dedicated Operator. Within this directory, there are kustomize definitions for the installation of the Operator.
Once deployed, users can use request Custom Resources that can manage a complete ArgoCD based GitOps workflow.

## Installation Steps

### Install the Operator using the `oc` CLI

The Operator needs installing first.

An overlay is provided to to deploy the STABLE version of the GitOps Operator, version 1.3

```
$ oc create -k dayzero/legion/cohorts/openshift/gitops-operator/overlays/stable
```

Verify the Operator has been deployed successfully. You should see output similar to the below.

```
$ oc get csv -n openshift-gitops
NAME                               DISPLAY                    VERSION   REPLACES                           PHASE
openshift-gitops-operator.v1.3.1   Red Hat OpenShift GitOps   1.3.1     openshift-gitops-operator.v1.3.0   Succeeded
```
