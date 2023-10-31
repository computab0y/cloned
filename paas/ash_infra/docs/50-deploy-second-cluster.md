# Installing a second cluster on ASDK

## Pre-Reqs
An OCP1 cluster has already been deployed to ASDK in a Subscription called "ocp". This includes an openshift-offline Resource Group containing the bootstrap quay VM and a Resource Group containing the ocp.local private DNS Zone.

## Steps
1. Create a new Subscription in the ASDK Admin Portal called "ocp-prod".
2. Add the Service Principal as an Owner, team members as Contributors, to match the original ocp Subscription
3. Add a Resource Group called "DNS". Add a Private DNS Zone called "prod.ocp.local"
4. Add a Resource Group called "ocp-cluster2".
5. SSH onto the quay VM as adminuser
6. Create a "prod" prep script
```
cp prep-cluster-config.sh prep-cluster-prod.sh
nano prep-cluster-prod.sh
```
7. Update the following lines to configure for the new Subscription and Cluster
```
export sub_id="<subscription-id>"

ocp_instance="ocp2"

base_domain='prod.ocp.local'

rg_name='ocp-cluster2'

```
8. After the line az login, add the following to select the new Subscription: 
```
az account --set subscription "<subscription-id>"
```
9. Save and run the script
```
./prep-cluster-prod.sh
```
10. Run the OCP Installer
```
openshift-install create cluster --dir ./ocp/ocp2 --log-level debug
```
11. Monitor as per (40-deploy-cluster.md)