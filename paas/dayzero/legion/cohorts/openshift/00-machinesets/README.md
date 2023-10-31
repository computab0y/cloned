# OpenShift Machineset deployment

This directory contains kustomize definitions for the installation of OpenShift Machinesets.


## Install OpenShift Macinessets using the `oc` CLI
Separate overlays have been provided to deploy infrastructure, storage and ingress Machinesets with the necessary labels and taints in each cluster



```
$ oc create -k dayzero/legion/cohorts/openshift/00-machinesets/ocp/overlays/ocp3/
```


Verify the Operator has been deployed successfully. You should see output similar to the below.

```
$ oc get csv -n openshift-file-integrity
NAME                                     DISPLAY                                          VERSION     REPLACES                            PHASE
file-integrity-operator.v0.1.22          File Integrity Operator                          0.1.22                                          Succeeded
```

## Configure the File Integrity instances using the `oc` CLI

Run the following command to deploy the file integrity scan instances on each node

```
$ oc create -k dayzero/legion/cohorts/openshift/file-integrity/instance/overlays/worker
```

Verify the pods were created successfully

```
$ oc get pod -n openshift-file-integrity
```
    NAME                                       READY   STATUS    RESTARTS   AGE
    aide-infra-fileintegrity-6559s             1/1     Running   0          14h
    aide-infra-fileintegrity-m76l2             1/1     Running   0          14h
    aide-infra-fileintegrity-td4wx             1/1     Running   0          14h
    aide-infra-fileintegrity-whf5p             1/1     Running   0          14h
    aide-ingress-fileintegrity-5wjjw           1/1     Running   0          14h
    aide-ingress-fileintegrity-7rzqz           1/1     Running   0          14h
    aide-ingress-fileintegrity-88js4           1/1     Running   0          14h
    aide-master-fileintegrity-2n69h            1/1     Running   0          16h
    aide-master-fileintegrity-2sxxp            1/1     Running   0          16h
    aide-master-fileintegrity-5z4g7            1/1     Running   0          16h
    aide-worker-fileintegrity-7j8m5            1/1     Running   0          15h
    aide-worker-fileintegrity-cfpww            1/1     Running   0          15h
    aide-worker-fileintegrity-hrxlg            1/1     Running   0          15h
    aide-worker-fileintegrity-kzhx8            1/1     Running   0          15h
    aide-worker-fileintegrity-qphzt            1/1     Running   0          15h
    file-integrity-operator-76fc8b845d-ds9t7   1/1     Running   0          45h




