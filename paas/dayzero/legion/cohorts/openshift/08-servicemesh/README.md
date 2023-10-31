# OpenShift Servicemesh installation

This directory contains kustomize definitions for the installation of OpenShift Container Storage (OCS).

OCS is deployed using a dedicated Operator. Within this directory, there are kustomize definitions for the installation of the Operator and the installation of the OCS StorageServer CR, which is then used by the operator to deploy all Storage Services.


## Install the Operator using the `oc` CLI
An overlay is provided to to deploy the Servicemesh, Jaeger and Kiali Operators 

```
$ oc create -k dayzero/legion/cohorts/openshift/servicemesh/smesh-operator/overlays/stable/
```

## Uninstall the Servicemesh

Please follow the steps in the link below to completely remove servicemesh
```
https://docs.openshift.com/container-platform/4.9/service_mesh/v2x/removing-ossm.html
```

