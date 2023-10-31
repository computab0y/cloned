Configuration

Pre-requisite
•	Installation of the cluster with ingress router pre-configured as default.
•	Ingress nodes to be configured/ deployed. Typically, we configure 3 ingress nodes, one onto each of the availability zones. 
This is part of the topology setup where the worker, infrastructure, storage and ingress nodes are setup into respective vnet’s.


Running below command to confirm ingress router is configured. This is defaulted to two instances and will typically be deployed onto the worker nodes.

```
oc get pod -n openshift-ingress -o wide
```

    NAME                              READY   STATUS    RESTARTS   AGE   IP           NODE                               NOMINATED NODE   READINESS GATES
    router-default-6b57f6558d-2kj6k   1/1     Running   0          17h   10.128.2.8   ocp3-6l8nl-worker-uksouth1-2wctj   <none>           <none>
    router-default-6b57f6558d-dcwmz   1/1     Running   0          17h   10.130.2.8   ocp3-6l8nl-worker-uksouth2-l8b25   <none>           <none>

View the ingresscontroller configuration:

```
oc get ingresscontroller default -n openshift-ingress-operator -o yaml
```

apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  creationTimestamp: "2022-04-19T13:15:31Z"
  finalizers:
  - ingresscontroller.operator.openshift.io/finalizer-ingresscontroller
  generation: 2
  name: default
  namespace: openshift-ingress-operator
  resourceVersion: "112484"
  uid: 47a22216-cd07-4373-8a87-5c145cbe9cac
spec:
  defaultCertificate:
    name: app-certs-001
  endpointPublishingStrategy:
    loadBalancer:
      scope: Internal
    type: LoadBalancerService
  httpErrorCodePages:
    name: ""
  tuningOptions: {}
  unsupportedConfigOverrides: null
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2022-04-19T13:23:13Z"
    reason: Valid
    status: "True"
    type: Admitted
  - lastTransitionTime: "2022-04-19T13:28:46Z"
    status: "True"
    type: PodsScheduled
  - lastTransitionTime: "2022-04-19T13:29:35Z"
    message: The deployment has Available status condition set to True
    reason: DeploymentAvailable
    status: "True"
    type: DeploymentAvailable
  - lastTransitionTime: "2022-04-19T13:29:35Z"
    message: Minimum replicas requirement is met
    reason: DeploymentMinimumReplicasMet
    status: "True"
    type: DeploymentReplicasMinAvailable
  - lastTransitionTime: "2022-04-19T16:55:02Z"
    message: All replicas are available
    reason: DeploymentReplicasAvailable
    status: "True"
    type: DeploymentReplicasAllAvailable
  - lastTransitionTime: "2022-04-19T13:23:14Z"
    message: The endpoint publishing strategy supports a managed load balancer
    reason: WantedByEndpointPublishingStrategy
    status: "True"
    type: LoadBalancerManaged
  - lastTransitionTime: "2022-04-19T13:24:18Z"
    message: The LoadBalancer service is provisioned
    reason: LoadBalancerProvisioned
    status: "True"
    type: LoadBalancerReady
  - lastTransitionTime: "2022-04-19T13:23:14Z"
    message: DNS management is supported and zones are specified in the cluster DNS
      config.
    reason: Normal
    status: "True"
    type: DNSManaged
  - lastTransitionTime: "2022-04-19T13:24:19Z"
    message: The record is provisioned in all reported zones.
    reason: NoFailedZones
    status: "True"
    type: DNSReady
  - lastTransitionTime: "2022-04-19T13:29:35Z"
    status: "True"
    type: Available
  - lastTransitionTime: "2022-04-19T13:29:35Z"
    status: "False"
    type: Degraded
  - lastTransitionTime: "2022-04-19T13:29:02Z"
    message: Canary route checks for the default ingress controller are successful
    reason: CanaryChecksSucceeding
    status: "True"
    type: CanaryChecksSucceeding
  domain: apps.ocp3.azure.dso.digital.mod.uk
  endpointPublishingStrategy:
    loadBalancer:
      scope: Internal
    type: LoadBalancerService
  observedGeneration: 2
  selector: ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default
  tlsProfile:
    ciphers:
    - TLS_AES_128_GCM_SHA256
    - TLS_AES_256_GCM_SHA384
    - TLS_CHACHA20_POLY1305_SHA256
    - ECDHE-ECDSA-AES128-GCM-SHA256
    - ECDHE-RSA-AES128-GCM-SHA256
    - ECDHE-ECDSA-AES256-GCM-SHA384
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-ECDSA-CHACHA20-POLY1305
    - ECDHE-RSA-CHACHA20-POLY1305
    - DHE-RSA-AES128-GCM-SHA256
    - DHE-RSA-AES256-GCM-SHA384
    minTLSVersion: VersionTLS12


Edit the ingress contoller to move the routers to the ingress nodes and set the replica set to 3. This is done by adding nodeselector and tolerances to ensure the routers are only deployed on the ingress nodes.

```
oc edit ingresscontroller default -n openshift-ingress-operator
```

apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  creationTimestamp: "2021-11-17T10:17:23Z"
  finalizers:
  - ingresscontroller.operator.openshift.io/finalizer-ingresscontroller
  generation: 8
  name: default
  namespace: openshift-ingress-operator
  resourceVersion: "402381379"
  uid: 024dd5e6-76be-48b6-84b9-3f8d9e5533db
spec:
  defaultCertificate:
    name: app-certs-001
  endpointPublishingStrategy:
    loadBalancer:
      scope: Internal
    type: LoadBalancerService
  httpErrorCodePages:
    name: ""
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/ingress: ""
    tolerations:
    - effect: NoSchedule
      operator: Exists
    - effect: NoExecute
      operator: Exists
  replicas: 3
  tuningOptions: {}
  unsupportedConfigOverrides: null
status:
  availableReplicas: 3
  conditions:
  - lastTransitionTime: "2021-11-17T10:26:25Z"
    reason: Valid
    status: "True"
    type: Admitted
  - lastTransitionTime: "2022-04-19T19:21:06Z"
    status: "True"
    type: PodsScheduled
  - lastTransitionTime: "2022-04-19T15:44:28Z"
    message: The deployment has Available status condition set to True
    reason: DeploymentAvailable
    status: "True"
    type: DeploymentAvailable
  - lastTransitionTime: "2022-04-19T15:44:28Z"
    message: Minimum replicas requirement is met
    reason: DeploymentMinimumReplicasMet
    status: "True"
    type: DeploymentReplicasMinAvailable
  - lastTransitionTime: "2022-04-19T19:23:44Z"
    message: All replicas are available
    reason: DeploymentReplicasAvailable
    status: "True"
    type: DeploymentReplicasAllAvailable
  - lastTransitionTime: "2021-11-17T10:26:27Z"
    message: The endpoint publishing strategy supports a managed load balancer
    reason: WantedByEndpointPublishingStrategy
    status: "True"
    type: LoadBalancerManaged
  - lastTransitionTime: "2021-11-17T10:27:38Z"
    message: The LoadBalancer service is provisioned
    reason: LoadBalancerProvisioned
    status: "True"
    type: LoadBalancerReady
  - lastTransitionTime: "2021-11-17T10:26:27Z"
    message: DNS management is supported and zones are specified in the cluster DNS
      config.
    reason: Normal
    status: "True"
    type: DNSManaged
  - lastTransitionTime: "2021-11-17T10:27:39Z"
    message: The record is provisioned in all reported zones.
    reason: NoFailedZones
    status: "True"
    type: DNSReady
  - lastTransitionTime: "2022-04-19T15:44:28Z"
    status: "True"
    type: Available
  - lastTransitionTime: "2021-12-06T13:54:08Z"
    status: "False"
    type: Degraded
  - lastTransitionTime: "2021-11-17T10:32:07Z"
    message: Canary route checks for the default ingress controller are successful
    reason: CanaryChecksSucceeding
    status: "True"
    type: CanaryChecksSucceeding
  domain: apps.ocp1.azure.dso.digital.mod.uk
  endpointPublishingStrategy:
    loadBalancer:
      scope: Internal
    type: LoadBalancerService
  observedGeneration: 8
  selector: ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default
  tlsProfile:
    ciphers:
    - TLS_AES_128_GCM_SHA256
    - TLS_AES_256_GCM_SHA384
    - TLS_CHACHA20_POLY1305_SHA256
    - ECDHE-ECDSA-AES128-GCM-SHA256
    - ECDHE-RSA-AES128-GCM-SHA256
    - ECDHE-ECDSA-AES256-GCM-SHA384
    - ECDHE-RSA-AES256-GCM-SHA384
    - ECDHE-ECDSA-CHACHA20-POLY1305
    - ECDHE-RSA-CHACHA20-POLY1305
    - DHE-RSA-AES128-GCM-SHA256
    - DHE-RSA-AES256-GCM-SHA384
    minTLSVersion: VersionTLS12

There is no need to apply the changes. Save the ingresscontroller yaml file and it will auto apply. The routers will move across to the ingress nodes automatically:

```
oc get pod -n openshift-ingress -o wide
```

    NAME                              READY   STATUS    RESTARTS   AGE   IP           NODE                                NOMINATED NODE   READINESS GATES
    router-default-74645644bc-fzsb8   1/1     Running   0          24m   10.xxx.xxx.xxx   ocpx-xxxxx-ingress-uksouth3-876jx   <none>           <none>
    router-default-74645644bc-w6qnt   1/1     Running   0          10m   10.xxx.xxx.xxx   ocpx-xxxxx-ingress-uksouth2-qpvsz   <none>           <none>
    router-default-74645644bc-wx45f   1/1     Running   0          24m   10.xxx.xxx.xxx   ocpx-xxxxx-ingress-uksouth1-s8mpv   <none>           <none>


