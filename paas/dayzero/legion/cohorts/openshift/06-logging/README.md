# OpenShift Logging Cohort

This directory contains kustomize definitions for the installation of OpenShift Logging.

Logging is deployed using a two operators, the ElasticSearch Operator and the Logging Operator itself. Within this directory, there are kustomize definitions for the installation of the two Operators and the installation of the ClusterLogging CR, which is then used by the operator to deploy all Logging resources.

In addition, this directory also includes kustomize definitions for the installation of Cluster Log Forwarding. See that directory for further instructions.
## Install the ElasticSearch Operator using the `oc` CLI
An overlay is provided to to deploy the latest ElasticSearch Operator version (5.3)

```
$ oc create -k dayzero/legion/cohorts/openshift/logging/elasticsearch-operator/overlays/stable
```

## Install the Logging Operator using the `oc` CLI
An overlay is provided to to deploy the latest Logging Operator version (5.3)

```
$ oc create -k dayzero/legion/cohorts/openshift/logging/logging-operator/overlays/stable
```

Verify the two Operators have been deployed successfully. You should see output similar to the below.

```
$ oc get csv -n openshift-logging
NAME                               DISPLAY                            VERSION    REPLACES                           PHASE
cluster-logging.5.3.0-55           Red Hat OpenShift Logging          5.3.0-55                                      Succeeded
elasticsearch-operator.5.3.0-67    OpenShift Elasticsearch Operator   5.3.0-67                                      Succeeded
```

## Install the ClusterLogging using the `oc` CLI

An overlay is provided to to deploy the ClusterLogging CR, using the earlier installed OCS Block StorageClass `ocs-storagecluster-ceph-rbd`. All Logging resources will be deployed.

```
$ oc create -k dayzero/legion/cohorts/openshift/logging/logging-instance/overlays/default-ocs
```

Be aware this step may take a few minutes to complete.


Verification step

Verify that the `csi-cephfsplugin-*` and `csi-rbdplugin-*` pods are running on all nodes in the `openshift-storage` namespace.

```
$ oc project openshift-storage

$ oc get pod -o wide |grep csi
```

    csi-cephfsplugin-427gz           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth3-mckrf     <none>           <none>
    csi-cephfsplugin-56psd           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth1-5whhx     <none>           <none>
    csi-cephfsplugin-5jfwg           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth3-qlwbw     <none>           <none>
    csi-cephfsplugin-5zp84           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth3-nsb5g    <none>           <none>
    csi-cephfsplugin-6q4n4           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth2-9fp7g    <none>           <none>
    csi-cephfsplugin-77b44           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-storage-uksouth1-zjtwn   <none>           <none>
    csi-cephfsplugin-78tkx           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth3-ssbht    <none>           <none>
    csi-cephfsplugin-88dwx           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth1-95d9k    <none>           <none>
    csi-cephfsplugin-89fpn           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth2-2j9zc     <none>           <none>
    csi-cephfsplugin-8pz2b           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-master-2                 <none>           <none>
    csi-cephfsplugin-9524b           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-storage-uksouth2-w77xt   <none>           <none>
    csi-cephfsplugin-r7qzf           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth2-wjfw6    <none>           <none>
    csi-cephfsplugin-sgjkx           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth3-nln6p    <none>           <none>
    csi-cephfsplugin-ss78c           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth1-9tfkg     <none>           <none>
    csi-cephfsplugin-tlb2f           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth2-brtn9    <none>           <none>
    csi-cephfsplugin-tmzlz           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-master-0                 <none>           <none>
    csi-cephfsplugin-wt88c           3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth1-jg9pz    <none>           <none>
    csi-rbdplugin-52blj              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-storage-uksouth2-w77xt   <none>           <none>
    csi-rbdplugin-6pxdb              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth1-d2dn8    <none>           <none>
    csi-rbdplugin-6s2wz              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-storage-uksouth3-hr65r   <none>           <none>
    csi-rbdplugin-6s8gm              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth1-gn2pm    <none>           <none>
    csi-rbdplugin-7llcb              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth2-89ts5    <none>           <none>
    csi-rbdplugin-89g9b              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-master-2                 <none>           <none>
    csi-rbdplugin-8bwj7              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-master-1                 <none>           <none>
    csi-rbdplugin-8lzw8              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth2-nbp47     <none>           <none>
    csi-rbdplugin-9wdp2              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth3-p4k2p     <none>           <none>
    csi-rbdplugin-br4kz              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth1-5whhx     <none>           <none>
    csi-rbdplugin-d2q95              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth2-brtn9    <none>           <none>
    csi-rbdplugin-f6tnh              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-infra-uksouth1-9tfkg     <none>           <none>
    csi-rbdplugin-fm2fz              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-worker-uksouth3-ssbht    <none>           <none>
    csi-rbdplugin-fvvfd              3/3     Running   3               4d20h   10.xxx.xxx.xxx     ocpx-xxxxx-storage-uksouth1-zjtwn   <none>           <none>

