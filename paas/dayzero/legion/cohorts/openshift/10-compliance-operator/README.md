# OpenShift Compliance Operator

This directory contains kustomize definitions for the installation of the OpenShift Compliance Operator.


## Install the OpenShift Compliance Operator via the `oc` CLI
An overlay is provided to to deploy the latest OpenShift Compliance Operator

```
$ oc create -k dayzero/legion/cohorts/openshift/compliance-operator/operator/overlays/release-0.1
```


Verify the Operator has been deployed successfully. You should see output similar to the below.

```
$ oc get csv -n openshift-compliance
NAME                                     DISPLAY                                    VERSION     REPLACES                            PHASE
compliance-operator.v0.1.49              Compliance Operator                        0.1.49      compliance-operator.v0.1.48         Succeeded
```


## Configure the Compliance Operator instances via the `oc` CLI
An overlay is provided to configure the OpenShift Compliance Operator scansettings and deploy on each node

```
$ oc create -k dayzero/legion/cohorts/openshift/compliance-operator/instance/overlays/ocp-cis
```

## Uninstalling the OpenShift Compliance Operator 

Please follow the steps in the link below to remove the Compliance Operator

https://docs.openshift.com/container-platform/4.9/security/compliance_operator/compliance-operator-uninstallation.html
