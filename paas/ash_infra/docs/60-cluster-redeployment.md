##Instructions to delete an existing cluster and cleanup ready for redeployment

1. In Azure Portal, delete the Resource Group containing the cluster infrastrcture, e.g. "ocp-cluster1". This will take some time.
2. Create a new, empty Resource Group with the same name
4. In the Private DNS Zone, delete the three OCP entries, leaving the defaults.
5. On the bootstrap quay VM, delete the installer manifest files for the cluster, e.g.
```
rm -r /ocp/ocp1
```
5. Follow the instructions in (40-deploy-cluster.md) from "run ./prep-cluster-config.sh" to create new installation manifest files