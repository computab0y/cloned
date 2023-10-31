#this gets the cluster name
INFRASTRUCTURE_ID=$(oc get -o jsonpath='{.status.infrastructureName}{"\n"}' infrastructure cluster)
#ocp3-6px9x
#for role in $(cat worker-nodes.txt) ; do cp template.yaml <infrastructure_id>-$ROLE-$LOCATION$REGION.yaml ;done 


sed -i 's/<cluster-name>/'$INFRASTRUCTURE_ID'/g' env.properties
sed -i 's/<cluster-name>/'$INFRASTRUCTURE_ID'/g' patch*.yaml

#LOCATION=uksouth
#REGION=1 

