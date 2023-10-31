##Openshift Cluster Deployment

***Run these commands on the kickstart VM created on ASH***

1. Using Moba Xterm, edit configure-bootstrap.sh
    - ash_region='local'
    - ash_fqdn='azurestack.external'
    - ResourceGroup = openshift-offline1
    - Container = images1

1. From the home directory of the user account created at provisioning time, run this script:

```
./configure-bootstrap.sh
```
This will set up the environment for Azure Stack Hub on the local system.  

2. Execute the following statement to clean up the generated Certificates.pem file
```
sed -nie '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' Certificates.pem
```

3. Run the following commands (the region and FQDN should match the environment being deployed to)
```
export ash_region='local'
export ash_fqdn='azurestack.external'
```
4.  modify the prep-cluster-config.sh file.  Modify the variables to match the environment 
```bash
# these vars should be setup as env variables to be used on the ASH subscription
export sub_id=""
export cli_id=""
export cli_secret=""

ocp_instance="ocp1"
region="local"
base_domain='ocp.local'
mirror_address='quay.internal.cloudapp.net/quay/openshift4'
base_domain_rg='DNS'

ash_fqdn='azurestack.external'
rg_name='ocp-cluster1'
img_cont='images1'

PUB_SSH_KEY='xxx'

```
5. Update the file name suffix to match the image uploaded to the images1 container
```
clusterOSimage: https://${img_cont}.blob.${ash_region}.${ash_fqdn}/rhcos/rhcos-410.84.202205191234-0-azurestack.x86_64.vhd
```

6. run ./prep-cluster-config.sh

7. Install the cluster running the following command:
```bash
openshift-install create cluster --dir ./ocp/ocp1 --log-level debug
```
## Post-Install

[Red Hat Docs](https://docs.openshift.com/container-platform/4.10/post_installation_configuration/connected-to-disconnected.html)

From  the Linux VM:

1. Set the kubeadmin password environment variable
   ```
   export KUBECONFIG=~/ocp/ocp1/auth/kubeconfig
   ```

2. Check the Openshift status. Three master and five worker nodes are initially provisioned by the installer.
    ```
    oc status
    oc get nodes
    ```

3. Setup the catalogs
    ```
    oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=pull-secret.json

    oc create configmap registry-config --from-file=quay.internal.cloudapp.net..443=/home/adminuser/ssl/rootCA.pem -n openshift-config

    oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' --type=merge

    oc apply -f $(find /quay/oc-mirror/oc-mirror-workspace/ -name resul*) 
    <check the correct directory name, it varies!>
    ```

##Recreating Image Content Policy
If you need to recreate the image content policy for the OpenShift release you can use the following yaml

```
apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: mirror-ocp
spec:
  repositoryDigestMirrors:
  - mirrors:
    - quay.internal.cloudapp.net/quay/openshift4
    source: quay.io/openshift-release-dev/ocp-release 
  - mirrors:
    - quay.internal.cloudapp.net/quay/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
```

Save as image-content-source.yaml and run 
    ```
    oc apply -f image-content-source.yaml
    ```
