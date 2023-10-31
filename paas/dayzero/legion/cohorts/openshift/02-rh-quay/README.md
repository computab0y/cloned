# Red Hat Quay Cohort

This directory contains kustomize definitions for the installation of Red Hat Quay.

Quay is deployed using a dedicated Operator. Within this directory, there are kustomize definitions for the installation of the Quay Operator, the creation of a Noobaa based Object Bucket that Quay consumes, the creation of the Secret based bundle configuration and finally the deployment of the QuayRegistry CR, which is then used by the operator to deploy all required Quay services.

## Installation Steps

### Install the Operator using the `oc` CLI

The Operator needs installing first.

An overlay is provided to to deploy the Quay Operator version 3.7

```
$ oc create -k dayzero/legion/cohorts/openshift/05-rh-quay/quay-operator/overlays/stable-3.7
```

Verify the Operator has been deployed successfully. You should see output similar to the below.

```
$ oc get csv -n quay-enterprise
NAME                               DISPLAY                    VERSION   REPLACES                           PHASE
quay-operator.v3.7.6               Red Hat Quay               3.7.6     quay-operator.v3.7.5               Succeeded
```


### Create a Noobaa Object Bucket Claim using the `oc` CLI

Quay consumes an Object Bucket which is used to provide object storage to store container images.

An overlay is provided to to create an OBC within Noobaa (OCS) that Quay can consume.

```
$ oc create -k dayzero/legion/cohorts/openshift/05-rh-quay/quay-bucket-claim/base
```

Verify the OBC has been created successfully. You should see output similar to the below.

```
$ oc get obc -n quay-enterprise
NAME              STORAGE-CLASS                 PHASE   AGE
dso-quay-bucket   openshift-storage.noobaa.io   Bound   3h15m
```

### Create the Quay Configuration YAML File and Deploy Quay

Quay uses a YAML based configuration file, which is stored as a k8s Secret as it contains semi-sensitive data (API Keys to access the bucket).

IMPORTANT: Ensure the correct API keys and bucket names are updated in the file `quayregistry-config-bundle-data.yaml` using information gathered when creating the Object Bucket Claim above.

An overlay is provided to to create the Config Bundle Secret, and deploy Quay

```
$ oc create -k dayzero/legion/cohorts/openshift/05-rh-quay/quay-instance/base
```

Be aware this step may take a few minutes to complete.

Verify that Quay has been successfully deployed by navigating to the Quay homepage.
