# RedHat Advanced Custer Security (RHACS)

This installation contains kustomize definitions for the installation of Red Hat Advanced Cluster Security.

The install is separated into two parts, the RHACS Operator install into the openshift-operators namespace and the install for both Central and SecureCluster instances with the sensors into the stackrox namespace.

## Installation Steps

### Install the Operator using the `oc` CLI

```
$ oc create -k dayzero/legion/cohorts/openshift/rhacs/rhacs-operator/overlays/latest/
```

Verify the Operator has been deployed successfully. You should see output similar to the below.

```
oc get csv -n openshift-operators

$ NAME                                     DISPLAY                                          VERSION    REPLACES                            PHASE
rhacs-operator.v3.69.1                   Advanced Cluster Security for Kubernetes         3.69.1     rhacs-operator.v3.69.0              Succeeded
```

Once the operator is running in openshift-operators you can then install an instance with the following command:

```
$ oc create -k dayzero/legion/cohorts/openshift/rhacs/rhacs-instances/base/
```

This will create a `stackrox` namespace and install `central` as well as a the `securedcluster`. Stackrox requires a cluster-init bundle to be deployed to link the two, a job in the stackrox namespace will run to do this. 

Check pods have been created successfully in the `stackrox` namespace

```
$ oc project stackrox
```

```
$ oc get pod -o wide
```

    NAME                                 READY   STATUS      RESTARTS   AGE   IP               NODE                                NOMINATED NODE   READINESS     GATES
    admission-control-857c9f8bfc-2r8sn   1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth2-9pkdz     <none>           <none>
    admission-control-857c9f8bfc-5ft2n   1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth3-hn878     <none>           <none>
    admission-control-857c9f8bfc-pn5hk   1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth1-p895p     <none>           <none>
    central-679c65586f-mkbnc             1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth2-9pkdz     <none>           <none>
    collector-29d84                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-storage-uksouth3-zf8lj   <none>           <none>
    collector-4dcg4                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth3-hn878     <none>           <none>
    collector-6nrvs                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-worker-uksouth2-49vnk    <none>           <none>
    collector-7d4fq                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-storage-uksouth1-c67sz   <none>           <none>
    collector-d9r22                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-ingress-uksouth1-8lrr4   <none>           <none>
    collector-jdbq6                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-storage-uksouth2-j7f6p   <none>           <none>
    collector-jqh7h                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-worker-uksouth3-22ngm    <none>           <none>
    collector-k76h8                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-ingress-uksouth3-6xssr   <none>           <none>
    collector-lcbt8                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-ingress-uksouth2-v88wh   <none>           <none>
    collector-m7jw9                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth1-p895p     <none>           <none>
    collector-mf6rp                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-master-0                 <none>           <none>
    collector-mscqj                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-worker-uksouth2-znxmd    <none>           <none>
    collector-rs7jw                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-worker-uksouth1-jvs9b    <none>           <none>
    collector-rskrp                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth2-9pkdz     <none>           <none>
    collector-tn9xs                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-master-1                 <none>           <none>
    collector-tt95p                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth1-sdjc2     <none>           <none>
    collector-xxhbc                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-master-2                 <none>           <none>
    collector-zbvcn                      2/2     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-worker-uksouth1-hhcsc    <none>           <none>
    create-cluster-init-bundle-zf6lb     0/1     Completed   0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-worker-uksouth2-znxmd    <none>           <none>
    scanner-7854d7779c-5cb5w             1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth2-9pkdz     <none>           <none>
    scanner-7854d7779c-gvclc             1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth1-p895p     <none>           <none>
    scanner-7854d7779c-psqxp             1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth3-hn878     <none>           <none>
    scanner-db-6597456b8d-nf5q2          1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth2-9pkdz     <none>           <none>
    sensor-59bb64fc47-m9z2q              1/1     Running     0          29h   10.xxx.xxx.xxx   ocpx-xxx9x-infra-uksouth1-p895p     <none>           <none>


Update the `central` route

Take a local back-up of the current central route YAML 

```
oc get route central -o yaml > central.yml
```

Extract the secret for secret/central-tls

```
oc extract secret/central-tls --keys ca.pem
```

View the certificate
cat ca.pem

Edit the route, add the destinationCACertificate, set the termination type to reencrypt :

```
oc edit route/central
```

      tls:
        destinationCACertificate: |-
          -----BEGIN CERTIFICATE-----
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
          -----END CERTIFICATE-----
        termination: reencrypt


Save and exit


