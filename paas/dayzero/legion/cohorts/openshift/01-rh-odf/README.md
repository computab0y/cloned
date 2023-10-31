# Red Hat Openshift Data Foundation installation

This directory contains kustomize definitions for the installation of Openshift Data Foundation (ODF) formerly OpenShift Container Storage (OCS).

ODF is deployed using a dedicated Operator. Within this directory, there are kustomize definitions for the installation of the Operator and the installation of the OCS StorageServer CR, which is then used by the operator to deploy all Storage Services.


## Install the Operator using the `oc` CLI
An overlay is provided to to deploy the ODF Operator

```
$ oc create -k dayzero/legion/cohorts/openshift/01-rh-odf/operator/overlays/stable-4.10
```

## Install the StorageCluster using the `oc` CLI

An overlay is provided to to deploy the OCS StorageServer CR, on Azure. 

```
$ oc create -k dayzero/legion/cohorts/openshift/01-rh-odf/ocs-cluster/overlays/stable-4.10-azure
```

Change the default storage class to ceph rdb

```
$ oc get storageclass
```

    NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    managed-csi                   disk.csi.azure.com                      Delete          WaitForFirstConsumer   true                   2d19h
    managed-premium (default)     kubernetes.io/azure-disk                Delete          WaitForFirstConsumer   true                   3d21h
    ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   53m
    ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   53m
    openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         Delete          Immediate              false                  50m

```
$ oc patch storageclass managed-premium -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
storageclass.storage.k8s.io/managed-premium patched
```

```
$ oc get storageclass
```
    NAME                          PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    managed-csi                   disk.csi.azure.com                      Delete          WaitForFirstConsumer   true                   2d19h
    managed-premium               kubernetes.io/azure-disk                Delete          WaitForFirstConsumer   true                   3d21h
    ocs-storagecluster-ceph-rbd   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   55m
    ocs-storagecluster-cephfs     openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   55m
    openshift-storage.noobaa.io   openshift-storage.noobaa.io/obc         Delete          Immediate              false                  53m

```
oc patch storageclass ocs-storagecluster-ceph-rdb -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
storageclass.storage.k8s.io/ocs-storagecluster-ceph-rbd patched
```
```
$ oc get storageclass
```
    NAME                                    PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    managed-csi                             disk.csi.azure.com                      Delete          WaitForFirstConsumer   true                   2d19h
    managed-premium                         kubernetes.io/azure-disk                Delete          WaitForFirstConsumer   true                   3d21h
    ocs-storagecluster-ceph-rbd (default)   openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   61m
    ocs-storagecluster-cephfs               openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   61m
    openshift-storage.noobaa.io             openshift-storage.noobaa.io/obc         Delete          Immediate              false                  58m
