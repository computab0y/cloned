
MACHINESET_NAME=$(oc get machineset -n openshift-machine-api | awk 'NR==2 {print $1}') 


#this gets the cluster name
INFRASTRUCTURE_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster)
#ocp3-6px9x
#for role in $(cat worker-nodes.txt) ; do cp template.yaml <infrastructure_id>-$ROLE-$LOCATION$REGION.yaml ;done 
#cp template/ingress-nodes-template.yaml $INFRASTRUCTURE_ID-ingress-machineset.yaml 
cp template/storage-nodes-template.yaml $INFRASTRUCTURE_ID-storage-machineset.yaml 
cp template/infra-nodes-template.yaml $INFRASTRUCTURE_ID-infra-machineset.yaml 
cp template/worker-nodes-template.yaml $INFRASTRUCTURE_ID-worker-machineset.yaml 



#this gets the subnet
SUBNET=$(oc -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.subnet}{"\n"}' get machineset/$MACHINESET_NAME)
#compute_subnet	
ROLE=worker
VNET=$(oc -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.vnet}{"\n"}' get machineset/$MACHINESET_NAME)
#vnet-ocp3-sbox-uks

#get resourcegroup
RESOURCEGROUP=$(oc -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.resourceGroup}{"\n"}' get machineset/$MACHINESET_NAME)
#rg-ocp3-sbox-uks

#get networkresourcegroup
NETWORKRESOURCEGROUP=$(oc -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.networkResourceGroup}{"\n"}' get machineset/$MACHINESET_NAME)
#rg-ocp3mgmt-sbox-uks

#LOCATION=uksouth
#REGION=1 

sed -i 's/<infrastructure_id>/'$INFRASTRUCTURE_ID'/g' *.yaml
sed -i 's/<machineset_name>/'$MACHINESET_NAME'/g' *.yaml
sed -i 's/<subnet>/'$SUBNET'/g' *.yaml
sed -i 's/<vnet>/'$VNET'/g' *.yaml
sed -i 's/<resourcegroup>/'$RESOURCEGROUP'/g' *.yaml
sed -i 's/<networkresourcegroup>/'$NETWORKRESOURCEGROUP'/g' *.yaml
